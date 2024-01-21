//
//  StatsPopularSales.swift
//  Durigo
//
//  Created by Joshua Cardozo on 21/01/24.
//

import SwiftUI

struct StatsPopularSales: View {
    let statsContainer: Stats.Container
    @State private var searchQuery = ""
    
    func getFilteredResults() -> [String] {
        if searchQuery.isEmpty {
            return statsContainer.sortedMenuItemsForSale
        } else {
            return statsContainer.sortedMenuItemsForSale.filter { $0.lowercased().contains(searchQuery.lowercased()) }
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
            List(getFilteredResults(), id: \.self) { item in
                Text("\(statsContainer.totalSalesAmounts[item]?.asCurrencyString() ?? "0") ") +
                Text(item).bold() +
                Text(" sold")
            }
            .navigationTitle("Popular Quantities")
        }
    }
}

#Preview {
    #if DEBUG
    return StatsPopularSales(statsContainer: PreviewData.billHistoryItems.getStatsContainer())
    #endif
}
