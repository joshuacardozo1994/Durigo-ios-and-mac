//
//  Reports.swift
//  Durigo
//
//  Server-driven Reports — mirrors the web's /reports page.
//  Fetches /api/reports?period=… for analytics that exactly match what the
//  website's analytics page renders (total revenue, orders, avg, top items,
//  category breakdown, payment methods, hour distribution, staff performance).
//

import SwiftUI

// MARK: - Models

enum ReportPeriod: String, CaseIterable, Identifiable {
    case last24h = "24h"
    case last7d = "7d"
    case last30d = "30d"
    case last90d = "90d"
    case last1y = "1y"
    case allTime = "all"

    var id: String { rawValue }
    var label: String {
        switch self {
        case .last24h:  "Last 24 Hours"
        case .last7d:   "Last 7 Days"
        case .last30d:  "Last 30 Days"
        case .last90d:  "Last 90 Days"
        case .last1y:   "Last Year"
        case .allTime:  "All Time"
        }
    }
}

struct ReportData: Decodable {
    let period: String
    let startDate: String
    let totalRevenue: Double
    let totalOrders: Int
    let avgOrderValue: Double
    let topSellingItems: [TopItem]
    let categoryBreakdown: [Category]
    let hourlyDistribution: [Hour]
    let paymentMethods: [PaymentMethod]
    let staffPerformance: [Staff]

    struct TopItem: Decodable, Identifiable {
        let name: String
        let category: String
        let quantity: Int
        let orders: Int
        var id: String { "\(name)-\(category)" }
    }
    struct Category: Decodable, Identifiable {
        let category: String
        let orders: Int
        let itemsSold: Int
        let revenue: Double
        var id: String { category }
    }
    struct Hour: Decodable, Identifiable {
        let hour: Int
        let orders: Int
        var id: Int { hour }
    }
    struct PaymentMethod: Decodable, Identifiable {
        let method: String
        let count: Int
        let total: Double
        var id: String { method }
    }
    struct Staff: Decodable, Identifiable {
        let staffName: String
        let role: String
        let ordersHandled: Int
        let revenueGenerated: Double
        var id: String { staffName }
    }
}

// MARK: - Store

@MainActor
@Observable
final class ReportsStore {
    private let session: Session
    private let urlSession: URLSession
    private let baseURL: URL

    var data: ReportData?
    var isLoading = false
    var error: String?

    init(session: Session,
         baseURL: URL? = nil,
         urlSession: URLSession = NetworkHelper.shared.currentSession) {
        self.session = session
        self.baseURL = baseURL
            ?? URL(string: Config.shared.serverURL)
            ?? URL(string: "http://127.0.0.1:3000")!
        self.urlSession = urlSession
    }

    func load(period: ReportPeriod) async {
        guard let token = session.token else {
            error = "Not signed in"
            return
        }

        isLoading = true
        error = nil
        defer { isLoading = false }

        let trimmed = baseURL.absoluteString.trimmingCharacters(in: CharacterSet(charactersIn: "/"))
        var components = URLComponents(string: "\(trimmed)/api/reports")!
        components.queryItems = [URLQueryItem(name: "period", value: period.rawValue)]
        guard let url = components.url else {
            error = "Bad URL"
            return
        }

        var request = URLRequest(url: url)
        request.setValue("auth-token=\(token)", forHTTPHeaderField: "Cookie")
        request.timeoutInterval = 30

        do {
            let (responseData, response) = try await urlSession.data(for: request)
            guard let http = response as? HTTPURLResponse else {
                error = "Bad response"
                return
            }
            if http.statusCode == 401 {
                session.signOut()
                error = "Session expired"
                return
            }
            guard (200..<300).contains(http.statusCode) else {
                error = "HTTP \(http.statusCode)"
                return
            }
            data = try JSONDecoder().decode(ReportData.self, from: responseData)
        } catch {
            self.error = error.localizedDescription
        }
    }
}

// MARK: - View

