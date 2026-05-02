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
        .accessibilityIdentifier("more-link-\(item.title.lowercased().replacingOccurrences(of: " ", with: "-"))")
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
        case .kitchen:      KitchenAdminView()
        case .billing:      BillHistoryList()
        case .reservations: ReservationsAdminView()
        case .menu:         MenuEditor()
        case .modifiers:    ModifiersAdminView()
        case .discounts:    DiscountsAdminView()
        case .inventory:    InventoryAdminView()
        case .users:        UsersAdminView()
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

                Section {
                    NavigationLink {
                        AppSettingsForm()
                    } label: {
                        Label("Restaurant settings", systemImage: "building.2")
                    }
                    .accessibilityIdentifier("settings-restaurant-link")
                } header: {
                    Text("Configuration")
                } footer: {
                    Text("Restaurant info, business hours, tax rate, billing methods, inventory thresholds.")
                        .font(.caption)
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

// MARK: - Users admin

struct AdminUserModel: Codable, Identifiable, Hashable {
    let id: String
    let email: String
    let username: String
    let name: String
    let role: String
    var active: Bool
}

struct AdminUserPayload: Encodable {
    let email: String
    let username: String
    let name: String
    let password: String?
    let role: String
    let active: Bool
}

@MainActor @Observable final class UsersStore {
    private let api: APIClient
    var items: [AdminUserModel] = []
    var isLoading = false
    var errorMessage: String?

    init(session: Session) { self.api = APIClient(session: session) }

    func load() async {
        isLoading = true; errorMessage = nil
        defer { isLoading = false }
        do {
            let data = try await api.get("/api/admin/users")
            items = try JSONDecoder().decode([AdminUserModel].self, from: data)
        } catch {
            errorMessage = (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
        }
    }

    func create(_ payload: AdminUserPayload) async throws -> AdminUserModel {
        let data = try await api.postJSON("/api/admin/users", payload: payload)
        let created = try JSONDecoder().decode(AdminUserModel.self, from: data)
        items.append(created)
        return created
    }

    func update(_ payload: AdminUserPayload, id: String) async throws -> AdminUserModel {
        let data = try await api.putJSON("/api/admin/users/\(id)", payload: payload)
        let updated = try JSONDecoder().decode(AdminUserModel.self, from: data)
        if let idx = items.firstIndex(where: { $0.id == updated.id }) { items[idx] = updated }
        return updated
    }

    func delete(_ user: AdminUserModel) async throws {
        try await api.delete("/api/admin/users/\(user.id)")
        items.removeAll { $0.id == user.id }
    }

    /// Most user records group by role. Sorted: Admin first, then alphabetical.
    var groupedByRole: [(role: String, users: [AdminUserModel])] {
        let order: [String: Int] = ["ADMIN": 0, "WAITER": 1, "KITCHEN": 2, "CASHIER": 3]
        let grouped = Dictionary(grouping: items, by: \.role)
        return grouped
            .sorted { (order[$0.key] ?? 99) < (order[$1.key] ?? 99) }
            .map { ($0.key, $0.value.sorted { $0.name < $1.name }) }
    }
}

struct UsersAdminView: View {
    @Environment(Session.self) private var session
    @State private var store: UsersStore?
    @State private var editing: AdminUserModel?
    @State private var creating = false
    @State private var deleteCandidate: AdminUserModel?

    var body: some View {
        NavigationStack {
            Group {
                if let store {
                    content(store: store)
                } else {
                    ProgressView().frame(maxWidth: .infinity, maxHeight: .infinity)
                }
            }
            .navigationTitle("Users")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button { creating = true } label: { Image(systemName: "plus") }
                        .accessibilityIdentifier("admin-users-new")
                }
            }
            .sheet(item: $editing) { user in
                if let store { UserFormSheet(store: store, existing: user) }
            }
            .sheet(isPresented: $creating) {
                if let store { UserFormSheet(store: store, existing: nil) }
            }
            .alert(
                "Delete \(deleteCandidate?.name ?? "user")?",
                isPresented: Binding(
                    get: { deleteCandidate != nil },
                    set: { if !$0 { deleteCandidate = nil } }
                ),
                presenting: deleteCandidate
            ) { user in
                Button("Delete", role: .destructive) {
                    Task { try? await store?.delete(user) }
                }
                Button("Cancel", role: .cancel) {}
            } message: { _ in
                Text("This is permanent. Sessions for this user are revoked.")
            }
            .task {
                if store == nil { store = UsersStore(session: session) }
                await store?.load()
            }
            .refreshable { await store?.load() }
        }
    }

    @ViewBuilder
    private func content(store: UsersStore) -> some View {
        ScrollView {
            VStack(alignment: .leading, spacing: DesignTokens.spacingL) {
                if let msg = store.errorMessage { errorBanner(msg) }
                if store.isLoading && store.items.isEmpty {
                    ProgressView().frame(maxWidth: .infinity).padding(.vertical, DesignTokens.spacing2XL)
                } else if store.items.isEmpty {
                    emptyState
                } else {
                    ForEach(store.groupedByRole, id: \.role) { group in
                        roleSection(role: group.role, users: group.users)
                    }
                }
            }
            .padding(DesignTokens.spacingL)
        }
        .background(Color(.systemGroupedBackground))
    }

    private func roleSection(role: String, users: [AdminUserModel]) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                Text(roleTitle(role))
                    .font(.system(.headline, weight: .semibold))
                Spacer()
                Text("\(users.count)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .padding(.horizontal, DesignTokens.spacingL)
            .padding(.top, DesignTokens.spacingL)
            .padding(.bottom, DesignTokens.spacingS)

            ForEach(Array(users.enumerated()), id: \.element.id) { idx, user in
                userRow(user)
                if idx < users.count - 1 {
                    Divider()
                        .background(Color.primary.opacity(DesignTokens.borderOpacity))
                        .padding(.leading, DesignTokens.spacingL)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .webCardBackground()
    }

    private func userRow(_ user: AdminUserModel) -> some View {
        Button {
            editing = user
        } label: {
            HStack(spacing: DesignTokens.spacingM) {
                ZStack {
                    Circle()
                        .fill(Color.primary.opacity(0.08))
                        .frame(width: 36, height: 36)
                    Text(initials(user.name))
                        .font(.system(.subheadline, weight: .semibold))
                        .foregroundStyle(.secondary)
                }
                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: 6) {
                        Text(user.name)
                            .font(.system(.body, weight: .semibold))
                            .foregroundStyle(.primary)
                        if !user.active {
                            Text("Inactive")
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(Capsule().fill(Color.primary.opacity(0.08)))
                        }
                    }
                    Text("@\(user.username) · \(user.email)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
                Spacer()
            }
            .padding(.horizontal, DesignTokens.spacingL)
            .padding(.vertical, DesignTokens.spacingM)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .swipeActions(edge: .trailing, allowsFullSwipe: false) {
            Button(role: .destructive) { deleteCandidate = user } label: {
                Label("Delete", systemImage: "trash")
            }
        }
    }

    private func roleTitle(_ role: String) -> String {
        switch role.uppercased() {
        case "ADMIN": "Administrators"
        case "WAITER": "Waitstaff"
        case "KITCHEN": "Kitchen"
        case "CASHIER": "Cashiers"
        default: role.capitalized
        }
    }

    private func initials(_ name: String) -> String {
        let parts = name.split(separator: " ").compactMap { $0.first.map(String.init) }
        return parts.prefix(2).joined().uppercased()
    }

    private var emptyState: some View {
        VStack(spacing: DesignTokens.spacingM) {
            Image(systemName: "person.crop.circle.badge.plus")
                .font(.system(size: 36, weight: .light))
                .foregroundStyle(.secondary)
            Text("No users yet").font(.headline)
            Text("Tap + to add an admin, waiter, kitchen, or cashier account.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(DesignTokens.spacing2XL)
    }

    private func errorBanner(_ message: String) -> some View {
        HStack(alignment: .top, spacing: DesignTokens.spacingS) {
            Image(systemName: "exclamationmark.triangle.fill").foregroundStyle(.red)
            Text(message).font(.subheadline)
            Spacer()
        }
        .padding(DesignTokens.spacingM)
        .background(RoundedRectangle(cornerRadius: DesignTokens.cornerRadiusSmall, style: .continuous).fill(Color.red.opacity(0.08)))
        .overlay(RoundedRectangle(cornerRadius: DesignTokens.cornerRadiusSmall, style: .continuous).stroke(Color.red.opacity(0.25), lineWidth: 1))
    }
}

private struct UserFormSheet: View {
    let store: UsersStore
    let existing: AdminUserModel?

    @State private var name = ""
    @State private var email = ""
    @State private var username = ""
    @State private var password = ""
    @State private var role = "WAITER"
    @State private var active = true
    @State private var saving = false
    @State private var errorMessage: String?

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            Form {
                Section("Account") {
                    TextField("Full name", text: $name)
                        .accessibilityIdentifier("user-form-name")
                    TextField("Email", text: $email)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        .keyboardType(.emailAddress)
                        .accessibilityIdentifier("user-form-email")
                    TextField("Username", text: $username)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        .accessibilityIdentifier("user-form-username")
                }
                Section {
                    SecureField(existing == nil ? "Password" : "New password (leave empty to keep)", text: $password)
                        .accessibilityIdentifier("user-form-password")
                } header: {
                    Text("Password")
                } footer: {
                    if existing != nil {
                        Text("Leave empty to keep the current password.").font(.caption)
                    }
                }
                Section("Role") {
                    Picker("Role", selection: $role) {
                        Text("Admin").tag("ADMIN")
                        Text("Waiter").tag("WAITER")
                        Text("Kitchen").tag("KITCHEN")
                        Text("Cashier").tag("CASHIER")
                    }
                }
                Section("Active") {
                    Toggle("Active", isOn: $active)
                }
                if let errorMessage {
                    Section { Text(errorMessage).font(.subheadline).foregroundStyle(.red) }
                }
            }
            .navigationTitle(existing == nil ? "New User" : "Edit User")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    if saving { ProgressView() }
                    else {
                        Button("Save", action: save).disabled(!isValid)
                    }
                }
            }
            .onAppear {
                if let existing {
                    name = existing.name
                    email = existing.email
                    username = existing.username
                    role = existing.role
                    active = existing.active
                }
            }
        }
        .interactiveDismissDisabled(saving)
    }

    private var isValid: Bool {
        !name.trimmingCharacters(in: .whitespaces).isEmpty
        && email.contains("@")
        && username.count >= 3
        && (existing != nil || password.count >= 6)
    }

    private func save() {
        let payload = AdminUserPayload(
            email: email.trimmingCharacters(in: .whitespaces).lowercased(),
            username: username.trimmingCharacters(in: .whitespaces).lowercased(),
            name: name.trimmingCharacters(in: .whitespaces),
            password: password.isEmpty ? nil : password,
            role: role,
            active: active
        )
        saving = true; errorMessage = nil
        Task {
            do {
                if let existing { _ = try await store.update(payload, id: existing.id) }
                else { _ = try await store.create(payload) }
                saving = false
                dismiss()
            } catch {
                saving = false
                errorMessage = (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
            }
        }
    }
}

// MARK: - Discounts admin

struct AdminDiscount: Codable, Identifiable, Hashable {
    let id: String
    let code: String
    let name: String
    let description: String?
    let type: String   // PERCENTAGE | FIXED | BOGO
    let value: Int
    let minOrderValue: Int?
    let maxDiscount: Int?
    let applicableTo: [String]
    let usageLimit: Int?
    let usageCount: Int
    let perUserLimit: Int?
    let validFrom: String   // ISO8601
    let validUntil: String?
    var active: Bool
}

struct DiscountPayload: Encodable {
    let code: String
    let name: String
    let description: String?
    let type: String
    let value: Int
    let minOrderValue: Int?
    let maxDiscount: Int?
    let applicableTo: [String]
    let usageLimit: Int?
    let perUserLimit: Int?
    let validFrom: String
    let validUntil: String?
    let active: Bool?
}

@MainActor @Observable final class DiscountsStore {
    private let api: APIClient
    var items: [AdminDiscount] = []
    var isLoading = false
    var errorMessage: String?

    init(session: Session) { self.api = APIClient(session: session) }

    func load() async {
        isLoading = true; errorMessage = nil
        defer { isLoading = false }
        do {
            let data = try await api.get("/api/admin/discounts")
            items = try JSONDecoder().decode([AdminDiscount].self, from: data)
        } catch {
            errorMessage = (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
        }
    }

    func create(_ payload: DiscountPayload) async throws -> AdminDiscount {
        let data = try await api.postJSON("/api/admin/discounts", payload: payload)
        let created = try JSONDecoder().decode(AdminDiscount.self, from: data)
        items.insert(created, at: 0)
        return created
    }

    func update(_ payload: DiscountPayload, id: String) async throws -> AdminDiscount {
        let body = try JSONEncoder().encode(payload)
        let data = try await api.patch("/api/admin/discounts/\(id)", body: body)
        let updated = try JSONDecoder().decode(AdminDiscount.self, from: data)
        if let idx = items.firstIndex(where: { $0.id == updated.id }) { items[idx] = updated }
        return updated
    }

    func delete(_ d: AdminDiscount) async throws {
        try await api.delete("/api/admin/discounts/\(d.id)")
        items.removeAll { $0.id == d.id }
    }
}

struct DiscountsAdminView: View {
    @Environment(Session.self) private var session
    @State private var store: DiscountsStore?
    @State private var editing: AdminDiscount?
    @State private var creating = false
    @State private var deleteCandidate: AdminDiscount?

    var body: some View {
        NavigationStack {
            Group {
                if let store { content(store: store) }
                else { ProgressView().frame(maxWidth: .infinity, maxHeight: .infinity) }
            }
            .navigationTitle("Discounts")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button { creating = true } label: { Image(systemName: "plus") }
                        .accessibilityIdentifier("admin-discounts-new")
                }
            }
            .sheet(item: $editing) { d in
                if let store { DiscountFormSheet(store: store, existing: d) }
            }
            .sheet(isPresented: $creating) {
                if let store { DiscountFormSheet(store: store, existing: nil) }
            }
            .alert(
                "Delete \(deleteCandidate?.code ?? "discount")?",
                isPresented: Binding(get: { deleteCandidate != nil }, set: { if !$0 { deleteCandidate = nil } }),
                presenting: deleteCandidate
            ) { d in
                Button("Delete", role: .destructive) { Task { try? await store?.delete(d) } }
                Button("Cancel", role: .cancel) {}
            } message: { _ in Text("Discounts already used on past orders stay attached to those records.") }
            .task {
                if store == nil { store = DiscountsStore(session: session) }
                await store?.load()
            }
            .refreshable { await store?.load() }
        }
    }

    @ViewBuilder
    private func content(store: DiscountsStore) -> some View {
        ScrollView {
            VStack(alignment: .leading, spacing: DesignTokens.spacingL) {
                if let msg = store.errorMessage {
                    HStack { Image(systemName: "exclamationmark.triangle.fill").foregroundStyle(.red); Text(msg).font(.subheadline); Spacer() }
                        .padding(DesignTokens.spacingM)
                        .background(RoundedRectangle(cornerRadius: DesignTokens.cornerRadiusSmall, style: .continuous).fill(Color.red.opacity(0.08)))
                }
                if store.isLoading && store.items.isEmpty {
                    ProgressView().frame(maxWidth: .infinity).padding(.vertical, DesignTokens.spacing2XL)
                } else if store.items.isEmpty {
                    VStack(spacing: DesignTokens.spacingM) {
                        Image(systemName: "ticket").font(.system(size: 36, weight: .light)).foregroundStyle(.secondary)
                        Text("No discounts yet").font(.headline)
                        Text("Promo codes like WELCOME10 go here.")
                            .font(.subheadline).foregroundStyle(.secondary).multilineTextAlignment(.center)
                    }
                    .frame(maxWidth: .infinity).padding(DesignTokens.spacing2XL)
                } else {
                    VStack(alignment: .leading, spacing: 0) {
                        ForEach(Array(store.items.enumerated()), id: \.element.id) { idx, d in
                            discountRow(d)
                            if idx < store.items.count - 1 {
                                Divider().background(Color.primary.opacity(DesignTokens.borderOpacity)).padding(.leading, DesignTokens.spacingL)
                            }
                        }
                    }
                    .webCardBackground()
                }
            }
            .padding(DesignTokens.spacingL)
        }
        .background(Color(.systemGroupedBackground))
    }

    private func discountRow(_ d: AdminDiscount) -> some View {
        Button {
            editing = d
        } label: {
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 6) {
                    Text(d.code).font(.system(.body, design: .monospaced, weight: .bold))
                    if !d.active {
                        Text("Inactive").font(.caption2).foregroundStyle(.secondary)
                            .padding(.horizontal, 6).padding(.vertical, 2)
                            .background(Capsule().fill(Color.primary.opacity(0.08)))
                    }
                    Spacer()
                    Text(formatValue(d)).font(.system(.body, weight: .semibold)).foregroundStyle(.green)
                }
                Text(d.name).font(.subheadline).foregroundStyle(.primary)
                if let desc = d.description, !desc.isEmpty {
                    Text(desc).font(.caption).foregroundStyle(.secondary).lineLimit(2)
                }
                HStack(spacing: 8) {
                    if let limit = d.usageLimit {
                        Text("\(d.usageCount)/\(limit) used").font(.caption2).foregroundStyle(.secondary)
                    } else {
                        Text("\(d.usageCount) used").font(.caption2).foregroundStyle(.secondary)
                    }
                    if let until = d.validUntil { Text("· valid until \(formatDate(until))").font(.caption2).foregroundStyle(.secondary) }
                }
            }
            .padding(.horizontal, DesignTokens.spacingL).padding(.vertical, DesignTokens.spacingM)
            .frame(maxWidth: .infinity, alignment: .leading)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .swipeActions(edge: .trailing, allowsFullSwipe: false) {
            Button(role: .destructive) { deleteCandidate = d } label: { Label("Delete", systemImage: "trash") }
        }
    }

    private func formatValue(_ d: AdminDiscount) -> String {
        switch d.type {
        case "PERCENTAGE": "\(d.value)% off"
        case "FIXED":      "₹\(d.value) off"
        case "BOGO":       "BOGO"
        default:           "\(d.value)"
        }
    }

    private func formatDate(_ iso: String) -> String {
        let f = ISO8601DateFormatter()
        f.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        let date = f.date(from: iso) ?? ISO8601DateFormatter().date(from: iso) ?? Date()
        let df = DateFormatter()
        df.dateStyle = .medium; df.timeStyle = .none
        return df.string(from: date)
    }
}

