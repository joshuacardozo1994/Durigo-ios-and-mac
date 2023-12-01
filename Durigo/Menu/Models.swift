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
    var prefix: String?
    var suffix: String?
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

enum ItemType: String, Decodable {
    case drinks
    case food
}

struct Category: Decodable, Identifiable {
    struct Item: Decodable, Identifiable {
        enum VisibilityScope: String, Codable {
            case menu
            case bill
            case both
        }
        
        let id: UUID
        let name: String
        let price: Int
        let prefix: String?
        let suffix: String?
        let visibilityScope: VisibilityScope
        let description: String?
    }
    
    let id: UUID
    
    let type: ItemType
    let name: String
    let items: [Item]
    
    static var placeholder: Category {
        let items = (1...7).map { _ in Category.Item(id: UUID(), name: "XXXXX", price: Int.random(in: 1...999), prefix: nil, suffix: nil, visibilityScope: .both, description: nil) }
        let category = Category(id: UUID(), type: .drinks, name: "XXXXXX", items: items)
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