struct Reports: View {
    @Environment(Session.self) private var session
    @State private var store: ReportsStore?
    @State private var period: ReportPeriod = .last7d

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: DesignTokens.spacingL) {
                    periodPicker
                    breakoutLinks

                    if let store, store.isLoading && store.data == nil {
                        loadingState
                    } else if let data = store?.data {
                        keyMetrics(data: data)
                        if !data.topSellingItems.isEmpty {
                            topItemsSection(items: data.topSellingItems)
                        }
                        if !data.categoryBreakdown.isEmpty {
                            categorySection(categories: data.categoryBreakdown, total: data.totalRevenue)
                        }
                        if !data.paymentMethods.isEmpty {
                            paymentMethodSection(methods: data.paymentMethods)
                        }
                        if !data.staffPerformance.isEmpty {
                            staffSection(staff: data.staffPerformance)
                        }
                        if !data.hourlyDistribution.isEmpty {
                            hourlyDistributionSection(hours: data.hourlyDistribution)
                        }
                    } else if let err = store?.error {
                        errorState(err)
                    }
                }
                .padding(DesignTokens.spacingL)
            }
            .background(Color(.systemBackground))
            .navigationTitle("Reports")
            .navigationBarTitleDisplayMode(.large)
            .refreshable {
                await store?.load(period: period)
            }
            .task {
                if store == nil {
                    store = ReportsStore(session: session)
                }
                await store?.load(period: period)
            }
            .onChange(of: period) { _, newPeriod in
                Task { await store?.load(period: newPeriod) }
            }
        }
        .lockWithBiometric()
    }

    // MARK: - Sections

    private var breakoutLinks: some View {
        NavigationLink {
            PerformanceReportView()
        } label: {
            HStack {
                Image(systemName: "speedometer").foregroundStyle(Color.accentColor)
                Text("Performance & efficiency").font(.system(.body, weight: .semibold))
                Spacer()
                Image(systemName: "chevron.right").font(.caption).foregroundStyle(.secondary)
            }
            .padding(DesignTokens.spacingL)
            .frame(maxWidth: .infinity, alignment: .leading)
            .webCardBackground()
        }
        .buttonStyle(.plain)
        .accessibilityIdentifier("reports-link-performance")
    }

    private var periodPicker: some View {
        Menu {
            ForEach(ReportPeriod.allCases) { p in
                Button {
                    period = p
                } label: {
                    if period == p {
                        Label(p.label, systemImage: "checkmark")
                    } else {
                        Text(p.label)
                    }
                }
            }
        } label: {
            HStack {
                Text(period.label)
                    .font(.system(.body, weight: .medium))
                Image(systemName: "chevron.up.chevron.down")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .padding(.horizontal, DesignTokens.spacingL)
            .padding(.vertical, DesignTokens.spacingM)
            .frame(maxWidth: .infinity, alignment: .leading)
            .webCardBackground(cornerRadius: DesignTokens.cornerRadiusSmall)
        }
    }

    private var loadingState: some View {
        VStack(spacing: 16) {
            ProgressView()
            Text("Loading reports…")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 60)
    }

    private func errorState(_ message: String) -> some View {
        VStack(spacing: 12) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 36))
                .foregroundStyle(.orange)
            Text("Couldn't load reports")
                .font(.headline)
            Text(message)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 24)
            Button("Retry") {
                Task { await store?.load(period: period) }
            }
            .buttonStyle(.webPrimary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
    }

    private func keyMetrics(data: ReportData) -> some View {
        VStack(spacing: DesignTokens.spacingM) {
            StatTile(
                title: "Total Revenue",
                value: data.totalRevenue.asCurrencyString() ?? "—",
                subtitle: nil,
                icon: "indianrupeesign"
            )
            HStack(spacing: DesignTokens.spacingM) {
                StatTile(
                    title: "Total Orders",
                    value: "\(data.totalOrders)",
                    subtitle: nil,
                    icon: "cart"
                )
                StatTile(
                    title: "Avg Order",
                    value: data.avgOrderValue.asCurrencyString() ?? "—",
                    subtitle: nil,
                    icon: "chart.line.uptrend.xyaxis"
                )
            }
        }
    }

    private func topItemsSection(items: [ReportData.TopItem]) -> some View {
        SectionCard(title: "Top Selling Items") {
            VStack(spacing: 0) {
                ForEach(Array(items.enumerated()), id: \.element.id) { index, item in
                    HStack(spacing: DesignTokens.spacingM) {
                        Text("\(index + 1)")
                            .font(.system(.subheadline, design: .rounded, weight: .semibold))
                            .foregroundStyle(.secondary)
                            .frame(width: 24)
                        VStack(alignment: .leading, spacing: 2) {
                            Text(item.name)
                                .font(.system(.body, weight: .medium))
                            Text(item.category)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                        VStack(alignment: .trailing, spacing: 2) {
                            Text("\(item.quantity)")
                                .font(.system(.body, design: .rounded, weight: .semibold))
                            Text("sold")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .padding(.vertical, 8)
                    if index < items.count - 1 { Divider() }
                }
            }
        }
    }

    private func categorySection(categories: [ReportData.Category], total: Double) -> some View {
        SectionCard(title: "Category Performance") {
            VStack(spacing: DesignTokens.spacingM) {
                ForEach(categories) { c in
                    VStack(alignment: .leading, spacing: 6) {
                        HStack {
                            Text(c.category)
                                .font(.system(.body, weight: .medium))
                            Spacer()
                            Text(c.revenue.asCurrencyString() ?? "—")
                                .font(.system(.body, design: .rounded, weight: .semibold))
                        }
                        // Progress bar
                        GeometryReader { geo in
                            ZStack(alignment: .leading) {
                                RoundedRectangle(cornerRadius: 3, style: .continuous)
                                    .fill(Color.primary.opacity(0.08))
                                    .frame(height: 6)
                                RoundedRectangle(cornerRadius: 3, style: .continuous)
                                    .fill(Color.accentColor)
                                    .frame(
                                        width: total > 0 ? geo.size.width * CGFloat(c.revenue / total) : 0,
                                        height: 6
                                    )
                            }
                        }
                        .frame(height: 6)
                        HStack {
                            Text("\(c.orders) orders")
                            Text("•").foregroundStyle(.tertiary)
                            Text("\(c.itemsSold) items")
                        }
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    }
                }
            }
        }
    }

    private func paymentMethodSection(methods: [ReportData.PaymentMethod]) -> some View {
        SectionCard(title: "Payment Methods") {
            VStack(spacing: 0) {
                ForEach(Array(methods.enumerated()), id: \.element.id) { index, m in
                    HStack(spacing: DesignTokens.spacingM) {
                        StatusChip(label: humanMethod(m.method), color: methodColor(m.method))
                        Spacer()
                        VStack(alignment: .trailing, spacing: 2) {
                            Text(m.total.asCurrencyString() ?? "—")
                                .font(.system(.body, design: .rounded, weight: .semibold))
                            Text("\(m.count) transaction\(m.count == 1 ? "" : "s")")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .padding(.vertical, 8)
                    if index < methods.count - 1 { Divider() }
                }
            }
        }
    }

    private func humanMethod(_ raw: String) -> String {
        switch raw {
        case "CASH": "Cash"
        case "CARD": "Card"
        case "UPI": "UPI"
        case "WALLET": "Wallet"
        case "BANK_TRANSFER": "Bank Transfer"
        default: raw.capitalized
        }
    }

    private func methodColor(_ raw: String) -> Color {
        switch raw {
        case "CASH": Color(red: 0.2, green: 0.7, blue: 0.3)
        case "CARD": Color(red: 0.5, green: 0.4, blue: 0.9)
        case "UPI":  Color(red: 1.0, green: 0.6, blue: 0.2)
        default: .gray
        }
    }

    private func staffSection(staff: [ReportData.Staff]) -> some View {
        SectionCard(title: "Top Performing Staff") {
            VStack(spacing: 0) {
                ForEach(Array(staff.prefix(5).enumerated()), id: \.element.id) { index, s in
                    HStack(spacing: DesignTokens.spacingM) {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(s.staffName)
                                .font(.system(.body, weight: .medium))
                            Text(s.role.capitalized)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                        VStack(alignment: .trailing, spacing: 2) {
                            Text(s.revenueGenerated.asCurrencyString() ?? "—")
                                .font(.system(.body, design: .rounded, weight: .semibold))
                            Text("\(s.ordersHandled) order\(s.ordersHandled == 1 ? "" : "s")")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .padding(.vertical, 8)
                    if index < min(staff.count, 5) - 1 { Divider() }
                }
            }
        }
    }

    private func hourlyDistributionSection(hours: [ReportData.Hour]) -> some View {
        let maxOrders = max(hours.map(\.orders).max() ?? 1, 1)
        return SectionCard(title: "Order Distribution by Hour") {
            VStack(spacing: 8) {
                ForEach(hours) { h in
                    HStack(spacing: DesignTokens.spacingM) {
                        Text(formatHour(h.hour))
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .frame(width: 56, alignment: .leading)
                        GeometryReader { geo in
                            ZStack(alignment: .leading) {
                                RoundedRectangle(cornerRadius: 4, style: .continuous)
                                    .fill(Color.primary.opacity(0.08))
                                    .frame(height: 22)
                                RoundedRectangle(cornerRadius: 4, style: .continuous)
                                    .fill(Color.accentColor)
                                    .frame(
                                        width: max(28, geo.size.width * CGFloat(h.orders) / CGFloat(maxOrders)),
                                        height: 22
                                    )
                                    .overlay(alignment: .trailing) {
                                        Text("\(h.orders)")
                                            .font(.caption2.monospacedDigit())
                                            .foregroundStyle(.white)
                                            .padding(.trailing, 6)
                                    }
                            }
                        }
                        .frame(height: 22)
                    }
                }
            }
        }
    }

    private func formatHour(_ hour24: Int) -> String {
        let h12 = hour24 % 12 == 0 ? 12 : hour24 % 12
        let suffix = hour24 < 12 ? "AM" : "PM"
        return "\(h12) \(suffix)"
    }
}

// MARK: - Performance sub-page (kitchen / staff / table utilization)

struct PerformanceReportData: Decodable, Equatable {
    let avgOrderTime: Double         // minutes
    let kitchenEfficiency: Int       // percentage 0..100
    let customerSatisfaction: Int
    let staffProductivity: Double
    let tableUtilization: Int
    let orderAccuracy: Int
    let staffPerformance: [StaffStat]
    let busyHours: [BusyHour]
    let alerts: [PerformanceAlert]

    struct StaffStat: Decodable, Equatable, Identifiable {
        let name: String
        let role: String
        let ordersHandled: Int
        let revenue: Double
        var id: String { "\(name)-\(role)" }
    }

    struct BusyHour: Decodable, Equatable, Identifiable {
        let hour: Int
        let orders: Int
        var id: Int { hour }
    }

    struct PerformanceAlert: Decodable, Equatable, Identifiable {
        let type: String         // warning / info / critical
        let title: String
        let message: String
        var id: String { "\(type)-\(title)" }
    }
}

@MainActor @Observable final class PerformanceReportStore {
    private let api: APIClient
    var data: PerformanceReportData?
    var isLoading = false
    var error: String?

    init(session: Session) { self.api = APIClient(session: session) }

    func load(range: String) async {
        isLoading = true; error = nil
        defer { isLoading = false }
        do {
            let bytes = try await api.get("/api/admin/reports/performance",
                                          query: [URLQueryItem(name: "range", value: range)])
            data = try JSONDecoder().decode(PerformanceReportData.self, from: bytes)
        } catch {
            self.error = (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
        }
    }
}

struct PerformanceReportView: View {
    @Environment(Session.self) private var session
    @State private var store: PerformanceReportStore?
    @State private var range: String = "7d"

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: DesignTokens.spacingL) {
                rangePicker
                if let store, store.isLoading && store.data == nil {
                    ProgressView().frame(maxWidth: .infinity).padding(.vertical, DesignTokens.spacing2XL)
                } else if let d = store?.data {
                    metricGrid(d)
                    if !d.alerts.isEmpty { alertsSection(d.alerts) }
                    if !d.staffPerformance.isEmpty { staffSection(d.staffPerformance) }
                    if !d.busyHours.isEmpty { busySection(d.busyHours) }
                } else if let err = store?.error {
                    errorBanner(err)
                }
            }
            .padding(DesignTokens.spacingL)
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle("Performance")
        #if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
        #endif
        .task {
            if store == nil { store = PerformanceReportStore(session: session) }
            await store?.load(range: range)
        }
        .onChange(of: range) { _, newRange in Task { await store?.load(range: newRange) } }
        .refreshable { await store?.load(range: range) }
    }

    private var rangePicker: some View {
        Picker("Range", selection: $range) {
            Text("Today").tag("today")
            Text("7d").tag("7d")
            Text("30d").tag("30d")
        }
        .pickerStyle(.segmented)
    }

    @ViewBuilder
    private func metricGrid(_ d: PerformanceReportData) -> some View {
        let columns = [GridItem(.flexible(), spacing: DesignTokens.spacingM),
                       GridItem(.flexible(), spacing: DesignTokens.spacingM)]
        LazyVGrid(columns: columns, spacing: DesignTokens.spacingM) {
            StatTile(title: "Avg order time", value: String(format: "%.1f min", d.avgOrderTime), subtitle: "ticket → served", icon: "timer")
            StatTile(title: "Kitchen efficiency", value: "\(d.kitchenEfficiency)%", subtitle: "of target throughput", icon: "fork.knife")
            StatTile(title: "Table utilization", value: "\(d.tableUtilization)%", subtitle: "seats occupied", icon: "square.grid.3x3")
            StatTile(title: "Order accuracy", value: "\(d.orderAccuracy)%", subtitle: "first-time correct", icon: "checkmark.seal")
            StatTile(title: "Customer satisfaction", value: "\(d.customerSatisfaction)%", subtitle: "from feedback", icon: "face.smiling")
            StatTile(title: "Staff productivity", value: String(format: "%.1f/hr", d.staffProductivity), subtitle: "orders per staff-hour", icon: "person.2")
        }
    }

    private func alertsSection(_ alerts: [PerformanceReportData.PerformanceAlert]) -> some View {
        SectionCard(title: "Alerts") {
            VStack(alignment: .leading, spacing: DesignTokens.spacingS) {
                ForEach(alerts) { a in
                    HStack(alignment: .top, spacing: 8) {
                        Image(systemName: alertIcon(a.type))
                            .foregroundStyle(alertColor(a.type))
                        VStack(alignment: .leading, spacing: 2) {
                            Text(a.title).font(.subheadline.weight(.semibold))
                            Text(a.message).font(.caption).foregroundStyle(.secondary)
                        }
                    }
                }
            }
        }
    }

    private func staffSection(_ staff: [PerformanceReportData.StaffStat]) -> some View {
        SectionCard(title: "Staff performance") {
            VStack(spacing: 0) {
                ForEach(Array(staff.enumerated()), id: \.element.id) { idx, s in
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(s.name).font(.subheadline.weight(.medium))
                            Text(s.role.lowercased()).font(.caption2).foregroundStyle(.secondary)
                        }
                        Spacer()
                        VStack(alignment: .trailing, spacing: 2) {
                            Text("\(s.ordersHandled) orders").font(.caption)
                            Text("₹\(Int(s.revenue))").font(.caption.monospacedDigit()).foregroundStyle(.secondary)
                        }
                    }
                    .padding(.vertical, 6)
                    if idx < staff.count - 1 { Divider() }
                }
            }
        }
    }

    private func busySection(_ hours: [PerformanceReportData.BusyHour]) -> some View {
        let max = Double(hours.map(\.orders).max() ?? 1)
        return SectionCard(title: "Busy hours") {
            VStack(spacing: DesignTokens.spacingS) {
                ForEach(hours) { h in
                    HStack {
                        Text(formatHour(h.hour)).font(.caption.monospacedDigit()).frame(width: 56, alignment: .leading)
                        GeometryReader { geo in
                            RoundedRectangle(cornerRadius: 3)
                                .fill(Color.accentColor.opacity(0.7))
                                .frame(width: geo.size.width * (Double(h.orders) / max))
                        }
                        .frame(height: 8)
                        Text("\(h.orders)").font(.caption.monospacedDigit()).foregroundStyle(.secondary).frame(width: 32, alignment: .trailing)
                    }
                }
            }
        }
    }

    private func errorBanner(_ msg: String) -> some View {
        HStack { Image(systemName: "exclamationmark.triangle.fill").foregroundStyle(.red); Text(msg).font(.subheadline); Spacer() }
            .padding(DesignTokens.spacingM)
            .background(RoundedRectangle(cornerRadius: DesignTokens.cornerRadiusSmall).fill(Color.red.opacity(0.08)))
    }

    private func alertIcon(_ type: String) -> String {
        switch type.lowercased() {
        case "critical": "exclamationmark.octagon.fill"
        case "warning":  "exclamationmark.triangle.fill"
        default:         "info.circle.fill"
        }
    }
    private func alertColor(_ type: String) -> Color {
        switch type.lowercased() {
        case "critical": .red
        case "warning":  .orange
        default:         .blue
        }
    }
    private func formatHour(_ h: Int) -> String {
        let h12 = h % 12 == 0 ? 12 : h % 12
        return "\(h12) \(h < 12 ? "AM" : "PM")"
    }
}

#Preview {
    Reports()
        .environment(Session())
}
