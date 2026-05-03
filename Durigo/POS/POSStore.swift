//
//  POSStore.swift
//  Durigo
//
//  Observable store backing the POS feature. Holds tables + admin-shape menu
//  + an SSE subscription so the tables grid stays live. All requests go
//  through APIClient (cookie auth, 401 handling).
//
//  AdminMenuItem / AdminCategory / AdminVariantTemplate are reused from
//  Menu/MenuEditor.swift — the same shape /api/admin/menu returns.
//

import Foundation
import SwiftUI

// MARK: - Variant pricing helper

extension AdminVariantTemplate {
    /// Effective unit price given a base price. The web stores `priceEquation`
    /// strings like "1.5", "0.5*x", "x+100" — `x` is the base. We try numeric
    /// (multiplier shorthand) first, fall back to NSExpression, fall back to
    /// the explicit `multiplier` field.
    func price(forBase base: Double) -> Double {
        let trimmed = priceEquation.trimmingCharacters(in: .whitespaces)
        if let mult = Double(trimmed) {
            return base * mult
        }
        let substituted = trimmed.replacingOccurrences(of: "x", with: "(\(base))")
        if let val = NSExpression(format: substituted).expressionValue(with: nil, context: nil) as? NSNumber {
            return val.doubleValue
        }
        return base * multiplier
    }
}

// MARK: - Cart line item used by TakeOrderView

struct CartLine: Identifiable {
    let id = UUID()
    let menuItem: AdminMenuItem
    let variant: AdminVariantTemplate?
    var quantity: Int
    var notes: String?

    var unitPrice: Double {
        let base = Double(menuItem.price)
        if let variant {
            return variant.price(forBase: base)
        }
        return base
    }

    var lineTotal: Double { unitPrice * Double(quantity) }
}

// MARK: - Store

@MainActor
@Observable
final class POSStore {
    var tables: [POSTable] = []
    var menu: [AdminMenuItem] = []
    var categories: [AdminCategory] = []
    var waiters: [WaiterRef] = []
    var tableGroups: [POSTableGroup] = []
    /// Upcoming reservations — surfaces the next-arriving party on each
    /// Available table's card. Includes today + tomorrow + further dates.
    var upcomingReservations: [POSReservation] = []
    /// Currently selected waiter for new orders. Persisted across orders
    /// within a session via UserDefaults so the picker remembers the last
    /// choice even if POSStore is recreated.
    var selectedWaiterId: String? {
        didSet { UserDefaults.standard.set(selectedWaiterId, forKey: "POS.selectedWaiterId") }
    }
    var isLoading: Bool = false
    var lastError: String?
    var sseConnected: Bool = false

    private let api: APIClient
    private var sseTask: Task<Void, Never>?

    init(api: APIClient) {
        self.api = api
        self.selectedWaiterId = UserDefaults.standard.string(forKey: "POS.selectedWaiterId")
    }

    // MARK: Table groups (merge)

    func loadTableGroups() async {
        do {
            let data = try await api.get("/api/tables/groups")
            self.tableGroups = try JSONDecoder().decode([POSTableGroup].self, from: data)
        } catch {
            // Non-fatal: groups are an optional display layer.
        }
    }

    /// Set of table IDs currently inside any merged group — used to render
    /// the merged badge on table cards and gate which tables can be merged.
    var groupedTableIds: Set<String> {
        Set(tableGroups.flatMap { $0.members.map { $0.tableId } })
    }

    @discardableResult
    func mergeTables(name: String?, tableIds: [String], primaryTableId: String) async throws -> POSTableGroup {
        let payload = CreateGroupRequest(name: name, tableIds: tableIds, primaryTableId: primaryTableId)
        let data = try await api.postJSON("/api/tables/groups", payload: payload)
        let group = try JSONDecoder().decode(POSTableGroup.self, from: data)
        tableGroups.append(group)
        return group
    }

    func unmergeGroup(_ groupId: String) async throws {
        _ = try await api.delete("/api/tables/groups/\(groupId)")
        tableGroups.removeAll { $0.id == groupId }
    }

    // MARK: Reservations

    func loadUpcomingReservations() async {
        do {
            let data = try await api.get("/api/reservations/upcoming")
            // The endpoint sometimes returns a bare array, sometimes a
            // wrapped object — handle both shapes defensively.
            if let arr = try? JSONDecoder().decode([POSReservation].self, from: data) {
                self.upcomingReservations = arr
            } else {
                struct Wrapper: Decodable { let reservations: [POSReservation]? }
                self.upcomingReservations = (try? JSONDecoder().decode(Wrapper.self, from: data))?.reservations ?? []
            }
        } catch {
            // Non-fatal — reservation indicator is purely additive UX.
        }
    }

    /// Returns the next reservation for a given table (PENDING / CONFIRMED,
    /// soonest first). Used by TableCardView for the Available-card hint.
    func nextReservation(for tableId: String) -> POSReservation? {
        upcomingReservations
            .filter { $0.tableId == tableId && ["PENDING", "CONFIRMED"].contains($0.status.uppercased()) }
            .sorted { ($0.date, $0.time) < ($1.date, $1.time) }
            .first
    }

