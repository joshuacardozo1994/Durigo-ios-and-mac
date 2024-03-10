//
//  Array+Extensions.swift
//  Durigo
//
//  Created by Joshua Cardozo on 21/01/24.
//

import Foundation


extension Array where Element == BillHistoryItem {
    func getStatsContainer() -> Stats.Container {
        // Define dictionaries to store the total sales amount and total quantity for each MenuItem
        var totalSalesAmounts: [String: Double] = [:]
        var totalQuantities: [String: Double] = [:]

        // Calculate the total sales amount and total quantity for each MenuItem
        for billHistoryItem in self {
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
        let uniqueMenuItemNames = Set(self.flatMap { $0.items.map { $0.name } })

        // Create an array of MenuItems sorted in descending order by total sales amount
        let sortedMenuItemsForSale = uniqueMenuItemNames.sorted {
            totalSalesAmounts[$0]! > totalSalesAmounts[$1]!
        }
        
        let sortedMenuItemsForQuantity = uniqueMenuItemNames.sorted {
            totalQuantities[$0]! > totalQuantities[$1]!
        }
        return Stats.Container(totalSalesAmounts: totalSalesAmounts, totalQuantities: totalQuantities, sortedMenuItemsForSale: sortedMenuItemsForSale, sortedMenuItemsForQuantity: sortedMenuItemsForQuantity)
    }
}
