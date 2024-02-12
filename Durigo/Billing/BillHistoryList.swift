//
//  BillHistoryList.swift
//  Durigo
//
//  Created by Joshua Cardozo on 19/11/23.
//

import SwiftUI
import SwiftData
import LocalAuthentication

struct BillHistoryList: View {
    @State private var selectedTable: Int?
    @State private var selectedWaiter: String?
    @State private var showTodaysBills = false
    @State private var sharingURL: URL?
    @State private var selectedPaymentStatus: BillHistoryItemStatus?
    @Query(sort: \BillHistoryItem.date, order: .reverse) private var billHistoryItems: [BillHistoryItem]
    
    func setAppBadgeCount() {
        let pendingBillsCount = (billHistoryItems.filter { $0.paymentStatus == .pending }).count
        UNUserNotificationCenter.current().setBadgeCount(pendingBillsCount)
    }
    
    func filteredBillHistoryItems() -> [BillHistoryItem] {
        var filteredBillHistoryItems = billHistoryItems
        if showTodaysBills {
            filteredBillHistoryItems = filteredBillHistoryItems.filter({ billHistoryItem in
                abs(billHistoryItem.date.timeIntervalSinceNow) < 60*60*24
            })
        }
        if let selectedTable {
            filteredBillHistoryItems = filteredBillHistoryItems.filter({ billHistoryItem in
                billHistoryItem.tableNumber == selectedTable
            })
        }
        if let selectedWaiter {
            filteredBillHistoryItems = filteredBillHistoryItems.filter({ billHistoryItem in
                billHistoryItem.waiter == selectedWaiter
            })
        }
        if let selectedPaymentStatus {
            filteredBillHistoryItems = filteredBillHistoryItems.filter({ billHistoryItem in
                billHistoryItem.paymentStatus == selectedPaymentStatus
            })
        }
        return filteredBillHistoryItems
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
                                HStack {
                                    Menu {
                                        Menu {
                                            Button(action: {
                                                billHistoryItem.paymentStatus = .paidByCash
                                                setAppBadgeCount()
                                            }) {
                                                Label("Cash", systemImage: "banknote")
                                            }
                                            
                                            Button(action: {
                                                billHistoryItem.paymentStatus = .paidByUPI
                                                setAppBadgeCount()
                                            }) {
                                                Label("UPI", systemImage: "indianrupeesign")
                                            }
                                            
                                            Button(action: {
                                                billHistoryItem.paymentStatus = .paidByCard
                                                setAppBadgeCount()
                                            }) {
                                                Label("Card", systemImage: "creditcard")
                                            }
                                        } label: {
                                            Label("Paid", systemImage: "checkmark.circle")
                                        }
                                        
                                        Button(action: {
                                            billHistoryItem.paymentStatus = .pending
                                            setAppBadgeCount()
                                        }) {
                                            Label("Pending", systemImage: "hourglass")
                                        }
                                        
                                    } label: {
                                        VStack {
                                            switch billHistoryItem.paymentStatus {
                                            case .pending:
                                                Label("Pending", systemImage: "hourglass")
                                                    .foregroundStyle(Color.red)
                                                    .accessibilityIdentifier("paymentStatus-\(billHistoryItem.id)")
                                            case .paidByCard:
                                                Label("Paid by card", systemImage: "creditcard")
                                                    .foregroundStyle(Color.green)
                                                    .accessibilityIdentifier("paymentStatus-\(billHistoryItem.id)")
                                            case .paidByCash:
                                                Label("Paid by cash", systemImage: "banknote")
                                                    .foregroundStyle(Color.green)
                                                    .accessibilityIdentifier("paymentStatus-\(billHistoryItem.id)")
                                            case .paidByUPI:
                                                Label("Paid by UPI", systemImage: "indianrupeesign")
                                                    .foregroundStyle(Color.green)
                                                    .accessibilityIdentifier("paymentStatus-\(billHistoryItem.id)")
                                            }
                                        }
                                    }
                                    Spacer()
                                    Label(billHistoryItem.waiter, systemImage: "person.circle")
                                }
                                .padding(.bottom)

                                HStack {
                                    GroupBox {
                                        let tableNumber = billHistoryItem.tableNumber
                                        if tableNumber == 0 {
                                            Text("Parcel")
                                        } else {
                                            Text("Table: \(tableNumber)")
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
                .animation(.linear, value: items)
            }
            }
            .navigationTitle("History")
            .toolbar {
                Menu {
                    Button(action: {
                        showTodaysBills.toggle()
                    }) {
                        Label("\(showTodaysBills ? "●" : "") Show todays bills", systemImage: "calendar")
                    }
                    TableDropdownSelector(showIfSelected: true, selectedOption: $selectedTable, options: Array(1...20))
                    WaiterDropdownSelector(showIfSelected: true, selectedOption: $selectedWaiter, options: ["Alcin", "Anthony", "Antone", "Amanda", "Monica", "Joshua"])
                    
                    Menu {
                        Menu {
                            Button(action: {
                                selectedPaymentStatus = .paidByCash
                            }) {
                                Label("Cash", systemImage: "banknote")
                            }
                            
                            Button(action: {
                                selectedPaymentStatus = .paidByUPI
                            }) {
                                Label("UPI", systemImage: "indianrupeesign")
                            }
                            
                            Button(action: {
                                selectedPaymentStatus = .paidByCard
                            }) {
                                Label("Card", systemImage: "creditcard")
                            }
                        } label: {
                            Label("Paid", systemImage: "checkmark.circle")
                        }
                        
                        Button(action: {
                            selectedPaymentStatus = .pending
                        }) {
                            Label("Pending", systemImage: "hourglass")
                        }
                        
                    } label: {
                        VStack {
                            switch selectedPaymentStatus {
                            case .pending:
                                Label("Pending", systemImage: "hourglass")
                                    .foregroundStyle(Color.red)
                            case .paidByCard:
                                Label("Paid by card", systemImage: "creditcard")
                                    .foregroundStyle(Color.green)
                            case .paidByCash:
                                Label("Paid by cash", systemImage: "banknote")
                                    .foregroundStyle(Color.green)
                            case .paidByUPI:
                                Label("Paid by UPI", systemImage: "indianrupeesign")
                                    .foregroundStyle(Color.green)
                            case .none:
                                Label("Select a Payment Status", systemImage: "info")
                            }
                        }
                    }
                    Section {
                        Button(action: {
                            showTodaysBills = false
                            selectedTable = nil
                            selectedWaiter = nil
                            selectedPaymentStatus = nil
                        }) {
                            Label("Clear filters", systemImage: "xmark.circle")
                        }
                    }

                } label: {
                    Image(systemName: "line.3.horizontal.decrease.circle")
                        .overlay(alignment: .topTrailing) {
                            let isFilterApplied = !(showTodaysBills == false && selectedTable == nil && selectedWaiter == nil && selectedPaymentStatus == nil)
                            Circle()
                                .fill(isFilterApplied ? Color.red : Color.clear)
                                .frame(width: 10, height: 10)
                        }
                }
            }
            .toolbar {
                if let sharingURL {
                    ShareLink(item: sharingURL)
                }
                Button(action: {
                    let url = URL.documentsDirectory.appending(path: "billsHistory.durigobills")
                    do {
                        let data = try JSONEncoder().encode(DurigoBills(items: billHistoryItems.map({  BillHistoryItemCopy(billHistoryItem: $0) }) ))
                        try data.write(to: url, options: [.atomic, .completeFileProtection])
                        let input = try String(contentsOf: url)
                        print("WTF did i save", input)
                        sharingURL = url
                    } catch {
                        
                    }
                }) {
                    Text("Share")
                }
            }
        }
        .lockWithBiometric()
        
    }
}

#if DEBUG
#Preview {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: BillHistoryItem.self, configurations: config)
    
    PreviewData.billHistoryItems.forEach { billHistoryItem in
        container.mainContext.insert(billHistoryItem)
    }
    return BillHistoryList()
        .modelContainer(container)

}
#endif
