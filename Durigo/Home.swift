//
//  Home.swift
//  Durigo
//
//  Root navigation container. Uses size class to pick the right shell:
//   - compact (iPhone, iPad split-view minified): TabView with bottom tabs
//   - regular (iPad full):                        NavigationSplitView with sidebar
//

import SwiftUI
import SwiftData

struct Home: View {
    @StateObject private var menuLoader = MenuLoader()
    @StateObject private var navigation = Navigation()
    @Query private var billHistoryItems: [BillHistoryItem]
    @Environment(\.modelContext) var modelContext
    @Environment(\.horizontalSizeClass) private var sizeClass
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
        .onOpenURL { url in
            handleIncomingURL(url)
        }
        .environmentObject(menuLoader)
        .environmentObject(navigation)
    }

    // MARK: - iPhone (compact)

    private var iPhoneShell: some View {
        TabView(selection: $navigation.tabSelection) {
            BillHistoryList()
                .tabItem {
                    Label(TabItems.billHistoryList.title, systemImage: TabItems.billHistoryList.icon)
                }
                .tag(TabItems.billHistoryList)
                .badge(pendingCount)

            BillGenerator()
                .tabItem {
                    Label(TabItems.billGenerator.title, systemImage: TabItems.billGenerator.icon)
                }
                .tag(TabItems.billGenerator)

            Stats()
                .tabItem {
                    Label(TabItems.stats.title, systemImage: TabItems.stats.icon)
                }
                .tag(TabItems.stats)

            Reports()
                .tabItem {
                    Label(TabItems.reports.title, systemImage: TabItems.reports.icon)
                }
                .tag(TabItems.reports)

            MenuGenerator()
                .tabItem {
                    Label(TabItems.menuGenerator.title, systemImage: TabItems.menuGenerator.icon)
                }
                .tag(TabItems.menuGenerator)
        }
    }

    // MARK: - iPad (regular)

    private var iPadShell: some View {
        NavigationSplitView(columnVisibility: $columnVisibility) {
            sidebar
        } detail: {
            destination(for: navigation.tabSelection)
                .toolbar {
                    // Explicit collapse/expand toggle in the detail toolbar.
                    ToolbarItem(placement: .topBarLeading) {
                        Button {
                            withAnimation(.easeInOut(duration: 0.25)) {
                                columnVisibility = (columnVisibility == .all) ? .detailOnly : .all
                            }
                        } label: {
                            Image(systemName: "sidebar.left")
                        }
                        .accessibilityLabel(columnVisibility == .all ? "Hide sidebar" : "Show sidebar")
                    }
                }
        }
        .navigationSplitViewStyle(.balanced)
    }

    private var sidebar: some View {
        List(selection: Binding(
            get: { navigation.tabSelection },
            set: { if let v = $0 { navigation.tabSelection = v } }
        )) {
            Section {
                ForEach(TabItems.allCases, id: \.self) { tab in
                    NavigationLink(value: tab) {
                        Label {
                            HStack {
                                Text(tab.title)
                                if tab == .billHistoryList && pendingCount > 0 {
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
                            Image(systemName: tab.icon)
                        }
                    }
                    .tag(tab)
                }
            } header: {
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
                .padding(.bottom, 4)
            }
        }
        .listStyle(.sidebar)
        .navigationTitle("")
        .toolbar(.hidden, for: .navigationBar)
    }

    @ViewBuilder
    private func destination(for tab: TabItems) -> some View {
        switch tab {
        case .billHistoryList:  BillHistoryList()
        case .billGenerator:    BillGenerator()
        case .stats:            Stats()
        case .reports:          Reports()
        case .menuGenerator:    MenuGenerator()
        }
    }

    // MARK: - Document import

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
