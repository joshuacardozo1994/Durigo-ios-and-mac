//
//  Models.swift
//  pdf test
//
//  Created by Joshua Cardozo on 14/10/23.
//

import Foundation
import SwiftData

struct MenuItem: Identifiable, Equatable, Hashable, Codable {
    var id: UUID
    var name: String
    var quantity: Int
    var price: Int
    
}

extension Array where Element == MenuItem {
    func getTotal() -> Int {
      
        self.reduce(0) { partialResult, item in
            return partialResult + (item.price*item.quantity)
        }
    }
}

enum FoodType: String, Decodable {
    case drinks
    case food
}

struct Category: Decodable, Identifiable {
    struct Menu: Decodable, Identifiable {
        let id: UUID
        let name: String
        let price: Int
        let subtext: String?
    }
    
    let id: UUID
    let type: FoodType
    let name: String
    let menus: [Menu]
    
    static var placeholder: Category {
        let menus = (1...7).map { _ in Category.Menu(id: UUID(), name: "XXXXX", price: Int.random(in: 1...999), subtext: nil) }
        let category = Category(id: UUID(), type: .drinks, name: "XXXXXX", menus: menus)
        return category
    }
}

@Model
class BillHistoryItem: Identifiable {
    let id: UUID
    var date: Date
    var tableNumber: Int?
    var items: [MenuItem]
    
    init(items: [MenuItem], tableNumber: Int) {
        self.id = UUID()
        self.date = Date()
        self.items = items
        self.tableNumber = tableNumber
    }
}
