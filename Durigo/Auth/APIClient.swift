//
//  APIClient.swift
//  Durigo
//
//  Thin URLSession wrapper that sends the auth-token cookie on every request.
//  All future iOS-side API calls should go through this.
//

import Foundation

enum APIError: LocalizedError {
    case unauthorized
    case server(code: Int, body: String?)
    case network(Error)
    case decoding(Error)
    case badResponse

    var errorDescription: String? {
        switch self {
        case .unauthorized: return "Session expired — please sign in again."
        case .server(let code, let body): return "Server returned \(code)\(body.map { ": \($0)" } ?? "")"
        case .network(let err): return "Network error: \(err.localizedDescription)"
        case .decoding(let err): return "Couldn't decode response: \(err.localizedDescription)"
        case .badResponse: return "Unexpected response from server."
        }
    }
}

@MainActor
final class APIClient {
    let baseURL: URL
    private let session: URLSession
    private weak var authSession: Session?

    init(session: Session,
         baseURL: URL = URL(string: Config.shared.serverURL) ?? URL(string: "http://localhost:3000")!,
         urlSession: URLSession = NetworkHelper.shared.currentSession) {
        self.authSession = session
        self.baseURL = baseURL
        self.session = urlSession
    }

    func get(_ path: String, query: [URLQueryItem] = []) async throws -> Data {
        try await execute(method: "GET", path: path, query: query, body: nil)
    }

    func post(_ path: String, body: Data?, query: [URLQueryItem] = []) async throws -> Data {
        try await execute(method: "POST", path: path, query: query, body: body)
    }

    func postJSON<T: Encodable>(_ path: String, payload: T, query: [URLQueryItem] = []) async throws -> Data {
        let body = try JSONEncoder().encode(payload)
        return try await execute(method: "POST", path: path, query: query, body: body)
    }

    private func execute(method: String, path: String, query: [URLQueryItem], body: Data?) async throws -> Data {
        var components = URLComponents(url: baseURL.appending(path: path), resolvingAgainstBaseURL: false)!
        if !query.isEmpty {
            components.queryItems = query
        }
        guard let url = components.url else {
            throw APIError.badResponse
        }

        var request = URLRequest(url: url)
        request.httpMethod = method
        request.timeoutInterval = 60

        if let token = authSession?.token {
            // Send as Cookie (matches what proxy.ts reads).
            request.setValue("auth-token=\(token)", forHTTPHeaderField: "Cookie")
        }

        if let body {
            request.httpBody = body
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        }

        let (data, response): (Data, URLResponse)
        do {
            (data, response) = try await session.data(for: request)
        } catch {
            throw APIError.network(error)
        }

        guard let http = response as? HTTPURLResponse else {
            throw APIError.badResponse
        }

        if http.statusCode == 401 {
            // Token expired or invalid — sign out so app shows the login screen.
            authSession?.signOut()
            throw APIError.unauthorized
        }

        guard (200..<300).contains(http.statusCode) else {
            let bodyStr = String(data: data, encoding: .utf8)
            throw APIError.server(code: http.statusCode, body: bodyStr)
        }

        return data
    }
}
