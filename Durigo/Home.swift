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
        case .modifiers:    ModifiersAdminView()
        case .discounts:    DiscountsAdminView()
        case .inventory:    ComingSoonView(title: "Inventory", icon: "shippingbox", note: "Ingredient stock levels, low-stock alerts, restock entries.")
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
                    TextField("Email", text: $email)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        .keyboardType(.emailAddress)
                    TextField("Username", text: $username)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                }
                Section {
                    SecureField(existing == nil ? "Password" : "New password (leave empty to keep)", text: $password)
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
                    TextField("Name", text: $name)
                    TextField("Description (optional)", text: $description, axis: .vertical).lineLimit(2...4)
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
                    TextField("Description (optional)", text: $description, axis: .vertical).lineLimit(2...4)
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
