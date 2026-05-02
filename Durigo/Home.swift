//
//  Home.swift
//  Durigo
//
//  Root navigation container, restructured to mirror the web's sidebar.
//  Sections: Overview / Operations / Management / Analytics + Settings.
//
//  iPhone: bottom tabs (Dashboard, POS, Billing, Reports, More).
//  iPad:   collapsible NavigationSplitView with full grouped sidebar.
//
//  Most screens (Dashboard, Settings, ComingSoon stubs) live below in the
//  same file so we don't have to add new sources to the .xcodeproj.
//

import SwiftUI
import SwiftData

// MARK: - iPhone bottom-tab roots

enum IPhoneRoot: Hashable {
    case dashboard, pos, billing, reports, more
}

// MARK: - Root container

struct Home: View {
    @StateObject private var menuLoader = MenuLoader()
    @StateObject private var navigation = Navigation()
    @Query private var billHistoryItems: [BillHistoryItem]
    @Environment(\.modelContext) var modelContext
    @Environment(\.horizontalSizeClass) private var sizeClass
    @Environment(Session.self) private var session
    @State private var columnVisibility: NavigationSplitViewVisibility = .all

    private var pendingCount: Int {
        billHistoryItems.count { $0.paymentStatus == .pending }
    }

    var body: some View {
        Group {
            if sizeClass == .regular {
                iPadShell
            } else {
                iPhoneShell
            }
        }
        .onOpenURL { url in handleIncomingURL(url) }
        .environmentObject(menuLoader)
        .environmentObject(navigation)
        .onAppear { menuLoader.authSession = session }
    }

    // MARK: - iPhone shell

    private var iPhoneShell: some View {
        TabView(selection: iPhoneRootBinding) {
            Dashboard()
                .tabItem { Label("Dashboard", systemImage: "square.grid.2x2") }
                .tag(IPhoneRoot.dashboard)

            BillGenerator()
                .tabItem { Label("POS", systemImage: "cart") }
                .tag(IPhoneRoot.pos)

            BillHistoryList()
                .tabItem { Label("Billing", systemImage: "doc.text") }
                .badge(pendingCount)
                .tag(IPhoneRoot.billing)

            Reports()
                .tabItem { Label("Reports", systemImage: "chart.bar.doc.horizontal") }
                .tag(IPhoneRoot.reports)

            iPhoneMore
                .tabItem { Label("More", systemImage: "ellipsis") }
                .tag(IPhoneRoot.more)
        }
    }

    /// "More" tab: NavigationStack root that lists every NavigationItem
    /// not already a bottom tab, plus Settings.
    private var iPhoneMore: some View {
        NavigationStack {
            List {
                Section("Operations") {
                    moreLink(.kitchen)
                    moreLink(.reservations)
                }
                Section("Management") {
                    moreLink(.menu)
                    moreLink(.modifiers)
                    moreLink(.discounts)
                    moreLink(.inventory)
                    moreLink(.users)
                }
                Section("Account") {
                    moreLink(.settings)
                }
            }
            .listStyle(.insetGrouped)
            .navigationTitle("More")
        }
    }

    private func moreLink(_ item: NavigationItem) -> some View {
        NavigationLink {
            destination(for: item)
                .navigationTitle(item.title)
                .navigationBarTitleDisplayMode(.inline)
        } label: {
            Label(item.title, systemImage: item.icon)
        }
    }

    /// Maps NavigationItem.selection ↔ IPhoneRoot. Selection changes from
    /// taps in the More list update Navigation.selection so the iPad
    /// sidebar (when reopened) reflects the same active screen.
    private var iPhoneRootBinding: Binding<IPhoneRoot> {
        Binding(
            get: {
                switch navigation.selection {
                case .dashboard: .dashboard
                case .pos:       .pos
                case .billing:   .billing
                case .reports:   .reports
                default:         .more
                }
            },
            set: { newRoot in
                switch newRoot {
                case .dashboard: navigation.selection = .dashboard
                case .pos:       navigation.selection = .pos
                case .billing:   navigation.selection = .billing
                case .reports:   navigation.selection = .reports
                case .more:      break // user navigates within More via NavigationLinks
                }
            }
        )
    }

    // MARK: - iPad shell

    private var iPadShell: some View {
        NavigationSplitView(columnVisibility: $columnVisibility) {
            sidebar
        } detail: {
            destination(for: navigation.selection)
        }
        .navigationSplitViewStyle(.balanced)
    }

    private var sidebar: some View {
        List(selection: Binding(
            get: { navigation.selection },
            set: { if let v = $0 { navigation.selection = v } }
        )) {
            Section { } header: { brandHeader.padding(.bottom, 4) }

            ForEach(NavigationSection.allCases) { section in
                Section(section.title) {
                    ForEach(section.items) { item in
                        sidebarRow(item).tag(item)
                    }
                }
            }

            Section {
                sidebarRow(.settings).tag(NavigationItem.settings)
            }
        }
        .listStyle(.sidebar)
        .navigationTitle("")
        .toolbar(.hidden, for: .navigationBar)
    }

