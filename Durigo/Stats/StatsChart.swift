//
//  StatsChart.swift
//  Durigo
//
//  Created by Joshua Cardozo on 21/01/24.
//

import SwiftUI
import Charts

struct DateTotal: Identifiable {
    var date: Date
    var totalAmount: Double
    var id: Date {
        date
    }
}

extension StatsChart {
    struct PaymentDistribution: View {
        let billHistoryItems: [BillHistoryItem]
        @State private var type = 0

        // Precomputed once from billHistoryItems
        private var cashCount: Int { billHistoryItems.filter { $0.paymentStatus == .paidByCash }.count }
        private var cardCount: Int { billHistoryItems.filter { $0.paymentStatus == .paidByCard }.count }
        private var upiCount: Int { billHistoryItems.filter { $0.paymentStatus == .paidByUPI }.count }
        private var cashAmount: Double {
            billHistoryItems.filter { $0.paymentStatus == .paidByCash }
                .reduce(0.0) { $0 + $1.items.reduce(0.0) { $0 + $1.quantity * $1.price } }
        }
        private var cardAmount: Double {
            billHistoryItems.filter { $0.paymentStatus == .paidByCard }
                .reduce(0.0) { $0 + $1.items.reduce(0.0) { $0 + $1.quantity * $1.price } }
        }
        private var upiAmount: Double {
            billHistoryItems.filter { $0.paymentStatus == .paidByUPI }
                .reduce(0.0) { $0 + $1.items.reduce(0.0) { $0 + $1.quantity * $1.price } }
        }

        var body: some View {
            VStack {
                Picker("Select the payment distribution type", selection: $type) {
                    Text("Count").tag(0)
                    Text("Amount").tag(1)
                }
                .pickerStyle(SegmentedPickerStyle())
                let cashValue = type == 0 ? Double(cashCount) : cashAmount
                let upiValue = type == 0 ? Double(upiCount) : upiAmount
                let cardValue = type == 0 ? Double(cardCount) : cardAmount
                Chart {
                    SectorMark(angle: .value("Cash", cashValue))
                        .foregroundStyle(by: .value("Type", "Cash"))
                        .annotation(position: .overlay) {
                            Text("\(cashValue)")
                        }
                    SectorMark(angle: .value("UPI", upiValue))
                        .foregroundStyle(by: .value("Type", "UPI"))
                        .annotation(position: .overlay) {
                            Text("\(upiValue)")
                        }
                    SectorMark(angle: .value("Card", cardValue))
                        .foregroundStyle(by: .value("Type", "Card"))
                        .annotation(position: .overlay) {
                            Text("\(cardValue)")
                        }
                }
                .frame(height: 250)
                .animation(.linear, value: type)
            }
        }
    }
    
    struct ItemSalesComparisonList: View {
        let billHistoryItems: [BillHistoryItem]
        @State private var searchQuery = ""
        @Binding var itemNames: [String]

        // Computed once; does not re-run on searchQuery changes
        private var allSortedItems: [String] {
            billHistoryItems.getStatsContainer().sortedMenuItemsForSale
        }

        private var filteredResults: [String] {
            if searchQuery.isEmpty {
                return allSortedItems
            } else {
                let query = searchQuery.lowercased()
                return allSortedItems.filter { $0.lowercased().contains(query) }
            }
        }

        var body: some View {
            VStack {
                HStack {
                    TextField("Search", text: $searchQuery)
                        .autocorrectionDisabled()
                        .padding()
                    Button(action: {
                        searchQuery = ""
                    }) {
                        Image(systemName: "x.circle")
                            .padding()
                    }
                    .accessibilityIdentifier("clearSearchField")
                }
                .overlay(RoundedRectangle(cornerRadius: 6).stroke(lineWidth: 1))
                .padding()
                List(filteredResults, id: \.self) { itemName in
                    HStack {
                        Image(systemName: itemNames.contains(itemName) ? "checkmark.circle.fill" : "circle")
                        Text(itemName)
                    }
                    .onTapGesture {
                        if itemNames.contains(itemName) {
                            itemNames = itemNames.filter({ $0 != itemName })
                        } else {
                            itemNames.append(itemName)
                        }
                    }
                }
            }
        }
    }
    
