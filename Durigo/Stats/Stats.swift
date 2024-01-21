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
    @State private var isShowingStatsFilter = false
    @State private var startDate = Date()
    @State private var endDate = Date()
    
    
    func getFilteredBillHistoryItems() -> [BillHistoryItem] {
        if startDate > endDate {
            return billHistoryItems
        }
        return billHistoryItems.filter { (startDate...endDate).contains($0.date) }
    }
    
    var body: some View {
        let billHistoryItems = getFilteredBillHistoryItems()
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
                        }) / max(billHistoryItems.count, 1)
                        Text("\(average.asCurrencyString() ?? "")")
                    }
                } header: {
                    Text("Overview")
                }
                
                Section{
                    let container = billHistoryItems.getStatsContainer()
                    NavigationLink {
                        StatsPopularQuantities(statsContainer: container)
                    } label: {
                        HStack {
                            Text("\(container.totalQuantities[container.sortedMenuItemsForQuantity.first ?? ""] ?? 0) \(container.sortedMenuItemsForQuantity.first ?? "") sold")
                        }
                    }
                    NavigationLink {
                        StatsPopularSales(statsContainer: container)
                    } label: {
                        HStack {
                            Text("\((container.totalSalesAmounts[container.sortedMenuItemsForSale.first ?? ""] ?? 0).asCurrencyString() ?? "") of \(container.sortedMenuItemsForSale.first ?? "") sold")
                        }
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
                            Label("\(Int(Double(cashPayments.count)/Double(max(billHistoryItems.count, 1))*100))% paid by cash", systemImage: "banknote")
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
                            Label("\(Int(Double(cardPayments.count)/Double(max(billHistoryItems.count, 1))*100))% paid by card", systemImage: "creditcard")
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
                            Label("\(Int(Double(upiPayments.count)/Double(max(billHistoryItems.count, 1))*100))% paid by UPI", systemImage: "indianrupeesign")
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
            .onAppear {
                startDate = billHistoryItems.map({ $0.date }).min() ?? Date()
            }
            .navigationTitle("Stats")
            .toolbar {
                Button(action: { isShowingStatsFilter.toggle() }) {
                    Image(systemName: "line.3.horizontal.decrease.circle")
                }
                NavigationLink {
                    StatsChart(billHistoryItems: billHistoryItems)
                } label: {
                    Image(systemName: "chart.xyaxis.line")
                }

            }
            .sheet(isPresented: $isShowingStatsFilter) {
                StatsFilter(startDate: $startDate, endDate: $endDate)
            }
        }
        .lockWithBiometric()
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
    return Stats()
#if DEBUG
        .modelContainer(container)
#endif
}
