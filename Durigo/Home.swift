//
//  Home.swift
//  Durigo
//
//  Created by Joshua Cardozo on 20/11/23.
//

import SwiftUI
import SwiftData



struct Home: View {
    @StateObject private var menuLoader = MenuLoader()
    @StateObject private var navigation = Navigation()
    @Query private var billHistoryItems: [BillHistoryItem]
    @Environment(\.modelContext) var modelContext
    var body: some View {
        TabView(selection: $navigation.tabSelection) {
            BillHistoryList()
                .tabItem {
                    Label("History", systemImage: "doc.text")
                }
                .tag(TabItems.billHistoryList)
                .badge(billHistoryItems.filter({ $0.paymentStatus == .pending }).count)
                
            BillGenerator()
                .tabItem {
                    Label("Bill Generator", systemImage: "gearshape.2")
                }
                .tag(TabItems.billGenerator)
            Stats()
                .tabItem {
                    Label("Stats", systemImage: "chart.bar.fill")
                }
                .tag(TabItems.stats)
            ChristmasMenuGenerator()
                .tabItem {
                    Label("Menu Generator", systemImage: "doc.plaintext.fill")
                }
                .tag(TabItems.menuGenerator)
            
                
        }
        .onOpenURL(perform: { url in
            do {
                let data = try Data(contentsOf: url)
                let durigoBills = try JSONDecoder().decode(DurigoBills.self, from: data)
                durigoBills.items.forEach { receivedBillHistoryItemCopy in
                    let receivedBillHistoryItem = receivedBillHistoryItemCopy.convertToBillHistoryItem()
                    if (!billHistoryItems.contains { $0.id == receivedBillHistoryItem.id }) {
                        modelContext.insert(receivedBillHistoryItem)
                    }
                }
            } catch {
                print("Error decoding object: \(error)")
            }
        })
        .environmentObject(menuLoader)
        .environmentObject(navigation)
    }
}

#Preview {
#if DEBUG
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: BillHistoryItem.self, configurations: config)
    
    PreviewData.billHistoryItems.forEach { billHistoryItem in
        container.mainContext.insert(billHistoryItem)
    }
    #endif
    return Home()
#if DEBUG
        .modelContainer(container)
#endif
}
