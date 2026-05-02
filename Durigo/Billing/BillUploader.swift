//
//  BillUploader.swift
//  Durigo
//
//  Uploads bills to the web backend (POST /api/bills/upload). Idempotent on the
//  server side via Order.externalId = BillHistoryItem.id, so re-uploading a bill
//  is safe (e.g. after payment status changes).
//

import Foundation
import SwiftData

enum BillSyncError: LocalizedError {
    case tokenMissing
    case unauthorized
    case server(code: Int, body: String?)
    case network(Error)
    case decoding(Error)

    var errorDescription: String? {
        switch self {
        case .tokenMissing:
            return "No bill upload token configured. Add BILL_UPLOAD_API_TOKEN in Settings."
        case .unauthorized:
            return "Server rejected the upload token. Re-enter it in Settings."
        case .server(let code, let body):
            return "Server returned \(code)\(body.map { ": \($0)" } ?? "")"
        case .network(let underlying):
            return "Network error: \(underlying.localizedDescription)"
        case .decoding(let underlying):
            return "Couldn't decode server response: \(underlying.localizedDescription)"
        }
    }
}

struct UploadSummary {
    let attempted: Int
    let succeeded: [UUID]
    let failed: [(id: UUID, error: BillSyncError)]
}

struct DownloadSummary {
    let pagesFetched: Int
    let billsInserted: Int
    let billsUpdated: Int
    let billsSkipped: Int
}

@MainActor
@Observable
final class BillUploader {
    private let session: URLSession
    private let baseURL: URL

    var isUploading: Bool = false
    var lastError: BillSyncError?
    var progress: (done: Int, total: Int)?

    init(baseURL: URL = URL(string: Config.shared.serverURL) ?? URL(string: "http://localhost:3000")!,
         session: URLSession = NetworkHelper.shared.currentSession) {
        self.baseURL = baseURL
        self.session = session
    }

    private func uploadURL() -> URL {
        baseURL.appending(path: "/api/bills/upload")
    }

    private func downloadURL(cursor: String?, limit: Int) -> URL {
        var components = URLComponents(url: baseURL.appending(path: "/api/bills"), resolvingAgainstBaseURL: false)!
        var query: [URLQueryItem] = [URLQueryItem(name: "limit", value: String(limit))]
        if let cursor { query.append(URLQueryItem(name: "cursor", value: cursor)) }
        components.queryItems = query
        return components.url!
    }

    private func token() throws -> String {
        guard let t = KeychainHelper.load(.billUploadToken), !t.isEmpty else {
            throw BillSyncError.tokenMissing
        }
        return t
    }

    /// Upload a single bill. Sets `syncedAt` on success.
    func uploadOne(_ bill: BillHistoryItem) async throws {
        try await uploadMany([bill])
    }