private struct DiscountFormSheet: View {
    let store: DiscountsStore
    let existing: AdminDiscount?

    @State private var code = ""
    @State private var name = ""
    @State private var description = ""
    @State private var type = "PERCENTAGE"
    @State private var value = 10
    @State private var minOrderValue = 0
    @State private var hasMin = false
    @State private var maxDiscount = 0
    @State private var hasMax = false
    @State private var usageLimit = 100
    @State private var hasLimit = false
    @State private var validFrom = Date()
    @State private var validUntil = Date().addingTimeInterval(30*24*3600)
    @State private var hasUntil = false
    @State private var active = true
    @State private var saving = false
    @State private var errorMessage: String?

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            Form {
                Section("Code") {
                    TextField("WELCOME10", text: $code)
                        .textInputAutocapitalization(.characters)
                        .autocorrectionDisabled()
                        .font(.system(.body, design: .monospaced))
                        .accessibilityIdentifier("discount-form-code")
                    TextField("Name", text: $name)
                        .accessibilityIdentifier("discount-form-name")
                    TextField("Description (optional)", text: $description, axis: .vertical).lineLimit(2...4)
                        .accessibilityIdentifier("discount-form-description")
                }
                Section("Type & value") {
                    Picker("Type", selection: $type) {
                        Text("Percentage").tag("PERCENTAGE")
                        Text("Fixed (₹)").tag("FIXED")
                        Text("BOGO").tag("BOGO")
                    }
                    HStack {
                        Text(type == "PERCENTAGE" ? "Value (%)" : "Value (₹)")
                        Spacer()
                        TextField("0", value: $value, format: .number)
                            .multilineTextAlignment(.trailing).frame(width: 80)
                        #if os(iOS)
                            .keyboardType(.numberPad)
                        #endif
                    }
                }
                Section("Limits") {
                    Toggle("Minimum order value", isOn: $hasMin)
                    if hasMin {
                        HStack { Text("Min ₹"); Spacer(); TextField("0", value: $minOrderValue, format: .number).multilineTextAlignment(.trailing).frame(width: 80)
                        #if os(iOS)
                            .keyboardType(.numberPad)
                        #endif
                        }
                    }
                    Toggle("Cap discount", isOn: $hasMax)
                    if hasMax {
                        HStack { Text("Max ₹"); Spacer(); TextField("0", value: $maxDiscount, format: .number).multilineTextAlignment(.trailing).frame(width: 80)
                        #if os(iOS)
                            .keyboardType(.numberPad)
                        #endif
                        }
                    }
                    Toggle("Limit total uses", isOn: $hasLimit)
                    if hasLimit {
                        HStack { Text("Total uses"); Spacer(); TextField("0", value: $usageLimit, format: .number).multilineTextAlignment(.trailing).frame(width: 80)
                        #if os(iOS)
                            .keyboardType(.numberPad)
                        #endif
                        }
                    }
                }
                Section("Validity") {
                    DatePicker("Valid from", selection: $validFrom, displayedComponents: .date)
                    Toggle("Has expiry", isOn: $hasUntil)
                    if hasUntil {
                        DatePicker("Valid until", selection: $validUntil, in: validFrom..., displayedComponents: .date)
                    }
                }
                Section("Active") { Toggle("Active", isOn: $active) }
                if let errorMessage { Section { Text(errorMessage).font(.subheadline).foregroundStyle(.red) } }
            }
            .navigationTitle(existing == nil ? "New Discount" : "Edit Discount")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    if saving { ProgressView() } else { Button("Save", action: save).disabled(!isValid) }
                }
            }
            .onAppear(perform: loadInitial)
        }
        .interactiveDismissDisabled(saving)
    }

    private var isValid: Bool {
        !code.trimmingCharacters(in: .whitespaces).isEmpty
        && !name.trimmingCharacters(in: .whitespaces).isEmpty
        && value > 0
        && (type != "PERCENTAGE" || value <= 100)
    }

    private func loadInitial() {
        guard let e = existing else { return }
        code = e.code; name = e.name
        description = e.description ?? ""
        type = e.type
        value = e.value
        if let m = e.minOrderValue { hasMin = true; minOrderValue = m }
        if let m = e.maxDiscount { hasMax = true; maxDiscount = m }
        if let l = e.usageLimit { hasLimit = true; usageLimit = l }
        let f = ISO8601DateFormatter(); f.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        if let d = f.date(from: e.validFrom) ?? ISO8601DateFormatter().date(from: e.validFrom) { validFrom = d }
        if let until = e.validUntil, let d = f.date(from: until) ?? ISO8601DateFormatter().date(from: until) {
            hasUntil = true; validUntil = d
        }
        active = e.active
    }

    private func save() {
        let f = ISO8601DateFormatter()
        let payload = DiscountPayload(
            code: code.trimmingCharacters(in: .whitespaces).uppercased(),
            name: name.trimmingCharacters(in: .whitespaces),
            description: description.isEmpty ? nil : description,
            type: type,
            value: value,
            minOrderValue: hasMin ? minOrderValue : nil,
            maxDiscount: hasMax ? maxDiscount : nil,
            applicableTo: ["all"],
            usageLimit: hasLimit ? usageLimit : nil,
            perUserLimit: nil,
            validFrom: f.string(from: validFrom),
            validUntil: hasUntil ? f.string(from: validUntil) : nil,
            active: active
        )
        saving = true; errorMessage = nil
        Task {
            do {
                if let existing { _ = try await store.update(payload, id: existing.id) }
                else { _ = try await store.create(payload) }
                saving = false
                dismiss()
            } catch {
                saving = false
                errorMessage = (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
            }
        }
    }
}

