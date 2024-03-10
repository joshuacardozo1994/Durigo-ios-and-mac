//
//  Preview.swift
//  Durigo
//
//  Created by Joshua Cardozo on 23/11/23.
//

import Foundation


struct PreviewData {
   static let menuItems = [
    MenuItem(id: UUID(), name: "Soda", quantity: 1, price: 20, allowPartialOrder: false),
        MenuItem(id: UUID(), name: "Fresh Lemon Soda", quantity: 2, price: 90, allowPartialOrder: false),
        MenuItem(id: UUID(), name: "Virgin Mojito", quantity: 1, price: 220, allowPartialOrder: false),
        MenuItem(id: UUID(), name: "Chonok", quantity: 1, price: 500, allowPartialOrder: false),
        MenuItem(id: UUID(), name: "Chilli Chicken", quantity: 2, price: 250, allowPartialOrder: false),
        MenuItem(id: UUID(), name: "Chicken Pulao", quantity: 1, price: 200, allowPartialOrder: false),
        MenuItem(id: UUID(), name: "Beef Soup", quantity: 1, price: 160, allowPartialOrder: false),
        MenuItem(id: UUID(), name: "Mackerel", quantity: 2, price: 180, allowPartialOrder: false),
        MenuItem(id: UUID(), name: "Ice Cream", quantity: 1, price: 100, allowPartialOrder: false),
        MenuItem(id: UUID(), name: "Caramel Pudding", quantity: 1, price: 100, allowPartialOrder: false),
        MenuItem(id: UUID(), name: "Pankcakes", quantity: 2, price: 100, allowPartialOrder: false),
        MenuItem(id: UUID(), name: "Item 12", quantity: 1, price: 100, allowPartialOrder: false),
        MenuItem(id: UUID(), name: "Item 13", quantity: 1, price: 100, allowPartialOrder: false),
        MenuItem(id: UUID(), name: "Item 14", quantity: 1, price: 100, allowPartialOrder: false),
        MenuItem(id: UUID(), name: "Item 15", quantity: 1, price: 100, allowPartialOrder: false),
        MenuItem(id: UUID(), name: "Item 16", quantity: 1, price: 100, allowPartialOrder: false),
        MenuItem(id: UUID(), name: "Item 17", quantity: 1, price: 100, allowPartialOrder: false),
        MenuItem(id: UUID(), name: "Item 18", quantity: 1, price: 100, allowPartialOrder: false),
        MenuItem(id: UUID(), name: "Item 19", quantity: 1, price: 100, allowPartialOrder: false),
        MenuItem(id: UUID(), name: "Item 20", quantity: 1, price: 100, allowPartialOrder: false),
        MenuItem(id: UUID(), name: "Chocolate Brownie (With ice-cream)", quantity: 1, price: 100, allowPartialOrder: false)
    ]
    
    static var billHistoryItems: [BillHistoryItem] {
        guard let path = Bundle.main.path(forResource: "billItems", ofType: "json") else { return [BillHistoryItem]() }
        do {
            let data = try Data(contentsOf: URL(fileURLWithPath: path), options: .mappedIfSafe)
            let durigoBills = try JSONDecoder().decode(DurigoBills.self, from: data)
            return durigoBills.items.map { $0.convertToBillHistoryItem() }
        } catch {
            return [BillHistoryItem]()
        }
        
    }
}
