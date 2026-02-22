//
//  Reports.swift
//  Durigo
//
//  Created by Claude Code on 22/02/26.
//

import SwiftUI
import SwiftData

struct Reports: View {
    @Query private var billHistoryItems: [BillHistoryItem]
    @EnvironmentObject private var menuLoader: MenuLoader
    
    @State private var selectedMonth = Calendar.current.component(.month, from: Date())
    @State private var selectedYear = Calendar.current.component(.year, from: Date())
    @State private var showCopiedMessage = false
    
    private let months = [
        1: "January", 2: "February", 3: "March", 4: "April",
        5: "May", 6: "June", 7: "July", 8: "August",
        9: "September", 10: "October", 11: "November", 12: "December"
    ]
    
    private var years: [Int] {
        let currentYear = Calendar.current.component(.year, from: Date())
        return Array((currentYear - 5)...currentYear)
    }
    
    private var filteredBills: [BillHistoryItem] {
        billHistoryItems.filter { item in
            let components = Calendar.current.dateComponents([.month, .year], from: item.date)
            return components.month == selectedMonth && components.year == selectedYear
        }
    }
    
    /// Build a lookup dictionary from menu item names to their tags
    private var menuItemTagsLookup: [String: [String]] {
        guard let categories = menuLoader.menu else { return [:] }
        var lookup: [String: [String]] = [:]
        for category in categories {
            for item in category.items {
                if let tags = item.tags {
                    // Store by item name (lowercased for matching)
                    lookup[item.name.lowercased()] = tags
                    // Also store with suffix if available
                    if let suffix = item.suffix {
                        lookup["\(item.name) (\(suffix))".lowercased()] = tags
                    }
                }
            }
        }
        return lookup
    }
    
    private var reportData: (cashTotal: Double, cardTotal: Double, upiTotal: Double, pendingTotal: Double, grandTotal: Double, billCount: Int, paidBillCount: Int, pendingBillCount: Int, totalItemsSold: Int, foodSales: Double, beverageSales: Double, alcoholSales: Double) {
        let bills = filteredBills
        var cashTotal: Double = 0
        var cardTotal: Double = 0
        var upiTotal: Double = 0
        var pendingTotal: Double = 0
        var totalItemsSold: Int = 0
        var foodSales: Double = 0
        var beverageSales: Double = 0
        var alcoholSales: Double = 0
        var paidBillCount: Int = 0
        var pendingBillCount: Int = 0
        
        for bill in bills {
            // Count total items
            totalItemsSold += bill.items.reduce(0) { $0 + Int($1.quantity) }
            
            // Calculate bill total by payment method
            let billTotal = bill.items.reduce(0.0) { $0 + ($1.quantity * $1.price) }
            switch bill.paymentStatus {
            case .paidByCash:
                cashTotal += billTotal
                paidBillCount += 1
            case .paidByCard:
                cardTotal += billTotal
                paidBillCount += 1
            case .paidByUPI:
                upiTotal += billTotal
                paidBillCount += 1
            case .pending:
                pendingTotal += billTotal
                pendingBillCount += 1
            }
            
            // Categorize sales by item type (for ALL bills including pending)
            for item in bill.items {
                let itemTotal = item.quantity * item.price
                
                // First try to use tags if available
                if let tags = item.tags, !tags.isEmpty {
                    if tags.contains("alcohol") {
                        alcoholSales += itemTotal
                    } else if tags.contains("beverage") {
                        beverageSales += itemTotal
                    } else if tags.contains("food") {
                        foodSales += itemTotal
                    } else {
                        // Default to food if tag is unrecognized
                        foodSales += itemTotal
                    }
                } else {
                    // Fallback: lookup item in current menu to find its tags
                    let itemName = item.name.lowercased()
                    let lookup = menuItemTagsLookup
                    
                    // Try exact match first, then try without suffix
                    let tags = lookup[itemName] ?? {
                        // Try to match without the suffix part (e.g., "Chicken Fried Rice" from "Chicken Fried Rice (Half)")
                        if let parenIndex = itemName.firstIndex(of: "(") {
                            let baseName = String(itemName[..<parenIndex]).trimmingCharacters(in: .whitespaces)
                            return lookup[baseName]
                        }
                        return nil
                    }()
                    
                    if let tags = tags, !tags.isEmpty {
                        if tags.contains("alcohol") {
                            alcoholSales += itemTotal
                        } else if tags.contains("beverage") {
                            beverageSales += itemTotal
                        } else if tags.contains("food") {
                            foodSales += itemTotal
                        } else {
                            foodSales += itemTotal
                        }
                    } else {
                        // Default to food if item not found in menu
                        foodSales += itemTotal
                    }
                }
            }
        }
        
        let grandTotal = cashTotal + cardTotal + upiTotal + pendingTotal
        return (cashTotal, cardTotal, upiTotal, pendingTotal, grandTotal, bills.count, paidBillCount, pendingBillCount, totalItemsSold, foodSales, beverageSales, alcoholSales)
    }
    
