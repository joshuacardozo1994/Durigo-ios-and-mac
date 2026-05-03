//
//  POSContainer.swift
//  Durigo
//
//  Top-level POS view. Hosts a 2-tab segmented switcher between the new
//  POS (table grid + take order) and the existing Bill Generator.
//
//  This view is what `Home.swift` routes `.pos` to.
//

import SwiftUI

enum POSTab: String, CaseIterable, Identifiable {
    case pos = "POS"
    case billGenerator = "Bill Generator"

    var id: String { rawValue }
}

struct POSContainerView: View {
    @Environment(Session.self) private var session
    @State private var tab: POSTab = .pos
    @State private var store: POSStore?

    var body: some View {
        VStack(spacing: 0) {
            Picker("View", selection: $tab) {
                ForEach(POSTab.allCases) { t in
                    Text(t.rawValue).tag(t)
                }
            }
            .pickerStyle(.segmented)
            .padding(.horizontal, DesignTokens.spacingL)
            .padding(.top, DesignTokens.spacingM)
            .padding(.bottom, DesignTokens.spacingS)

            Divider().opacity(0.4)

            Group {
                switch tab {
                case .pos:
                    if let store {
                        TablesGridView(store: store)
                    } else {
                        ProgressView().frame(maxWidth: .infinity, maxHeight: .infinity)
                    }
                case .billGenerator:
                    BillGenerator()
                }
            }
        }
        .task {
            if store == nil {
                let api = APIClient(session: session)
                let s = POSStore(api: api)
                store = s
                await s.loadTables()
                await s.loadMenu()
                await s.loadWaiters()
                await s.loadTableGroups()
                await s.loadUpcomingReservations()
                s.startSSE()
            }
        }
        .onDisappear {
            store?.stopSSE()
        }
    }
}
