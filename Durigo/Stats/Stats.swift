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
    
    struct HeroMetric: View {
        let totalSales: Double
        
        var body: some View {
            VStack(spacing: 12) {
                Text("Total Sales")
                    .font(.subheadline)
                    .foregroundStyle(.white.opacity(0.8))
                    .textCase(.uppercase)
                Text(totalSales.asCurrencyString() ?? "₹0.00")
                    .font(.system(size: 48, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 40)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(
                        LinearGradient(
                            colors: [Color(red: 0.2, green: 0.6, blue: 1.0), Color(red: 0.1, green: 0.4, blue: 0.9)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .shadow(color: Color.blue.opacity(0.3), radius: 16, y: 8)
            )
            .padding(.horizontal)
        }
    }
    
    struct SecondaryMetrics: View {
        let totalBills: Int
        let totalQuantity: Double
        
        var body: some View {
            HStack(spacing: 16) {
                VStack(spacing: 8) {
                    Text("\(totalBills)")
                        .font(.system(.title, design: .rounded))
                        .fontWeight(.semibold)
                        .foregroundStyle(Color.purple)
                    Text("Bills")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .textCase(.uppercase)
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color.purple.opacity(0.1))
                )
                
                VStack(spacing: 8) {
                    Text("\(totalQuantity, specifier: "%.0f")")
                        .font(.system(.title, design: .rounded))
                        .fontWeight(.semibold)
                        .foregroundStyle(Color.orange)
                    Text("Items")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .textCase(.uppercase)
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color.orange.opacity(0.1))
                )
            }
            .padding(.horizontal)
        }
    }
    
    struct AverageBillCard: View {
        let averageBillAmount: Double
        
        var body: some View {
            VStack(spacing: 8) {
                Text(averageBillAmount.asCurrencyString() ?? "₹0.00")
                    .font(.system(.title2, design: .rounded))
                    .fontWeight(.semibold)
                Text("Average Bill")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .textCase(.uppercase)
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color(.secondarySystemGroupedBackground))
            )
            .padding(.horizontal)
        }
    }
    
    struct PaymentRow: View {
        let color: Color
        let title: String
        let percentage: Int
        let count: Int
        let amount: String
        
        var body: some View {
            HStack(alignment: .center, spacing: 12) {
                Circle()
                    .fill(color)
                    .frame(width: 8, height: 8)
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.body)
                    Text("\(percentage)% · \(count) bills")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Text(amount)
                    .font(.body)
                    .fontWeight(.semibold)
            }
            .padding()
        }
    }
}

struct Stats: View {
    @Environment(\.modelContext) private var modelContext
    @State private var isShowingStatsFilter = false
    @State private var startDate = Date()
    @State private var endDate = Date()
    @State private var isLoading = true
    @State private var statsData = StatsData()

    @ViewBuilder
    private func popularSection(container: Container) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Popular")
                .font(.headline)
                .textCase(.uppercase)
                .foregroundStyle(.secondary)
                .padding(.horizontal)
            
            VStack(spacing: 0) {
                NavigationLink {
                    StatsPopularQuantities(statsContainer: container)
                } label: {
                    HStack(alignment: .center, spacing: 12) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("\(container.totalQuantities[container.sortedMenuItemsForQuantity.first ?? ""] ?? 0, specifier: "%.0f") sold")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                            Text(container.sortedMenuItemsForQuantity.first ?? "")
                                .font(.body)
                                .foregroundStyle(.primary)
                        }
                        Spacer()
                        Image(systemName: "chevron.right")
                            .font(.caption)
                            .foregroundStyle(.tertiary)
                    }
                    .padding()
                }
                
                Divider()
                    .padding(.leading)
                
                NavigationLink {
                    StatsPopularSales(statsContainer: container)
                } label: {
                    HStack(alignment: .center, spacing: 12) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("\((container.totalSalesAmounts[container.sortedMenuItemsForSale.first ?? ""] ?? 0).asCurrencyString() ?? "") sold")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                            Text(container.sortedMenuItemsForSale.first ?? "")
                                .font(.body)
                                .foregroundStyle(.primary)
                        }
                        Spacer()
                        Image(systemName: "chevron.right")
                            .font(.caption)
                            .foregroundStyle(.tertiary)
                    }
                    .padding()
                }
            }
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color(.secondarySystemGroupedBackground))
            )
            .padding(.horizontal)
        }
    }
    
    @ViewBuilder
    private func paymentDistributionSection() -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Payment Distribution")
                .font(.headline)
                .textCase(.uppercase)
                .foregroundStyle(.secondary)
                .padding(.horizontal)
            
            VStack(spacing: 0) {
                PaymentRow(
                    color: Color(red: 0.3, green: 0.7, blue: 0.4),
                    title: "Cash",
                    percentage: Int(Double(statsData.cashPayments.count)/Double(max(statsData.totalBills, 1))*100),
                    count: statsData.cashPayments.count,
                    amount: statsData.salesInCash.asCurrencyString() ?? ""
                )
                
                Divider()
                    .padding(.leading)
                
                PaymentRow(
                    color: Color(red: 0.5, green: 0.4, blue: 0.9),
                    title: "Card",
                    percentage: Int(Double(statsData.cardPayments.count)/Double(max(statsData.totalBills, 1))*100),
                    count: statsData.cardPayments.count,
                    amount: statsData.salesInCard.asCurrencyString() ?? ""
                )
                
                Divider()
                    .padding(.leading)
                
                PaymentRow(
                    color: Color.orange,
                    title: "UPI",
                    percentage: Int(Double(statsData.upiPayments.count)/Double(max(statsData.totalBills, 1))*100),
                    count: statsData.upiPayments.count,
                    amount: statsData.salesInUPI.asCurrencyString() ?? ""
                )
            }
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color(.secondarySystemGroupedBackground))
            )
            .padding(.horizontal)
        }
    }
    
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
                    ScrollView {
                        VStack(spacing: 24) {
                            HeroMetric(totalSales: statsData.totalSales)
                            
                            SecondaryMetrics(totalBills: statsData.totalBills, totalQuantity: statsData.totalQuantity)
                            
                            AverageBillCard(averageBillAmount: statsData.averageBillAmount)
                            
                            if let container = statsData.container {
                                popularSection(container: container)
                            }
                            
                            paymentDistributionSection()
                        }
                        .padding(.vertical)
                    }
                    .background(Color(.systemGroupedBackground))
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
            .navigationBarTitleDisplayMode(.large)
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
