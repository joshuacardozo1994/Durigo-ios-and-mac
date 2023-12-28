//
//  BillHistoryList.swift
//  Durigo
//
//  Created by Joshua Cardozo on 19/11/23.
//

import SwiftUI
import SwiftData
import LocalAuthentication

struct BillHistoryListUnlocked: View {
    @State private var selectedTable: Int?
    @State private var selectedWaiter: String?
    @State private var showTodaysBills = false
    @State private var sharingURL: URL?
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
        if let selectedWaiter {
            return billHistoryItems.filter({ billHistoryItem in
                billHistoryItem.waiter == selectedWaiter
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
                                HStack {
                                    Menu {
                                        Menu {
                                            Button(action: {
                                                billHistoryItem.paymentStatus = .paidByCash
                                            }) {
                                                Label("Cash", systemImage: "banknote")
                                            }
                                            
                                            Button(action: {
                                                billHistoryItem.paymentStatus = .paidByUPI
                                            }) {
                                                Label("UPI", systemImage: "indianrupeesign")
                                            }
                                            
                                            Button(action: {
                                                billHistoryItem.paymentStatus = .paidByCard
                                            }) {
                                                Label("Card", systemImage: "creditcard")
                                            }
                                        } label: {
                                            Label("Paid", systemImage: "checkmark.circle")
                                        }
                                        
                                        Button(action: {
                                            billHistoryItem.paymentStatus = .pending
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
            }
            }
            .navigationTitle("History")
            .toolbar {
                Menu {
                    Button(action: {
                        showTodaysBills = true
                        selectedTable = nil
                        selectedWaiter = nil
                    }) {
                        Label("\(showTodaysBills ? "●" : "") Show todays bills", systemImage: "calendar")
                    }
                    TableDropdownSelector(showIfSelected: true, selectedOption: $selectedTable, options: Array(1...12))
                    WaiterDropdownSelector(showIfSelected: true, selectedOption: $selectedWaiter, options: ["Alcin", "Anthony", "Antone", "Amanda", "Monica", "Joshua"])
                    Button(action: {
                        showTodaysBills = false
                        selectedTable = nil
                        selectedWaiter = nil
                    }) {
                        Label("Clear filters", systemImage: "xmark.circle")
                    }

                } label: {
                    Image(systemName: "line.3.horizontal.decrease.circle")
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
            .onChange(of: selectedTable) { _, _ in
                showTodaysBills = false
                selectedWaiter = nil
            }
            .onChange(of: selectedWaiter) { _, _ in
                showTodaysBills = false
                selectedTable = nil
            }
        }
        
    }
}

struct BillHistoryList: View {
    @State private var isUnlocked = true
    private func authenticateWithBiometrics() {
            let context = LAContext()

            var error: NSError?

            if context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) {
                let reason = "Authenticate to unlock the app"
                
                context.evaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, localizedReason: reason) { success, authenticationError in
                    DispatchQueue.main.async {
                        if success {
                            isUnlocked = true
                        } else {
                            // Handle authentication failure
                            if let error = authenticationError as? LAError {
                                switch error.code {
                                case .userFallback:
                                    // User tapped "Enter Password"
                                    // You can provide an alternative method for authentication here.
                                    break
                                default:
                                    // Handle other authentication errors
                                    break
                                }
                            }
                        }
                    }
                }
            } else {
                // Device doesn't support biometric authentication or has no enrolled biometrics.
                // Handle accordingly.
            }
        }
    var body: some View {
        VStack {
            if isUnlocked {
                BillHistoryListUnlocked()
            } else {
                VStack {
                    ContentUnavailableView("You do not have access to this screen", systemImage: "exclamationmark.triangle", description: Text("Please click unlock, to unlock the screen"))
                    Button(action: { authenticateWithBiometrics() }) {
                        Label("Unlock", systemImage: "lock.open.fill")
                    }
                    .padding(.bottom, 60)
                }
            }
        }
        .task {
            if !isUnlocked {
                authenticateWithBiometrics()
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
        ], tableNumber: tableNumber, waiter: "Anthony"))
    }
    
    return BillHistoryList()
        .modelContainer(container)
}
