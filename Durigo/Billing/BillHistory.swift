//
//  BillHistory.swift
//  Durigo
//
//  Created by Joshua Cardozo on 20/11/23.
//

import SwiftUI

struct BillHistory: View {
    @EnvironmentObject private var menuLoader: MenuLoader
    @EnvironmentObject private var navigation: Navigation
    @State private var showingBillRegenerateAlert = false
    let billHistoryItem: BillHistoryItem
    var body: some View {
        VStack {
            List {
                ForEach(billHistoryItem.items) { menuItem in
                    HStack {
                        Text("\(menuItem.quantity)")
                        Text("\(menuItem.name)")
                        Spacer()
                        Text("\(menuItem.price)")
                    }
                    
                }
                
            }
            totalSection
        }
        .alert("Are you sure you want to regenerate the bill", isPresented: $showingBillRegenerateAlert) {
            Button("Regenerate", role: .destructive) {
                menuLoader.billItems = billHistoryItem.items
                navigation.tabSelection = .billGenerator
            }
            Button("Cancel", role: .cancel) {}
        }
        .navigationTitle("Bill")
        .toolbar {
            printButton
        }
    }
    
    private var printButton: some View {
        Button(action: {
            showingBillRegenerateAlert.toggle()
        }) {
            Text("Regenerate")
        }
    }
    
    private var totalSection: some View {
        HStack {
            Text("\(billHistoryItem.items.count) Items")
            Spacer()
            Text("Total: \(billHistoryItem.items.getTotal())")
        }
        .padding(.horizontal)
        .font(.title)
        .bold()
    }
}

#Preview {
    BillHistory(billHistoryItem: BillHistoryItem(items: [MenuItem]()))
}