// MARK: - Modifiers admin

struct AdminCategoryRefMin: Codable, Hashable {
    let id: String
    let name: String
}

struct AdminModifier: Codable, Identifiable, Hashable {
    let id: String
    let name: String
    let description: String?
    let price: Int
    let type: String   // ADD | REMOVE | SUBSTITUTE | SPECIAL
    let categoryId: String?
    let category: AdminCategoryRefMin?
    var active: Bool
    let sortOrder: Int
}

struct ModifierPayload: Encodable {
    let name: String
    let description: String?
    let price: Int
    let type: String
    let categoryId: String?
    let sortOrder: Int
    let active: Bool?
}

@MainActor @Observable final class ModifiersStore {
    private let api: APIClient
    var items: [AdminModifier] = []
    var categories: [AdminCategory] = []
    var isLoading = false
    var errorMessage: String?

    init(session: Session) { self.api = APIClient(session: session) }

    func load() async {
        isLoading = true; errorMessage = nil
        defer { isLoading = false }
        do {
            async let modsData = api.get("/api/admin/modifiers")
            async let catsData = api.get("/api/admin/categories")
            items = try JSONDecoder().decode([AdminModifier].self, from: try await modsData)
            categories = try JSONDecoder().decode([AdminCategory].self, from: try await catsData)
        } catch {
            errorMessage = (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
        }
    }

    func create(_ payload: ModifierPayload) async throws -> AdminModifier {
        let data = try await api.postJSON("/api/admin/modifiers", payload: payload)
        let created = try JSONDecoder().decode(AdminModifier.self, from: data)
        items.append(created)
        return created
    }

    func update(_ payload: ModifierPayload, id: String) async throws -> AdminModifier {
        let body = try JSONEncoder().encode(payload)
        let data = try await api.patch("/api/admin/modifiers/\(id)", body: body)
        let updated = try JSONDecoder().decode(AdminModifier.self, from: data)
        if let idx = items.firstIndex(where: { $0.id == updated.id }) { items[idx] = updated }
        return updated
    }

    func delete(_ m: AdminModifier) async throws {
        try await api.delete("/api/admin/modifiers/\(m.id)")
        items.removeAll { $0.id == m.id }
    }

    var groupedByType: [(type: String, mods: [AdminModifier])] {
        let order: [String: Int] = ["ADD": 0, "REMOVE": 1, "SUBSTITUTE": 2, "SPECIAL": 3]
        let grouped = Dictionary(grouping: items, by: \.type)
        return grouped
            .sorted { (order[$0.key] ?? 99) < (order[$1.key] ?? 99) }
            .map { ($0.key, $0.value.sorted { $0.sortOrder == $1.sortOrder ? $0.name < $1.name : $0.sortOrder < $1.sortOrder }) }
    }
}

struct ModifiersAdminView: View {
    @Environment(Session.self) private var session
    @State private var store: ModifiersStore?
    @State private var editing: AdminModifier?
    @State private var creating = false
    @State private var deleteCandidate: AdminModifier?