    @discardableResult
    func createReservation(tableId: String,
                           guestName: String,
                           guestPhone: String,
                           guestCount: Int,
                           date: String,
                           time: String,
                           duration: Int = 120,
                           notes: String? = nil) async throws -> POSReservation {
        let payload = CreateReservationRequest(
            tableId: tableId,
            guestName: guestName,
            guestPhone: guestPhone,
            guestCount: guestCount,
            date: date,
            time: time,
            duration: duration,
            notes: notes
        )
        let data = try await api.postJSON("/api/reservations", payload: payload)
        return try JSONDecoder().decode(POSReservation.self, from: data)
    }

    func loadWaiters() async {
        do {
            let data = try await api.get("/api/users/waiters")
            self.waiters = try JSONDecoder().decode([WaiterRef].self, from: data)
            // If the previously-selected waiter is no longer active or
            // doesn't exist, drop the selection so the UI prompts for one.
            if let id = selectedWaiterId, !waiters.contains(where: { $0.id == id }) {
                selectedWaiterId = nil
            }
        } catch {
            lastError = "Failed to load waiters: \(error.localizedDescription)"
        }
    }

    // MARK: Tables

    func loadTables() async {
        isLoading = true
        defer { isLoading = false }
        do {
            let data = try await api.get("/api/tables")
            let decoded = try JSONDecoder().decode([POSTable].self, from: data)
            self.tables = decoded.sorted { $0.number < $1.number }
        } catch {
            lastError = "Failed to load tables: \(error.localizedDescription)"
        }
    }

    // MARK: Menu (admin shape — real CUIDs)

    func loadMenu() async {
        do {
            async let menuData = api.get("/api/admin/menu")
            async let catData = api.get("/api/admin/categories")
            let decoder = JSONDecoder()
            self.menu = try decoder.decode([AdminMenuItem].self, from: try await menuData)
            self.categories = try decoder.decode([AdminCategory].self, from: try await catData)
        } catch {
            lastError = "Failed to load menu: \(error.localizedDescription)"
        }
    }

    // MARK: Place order

    @discardableResult
    func placeOrder(tableId: String?,
                    type: OrderType,
                    cart: [CartLine],
                    notes: String? = nil,
                    customerName: String? = nil,
                    customerPhone: String? = nil) async throws -> POSOrder {
        let payload = CreateOrderRequest(
            tableId: tableId,
            type: type.rawValue,
            items: cart.map { line in
                CreateOrderRequest.Item(
                    menuItemId: line.menuItem.id,
                    variantTemplateId: line.variant?.id,
                    quantity: line.quantity,
                    unitPrice: line.unitPrice,
                    notes: line.notes
                )
            },
            notes: notes,
            customerName: customerName,
            customerPhone: customerPhone,
            customerAddress: nil,
            waiterId: selectedWaiterId
        )
        let data = try await api.postJSON("/api/pos/orders", payload: payload)
        let order = try JSONDecoder().decode(POSOrder.self, from: data)

        // Optimistic local update so UI reflects new order before SSE arrives.
        if let tableId, type == .dineIn,
           let idx = tables.firstIndex(where: { $0.id == tableId }) {
            let existing = tables[idx]
            var newOrders = existing.orders ?? []
            newOrders.append(order)
            tables[idx] = POSTable(
                id: existing.id,
                number: existing.number,
                capacity: existing.capacity,
                status: "OCCUPIED",
                orders: newOrders
            )
        }
        return order
    }

    // MARK: Bill request + payment

    /// Mark a table as BILL_REQUESTED — flips the visual state on every
    /// connected device (waiters know to deliver the bill, cashier knows
    /// payment is pending). Mirrors the web's PUT /api/admin/tables/{id}.
    func requestBill(tableId: String) async throws {
        struct Payload: Encodable { let status: String }
        _ = try await api.putJSON("/api/admin/tables/\(tableId)", payload: Payload(status: "BILL_REQUESTED"))
        // Optimistic: flip local state immediately.
        if let idx = tables.firstIndex(where: { $0.id == tableId }) {
            let t = tables[idx]
            tables[idx] = POSTable(id: t.id, number: t.number, capacity: t.capacity,
                                    status: "BILL_REQUESTED", orders: t.orders)
        }
    }