    private func sidebarRow(_ item: NavigationItem) -> some View {
        Label {
            HStack {
                Text(item.title)
                if item == .billing && pendingCount > 0 {
                    Spacer()
                    Text("\(pendingCount)")
                        .font(.caption)
                        .foregroundStyle(.white)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 2)
                        .background(Capsule().fill(Color.red))
                }
            }
        } icon: {
            Image(systemName: item.icon)
        }
    }

    private var brandHeader: some View {
        HStack(spacing: 8) {
            ZStack {
                RoundedRectangle(cornerRadius: 6, style: .continuous)
                    .fill(Color.primary.opacity(0.12))
                    .frame(width: 24, height: 24)
                Image(systemName: "fork.knife")
                    .font(.system(size: 12, weight: .medium))
            }
            Text("Durigo's")
                .font(.system(.headline, weight: .semibold))
                .foregroundStyle(.primary)
                .textCase(nil)
        }
    }

    // MARK: - Destination switch

    @ViewBuilder
    private func destination(for item: NavigationItem) -> some View {
        switch item {
        case .dashboard:    Dashboard()
        case .pos:          BillGenerator()
        case .kitchen:      ComingSoonView(title: "Kitchen", icon: "fork.knife.circle", note: "Live order queue with TODO / IN PREP / READY columns.")
        case .billing:      BillHistoryList()
        case .reservations: ComingSoonView(title: "Reservations", icon: "calendar", note: "Upcoming reservations and table assignments.")
        case .menu:         MenuEditor()
        case .modifiers:    ComingSoonView(title: "Modifiers", icon: "tag", note: "Add-ons (extra cheese), removals (no onions), and option groups.")
        case .discounts:    ComingSoonView(title: "Discounts", icon: "ticket", note: "Promo codes and category-targeted discounts.")
        case .inventory:    ComingSoonView(title: "Inventory", icon: "shippingbox", note: "Ingredient stock levels, low-stock alerts, restock entries.")
        case .users:        ComingSoonView(title: "Users", icon: "person.2", note: "Staff accounts: name, role, password reset.")
        case .reports:      Reports()
        case .settings:     SettingsView()
        }
    }

    // MARK: - Document import (iOS bills file)

    private func handleIncomingURL(_ url: URL) {
        do {
            let data = try Data(contentsOf: url)
            let durigoBills = try JSONDecoder().decode(DurigoBills.self, from: data)
            durigoBills.items.forEach { copy in
                let item = copy.convertToBillHistoryItem()
                if !billHistoryItems.contains(where: { $0.id == item.id }) {
                    modelContext.insert(item)
                }
            }
        } catch {
            print("Error decoding object: \(error)")
        }
    }
}

// MARK: - Coming Soon stub

struct ComingSoonView: View {
    let title: String
    let icon: String
    let note: String

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: DesignTokens.spacingL) {
                VStack(spacing: DesignTokens.spacingM) {
                    Image(systemName: icon)
                        .font(.system(size: 44, weight: .light))
                        .foregroundStyle(.secondary)
                    VStack(spacing: 4) {
                        Text(title)
                            .font(.system(.title2, weight: .bold))
                        Text("Coming soon")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    Text(note)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity)
                .padding(DesignTokens.spacing2XL)
                .webCardBackground()
            }
            .padding(DesignTokens.spacingL)
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle(title)
        #if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
        #endif
    }
}

// MARK: - Dashboard

@MainActor
@Observable
private final class DashboardStore {
    private let api: APIClient
    var stats: DashboardStats?
    var isLoading = false
    var errorMessage: String?

    init(session: Session) {
        self.api = APIClient(session: session)
    }

    func load() async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }
        do {
            let data = try await api.get("/api/admin/dashboard/stats")
            stats = try JSONDecoder().decode(DashboardStats.self, from: data)
        } catch {
            errorMessage = (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
        }
    }
}

struct DashboardStats: Decodable, Equatable {
    let todayOrders: Int
    let todayRevenue: Double
    let activeOrders: Int
    let availableTables: Int
    let totalCustomers: Int
    let lowStockItems: Int
    let revenueChange: Double
    let ordersChange: Double
}