    /// Upload many bills in one request. Sets `syncedAt` on each that the server confirms.
    /// Doesn't throw on per-bill failures; returns a summary instead.
    @discardableResult
    func uploadMany(_ bills: [BillHistoryItem]) async throws -> UploadSummary {
        guard !bills.isEmpty else {
            return UploadSummary(attempted: 0, succeeded: [], failed: [])
        }

        let authToken = try token()
        isUploading = true
        progress = (done: 0, total: bills.count)
        lastError = nil
        defer {
            isUploading = false
            progress = nil
        }

        let payload = DurigoBills(items: bills.map { BillHistoryItemCopy(billHistoryItem: $0) })
        let body: Data
        do {
            body = try JSONEncoder().encode(payload)
        } catch {
            lastError = .decoding(error)
            throw BillSyncError.decoding(error)
        }

        var request = URLRequest(url: uploadURL())
        request.httpMethod = "POST"
        request.setValue("Bearer \(authToken)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = body
        request.timeoutInterval = 120

        let (data, response): (Data, URLResponse)
        do {
            (data, response) = try await session.data(for: request)
        } catch {
            lastError = .network(error)
            throw BillSyncError.network(error)
        }

        guard let http = response as? HTTPURLResponse else {
            let err = BillSyncError.server(code: -1, body: nil)
            lastError = err
            throw err
        }

        if http.statusCode == 401 {
            lastError = .unauthorized
            throw BillSyncError.unauthorized
        }

        guard (200..<300).contains(http.statusCode) else {
            let bodyStr = String(data: data, encoding: .utf8)
            let err = BillSyncError.server(code: http.statusCode, body: bodyStr)
            lastError = err
            throw err
        }

        // Decode server response
        struct Result: Decodable {
            let externalId: String
            let created: Bool
        }
        struct Response: Decodable {
            let uploaded: Int
            let created: Int
            let updated: Int
            let failed: Int?
            let results: [Result]
        }

        let decoded: Response
        do {
            decoded = try JSONDecoder().decode(Response.self, from: data)
        } catch {
            lastError = .decoding(error)
            throw BillSyncError.decoding(error)
        }

        let now = Date()
        let confirmed = Set(decoded.results.compactMap { UUID(uuidString: $0.externalId) })
        var succeeded: [UUID] = []
        for bill in bills where confirmed.contains(bill.id) {
            bill.syncedAt = now
            succeeded.append(bill.id)
        }

        let failed: [(id: UUID, error: BillSyncError)] = bills
            .filter { !confirmed.contains($0.id) }
            .map { ($0.id, BillSyncError.server(code: 200, body: "not in server response")) }

        progress = (done: bills.count, total: bills.count)
        return UploadSummary(attempted: bills.count, succeeded: succeeded, failed: failed)
    }

    /// Download all bills from the server, paginated. Inserts new bills into the
    /// given context; updates existing bills (matched by id) in place. Bills returned
    /// from the server are by definition synced, so syncedAt is set to "now" on insert.
    @discardableResult
    func downloadAll(into context: ModelContext, pageSize: Int = 200) async throws -> DownloadSummary {
        let authToken = try token()
        isUploading = true
        progress = nil
        lastError = nil
        defer { isUploading = false; progress = nil }

        struct PageResponse: Decodable {
            let items: [BillHistoryItemCopy]
            let nextCursor: String?
        }

        var cursor: String? = nil
        var pages = 0
        var inserted = 0
        var updated = 0
        var skipped = 0

        repeat {
            var request = URLRequest(url: downloadURL(cursor: cursor, limit: pageSize))
            request.httpMethod = "GET"
            request.setValue("Bearer \(authToken)", forHTTPHeaderField: "Authorization")
            request.timeoutInterval = 60

            let (data, response): (Data, URLResponse)
            do {
                (data, response) = try await session.data(for: request)
            } catch {
                lastError = .network(error)
                throw BillSyncError.network(error)
            }

            guard let http = response as? HTTPURLResponse else {
                let err = BillSyncError.server(code: -1, body: nil)
                lastError = err
                throw err
            }

            if http.statusCode == 401 {
                lastError = .unauthorized
                throw BillSyncError.unauthorized
            }

            guard (200..<300).contains(http.statusCode) else {
                let bodyStr = String(data: data, encoding: .utf8)
                let err = BillSyncError.server(code: http.statusCode, body: bodyStr)
                lastError = err
                throw err
            }

            let page: PageResponse
            do {
                page = try JSONDecoder().decode(PageResponse.self, from: data)
            } catch {
                lastError = .decoding(error)
                throw BillSyncError.decoding(error)
            }

            pages += 1
            let now = Date()

            for copy in page.items {
                // Look up existing by ID
                let id = copy.id
                let descriptor = FetchDescriptor<BillHistoryItem>(predicate: #Predicate { $0.id == id })
                let existing = (try? context.fetch(descriptor))?.first

                if let existing {
                    // Update in place — server is authoritative
                    existing.date = copy.date
                    existing.tableNumber = copy.tableNumber
                    existing.waiter = copy.waiter
                    existing.paymentStatus = BillHistoryItemStatus(rawValue: copy.paymentStatus.rawValue) ?? .pending
                    existing.items = copy.items
                    existing.syncedAt = now
                    updated += 1
                } else {
                    let bill = copy.convertToBillHistoryItem()
                    bill.syncedAt = now
                    context.insert(bill)
                    inserted += 1
                }
            }
            try? context.save()
            progress = (done: inserted + updated, total: inserted + updated)

            cursor = page.nextCursor
        } while cursor != nil

        return DownloadSummary(pagesFetched: pages, billsInserted: inserted, billsUpdated: updated, billsSkipped: skipped)
    }
}