    struct ItemSalesComparison: View {
        let billHistoryItems: [BillHistoryItem]
        @State private var isShowingItemsList = false
        @State private var itemNames: [String] = ["Bombill (Bombay Duck)", "Sorpotel"]
        
        
        func getAggregatedTotalsOfItemByDate(item: String) -> [DateTotal] {
            var totalsByDate = [Date: Double]()
            for bill in billHistoryItems {
                var total: Double = 0
                bill.items.forEach { billItem in
                    if billItem.name == item {
                        total += (billItem.price * billItem.quantity)
                    }
                }
//                let date = Calendar.current.startOfDay(for: bill.date) // Grouping by date

                if let currentTotal = totalsByDate[bill.date] {
                    totalsByDate[bill.date] = currentTotal + total
                } else {
                    totalsByDate[bill.date] = total
                }
            }

            // Convert to array of DateTotal and sort by date
            var dateTotals = totalsByDate.map { DateTotal(date: $0.key, totalAmount: $0.value) }
            dateTotals.sort { $0.date < $1.date }

            // Calculate cumulative sum
            var cumulativeSum: Double = 0
            for i in 0..<dateTotals.count {
                cumulativeSum += dateTotals[i].totalAmount
                dateTotals[i].totalAmount = cumulativeSum
            }
            return dateTotals
        }
        var body: some View {
            VStack {
                HStack {
                    Spacer()
                    Button(action: { isShowingItemsList.toggle() }) {
                        Text("Select Items")
                            .padding()
                    }
                }
                Chart {
                    ForEach(itemNames, id: \.self) { itemName in
                        ForEach(getAggregatedTotalsOfItemByDate(item: itemName)) { dateTotal in
                            LineMark(
                                x: .value("Date", dateTotal.date),
                                y: .value("Sales", dateTotal.totalAmount),
                                series: .value("", itemName)
                            )
                            .foregroundStyle(by: .value("type", itemName))
                        }
                    }
                }
                .chartScrollableAxes(.horizontal)
                .frame(height: 300)
            }
            .sheet(isPresented: $isShowingItemsList) {
                ItemSalesComparisonList(billHistoryItems: billHistoryItems, itemNames: $itemNames)
            }
        }
    }
}

struct StatsChart: View {
    let billHistoryItems: [BillHistoryItem]

    @State private var sortedTotalsByDate: [DateTotal] = []
    @State private var aggregatedTotalsByDate: [DateTotal] = []

    private func computeSortedTotalsByDate() -> [DateTotal] {
        var totalsByDate = [Date: Double]()
        var utcCalendar = Calendar(identifier: .gregorian)
        utcCalendar.timeZone = TimeZone(secondsFromGMT: 0)!
        for bill in billHistoryItems {
            let total = bill.totalAmount
            let localDate = utcCalendar.date(byAdding: .second, value: TimeZone.current.secondsFromGMT(), to: bill.date)!
            let localStartOfDay = utcCalendar.startOfDay(for: localDate)
            totalsByDate[localStartOfDay, default: 0] += total
        }
        return totalsByDate.map { DateTotal(date: $0.key, totalAmount: $0.value) }
            .sorted { $0.date < $1.date }
    }

    private func computeAggregatedTotalsByDate() -> [DateTotal] {
        var totalsByDate = [Date: Double]()
        for bill in billHistoryItems {
            totalsByDate[bill.date, default: 0] += bill.totalAmount
        }
        var dateTotals = totalsByDate.map { DateTotal(date: $0.key, totalAmount: $0.value) }
            .sorted { $0.date < $1.date }
        var cumulativeSum: Double = 0
        for i in 0..<dateTotals.count {
            cumulativeSum += dateTotals[i].totalAmount
            dateTotals[i].totalAmount = cumulativeSum
        }
        return dateTotals
    }

    var body: some View {
        Form {
            Section {
                Chart(sortedTotalsByDate) { dateTotal in
                    BarMark(
                        x: .value("Date", dateTotal.date),
                        y: .value("Sales", dateTotal.totalAmount)
                    )
                }
                .chartScrollableAxes(.horizontal)
                .frame(height: 300)
            } header: {
                Text("Sales")
            }
            Section {
                Chart(aggregatedTotalsByDate) { dateTotal in
                    LineMark(
                        x: .value("Date", dateTotal.date),
                        y: .value("Sales", dateTotal.totalAmount)
                    )
                }
                .chartScrollableAxes(.horizontal)
                .frame(height: 300)
            } header: {
                Text("Cumulative Sales")
            }

            Section {
                PaymentDistribution(billHistoryItems: billHistoryItems)
            } header: {
                Text("Payment Distribution")
            }

            Section {
                ItemSalesComparison(billHistoryItems: billHistoryItems)
            } header: {
                Text("Item Sales Comparison")
            }
        }
        .navigationTitle("Charts")
        .task(id: billHistoryItems.count) {
            sortedTotalsByDate = computeSortedTotalsByDate()
            aggregatedTotalsByDate = computeAggregatedTotalsByDate()
        }
    }
}
#if DEBUG
#Preview {
    return StatsChart(billHistoryItems: PreviewData.billHistoryItems)

}
#endif

