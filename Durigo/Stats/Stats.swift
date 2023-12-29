//
//  Stats.swift
//  Durigo
//
//  Created by Joshua Cardozo on 29/12/23.
//

import SwiftUI
import SwiftData

extension Stats {
    struct Container {
        let totalSalesAmounts: [String: Int]
        let totalQuantities: [String: Int]
        let sortedMenuItemsForSale: [String]
        let sortedMenuItemsForQuantity: [String]
    }
}

struct Stats: View {
    @Query private var billHistoryItems: [BillHistoryItem]
    
    func getPopularItems() -> Stats.Container {
        // Define dictionaries to store the total sales amount and total quantity for each MenuItem
        var totalSalesAmounts: [String: Int] = [:]
        var totalQuantities: [String: Int] = [:]

        // Calculate the total sales amount and total quantity for each MenuItem
        for billHistoryItem in billHistoryItems {
            for item in billHistoryItem.items {
                if let salesAmount = totalSalesAmounts[item.name], let quantity = totalQuantities[item.name] {
                    totalSalesAmounts[item.name] = salesAmount + (item.quantity * item.price)
                    totalQuantities[item.name] = quantity + item.quantity
                } else {
                    totalSalesAmounts[item.name] = item.quantity * item.price
                    totalQuantities[item.name] = item.quantity
                }
            }
        }

        // Create an array of unique MenuItem names
        let uniqueMenuItemNames = Set(billHistoryItems.flatMap { $0.items.map { $0.name } })

        // Create an array of MenuItems sorted in descending order by total sales amount
        let sortedMenuItemsForSale = uniqueMenuItemNames.sorted {
            totalSalesAmounts[$0]! > totalSalesAmounts[$1]!
        }
        
        let sortedMenuItemsForQuantity = uniqueMenuItemNames.sorted {
            totalQuantities[$0]! > totalQuantities[$1]!
        }
        return Container(totalSalesAmounts: totalSalesAmounts, totalQuantities: totalQuantities, sortedMenuItemsForSale: sortedMenuItemsForSale, sortedMenuItemsForQuantity: sortedMenuItemsForQuantity)
    }
    
    var body: some View {
        NavigationStack {
            Form {
                Section {
                    HStack {
                        Text("Total number of bills")
                        Spacer()
                        Text("\(billHistoryItems.count)")
                    }
                    HStack {
                        Text("Total number of items sold")
                        Spacer()
                        let totalQuantity = billHistoryItems.reduce(0, { partialResult, item in
                            partialResult + item.items.reduce(0, { partialResult, menuitem in
                                partialResult + menuitem.quantity
                            })
                        })
                        Text("\(totalQuantity)")
                    }
                    HStack {
                        Text("Total sales")
                        Spacer()
                        let sales = billHistoryItems.reduce(0, { partialResult, item in
                            partialResult + item.items.reduce(0, { partialResult, menuitem in
                                partialResult + (menuitem.quantity * menuitem.price)
                            })
                        })
                        Text("\(sales.asCurrencyString() ?? "")")
                    }
                    HStack {
                        Text("Average Bill amount")
                        Spacer()
                        let average = billHistoryItems.reduce(0, { partialResult, item in
                            partialResult + item.items.reduce(0, { partialResult, menuitem in
                                partialResult + (menuitem.quantity * menuitem.price)
                            })
                        }) / billHistoryItems.count
                        Text("\(average.asCurrencyString() ?? "")")
                    }
                    let _ = getPopularItems()
                } header: {
                    Text("Overview")
                }
                
                Section{
                    let container = getPopularItems()
                    HStack {
                        Text("\(container.totalQuantities[container.sortedMenuItemsForQuantity.first ?? ""] ?? 0) \(container.sortedMenuItemsForQuantity.first ?? "") sold")
                    }
                    HStack {
                        Text("\((container.totalSalesAmounts[container.sortedMenuItemsForSale.first ?? ""] ?? 0).asCurrencyString() ?? "") of \(container.sortedMenuItemsForSale.first ?? "") sold")
                    }
                } header: {
                    Text("Popular")
                }
                
                Section{
                    let cashPayments = billHistoryItems.filter { billHistoryItem in
                        billHistoryItem.paymentStatus == .paidByCash
                    }
                    let cardPayments = billHistoryItems.filter { billHistoryItem in
                        billHistoryItem.paymentStatus == .paidByCard
                    }
                    let upiPayments = billHistoryItems.filter { billHistoryItem in
                        billHistoryItem.paymentStatus == .paidByUPI
                    }
                    
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Label("\(Int(Double(cashPayments.count)/Double(billHistoryItems.count)*100))% paid by cash", systemImage: "banknote")
                            Spacer()
                            Text("\(cashPayments.count)")
                        }
                        let salesInCash = cashPayments.reduce(0, { partialResult, item in
                            partialResult + item.items.reduce(0, { partialResult, menuitem in
                                partialResult + (menuitem.quantity * menuitem.price)
                            })
                        })
                        Text(salesInCash.asCurrencyString() ?? "")
                    }
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Label("\(Int(Double(cardPayments.count)/Double(billHistoryItems.count)*100))% paid by card", systemImage: "creditcard")
                            Spacer()
                            Text("\(cardPayments.count)")
                        }
                        let salesInCard = cardPayments.reduce(0, { partialResult, item in
                            partialResult + item.items.reduce(0, { partialResult, menuitem in
                                partialResult + (menuitem.quantity * menuitem.price)
                            })
                        })
                        Text(salesInCard.asCurrencyString() ?? "")
                    }
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Label("\(Int(Double(upiPayments.count)/Double(billHistoryItems.count)*100))% paid by UPI", systemImage: "indianrupeesign")
                            Spacer()
                            Text("\(upiPayments.count)")
                        }
                        let salesInupi = upiPayments.reduce(0, { partialResult, item in
                            partialResult + item.items.reduce(0, { partialResult, menuitem in
                                partialResult + (menuitem.quantity * menuitem.price)
                            })
                        })
                        Text(salesInupi.asCurrencyString() ?? "")
                    }
                    
                } header: {
                    Text("Payment Distribution")
                }
            }
            .navigationTitle("Stats")
        }
        .lockWithBiometric()
    }
}

#Preview {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: BillHistoryItem.self, configurations: config)
    
    PreviewData.billHistoryItems.forEach { billHistoryItem in
        container.mainContext.insert(billHistoryItem)
    }
    return Stats()
        .modelContainer(container)
}