    var body: some View {
        NavigationStack {
            Group {
                if let store { content(store: store) }
                else { ProgressView().frame(maxWidth: .infinity, maxHeight: .infinity) }
            }
            .navigationTitle("Modifiers")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button { creating = true } label: { Image(systemName: "plus") }
                        .accessibilityIdentifier("admin-modifiers-new")
                }
            }
            .sheet(item: $editing) { m in
                if let store { ModifierFormSheet(store: store, existing: m) }
            }
            .sheet(isPresented: $creating) {
                if let store { ModifierFormSheet(store: store, existing: nil) }
            }
            .alert(
                "Delete \(deleteCandidate?.name ?? "modifier")?",
                isPresented: Binding(get: { deleteCandidate != nil }, set: { if !$0 { deleteCandidate = nil } }),
                presenting: deleteCandidate
            ) { m in
                Button("Delete", role: .destructive) { Task { try? await store?.delete(m) } }
                Button("Cancel", role: .cancel) {}
            } message: { _ in Text("Modifiers attached to past orders stay on those records.") }
            .task {
                if store == nil { store = ModifiersStore(session: session) }
                await store?.load()
            }
            .refreshable { await store?.load() }
        }
    }

    @ViewBuilder
    private func content(store: ModifiersStore) -> some View {
        ScrollView {
            VStack(alignment: .leading, spacing: DesignTokens.spacingL) {
                if let msg = store.errorMessage {
                    HStack { Image(systemName: "exclamationmark.triangle.fill").foregroundStyle(.red); Text(msg).font(.subheadline); Spacer() }
                        .padding(DesignTokens.spacingM)
                        .background(RoundedRectangle(cornerRadius: DesignTokens.cornerRadiusSmall, style: .continuous).fill(Color.red.opacity(0.08)))
                }
                if store.isLoading && store.items.isEmpty {
                    ProgressView().frame(maxWidth: .infinity).padding(.vertical, DesignTokens.spacing2XL)
                } else if store.items.isEmpty {
                    VStack(spacing: DesignTokens.spacingM) {
                        Image(systemName: "tag").font(.system(size: 36, weight: .light)).foregroundStyle(.secondary)
                        Text("No modifiers yet").font(.headline)
                        Text("Add-ons (extra cheese), removals (no onion), and substitutions live here.")
                            .font(.subheadline).foregroundStyle(.secondary).multilineTextAlignment(.center)
                    }
                    .frame(maxWidth: .infinity).padding(DesignTokens.spacing2XL)
                } else {
                    ForEach(store.groupedByType, id: \.type) { group in
                        modSection(type: group.type, mods: group.mods)
                    }
                }
            }
            .padding(DesignTokens.spacingL)
        }
        .background(Color(.systemGroupedBackground))
    }

    private func modSection(type: String, mods: [AdminModifier]) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                Text(typeTitle(type)).font(.system(.headline, weight: .semibold))
                Spacer()
                Text("\(mods.count)").font(.caption).foregroundStyle(.secondary)
            }
            .padding(.horizontal, DesignTokens.spacingL).padding(.top, DesignTokens.spacingL).padding(.bottom, DesignTokens.spacingS)

            ForEach(Array(mods.enumerated()), id: \.element.id) { idx, m in
                modRow(m)
                if idx < mods.count - 1 {
                    Divider().background(Color.primary.opacity(DesignTokens.borderOpacity)).padding(.leading, DesignTokens.spacingL)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .webCardBackground()
    }

    private func modRow(_ m: AdminModifier) -> some View {
        Button {
            editing = m
        } label: {
            HStack(spacing: DesignTokens.spacingM) {
                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: 6) {
                        Text(m.name).font(.system(.body, weight: .semibold)).foregroundStyle(.primary)
                        if !m.active {
                            Text("Inactive").font(.caption2).foregroundStyle(.secondary)
                                .padding(.horizontal, 6).padding(.vertical, 2)
                                .background(Capsule().fill(Color.primary.opacity(0.08)))
                        }
                    }
                    HStack(spacing: 6) {
                        if let cat = m.category { Text(cat.name).font(.caption2).foregroundStyle(.secondary) }
                        else { Text("All categories").font(.caption2).foregroundStyle(.secondary) }
                        if let desc = m.description, !desc.isEmpty {
                            Text("·").font(.caption2).foregroundStyle(.secondary)
                            Text(desc).font(.caption).foregroundStyle(.secondary).lineLimit(1)
                        }
                    }
                }
                Spacer()
                Text(m.price > 0 ? "+₹\(m.price)" : (m.price == 0 ? "Free" : "−₹\(-m.price)"))
                    .font(.system(.body, design: .rounded, weight: .semibold))
                    .foregroundStyle(m.price > 0 ? .primary : .secondary)
            }
            .padding(.horizontal, DesignTokens.spacingL).padding(.vertical, DesignTokens.spacingM)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .swipeActions(edge: .trailing, allowsFullSwipe: false) {
            Button(role: .destructive) { deleteCandidate = m } label: { Label("Delete", systemImage: "trash") }
        }
    }

    private func typeTitle(_ t: String) -> String {
        switch t {
        case "ADD": "Add-ons"
        case "REMOVE": "Removals"
        case "SUBSTITUTE": "Substitutions"
        case "SPECIAL": "Special instructions"
        default: t
        }
    }
}

private struct ModifierFormSheet: View {
    let store: ModifiersStore
    let existing: AdminModifier?

    @State private var name = ""
    @State private var description = ""
    @State private var price = 0
    @State private var type = "ADD"
    @State private var categoryId: String? = nil
    @State private var sortOrder = 0
    @State private var active = true
    @State private var saving = false
    @State private var errorMessage: String?

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            Form {
                Section("Details") {
                    TextField("Name (e.g. Extra cheese, No onion)", text: $name)
                        .accessibilityIdentifier("modifier-form-name")
                    TextField("Description (optional)", text: $description, axis: .vertical).lineLimit(2...4)
                        .accessibilityIdentifier("modifier-form-description")
                }
                Section {
                    Picker("Type", selection: $type) {
                        Text("Add-on").tag("ADD")
                        Text("Removal").tag("REMOVE")
                        Text("Substitute").tag("SUBSTITUTE")
                        Text("Special").tag("SPECIAL")
                    }
                    HStack {
                        Text("Price")
                        Spacer()
                        Text("₹")
                        TextField("0", value: $price, format: .number).multilineTextAlignment(.trailing).frame(width: 80)
                        #if os(iOS)
                            .keyboardType(.numberPad)
                        #endif
                    }
                } header: { Text("Type & price") }
                  footer: { Text("Removals are usually free (₹0). Add-ons charge a positive amount.").font(.caption) }
                Section("Category") {
                    Picker("Category", selection: $categoryId) {
                        Text("All categories").tag(String?.none)
                        ForEach(store.categories, id: \.id) { c in
                            Text(c.name).tag(String?.some(c.id))
                        }
                    }
                }
                Section {
                    Toggle("Active", isOn: $active)
                    HStack {
                        Text("Sort order"); Spacer()
                        TextField("0", value: $sortOrder, format: .number).multilineTextAlignment(.trailing).frame(width: 80)
                        #if os(iOS)
                            .keyboardType(.numberPad)
                        #endif
                    }
                }
                if let errorMessage { Section { Text(errorMessage).font(.subheadline).foregroundStyle(.red) } }
            }
            .navigationTitle(existing == nil ? "New Modifier" : "Edit Modifier")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    if saving { ProgressView() } else { Button("Save", action: save).disabled(name.trimmingCharacters(in: .whitespaces).isEmpty) }
                }
            }
            .onAppear {
                if let e = existing {
                    name = e.name
                    description = e.description ?? ""
                    price = e.price
                    type = e.type
                    categoryId = e.categoryId
                    sortOrder = e.sortOrder
                    active = e.active
                }
            }
        }
        .interactiveDismissDisabled(saving)
    }

    private func save() {
        let payload = ModifierPayload(
            name: name.trimmingCharacters(in: .whitespaces),
            description: description.isEmpty ? nil : description,
            price: price,
            type: type,
            categoryId: categoryId,
            sortOrder: sortOrder,
            active: active
        )
        saving = true; errorMessage = nil
        Task {
            do {
                if let existing { _ = try await store.update(payload, id: existing.id) }
                else { _ = try await store.create(payload) }
                saving = false
                dismiss()
            } catch {
                saving = false
                errorMessage = (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
            }
        }
    }
}

// MARK: - App settings (full editable form)

struct AppSettings: Codable, Equatable {
    var restaurant: RestaurantInfo
    var business: BusinessHours
    var billing: BillingSettings
    var inventory: InventorySettings