struct Dashboard: View {
    @Environment(Session.self) private var session
    @State private var store: DashboardStore?

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: DesignTokens.spacingL) {
                    if let s = store?.stats {
                        heroRevenue(s)
                        statsGrid(s)
                    } else if store?.isLoading == true {
                        ProgressView().frame(maxWidth: .infinity).padding(.vertical, DesignTokens.spacing2XL)
                    } else if let msg = store?.errorMessage {
                        errorBanner(msg)
                    }
                    if let user = session.user {
                        welcomeCard(user: user)
                    }
                }
                .padding(DesignTokens.spacingL)
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Dashboard")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .refreshable { await store?.load() }
            .task {
                if store == nil { store = DashboardStore(session: session) }
                await store?.load()
            }
        }
    }

    private func heroRevenue(_ s: DashboardStats) -> some View {
        VStack(alignment: .leading, spacing: DesignTokens.spacingS) {
            Text("Today's Revenue")
                .font(.subheadline)
                .foregroundStyle(.secondary)
            Text("₹\(Int(s.todayRevenue).formatted(.number))")
                .font(.system(.largeTitle, design: .rounded, weight: .bold))
            HStack(spacing: 6) {
                Image(systemName: s.revenueChange >= 0 ? "arrow.up.right" : "arrow.down.right")
                    .font(.caption2)
                Text("\(s.revenueChange >= 0 ? "+" : "")\(s.revenueChange, specifier: "%.1f")% from yesterday")
                    .font(.caption)
            }
            .foregroundStyle(s.revenueChange >= 0 ? .green : .red)
        }
        .padding(DesignTokens.spacingL)
        .frame(maxWidth: .infinity, alignment: .leading)
        .webCardBackground()
    }

    private func statsGrid(_ s: DashboardStats) -> some View {
        let columns = [GridItem(.flexible(), spacing: DesignTokens.spacingM),
                       GridItem(.flexible(), spacing: DesignTokens.spacingM)]
        return LazyVGrid(columns: columns, spacing: DesignTokens.spacingM) {
            StatTile(
                title: "Today's Orders",
                value: "\(s.todayOrders)",
                subtitle: "vs yesterday",
                icon: "cart",
                trend: s.ordersChange >= 0
                    ? .up(String(format: "+%.1f%%", s.ordersChange))
                    : .down(String(format: "%.1f%%", s.ordersChange))
            )
            StatTile(
                title: "Active Orders",
                value: "\(s.activeOrders)",
                subtitle: "in progress",
                icon: "clock"
            )
            StatTile(
                title: "Available Tables",
                value: "\(s.availableTables)",
                subtitle: "free now",
                icon: "square.grid.3x3"
            )
            StatTile(
                title: "Low Stock",
                value: "\(s.lowStockItems)",
                subtitle: s.lowStockItems == 0 ? "all good" : "items below min",
                icon: "exclamationmark.triangle"
            )
        }
    }

    private func welcomeCard(user: CurrentUser) -> some View {
        SectionCard(title: "Welcome, \(user.name)") {
            Text("Logged in as \(user.role.lowercased()).")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
    }

    private func errorBanner(_ message: String) -> some View {
        HStack(alignment: .top, spacing: DesignTokens.spacingS) {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundStyle(.red)
            Text(message)
                .font(.subheadline)
                .foregroundStyle(.primary)
            Spacer()
        }
        .padding(DesignTokens.spacingM)
        .background(
            RoundedRectangle(cornerRadius: DesignTokens.cornerRadiusSmall, style: .continuous)
                .fill(Color.red.opacity(0.08))
        )
        .overlay(
            RoundedRectangle(cornerRadius: DesignTokens.cornerRadiusSmall, style: .continuous)
                .stroke(Color.red.opacity(0.25), lineWidth: 1)
        )
    }
}

// MARK: - Settings + Logout

struct SettingsView: View {
    @Environment(Session.self) private var session
    @State private var showingLogoutConfirm = false
    @State private var loggingOut = false

    var body: some View {
        NavigationStack {
            Form {
                if let user = session.user {
                    Section("Account") {
                        LabeledContent("Name", value: user.name)
                        LabeledContent("Username", value: user.username)
                        LabeledContent("Role", value: user.role)
                    }
                }

                Section("Server") {
                    LabeledContent("URL", value: Config.shared.serverURL)
                }

                Section("About") {
                    LabeledContent("App Version", value: Bundle.main.shortVersion)
                    LabeledContent("Build", value: Bundle.main.buildNumber)
                }

                Section {
                    Button(role: .destructive) {
                        showingLogoutConfirm = true
                    } label: {
                        HStack {
                            Image(systemName: "rectangle.portrait.and.arrow.right")
                            Text(loggingOut ? "Signing out…" : "Sign Out")
                        }
                        .frame(maxWidth: .infinity)
                    }
                    .disabled(loggingOut)
                    .accessibilityIdentifier("settings-logout-button")
                }
            }
            .navigationTitle("Settings")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .alert("Sign out?", isPresented: $showingLogoutConfirm) {
                Button("Sign Out", role: .destructive) {
                    loggingOut = true
                    Task {
                        await session.signOutRemotely()
                        loggingOut = false
                    }
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("You'll need to sign in again to use the app.")
            }
        }
    }
}

private extension Bundle {
    var shortVersion: String { (object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String) ?? "—" }
    var buildNumber: String { (object(forInfoDictionaryKey: "CFBundleVersion") as? String) ?? "—" }
}

// MARK: - Preview

#Preview {
#if DEBUG
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: BillHistoryItem.self, configurations: config)
    PreviewData.billHistoryItems.forEach { container.mainContext.insert($0) }
#endif
    return Home()
        .environment(Session())
#if DEBUG
        .modelContainer(container)
#endif
}