    private func generateReportText() -> String {
        let data = reportData
        
        guard data.billCount > 0 else {
            return "No data available for \(months[selectedMonth] ?? "") \(selectedYear)"
        }
        
        let foodPercentage = data.grandTotal > 0 ? (data.foodSales / data.grandTotal * 100) : 0
        let beveragePercentage = data.grandTotal > 0 ? (data.beverageSales / data.grandTotal * 100) : 0
        let alcoholPercentage = data.grandTotal > 0 ? (data.alcoholSales / data.grandTotal * 100) : 0
        
        return """
        Total Sales: \(data.grandTotal.asCurrencyString() ?? "₹0.00")
        Total Items Sold: \(data.totalItemsSold)
        Total Bills: \(data.billCount) (\(data.paidBillCount) paid, \(data.pendingBillCount) pending)
        
        Category Breakdown:
        Food Sales: \(data.foodSales.asCurrencyString() ?? "₹0.00") (\(String(format: "%.1f", foodPercentage))%)
        Beverage Sales: \(data.beverageSales.asCurrencyString() ?? "₹0.00") (\(String(format: "%.1f", beveragePercentage))%)
        Alcohol Sales: \(data.alcoholSales.asCurrencyString() ?? "₹0.00") (\(String(format: "%.1f", alcoholPercentage))%)
        
        Payment Breakdown:
        Cash: \(data.cashTotal.asCurrencyString() ?? "₹0.00")
        Card: \(data.cardTotal.asCurrencyString() ?? "₹0.00")
        UPI: \(data.upiTotal.asCurrencyString() ?? "₹0.00")
        Pending: \(data.pendingTotal.asCurrencyString() ?? "₹0.00")
        """
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // Period Selector Card
                    VStack(spacing: 0) {
                        HStack(spacing: 12) {
                            // Month Picker
                            Menu {
                                Picker("Month", selection: $selectedMonth) {
                                    ForEach(Array(months.keys.sorted()), id: \.self) { key in
                                        Text(months[key] ?? "").tag(key)
                                    }
                                }
                            } label: {
                                HStack {
                                    VStack(alignment: .leading, spacing: 6) {
                                        Text("MONTH")
                                            .font(.caption2)
                                            .fontWeight(.semibold)
                                            .foregroundStyle(.secondary)
                                            .tracking(0.5)
                                        Text(months[selectedMonth] ?? "")
                                            .font(.system(.body, design: .rounded))
                                            .fontWeight(.semibold)
                                    }
                                    Spacer()
                                    Image(systemName: "chevron.up.chevron.down")
                                        .font(.caption)
                                        .foregroundStyle(.tertiary)
                                }
                                .padding(16)
                                .background(Color(.systemBackground))
                                .cornerRadius(14)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 14)
                                        .stroke(Color(.systemGray5), lineWidth: 1)
                                )
                            }
                            
                            // Year Picker
                            Menu {
                                Picker("Year", selection: $selectedYear) {
                                    ForEach(years.reversed(), id: \.self) { year in
                                        Text(String(year)).tag(year)
                                    }
                                }
                            } label: {
                                HStack {
                                    VStack(alignment: .leading, spacing: 6) {
                                        Text("YEAR")
                                            .font(.caption2)
                                            .fontWeight(.semibold)
                                            .foregroundStyle(.secondary)
                                            .tracking(0.5)
                                        Text(String(selectedYear))
                                            .font(.system(.body, design: .rounded))
                                            .fontWeight(.semibold)
                                    }
                                    Spacer()
                                    Image(systemName: "chevron.up.chevron.down")
                                        .font(.caption)
                                        .foregroundStyle(.tertiary)
                                }
                                .padding(16)
                                .background(Color(.systemBackground))
                                .cornerRadius(14)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 14)
                                        .stroke(Color(.systemGray5), lineWidth: 1)
                                )
                            }
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 4)
                    
                    if reportData.billCount > 0 {
                        // Summary Cards
                        VStack(spacing: 20) {
                            // Key Metrics
                            VStack(spacing: 12) {
                                // Total Sales - Hero metric
                                VStack(spacing: 8) {
                                    Text("Total Sales")
                                        .font(.subheadline)
                                        .foregroundStyle(.white.opacity(0.8))
                                    Text(reportData.grandTotal.asCurrencyString() ?? "₹0.00")
                                        .font(.system(size: 48, weight: .bold, design: .rounded))
                                        .foregroundStyle(.white)
                                        .minimumScaleFactor(0.7)
                                }
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 32)
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
                                
                                // Secondary metrics
                                HStack(spacing: 12) {
                                    VStack(spacing: 8) {
                                        Text("\(reportData.totalItemsSold)")
                                            .font(.system(.title, design: .rounded))
                                            .fontWeight(.semibold)
                                            .foregroundStyle(Color.orange)
                                        Text("Items")
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                    }
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 20)
                                    .background(
                                        RoundedRectangle(cornerRadius: 16)
                                            .fill(Color.orange.opacity(0.1))
                                    )
                                    
                                    VStack(spacing: 8) {
                                        Text("\(reportData.paidBillCount)")
                                            .font(.system(.title, design: .rounded))
                                            .fontWeight(.semibold)
                                            .foregroundStyle(Color.purple)
                                        Text("Paid Bills")
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                    }
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 20)
                                    .background(
                                        RoundedRectangle(cornerRadius: 16)
                                            .fill(Color.purple.opacity(0.1))
                                    )
                                    
                                    VStack(spacing: 8) {
                                        Text("\(reportData.pendingBillCount)")
                                            .font(.system(.title, design: .rounded))
                                            .fontWeight(.semibold)
                                            .foregroundStyle(Color.red)
                                        Text("Pending")
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                    }
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 20)
                                    .background(
                                        RoundedRectangle(cornerRadius: 16)
                                            .fill(Color.red.opacity(0.1))
                                    )
                                }
                            }
                            
                            // Category Breakdown
                            VStack(alignment: .leading, spacing: 16) {
                                Text("Categories")
                                    .font(.headline)
                                    .padding(.horizontal, 4)
                                
                                VStack(spacing: 0) {
                                    CategoryRow(
                                        category: "Food",
                                        amount: reportData.foodSales,
                                        percentage: reportData.grandTotal > 0 ? (reportData.foodSales / reportData.grandTotal * 100) : 0
                                    )
                                    
                                    Divider()
                                        .padding(.leading, 20)
                                    
                                    CategoryRow(
                                        category: "Beverages",
                                        amount: reportData.beverageSales,
                                        percentage: reportData.grandTotal > 0 ? (reportData.beverageSales / reportData.grandTotal * 100) : 0
                                    )
                                    
                                    Divider()
                                        .padding(.leading, 20)
                                    
                                    CategoryRow(
                                        category: "Alcohol",
                                        amount: reportData.alcoholSales,
                                        percentage: reportData.grandTotal > 0 ? (reportData.alcoholSales / reportData.grandTotal * 100) : 0
                                    )
                                }
                                .background(
                                    RoundedRectangle(cornerRadius: 16)
                                        .fill(Color(.systemBackground))
                                        .shadow(color: Color.black.opacity(0.05), radius: 8, y: 2)
                                )
                            }
                            
                            // Payment Breakdown
                            VStack(alignment: .leading, spacing: 16) {
                                Text("Payment Methods")
                                    .font(.headline)
                                    .padding(.horizontal, 4)
                                
                                VStack(spacing: 0) {
                                    PaymentMethodRow(
                                        method: "Cash",
                                        amount: reportData.cashTotal
                                    )
                                    
                                    Divider()
                                        .padding(.leading, 20)
                                    
                                    PaymentMethodRow(
                                        method: "Card",
                                        amount: reportData.cardTotal
                                    )
                                    
                                    Divider()
                                        .padding(.leading, 20)
                                    
                                    PaymentMethodRow(
                                        method: "UPI",
                                        amount: reportData.upiTotal
                                    )
                                    
                                    Divider()
                                        .padding(.leading, 20)
                                    
                                    PaymentMethodRow(
                                        method: "Pending",
                                        amount: reportData.pendingTotal
                                    )
                                }
                                .background(
                                    RoundedRectangle(cornerRadius: 16)
                                        .fill(Color(.systemBackground))
                                        .shadow(color: Color.black.opacity(0.05), radius: 8, y: 2)
                                )
                            }
                        }
                        .padding(.horizontal, 20)
                        
                        // Copy Button
                        Button(action: {
                            UIPasteboard.general.string = generateReportText()
                            showCopiedMessage = true
                            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                                showCopiedMessage = false
                            }
                        }) {
                            HStack(spacing: 8) {
                                if showCopiedMessage {
                                    Image(systemName: "checkmark")
                                        .font(.body.weight(.semibold))
                                    Text("Copied")
                                        .font(.body)
                                        .fontWeight(.semibold)
                                } else {
                                    Image(systemName: "square.and.arrow.up")
                                        .font(.body.weight(.semibold))
                                    Text("Share Report")
                                        .font(.body)
                                        .fontWeight(.semibold)
                                }
                            }
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(
                                RoundedRectangle(cornerRadius: 14)
                                    .fill(showCopiedMessage ? Color.green : Color.accentColor)
                            )
                        }
                        .buttonStyle(.plain)
                        .padding(.horizontal, 20)
                        .padding(.top, 8)
                        
                    } else {
                        // Empty State
                        VStack(spacing: 20) {
                            Image(systemName: "chart.bar.doc.horizontal")
                                .font(.system(size: 64))
                                .foregroundStyle(.tertiary)
                            
                            VStack(spacing: 8) {
                                Text("No Data Available")
                                    .font(.system(.title2, design: .rounded))
                                    .fontWeight(.bold)
                                
                                Text("No bills found for \(months[selectedMonth] ?? "") \(selectedYear)")
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                                    .multilineTextAlignment(.center)
                                    .padding(.horizontal, 32)
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 80)
                    }
                }
                .padding(.bottom, 24)
            }
            .navigationTitle("Reports")
            .navigationBarTitleDisplayMode(.large)
            .background(Color(.systemGroupedBackground))
            .task {
                await menuLoader.loadMenu()
            }
        }
    }
}