    struct RestaurantInfo: Codable, Equatable {
        var name: String
        var address: String
        var phone: String
        var email: String
        var gstin: String
        var socialHandle: String
    }
    struct BusinessHours: Codable, Equatable {
        var openingTime: String
        var closingTime: String
        var orderPrefix: String
    }
    struct BillingSettings: Codable, Equatable {
        var taxRate: Double
        var taxLabel: String
        var currency: String
        var locale: String
        var acceptCash: Bool
        var acceptCard: Bool
        var acceptUPI: Bool
        var acceptDigitalWallet: Bool
        var printReceipt: Bool
    }
    struct InventorySettings: Codable, Equatable {
        var lowStockThreshold: Int
        var autoReorder: Bool
        var trackExpiry: Bool
    }
}

@MainActor @Observable final class AppSettingsStore {
    private let api: APIClient
    var settings: AppSettings?
    var isLoading = false
    var saving = false
    var errorMessage: String?

    init(session: Session) { self.api = APIClient(session: session) }

    func load() async {
        isLoading = true; errorMessage = nil
        defer { isLoading = false }
        do {
            let data = try await api.get("/api/admin/settings")
            settings = try JSONDecoder().decode(AppSettings.self, from: data)
        } catch {
            errorMessage = (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
        }
    }

    func save(_ s: AppSettings) async throws {
        saving = true; defer { saving = false }
        _ = try await api.putJSON("/api/admin/settings", payload: s)
        settings = s
    }
}

struct AppSettingsForm: View {
    @Environment(Session.self) private var session
    @State private var store: AppSettingsStore?
    @State private var draft: AppSettings?
    @State private var saveError: String?
    @State private var saveSuccess = false

    var body: some View {
        NavigationStack {
            Form {
                if let draft = Binding($draft) {
                    Section("Restaurant") {
                        TextField("Name", text: draft.restaurant.name).accessibilityIdentifier("settings-restaurant-name")
                        TextField("Address", text: draft.restaurant.address)
                        TextField("Phone", text: draft.restaurant.phone).keyboardType(.phonePad)
                        TextField("Email", text: draft.restaurant.email).keyboardType(.emailAddress).textInputAutocapitalization(.never)
                        TextField("GSTIN", text: draft.restaurant.gstin).textInputAutocapitalization(.characters)
                        TextField("Social handle", text: draft.restaurant.socialHandle)
                    }
                    Section("Business hours") {
                        TextField("Opening", text: draft.business.openingTime).keyboardType(.numbersAndPunctuation)
                        TextField("Closing", text: draft.business.closingTime).keyboardType(.numbersAndPunctuation)
                        TextField("Order prefix", text: draft.business.orderPrefix)
                    }
                    Section("Billing") {
                        HStack { Text("Tax rate"); Spacer()
                            TextField("0", value: draft.billing.taxRate, format: .number).multilineTextAlignment(.trailing).frame(width: 80)
                            #if os(iOS)
                                .keyboardType(.decimalPad)
                            #endif
                        }
                        TextField("Tax label", text: draft.billing.taxLabel)
                        Toggle("Accept Cash", isOn: draft.billing.acceptCash)
                        Toggle("Accept Card", isOn: draft.billing.acceptCard)
                        Toggle("Accept UPI", isOn: draft.billing.acceptUPI)
                        Toggle("Accept Digital Wallet", isOn: draft.billing.acceptDigitalWallet)
                        Toggle("Print receipt", isOn: draft.billing.printReceipt)
                    }
                    Section("Inventory") {
                        HStack { Text("Low stock threshold"); Spacer()
                            TextField("0", value: draft.inventory.lowStockThreshold, format: .number).multilineTextAlignment(.trailing).frame(width: 80)
                            #if os(iOS)
                                .keyboardType(.numberPad)
                            #endif
                        }
                        Toggle("Auto-reorder", isOn: draft.inventory.autoReorder)
                        Toggle("Track expiry", isOn: draft.inventory.trackExpiry)
                    }
                } else {
                    if store?.isLoading == true {
                        Section { HStack { Spacer(); ProgressView(); Spacer() } }
                    } else if let msg = store?.errorMessage {
                        Section { Text(msg).foregroundStyle(.red) }
                    }
                }
                if let saveError {
                    Section { Text(saveError).foregroundStyle(.red) }
                }
            }
            .navigationTitle("Settings")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    if store?.saving == true { ProgressView() }
                    else {
                        Button("Save") { Task { await persist() } }
                            .disabled(draft == nil)
                            .accessibilityIdentifier("settings-save")
                    }
                }
            }
            .alert("Saved", isPresented: $saveSuccess) {
                Button("OK", role: .cancel) {}
            } message: { Text("Settings updated.") }
            .task {
                if store == nil { store = AppSettingsStore(session: session) }
                await store?.load()
                draft = store?.settings
            }
        }
    }

    private func persist() async {
        guard let store, let draft else { return }
        do {
            try await store.save(draft)
            saveSuccess = true
        } catch {
            saveError = (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
        }
    }
}

// MARK: - Reservations

struct AdminTable: Codable, Identifiable, Hashable {
    let id: String
    let number: Int
    let capacity: Int
    let status: String
}

struct AdminReservation: Codable, Identifiable, Hashable {
    let id: String
    var tableId: String?
    var guestName: String
    var guestPhone: String
    var guestCount: Int
    var date: String      // ISO date
    var time: String      // HH:MM
    var duration: Int
    var status: String
    var notes: String?
    var table: AdminTable?
}

struct ReservationCreatePayload: Encodable {
    let tableId: String
    let guestName: String
    let guestPhone: String
    let guestCount: Int
    let date: String
    let time: String
    let duration: Int
    let notes: String?
}

struct ReservationUpdatePayload: Encodable {
    let status: String?
    let guestName: String?
    let guestPhone: String?
    let guestCount: Int?
    let time: String?
    let notes: String?
}

@MainActor @Observable final class ReservationsStore {
    private let api: APIClient
    var items: [AdminReservation] = []
    var tables: [AdminTable] = []
    var isLoading = false
    var errorMessage: String?

    init(session: Session) { self.api = APIClient(session: session) }

    func load() async {
        isLoading = true; errorMessage = nil
        defer { isLoading = false }
        do {
            async let resData = api.get("/api/reservations/upcoming", query: [URLQueryItem(name: "days", value: "30")])
            async let tablesData = api.get("/api/admin/tables")
            items = try JSONDecoder().decode([AdminReservation].self, from: try await resData)
            tables = try JSONDecoder().decode([AdminTable].self, from: try await tablesData)
        } catch {
            errorMessage = (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
        }
    }

    func create(_ payload: ReservationCreatePayload) async throws -> AdminReservation {
        let data = try await api.postJSON("/api/reservations", payload: payload)
        let created = try JSONDecoder().decode(AdminReservation.self, from: data)
        items.append(created)
        items.sort { $0.date < $1.date }
        return created
    }

    func update(_ payload: ReservationUpdatePayload, id: String) async throws -> AdminReservation {
        let data = try await api.putJSON("/api/reservations/\(id)", payload: payload)
        let updated = try JSONDecoder().decode(AdminReservation.self, from: data)
        if let idx = items.firstIndex(where: { $0.id == id }) { items[idx] = updated }
        return updated
    }

    func cancel(_ r: AdminReservation) async throws {
        try await api.delete("/api/reservations/\(r.id)")
        items.removeAll { $0.id == r.id }
    }
}

struct ReservationsAdminView: View {
    @Environment(Session.self) private var session
    @State private var store: ReservationsStore?
    @State private var creating = false
    @State private var editing: AdminReservation?

