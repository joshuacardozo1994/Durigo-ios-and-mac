//
//  Home.swift
//  Durigo
//
//  Created by Joshua Cardozo on 20/11/23.
//

import SwiftUI



struct Home: View {
    @StateObject private var menuLoader = MenuLoader()
    @StateObject private var navigation = Navigation()
    var body: some View {
        TabView(selection: $navigation.tabSelection) {
            BillHistoryList()
                .tabItem {
                    Label("History", systemImage: "doc.text")
                }
                .tag(TabItems.billHistoryList)
            BillGenerator()
                .tabItem {
                    Label("Bill Generator", systemImage: "gearshape.2")
                }
                .tag(TabItems.billGenerator)
        }
        .environmentObject(menuLoader)
        .environmentObject(navigation)
    }
}

#Preview {
    Home()
}
