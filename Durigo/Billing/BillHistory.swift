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
                        Text("\(menuItem.quantity) ")
                        +
                        Text(menuItem.servingSize?.shouldDisplay == true ? "\(menuItem.servingSize?.name ?? "") " : "")
                        +
                        Text(menuItem.prefix != nil ? "(\(menuItem.prefix ?? "")) " : "")
                        +
                        Text("\(menuItem.name)")
                        +
                        Text(menuItem.suffix != nil ? " (\(menuItem.suffix ?? ""))" : "")
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
                menuLoader.tableNumber = billHistoryItem.tableNumber
                menuLoader.waiter = billHistoryItem.waiter
                menuLoader.billID = billHistoryItem.id
                navigation.tabSelection = .billGenerator
            }
            Button("Cancel", role: .cancel) {}
        }
        .navigationTitle("\(billHistoryItem.tableNumber == 0 ? "Parcel Bill" : "Table \(billHistoryItem.tableNumber ) Bill")")
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
    BillHistory(billHistoryItem: BillHistoryItem(id: UUID(), items: [MenuItem](), tableNumber: 1, waiter: "anthony"))
}