    var body: some View {
        NavigationStack {
            Group {
                if let store { content(store: store) }
                else { ProgressView().frame(maxWidth: .infinity, maxHeight: .infinity) }
            }
            .navigationTitle("Reservations")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button { creating = true } label: { Image(systemName: "plus") }
                        .accessibilityIdentifier("admin-reservations-new")
                }
            }
            .sheet(isPresented: $creating) {
                if let store { ReservationFormSheet(store: store) }
            }
            .sheet(item: $editing) { r in
                if let store { ReservationDetailSheet(store: store, reservation: r) }
            }
            .task {
                if store == nil { store = ReservationsStore(session: session) }
                await store?.load()
            }
            .refreshable { await store?.load() }
        }
    }

    @ViewBuilder
    private func content(store: ReservationsStore) -> some View {
        ScrollView {
            VStack(alignment: .leading, spacing: DesignTokens.spacingL) {
                if let msg = store.errorMessage {
                    HStack { Image(systemName: "exclamationmark.triangle.fill").foregroundStyle(.red); Text(msg).font(.subheadline); Spacer() }
                        .padding(DesignTokens.spacingM)
                        .background(RoundedRectangle(cornerRadius: DesignTokens.cornerRadiusSmall).fill(Color.red.opacity(0.08)))
                }
                if store.items.isEmpty {
                    VStack(spacing: DesignTokens.spacingM) {
                        Image(systemName: "calendar").font(.system(size: 36, weight: .light)).foregroundStyle(.secondary)
                        Text("No upcoming reservations").font(.headline)
                        Text("Tap + to book a table.").font(.subheadline).foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity).padding(DesignTokens.spacing2XL)
                } else {
                    ForEach(groupedByDay(store.items), id: \.day) { group in
                        daySection(day: group.day, items: group.items)
                    }
                }
            }
            .padding(DesignTokens.spacingL)
        }
        .background(Color(.systemGroupedBackground))
    }

    private func daySection(day: String, items: [AdminReservation]) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(day)
                .font(.system(.headline, weight: .semibold))
                .padding(.horizontal, DesignTokens.spacingL)
                .padding(.top, DesignTokens.spacingL)
                .padding(.bottom, DesignTokens.spacingS)

            ForEach(Array(items.enumerated()), id: \.element.id) { idx, r in
                reservationRow(r)
                if idx < items.count - 1 {
                    Divider().background(Color.primary.opacity(DesignTokens.borderOpacity)).padding(.leading, DesignTokens.spacingL)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .webCardBackground()
    }

    private func reservationRow(_ r: AdminReservation) -> some View {
        Button {
            editing = r
        } label: {
            HStack(spacing: DesignTokens.spacingM) {
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 6) {
                        Text(r.time).font(.system(.body, weight: .semibold))
                        Text("·").foregroundStyle(.secondary)
                        Text(r.guestName).font(.body)
                        statusChip(r.status)
                    }
                    Text("\(r.guestCount) guest\(r.guestCount == 1 ? "" : "s") · \(tableLabel(r))")
                        .font(.caption).foregroundStyle(.secondary)
                }
                Spacer()
                Image(systemName: "chevron.right").font(.caption).foregroundStyle(.secondary)
            }
            .padding(.horizontal, DesignTokens.spacingL).padding(.vertical, DesignTokens.spacingM)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    private func tableLabel(_ r: AdminReservation) -> String {
        if let t = r.table { return "Table \(t.number)" }
        if let tid = r.tableId, let t = (store?.tables.first { $0.id == tid }) { return "Table \(t.number)" }
        return "No table"
    }

    private func statusChip(_ status: String) -> some View {
        let color: Color = {
            switch status.uppercased() {
            case "CONFIRMED": .green
            case "ARRIVED":   .blue
            case "COMPLETED": .gray
            case "CANCELLED", "NO_SHOW": .red
            default:          .orange
            }
        }()
        return Text(status.replacingOccurrences(of: "_", with: " ").capitalized)
            .font(.caption2)
            .padding(.horizontal, 6).padding(.vertical, 2)
            .background(Capsule().fill(color.opacity(0.15)))
            .foregroundStyle(color)
    }

    /// Group reservations by `date` (the ISO day field), display "Today / Tomorrow / Mon May 4" etc.
    private func groupedByDay(_ items: [AdminReservation]) -> [(day: String, items: [AdminReservation])] {
        let f = ISO8601DateFormatter(); f.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        let groups = Dictionary(grouping: items, by: { dayLabel(for: $0.date, formatter: f) })
        return groups
            .sorted { ($0.value.first?.date ?? "") < ($1.value.first?.date ?? "") }
            .map { ($0.key, $0.value.sorted { $0.time < $1.time }) }
    }

    private func dayLabel(for iso: String, formatter: ISO8601DateFormatter) -> String {
        let date = formatter.date(from: iso) ?? ISO8601DateFormatter().date(from: iso) ?? Date()
        let cal = Calendar.current
        if cal.isDateInToday(date) { return "Today" }
        if cal.isDateInTomorrow(date) { return "Tomorrow" }
        let df = DateFormatter(); df.dateFormat = "EEE, MMM d"
        return df.string(from: date)
    }
}

private struct ReservationFormSheet: View {
    let store: ReservationsStore
    @Environment(\.dismiss) private var dismiss
    @State private var tableId: String = ""
    @State private var guestName = ""
    @State private var guestPhone = ""
    @State private var guestCount = 2
    @State private var date = Date().addingTimeInterval(2 * 3600) // default 2h from now
    @State private var time = "19:00"
    @State private var duration = 120
    @State private var notes = ""
    @State private var saving = false
    @State private var errorMessage: String?

    var body: some View {
        NavigationStack {
            Form {
                Section("Guest") {
                    TextField("Name", text: $guestName).accessibilityIdentifier("reservation-form-name")
                    TextField("Phone", text: $guestPhone).keyboardType(.phonePad)
                    Stepper(value: $guestCount, in: 1...20) { Text("\(guestCount) guest\(guestCount == 1 ? "" : "s")") }
                }
                Section("When") {
                    DatePicker("Date", selection: $date, in: Date()..., displayedComponents: .date)
                    HStack {
                        Text("Time"); Spacer()
                        TextField("HH:MM", text: $time).multilineTextAlignment(.trailing).frame(width: 80)
                            .accessibilityIdentifier("reservation-form-time")
                    }
                    Stepper(value: $duration, in: 30...480, step: 30) { Text("\(duration) min") }
                }
                Section("Table") {
                    Picker("Table", selection: $tableId) {
                        Text("Select…").tag("")
                        ForEach(store.tables, id: \.id) { t in
                            Text("Table \(t.number) (\(t.capacity) seats)").tag(t.id)
                        }
                    }
                }
                Section("Notes") {
                    TextField("Optional", text: $notes, axis: .vertical).lineLimit(2...4)
                }
                if let errorMessage { Section { Text(errorMessage).foregroundStyle(.red) } }
            }
            .navigationTitle("New Reservation")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    if saving { ProgressView() }
                    else { Button("Save", action: save).disabled(!isValid) }
                }
            }
            .onAppear {
                if tableId.isEmpty, let first = store.tables.first { tableId = first.id }
            }
        }
        .interactiveDismissDisabled(saving)
    }

    private var isValid: Bool {
        !guestName.trimmingCharacters(in: .whitespaces).isEmpty
        && !guestPhone.trimmingCharacters(in: .whitespaces).isEmpty
        && !tableId.isEmpty
        && guestCount > 0
    }

    private func save() {
        // Server expects date-only YYYY-MM-DD, separate `time` field. If we
        // send a full ISO timestamp the server's `new Date(date + " " + time)`
        // produces "Invalid Date" silently.
        let dateF = DateFormatter()
        dateF.dateFormat = "yyyy-MM-dd"
        dateF.timeZone = .current
        let payload = ReservationCreatePayload(
            tableId: tableId,
            guestName: guestName.trimmingCharacters(in: .whitespaces),
            guestPhone: guestPhone.trimmingCharacters(in: .whitespaces),
            guestCount: guestCount,
            date: dateF.string(from: date),
            time: time,
            duration: duration,
            notes: notes.isEmpty ? nil : notes
        )
        saving = true; errorMessage = nil
        Task {
            do {
                _ = try await store.create(payload)
                saving = false
                dismiss()
            } catch {
                saving = false
                errorMessage = (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
            }
        }
    }
}

private struct ReservationDetailSheet: View {
    let store: ReservationsStore
    let reservation: AdminReservation
    @Environment(\.dismiss) private var dismiss
    @State private var saving = false
    @State private var errorMessage: String?

    var body: some View {
        NavigationStack {
            Form {
                Section("Guest") {
                    LabeledContent("Name", value: reservation.guestName)
                    LabeledContent("Phone", value: reservation.guestPhone)
                    LabeledContent("Party size", value: "\(reservation.guestCount)")
                }
                Section("When") {
                    LabeledContent("Date", value: dayLabel(reservation.date))
                    LabeledContent("Time", value: reservation.time)
                    LabeledContent("Duration", value: "\(reservation.duration) min")
                }
                Section("Update status") {
                    ForEach(["CONFIRMED", "ARRIVED", "COMPLETED", "CANCELLED", "NO_SHOW"], id: \.self) { status in
                        Button {
                            Task { await setStatus(status) }
                        } label: {
                            HStack {
                                Text(status.replacingOccurrences(of: "_", with: " ").capitalized)
                                if reservation.status == status {
                                    Spacer(); Image(systemName: "checkmark").foregroundStyle(.green)
                                }
                            }
                        }
                    }
                }
                if let errorMessage { Section { Text(errorMessage).foregroundStyle(.red) } }
            }
            .navigationTitle(reservation.guestName)
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar { ToolbarItem(placement: .cancellationAction) { Button("Done") { dismiss() } } }
        }
    }

    private func dayLabel(_ iso: String) -> String {
        let f = ISO8601DateFormatter(); f.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        let date = f.date(from: iso) ?? ISO8601DateFormatter().date(from: iso) ?? Date()
        let df = DateFormatter(); df.dateStyle = .medium
        return df.string(from: date)
    }

