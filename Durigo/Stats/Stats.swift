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
        let totalSalesAmounts: [String: Double]
        let totalQuantities: [String: Double]
        let sortedMenuItemsForSale: [String]
        let sortedMenuItemsForQuantity: [String]
    }

    struct StatsData {
        var totalBills: Int = 0
        var totalQuantity: Double = 0
        var totalSales: Double = 0
        var averageBillAmount: Double = 0
        var cashPayments: [BillHistoryItem] = []
        var cardPayments: [BillHistoryItem] = []
        var upiPayments: [BillHistoryItem] = []
        var salesInCash: Double = 0
        var salesInCard: Double = 0
        var salesInUPI: Double = 0
        var container: Container?
        var filteredItems: [BillHistoryItem] = []
    }
}

struct Stats: View {
    @Environment(\.modelContext) private var modelContext
    @State private var isShowingStatsFilter = false
    @State private var startDate = Date()
    @State private var endDate = Date()
    @State private var isLoading = true
    @State private var statsData = StatsData()

    private func loadStats() async {
        isLoading = true

        // Fetch data on background thread
        let descriptor = FetchDescriptor<BillHistoryItem>(
            sortBy: [SortDescriptor(\.date, order: .reverse)]
        )

        do {
            let items = try modelContext.fetch(descriptor)

            // Filter by date range
            let filteredItems: [BillHistoryItem]
            if startDate <= endDate {
                filteredItems = items.filter { (startDate...endDate).contains($0.date) }
            } else {
                filteredItems = items
            }

            // Calculate stats
            var data = StatsData()
            data.filteredItems = filteredItems
            data.totalBills = filteredItems.count

            data.totalQuantity = filteredItems.reduce(0.0) { partialResult, item in
                partialResult + item.items.reduce(0.0) { $0 + $1.quantity }
            }

            data.totalSales = filteredItems.reduce(0.0) { partialResult, item in
                partialResult + item.items.reduce(0.0) { $0 + ($1.quantity * $1.price) }
            }

            data.averageBillAmount = data.totalSales / max(Double(data.totalBills), 1.0)

            // Single pass to categorise by payment status
            for item in filteredItems {
                let itemTotal = item.items.reduce(0.0) { $0 + ($1.quantity * $1.price) }
                switch item.paymentStatus {
                case .paidByCash:
                    data.cashPayments.append(item)
                    data.salesInCash += itemTotal
                case .paidByCard:
                    data.cardPayments.append(item)
                    data.salesInCard += itemTotal
                case .paidByUPI:
                    data.upiPayments.append(item)
                    data.salesInUPI += itemTotal
                case .pending:
                    break
                }
            }

            data.container = filteredItems.getStatsContainer()

            // Set minimum start date
            if let minDate = items.map({ $0.date }).min() {
                await MainActor.run {
                    if startDate > minDate {
                        startDate = minDate
                    }
                }
            }

            await MainActor.run {
                statsData = data
                isLoading = false
            }
        } catch {
            await MainActor.run {
                isLoading = false
            }
        }
    }
    
    var body: some View {
        NavigationStack {
            Group {
                if isLoading {
                    VStack {
                        Spacer()
                        ProgressView("Loading stats...")
                        Spacer()
                    }
                } else {
                    Form {
                        Section {
                            HStack {
                                Text("Total number of bills")
                                Spacer()
                                Text("\(statsData.totalBills)")
                            }
                            HStack {
                                Text("Total number of items sold")
                                Spacer()
                                Text("\(statsData.totalQuantity, specifier: "%.1f")")
                            }
                            HStack {
                                Text("Total sales")
                                Spacer()
                                Text("\(statsData.totalSales.asCurrencyString() ?? "")")
                            }
                            HStack {
                                Text("Average Bill amount")
                                Spacer()
                                Text("\(statsData.averageBillAmount.asCurrencyString() ?? "")")
                            }
                        } header: {
                            Text("Overview")
                        }

                        if let container = statsData.container {
                            Section {
                                NavigationLink {
                                    StatsPopularQuantities(statsContainer: container)
                                } label: {
                                    HStack {
                                        Text("\(container.totalQuantities[container.sortedMenuItemsForQuantity.first ?? ""] ?? 0, specifier: "%.1f") \(container.sortedMenuItemsForQuantity.first ?? "") sold")
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
                        }

                        Section {
                            VStack(alignment: .leading, spacing: 8) {
                                HStack {
                                    Label("\(Int(Double(statsData.cashPayments.count)/Double(max(statsData.totalBills, 1))*100))% paid by cash", systemImage: "banknote")
                                    Spacer()
                                    Text("\(statsData.cashPayments.count)")
                                }
                                Text(statsData.salesInCash.asCurrencyString() ?? "")
                            }
                            VStack(alignment: .leading, spacing: 8) {
                                HStack {
                                    Label("\(Int(Double(statsData.cardPayments.count)/Double(max(statsData.totalBills, 1))*100))% paid by card", systemImage: "creditcard")
                                    Spacer()
                                    Text("\(statsData.cardPayments.count)")
                                }
                                Text(statsData.salesInCard.asCurrencyString() ?? "")
                            }
                            VStack(alignment: .leading, spacing: 8) {
                                HStack {
                                    Label("\(Int(Double(statsData.upiPayments.count)/Double(max(statsData.totalBills, 1))*100))% paid by UPI", systemImage: "indianrupeesign")
                                    Spacer()
                                    Text("\(statsData.upiPayments.count)")
                                }
                                Text(statsData.salesInUPI.asCurrencyString() ?? "")
                            }
                        } header: {
                            Text("Payment Distribution")
                        }
                    }
                }
            }
            .task {
                await loadStats()
            }
            .onChange(of: startDate) { _, _ in
                Task { await loadStats() }
            }
            .onChange(of: endDate) { _, _ in
                Task { await loadStats() }
            }
            .navigationTitle("Stats")
            .toolbar {
                Button(action: { isShowingStatsFilter.toggle() }) {
                    Image(systemName: "line.3.horizontal.decrease.circle")
                }
                NavigationLink {
                    StatsChart(billHistoryItems: statsData.filteredItems)
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
