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
    var totalAmount: Int
    var id: Date {
        date
    }
}

extension StatsChart {
    struct PaymentDistribution: View {
        let billHistoryItems: [BillHistoryItem]
        @State private var type = 0
        var body: some View {
            let cashPayments = billHistoryItems.filter { billHistoryItem in
                billHistoryItem.paymentStatus == .paidByCash
            }
            let cardPayments = billHistoryItems.filter { billHistoryItem in
                billHistoryItem.paymentStatus == .paidByCard
            }
            let upiPayments = billHistoryItems.filter { billHistoryItem in
                billHistoryItem.paymentStatus == .paidByUPI
            }
            VStack {
                Picker("Select the payment distribution type", selection: $type) {
                    Text("Count").tag(0)
                    Text("Amount").tag(1)
                }
                .pickerStyle(SegmentedPickerStyle())
                let cashValue = type == 0 ? cashPayments.count : cashPayments.reduce(0, { partialResult, item in
                    partialResult + item.items.reduce(0, { partialResult, menuitem in
                        partialResult + (menuitem.quantity * menuitem.price)
                    })
                })
                let upiValue = type == 0 ? upiPayments.count : upiPayments.reduce(0, { partialResult, item in
                    partialResult + item.items.reduce(0, { partialResult, menuitem in
                        partialResult + (menuitem.quantity * menuitem.price)
                    })
                })
                let cardValue = type == 0 ? cardPayments.count : cardPayments.reduce(0, { partialResult, item in
                    partialResult + item.items.reduce(0, { partialResult, menuitem in
                        partialResult + (menuitem.quantity * menuitem.price)
                    })
                })
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
        
        func getFilteredResults() -> [String] {
            if searchQuery.isEmpty {
                return billHistoryItems.getStatsContainer().sortedMenuItemsForSale
            } else {
                return billHistoryItems.getStatsContainer().sortedMenuItemsForSale.filter { $0.lowercased().contains(searchQuery.lowercased()) }
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
                List(getFilteredResults(), id: \.self) { itemName in
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
            var totalsByDate = [Date: Int]()
            for bill in billHistoryItems {
                var total = 0
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
            var cumulativeSum = 0
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
    
    func getSortedTotalsByDate() -> [DateTotal] {
        var totalsByDate = [Date: Int]()

        var utcCalendar = Calendar(identifier: .gregorian)
        utcCalendar.timeZone = TimeZone(secondsFromGMT: 0)!

        for bill in billHistoryItems {
            let total = bill.totalAmount

            // Convert UTC date to local date
            let localDate = utcCalendar.date(byAdding: .second, value: TimeZone.current.secondsFromGMT(), to: bill.date)!
            
            print("localDate", localDate)

            // Get start of the day for local date
            let localStartOfDay = utcCalendar.startOfDay(for: localDate)

            if let currentTotal = totalsByDate[localStartOfDay] {
                totalsByDate[localStartOfDay] = currentTotal + total
            } else {
                totalsByDate[localStartOfDay] = total
            }
            print("Bill Date (UTC): \(bill.date), Local Start of Day: \(localStartOfDay)")
        }

        // Convert to array of DateTotal
        let dateTotals = totalsByDate.map { DateTotal(date: $0.key, totalAmount: $0.value) }
        
        // Sorting by date
        return dateTotals.sorted { $0.date < $1.date }
    }



    
    func getAggregatedTotalsByDate() -> [DateTotal] {
        var totalsByDate = [Date: Int]()
        for bill in billHistoryItems {
            let total = bill.totalAmount
//            let date = Calendar.current.startOfDay(for: bill.date) // Grouping by date

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
        var cumulativeSum = 0
        for i in 0..<dateTotals.count {
            cumulativeSum += dateTotals[i].totalAmount
            dateTotals[i].totalAmount = cumulativeSum
        }
        return dateTotals
    }
    
    
    
    var body: some View {
        Form {
            Section {
                Chart(getSortedTotalsByDate()) { dateTotal in
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
                Chart(getAggregatedTotalsByDate()) { dateTotal in
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
    }
}
#if DEBUG
#Preview {
    return StatsChart(billHistoryItems: PreviewData.billHistoryItems)

}
#endif