    private func setStatus(_ status: String) async {
        let payload = ReservationUpdatePayload(status: status, guestName: nil, guestPhone: nil, guestCount: nil, time: nil, notes: nil)
        saving = true; errorMessage = nil
        do {
            _ = try await store.update(payload, id: reservation.id)
            saving = false
            dismiss()
        } catch {
            saving = false
            errorMessage = (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
        }
    }
}

// MARK: - Kitchen

struct KitchenOrderItem: Codable, Identifiable, Hashable {
    let id: String
    let quantity: Int
    var status: String   // PENDING / PREPARING / READY / SERVED / CANCELLED
    let notes: String?
    let menuItem: NamedRef?
    let itemName: String?

    struct NamedRef: Codable, Hashable {
        let id: String?
        let name: String?
    }

    var displayName: String { menuItem?.name ?? itemName ?? "Custom item" }
}

struct KitchenOrder: Codable, Identifiable, Hashable {
    let id: String
    let orderNumber: String
    var status: String
    let type: String
    let createdAt: String
    let table: TableRef?
    let items: [KitchenOrderItem]

    struct TableRef: Codable, Hashable {
        let number: Int?
    }
}

@MainActor @Observable final class KitchenStore {
    private let api: APIClient
    var orders: [KitchenOrder] = []
    var isLoading = false
    var errorMessage: String?

    init(session: Session) { self.api = APIClient(session: session) }