    /// Process payment for an entire table — mirrors web's `processPayment`:
    /// 1) POST a payment record against one of the orders (the table's
    ///    "anchor"; the server only accepts one payment per order)
    /// 2) PATCH all live orders for the table to COMPLETED
    /// 3) PUT the table back to AVAILABLE
    /// Steps 2–3 are best-effort — even if the SSE/websocket lag means
    /// our local state is briefly stale, the next /api/tables fetch
    /// reconciles.
    func processPayment(table: POSTable, total: Double, method: String) async throws {
        let liveOrders = table.liveOrders
        guard let anchor = liveOrders.first else { return }

        struct PaymentBody: Encodable {
            let subtotal: Double
            let tax: Double
            let total: Double
            let method: String
        }
        // Web treats price as tax-inclusive (page.tsx:168-169) so we send
        // tax: 0 and subtotal == total. The TAX_RATE config is purely for
        // receipt display, not for adjusting payment math.
        let body = PaymentBody(subtotal: total, tax: 0, total: total, method: method)
        do {
            _ = try await api.postJSON("/api/orders/\(anchor.id)/payment", payload: body)
        } catch let APIError.server(code: _, body: errBody) {
            // "Payment already exists" is non-fatal — fall through and
            // still complete the orders. Mirrors web's catch in page.tsx.
            if errBody?.lowercased().contains("already exists") != true { throw APIError.server(code: 0, body: errBody) }
        }

        // Complete every live order on the table in parallel.
        struct StatusBody: Encodable { let status: String }
        try await withThrowingTaskGroup(of: Void.self) { group in
            for o in liveOrders {
                group.addTask { [api] in
                    _ = try await api.patch(
                        "/api/orders/\(o.id)/status",
                        body: try JSONEncoder().encode(StatusBody(status: "COMPLETED"))
                    )
                }
            }
            try await group.waitForAll()
        }

        // Free the table.
        struct TableStatusBody: Encodable { let status: String }
        _ = try await api.putJSON("/api/admin/tables/\(table.id)", payload: TableStatusBody(status: "AVAILABLE"))

        // Optimistic local: drop completed orders and flip table to AVAILABLE.
        if let idx = tables.firstIndex(where: { $0.id == table.id }) {
            let t = tables[idx]
            let remaining = (t.orders ?? []).filter { o in !liveOrders.contains(where: { $0.id == o.id }) }
            tables[idx] = POSTable(id: t.id, number: t.number, capacity: t.capacity,
                                    status: "AVAILABLE", orders: remaining)
        }
    }

    // MARK: SSE

    func startSSE() {
        guard sseTask == nil else { return }
        sseTask = Task { [weak self] in
            guard let self else { return }
            var backoff: UInt64 = 1_000_000_000 // 1s
            while !Task.isCancelled {
                do {
                    let stream = await self.api.eventStream("/api/events")
                    await MainActor.run { self.sseConnected = true }
                    for try await event in stream {
                        await self.handleSSEEvent(event)
                    }
                } catch {
                    // fall through to backoff/reconnect
                }
                await MainActor.run { self.sseConnected = false }
                if Task.isCancelled { return }
                try? await Task.sleep(nanoseconds: backoff)
                backoff = min(backoff * 2, 30_000_000_000)
            }
        }
    }

    func stopSSE() {
        sseTask?.cancel()
        sseTask = nil
        sseConnected = false
    }

    private func handleSSEEvent(_ event: APIClient.SSEEvent) async {
        guard let raw = event.data.data(using: .utf8) else { return }
        struct Envelope: Decodable { let type: String }
        guard let env = try? JSONDecoder().decode(Envelope.self, from: raw) else { return }

        switch env.type {
        case "table_status_changed":
            handleTableStatusChanged(raw: raw)
        case "order_created", "order_updated", "order_status_changed":
            handleOrderEvent(raw: raw, type: env.type)
        default:
            break
        }
    }

    private func handleTableStatusChanged(raw: Data) {
        struct Wrapper: Decodable { let data: POSTable }
        guard let w = try? JSONDecoder().decode(Wrapper.self, from: raw) else { return }
        if let idx = tables.firstIndex(where: { $0.id == w.data.id }) {
            let existing = tables[idx]
            tables[idx] = POSTable(
                id: existing.id,
                number: existing.number,
                capacity: existing.capacity,
                status: w.data.status,
                orders: existing.orders
            )
        }
    }

    private func handleOrderEvent(raw: Data, type: String) {
        struct Wrapper: Decodable { let data: POSOrder }
        guard let w = try? JSONDecoder().decode(Wrapper.self, from: raw) else { return }
        let order = w.data
        guard let tableId = order.tableId,
              let idx = tables.firstIndex(where: { $0.id == tableId }) else { return }

        let table = tables[idx]
        var orders = table.orders ?? []
        if let oi = orders.firstIndex(where: { $0.id == order.id }) {
            orders[oi] = order
        } else if type == "order_created" {
            orders.append(order)
        }

        let hasActive = orders.contains { o in
            !["COMPLETED", "CANCELLED"].contains(o.status) &&
            (o.items?.contains(where: { $0.status != "CANCELLED" }) ?? false)
        }
        let newStatus: String
        if hasActive && table.status == "AVAILABLE" {
            newStatus = "OCCUPIED"
        } else if !hasActive && table.status == "OCCUPIED" {
            newStatus = "AVAILABLE"
        } else {
            newStatus = table.status
        }

        tables[idx] = POSTable(
            id: table.id,
            number: table.number,
            capacity: table.capacity,
            status: newStatus,
            orders: orders
        )
    }
}
