//
//  BillHistoryList.swift
//  Durigo
//
//  Created by Joshua Cardozo on 19/11/23.
//

import SwiftUI
import SwiftData

struct BillHistoryList: View {
    @State private var selectedTable: Int?
    @State private var showTodaysBills = false
    @Query(sort: \BillHistoryItem.date, order: .reverse) private var billHistoryItems: [BillHistoryItem]
    
    func filteredBillHistoryItems() -> [BillHistoryItem] {
        
        if showTodaysBills {
            return billHistoryItems.filter({ billHistoryItem in
                abs(billHistoryItem.date.timeIntervalSinceNow) < 60*60*24
            })
        }
        if let selectedTable {
            return billHistoryItems.filter({ billHistoryItem in
                billHistoryItem.tableNumber == selectedTable
            })
        }
        return billHistoryItems
    }
    
    var body: some View {
        NavigationStack {
            VStack {
                let items = filteredBillHistoryItems()
                if items.count == 0 {
                    VStack {
                        Spacer()
                        ContentUnavailableView(
                            "No Bills available\(showTodaysBills ? " for today" : "") \(selectedTable != nil ? " for this table" : "")",
                            systemImage: "exclamationmark.triangle",
                            description: Text("Try a different filter, or clear your filters")
                        )
                        Spacer()
                    }
                } else {
                List {
                    
                    ForEach(items) { billHistoryItem in
                        NavigationLink {
                            BillHistory(billHistoryItem: billHistoryItem)
                        } label: {
                            VStack(alignment: .leading) {
                                Menu {
                                    Button(action: {
                                        billHistoryItem.paymentStatus = .paid
                                    }) {
                                        Label("Paid", systemImage: "checkmark.circle")
                                    }
                                    
                                    Button(action: {
                                        billHistoryItem.paymentStatus = .pending
                                    }) {
                                        Label("Pending", systemImage: "hourglass")
                                    }
                                    
                                } label: {
                                    Label(billHistoryItem.paymentStatus.rawValue.capitalized(with: .current), systemImage: billHistoryItem.paymentStatus == .paid ? "checkmark.circle" : "hourglass")
                                        .foregroundStyle(billHistoryItem.paymentStatus == .paid ? Color.green : Color.red)
                                        .accessibilityIdentifier("paymentStatus-\(billHistoryItem.id)")
                                }
                                .padding(.bottom)

                                HStack {
                                    GroupBox {
                                        if let tableNumber = billHistoryItem.tableNumber {
                                            Text("Table: \(tableNumber)")
                                        } else {
                                            Text("Table: unknown")
                                        }
                                    }
                                    .backgroundStyle(Color.tableColor(tableNumber: billHistoryItem.tableNumber))
                                    Spacer()
                                    GroupBox {
                                        Text("\(billHistoryItem.items.count)")
                                    }
                                    .backgroundStyle(Color.billHistoryItemQuantity)
                                    
                                    GroupBox {
                                        
                                        Text("\(billHistoryItem.items.getTotal().asCurrencyString() ?? "")")
                                            .accessibilityIdentifier("BillHistoryList-Item-\(billHistoryItem.id.uuidString)")
                                        
                                    }
                                    .backgroundStyle(Color.billHistoryItemTotal)
                                    
                                }
                                .bold()
                                Text(billHistoryItem.date.getTimeInFormat(dateStyle: .medium, timeStyle: .short))
                                    .padding(.vertical, 4)
                                
                            }
                        }
                        
                    }
                }
            }
            }
            .navigationTitle("History")
            .toolbar {
                Menu {
                    Button(action: {
                        showTodaysBills = true
                        selectedTable = nil
                    }) {
                        Label("Show todays bills", systemImage: "calendar")
                    }
                    DropdownSelector(selectedOption: $selectedTable, options: Array(1...12))
                    Button(action: {
                        showTodaysBills = false
                        selectedTable = nil
                    }) {
                        Label("Clear filters", systemImage: "xmark.circle")
                    }

                } label: {
                    Image(systemName: "line.3.horizontal.decrease.circle")
                }
            }
            .onChange(of: selectedTable) { _, _ in
                showTodaysBills = false
            }
        }
        
    }
}

#Preview {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: BillHistoryItem.self, configurations: config)
    
    Array(1...10).forEach { tableNumber in
        container.mainContext.insert(BillHistoryItem(id: UUID(), items: [
            MenuItem(id: UUID(), name: "Delicious dish", quantity: 2, price: 300)
        ], tableNumber: tableNumber))
    }
    
    return BillHistoryList()
        .modelContainer(container)
}