    func load() async {
        isLoading = true; errorMessage = nil
        defer { isLoading = false }
        do {
            let data = try await api.get("/api/kitchen/orders")
            let all = try JSONDecoder().decode([KitchenOrder].self, from: data)
            // Kitchen display: only show orders the kitchen still has work on.
            // SERVED means the food's already at the table — drop it.
            orders = all.filter { !["SERVED", "COMPLETED", "CANCELLED"].contains($0.status.uppercased()) }
        } catch {
            errorMessage = (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
        }
    }

    func advance(_ order: KitchenOrder) async {
        let next: String
        switch order.status.uppercased() {
        case "PENDING", "CONFIRMED":  next = "PREPARING"
        case "PREPARING":             next = "READY"
        case "READY":                 next = "SERVED"
        default: return
        }
        do {
            let payload: [String: String] = ["status": next]
            let body = try JSONEncoder().encode(payload)
            _ = try await api.patch("/api/orders/\(order.id)", body: body)
            if let idx = orders.firstIndex(where: { $0.id == order.id }) {
                if next == "SERVED" {
                    orders.remove(at: idx)
                } else {
                    orders[idx] = KitchenOrder(
                        id: order.id, orderNumber: order.orderNumber, status: next,
                        type: order.type, createdAt: order.createdAt, table: order.table,
                        items: order.items
                    )
                }
            }
        } catch {
            errorMessage = (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
        }
    }

    var groupedByStatus: [(status: String, orders: [KitchenOrder])] {
        let order: [String: Int] = ["PENDING": 0, "CONFIRMED": 1, "PREPARING": 2, "READY": 3]
        let grouped = Dictionary(grouping: orders, by: { $0.status.uppercased() })
        return grouped
            .sorted { (order[$0.key] ?? 99) < (order[$1.key] ?? 99) }
            .map { ($0.key, $0.value.sorted { $0.createdAt < $1.createdAt }) }
    }
}

struct KitchenAdminView: View {
    @Environment(Session.self) private var session
    @State private var store: KitchenStore?

    var body: some View {
        NavigationStack {
            Group {
                if let store { content(store: store) }
                else { ProgressView().frame(maxWidth: .infinity, maxHeight: .infinity) }
            }
            .navigationTitle("Kitchen")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .task {
                if store == nil { store = KitchenStore(session: session) }
                await store?.load()
            }
            .refreshable { await store?.load() }
        }
    }

    @ViewBuilder
    private func content(store: KitchenStore) -> some View {
        ScrollView {
            VStack(alignment: .leading, spacing: DesignTokens.spacingL) {
                if let msg = store.errorMessage {
                    HStack { Image(systemName: "exclamationmark.triangle.fill").foregroundStyle(.red); Text(msg).font(.subheadline); Spacer() }
                        .padding(DesignTokens.spacingM)
                        .background(RoundedRectangle(cornerRadius: DesignTokens.cornerRadiusSmall).fill(Color.red.opacity(0.08)))
                }
                if store.orders.isEmpty {
                    VStack(spacing: DesignTokens.spacingM) {
                        Image(systemName: "fork.knife.circle").font(.system(size: 36, weight: .light)).foregroundStyle(.secondary)
                        Text("No active orders").font(.headline)
                        Text("New orders will appear here as they come in.").font(.subheadline).foregroundStyle(.secondary).multilineTextAlignment(.center)
                    }
                    .frame(maxWidth: .infinity).padding(DesignTokens.spacing2XL)
                } else {
                    ForEach(store.groupedByStatus, id: \.status) { group in
                        statusColumn(status: group.status, orders: group.orders, store: store)
                    }
                }
            }
            .padding(DesignTokens.spacingL)
        }
        .background(Color(.systemGroupedBackground))
    }

    private func statusColumn(status: String, orders: [KitchenOrder], store: KitchenStore) -> some View {
        VStack(alignment: .leading, spacing: DesignTokens.spacingS) {
            HStack {
                Text(statusTitle(status)).font(.system(.title3, weight: .bold))
                Spacer()
                Text("\(orders.count)")
                    .font(.caption).foregroundStyle(.secondary)
                    .padding(.horizontal, 8).padding(.vertical, 2)
                    .background(Capsule().fill(Color.primary.opacity(0.08)))
            }
            ForEach(orders) { o in
                orderCard(o, store: store)
            }
        }
    }

    private func orderCard(_ o: KitchenOrder, store: KitchenStore) -> some View {
        VStack(alignment: .leading, spacing: DesignTokens.spacingS) {
            HStack {
                Text(o.orderNumber).font(.system(.subheadline, design: .monospaced, weight: .bold))
                Spacer()
                if let n = o.table?.number { Text("Table \(n)").font(.caption).foregroundStyle(.secondary) }
                else { Text(o.type).font(.caption).foregroundStyle(.secondary) }
            }
            ForEach(o.items.filter { $0.status.uppercased() != "CANCELLED" }) { it in
                HStack(alignment: .top) {
                    Text("\(it.quantity)×").font(.caption.monospaced()).frame(width: 28, alignment: .leading).foregroundStyle(.secondary)
                    VStack(alignment: .leading, spacing: 2) {
                        Text(it.displayName).font(.subheadline)
                        if let n = it.notes, !n.isEmpty {
                            Text("note: \(n)").font(.caption2).foregroundStyle(.blue)
                        }
                    }
                    Spacer()
                }
            }
            if let label = nextLabel(o.status) {
                Button { Task { await store.advance(o) } } label: {
                    Label(label, systemImage: "checkmark")
                        .font(.subheadline.weight(.semibold))
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.small)
                .padding(.top, 4)
                .accessibilityIdentifier("kitchen-advance-\(o.id)")
            }
        }
        .padding(DesignTokens.spacingM)
        .frame(maxWidth: .infinity, alignment: .leading)
        .webCardBackground()
    }

    private func nextLabel(_ status: String) -> String? {
        switch status.uppercased() {
        case "PENDING", "CONFIRMED":  return "Start preparing"
        case "PREPARING":             return "Mark ready"
        case "READY":                 return "Mark served"
        default:                      return nil
        }
    }

    private func statusTitle(_ status: String) -> String {
        switch status.uppercased() {
        case "PENDING", "CONFIRMED": "To do"
        case "PREPARING": "Preparing"
        case "READY":     "Ready"
        default: status
        }
    }
}

// MARK: - Inventory

struct AdminIngredient: Codable, Identifiable, Hashable {
    let id: String
    var name: String
    var unit: String
    var currentStock: Double
    var minimumStock: Double
    var maximumStock: Double?
    var costPerUnit: Int?
    var supplier: String?
}

struct IngredientPayload: Encodable {
    let name: String
    let unit: String
    let currentStock: Double
    let minimumStock: Double
    let maximumStock: Double?
    let costPerUnit: Int?
    let supplier: String?
}

@MainActor @Observable final class InventoryStore {
    private let api: APIClient
    var items: [AdminIngredient] = []
    var isLoading = false
    var errorMessage: String?

    init(session: Session) { self.api = APIClient(session: session) }

    func load() async {
        isLoading = true; errorMessage = nil
        defer { isLoading = false }
        do {
            let data = try await api.get("/api/admin/inventory")
            items = try JSONDecoder().decode([AdminIngredient].self, from: data)
        } catch {
            errorMessage = (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
        }
    }

    func create(_ payload: IngredientPayload) async throws -> AdminIngredient {
        let data = try await api.postJSON("/api/admin/inventory", payload: payload)
        let created = try JSONDecoder().decode(AdminIngredient.self, from: data)
        items.append(created)
        items.sort { $0.name < $1.name }
        return created
    }

    func update(_ payload: IngredientPayload, id: String) async throws -> AdminIngredient {
        let data = try await api.putJSON("/api/admin/inventory/\(id)", payload: payload)
        let updated = try JSONDecoder().decode(AdminIngredient.self, from: data)
        if let idx = items.firstIndex(where: { $0.id == id }) { items[idx] = updated }
        return updated
    }

    func delete(_ ing: AdminIngredient) async throws {
        try await api.delete("/api/admin/inventory/\(ing.id)")
        items.removeAll { $0.id == ing.id }
    }
}

struct InventoryAdminView: View {
    @Environment(Session.self) private var session
    @State private var store: InventoryStore?
    @State private var editing: AdminIngredient?
    @State private var creating = false
    @State private var deleteCandidate: AdminIngredient?

    var body: some View {
        NavigationStack {
            Group {
                if let store { content(store: store) }
                else { ProgressView().frame(maxWidth: .infinity, maxHeight: .infinity) }
            }
            .navigationTitle("Inventory")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button { creating = true } label: { Image(systemName: "plus") }
                        .accessibilityIdentifier("admin-inventory-new")
                }
            }
            .sheet(item: $editing) { ing in
                if let store { IngredientFormSheet(store: store, existing: ing) }
            }
            .sheet(isPresented: $creating) {
                if let store { IngredientFormSheet(store: store, existing: nil) }
            }
            .alert(
                "Delete \(deleteCandidate?.name ?? "ingredient")?",
                isPresented: Binding(get: { deleteCandidate != nil }, set: { if !$0 { deleteCandidate = nil } }),
                presenting: deleteCandidate
            ) { ing in
                Button("Delete", role: .destructive) { Task { try? await store?.delete(ing) } }
                Button("Cancel", role: .cancel) {}
            } message: { _ in Text("Ingredients linked to recipes can't be deleted.") }
            .task {
                if store == nil { store = InventoryStore(session: session) }
                await store?.load()
            }
            .refreshable { await store?.load() }
        }
    }

    @ViewBuilder
    private func content(store: InventoryStore) -> some View {
        ScrollView {
            VStack(alignment: .leading, spacing: DesignTokens.spacingL) {
                if let msg = store.errorMessage {
                    HStack { Image(systemName: "exclamationmark.triangle.fill").foregroundStyle(.red); Text(msg).font(.subheadline); Spacer() }
                        .padding(DesignTokens.spacingM)
                        .background(RoundedRectangle(cornerRadius: DesignTokens.cornerRadiusSmall).fill(Color.red.opacity(0.08)))
                }
                if store.isLoading && store.items.isEmpty {
                    ProgressView().frame(maxWidth: .infinity).padding(.vertical, DesignTokens.spacing2XL)
                } else if store.items.isEmpty {
                    VStack(spacing: DesignTokens.spacingM) {
                        Image(systemName: "shippingbox").font(.system(size: 36, weight: .light)).foregroundStyle(.secondary)
                        Text("No ingredients yet").font(.headline)
                        Text("Tap + to add an ingredient to track.").font(.subheadline).foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity).padding(DesignTokens.spacing2XL)
                } else {
                    ForEach(store.items) { ing in ingredientCard(ing) }
                }
            }
            .padding(DesignTokens.spacingL)
        }
        .background(Color(.systemGroupedBackground))
    }

    private func ingredientCard(_ ing: AdminIngredient) -> some View {
        Button {
            editing = ing
        } label: {
            VStack(alignment: .leading, spacing: DesignTokens.spacingS) {
                HStack {
                    Text(ing.name).font(.system(.body, weight: .semibold))
                    if ing.currentStock <= ing.minimumStock {
                        Text("Low").font(.caption2).foregroundStyle(.red)
                            .padding(.horizontal, 6).padding(.vertical, 2)
                            .background(Capsule().fill(Color.red.opacity(0.15)))
                    }
                    Spacer()
                    Text(stockText(ing)).font(.system(.body, design: .rounded, weight: .semibold))
                        .foregroundStyle(ing.currentStock <= ing.minimumStock ? .red : .primary)
                }
                stockBar(ing)
                if let supplier = ing.supplier, !supplier.isEmpty {
                    Text("Supplier: \(supplier)").font(.caption2).foregroundStyle(.secondary)
                }
            }
            .padding(DesignTokens.spacingL)
            .frame(maxWidth: .infinity, alignment: .leading)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .webCardBackground()
        .swipeActions(edge: .trailing, allowsFullSwipe: false) {
            Button(role: .destructive) { deleteCandidate = ing } label: { Label("Delete", systemImage: "trash") }
        }
    }

    private func stockBar(_ ing: AdminIngredient) -> some View {
        let max = ing.maximumStock ?? Swift.max(ing.minimumStock * 2, ing.currentStock * 1.2)
        let frac = max > 0 ? min(1.0, ing.currentStock / max) : 0
        let lowFrac = max > 0 ? min(1.0, ing.minimumStock / max) : 0
        return GeometryReader { geo in
            ZStack(alignment: .leading) {
                RoundedRectangle(cornerRadius: 3).fill(Color.primary.opacity(0.08))
                Rectangle().fill(Color.red.opacity(0.6))
                    .frame(width: 1, height: 6)
                    .offset(x: geo.size.width * lowFrac)
                RoundedRectangle(cornerRadius: 3).fill(ing.currentStock <= ing.minimumStock ? Color.red : Color.green)
                    .frame(width: geo.size.width * frac)
            }
        }
        .frame(height: 6)
    }

    private func stockText(_ ing: AdminIngredient) -> String {
        let pretty = ing.currentStock.truncatingRemainder(dividingBy: 1) == 0
            ? "\(Int(ing.currentStock))" : String(format: "%.1f", ing.currentStock)
        return "\(pretty) \(ing.unit)"
    }
}

private struct IngredientFormSheet: View {
    let store: InventoryStore
    let existing: AdminIngredient?

    @Environment(\.dismiss) private var dismiss
    @State private var name = ""
    @State private var unit = "kg"
    @State private var currentStock: Double = 0
    @State private var minimumStock: Double = 0
    @State private var maximumStock: Double = 0
    @State private var hasMax = false
    @State private var costPerUnit = 0
    @State private var hasCost = false
    @State private var supplier = ""
    @State private var saving = false
    @State private var errorMessage: String?

    var body: some View {
        NavigationStack {
            Form {
                Section("Item") {
                    TextField("Name", text: $name).accessibilityIdentifier("inventory-form-name")
                    TextField("Unit (kg, L, pieces)", text: $unit)
                }
                Section("Stock") {
                    HStack { Text("Current"); Spacer()
                        TextField("0", value: $currentStock, format: .number).multilineTextAlignment(.trailing).frame(width: 100)
                        #if os(iOS)
                            .keyboardType(.decimalPad)
                        #endif
                    }
                    HStack { Text("Minimum"); Spacer()
                        TextField("0", value: $minimumStock, format: .number).multilineTextAlignment(.trailing).frame(width: 100)
                        #if os(iOS)
                            .keyboardType(.decimalPad)
                        #endif
                    }
                    Toggle("Has max", isOn: $hasMax)
                    if hasMax {
                        HStack { Text("Maximum"); Spacer()
                            TextField("0", value: $maximumStock, format: .number).multilineTextAlignment(.trailing).frame(width: 100)
                            #if os(iOS)
                                .keyboardType(.decimalPad)
                            #endif
                        }
                    }
                }
                Section("Sourcing") {
                    Toggle("Track cost", isOn: $hasCost)
                    if hasCost {
                        HStack { Text("Cost per unit (₹)"); Spacer()
                            TextField("0", value: $costPerUnit, format: .number).multilineTextAlignment(.trailing).frame(width: 100)
                            #if os(iOS)
                                .keyboardType(.numberPad)
                            #endif
                        }
                    }
                    TextField("Supplier", text: $supplier)
                }
                if let errorMessage { Section { Text(errorMessage).foregroundStyle(.red) } }
            }
            .navigationTitle(existing == nil ? "New Ingredient" : "Edit Ingredient")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    if saving { ProgressView() }
                    else { Button("Save", action: save).disabled(name.trimmingCharacters(in: .whitespaces).isEmpty || unit.isEmpty) }
                }
            }
            .onAppear {
                if let e = existing {
                    name = e.name; unit = e.unit
                    currentStock = e.currentStock; minimumStock = e.minimumStock
                    if let m = e.maximumStock { hasMax = true; maximumStock = m }
                    if let c = e.costPerUnit { hasCost = true; costPerUnit = c }
                    supplier = e.supplier ?? ""
                }
            }
        }
        .interactiveDismissDisabled(saving)
    }

    private func save() {
        let payload = IngredientPayload(
            name: name.trimmingCharacters(in: .whitespaces),
            unit: unit.trimmingCharacters(in: .whitespaces),
            currentStock: currentStock,
            minimumStock: minimumStock,
            maximumStock: hasMax ? maximumStock : nil,
            costPerUnit: hasCost ? costPerUnit : nil,
            supplier: supplier.isEmpty ? nil : supplier
        )
        saving = true; errorMessage = nil
        Task {
            do {
                if let existing { _ = try await store.update(payload, id: existing.id) }
                else { _ = try await store.create(payload) }
                saving = false
                dismiss()
            } catch {
                saving = false
                errorMessage = (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
            }
        }
    }
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