struct PaymentMethodRow: View {
    let method: String
    let amount: Double
    
    private var methodColor: Color {
        switch method {
        case "Cash": return Color(red: 0.2, green: 0.7, blue: 0.3)
        case "Card": return Color(red: 0.5, green: 0.4, blue: 0.9)
        case "UPI": return Color(red: 1.0, green: 0.6, blue: 0.2)
        case "Pending": return Color.red
        default: return .gray
        }
    }
    
    var body: some View {
        HStack(spacing: 12) {
            Circle()
                .fill(methodColor)
                .frame(width: 8, height: 8)
            
            Text(method)
                .font(.body)
            
            Spacer()
            
            Text(amount.asCurrencyString() ?? "₹0.00")
                .font(.system(.body, design: .rounded))
                .fontWeight(.medium)
                .foregroundStyle(.secondary)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
        .contentShape(Rectangle())
    }
}

struct CategoryRow: View {
    let category: String
    let amount: Double
    let percentage: Double
    
    private var categoryColor: Color {
        switch category {
        case "Food": return Color(red: 0.3, green: 0.7, blue: 0.4)
        case "Beverages": return Color(red: 0.2, green: 0.6, blue: 1.0)
        case "Alcohol": return Color(red: 0.7, green: 0.3, blue: 0.7)
        default: return .gray
        }
    }
    
