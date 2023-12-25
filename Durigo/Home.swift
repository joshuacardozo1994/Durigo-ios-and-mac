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
                
            ChristmasMenuGenerator()
                .tabItem {
                    Label("Menu Generator", systemImage: "doc.plaintext.fill")
                }
                .tag(TabItems.menuGenerator)
                
        }
        .environmentObject(menuLoader)
        .environmentObject(navigation)
    }
}

#Preview {
    Home()
}