    var body: some View {
        HStack(alignment: .center, spacing: 12) {
            Circle()
                .fill(categoryColor)
                .frame(width: 8, height: 8)
            
            Text(category)
                .font(.body)
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 2) {
                Text(amount.asCurrencyString() ?? "₹0.00")
                    .font(.system(.body, design: .rounded))
                    .fontWeight(.medium)
                Text("\(String(format: "%.0f", percentage))%")
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
        .contentShape(Rectangle())
    }
}

#if DEBUG
#Preview {
    @Previewable @State var container: ModelContainer = {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try! ModelContainer(for: BillHistoryItem.self, configurations: config)
        
        // Insert sample bills with recent dates
        let calendar = Calendar.current
        let now = Date()
        
        // Create bills for current month
        for i in 0..<5 {
            let billDate = calendar.date(byAdding: .day, value: -i, to: now) ?? now
            let items = [
                MenuItem(id: UUID(), name: "Sprite", quantity: 2, price: 30, tags: ["beverage"]),
                MenuItem(id: UUID(), name: "Chicken Fried Rice", quantity: 1, price: 200, tags: ["food"]),
                MenuItem(id: UUID(), name: "Old Monk", quantity: 1, price: 290, tags: ["alcohol"])
            ]
            let paymentStatus: BillHistoryItemStatus = i % 4 == 0 ? .paidByCash : (i % 4 == 1 ? .paidByCard : (i % 4 == 2 ? .paidByUPI : .pending))
            let bill = BillHistoryItem(id: UUID(), date: billDate, items: items, tableNumber: i + 1, paymentStatus: paymentStatus, waiter: "John")
            container.mainContext.insert(bill)
        }
        
        return container
    }()
    
    Reports()
        .modelContainer(container)
        .environmentObject(MenuLoader())
}
#endif
