//
//  Models.swift
//  pdf test
//
//  Created by Joshua Cardozo on 14/10/23.
//

import Foundation
import UniformTypeIdentifiers
import CoreTransferable

extension Array where Element == MenuItem {
    func getTotal() -> Int {
        self.reduce(0) { partialResult, item in
            return partialResult + Int(item.price*item.quantity)
        }
    }
}

enum ItemType: String, Codable {
    case drinks
    case food
}

struct Category: Codable, Identifiable {
    struct Item: Codable, Identifiable {
        enum VisibilityScope: String, Codable {
            case menu
            case bill
            case both
        }
        
        struct ServingSize: Codable, Identifiable, Equatable, Hashable {
            let id: UUID
            let name: String
            let expression: String
            let description: String
            let shouldDisplay: Bool
            var isSelected = false
            
            
            enum CodingKeys: String, CodingKey {
                case id, name, expression, description, shouldDisplay
            }
        }
        
        let id: UUID
        let name: String
        let price: Double
        let prefix: String?
        let suffix: String?
        let visibilityScope: VisibilityScope
        let description: String?
        let servingSizes: [ServingSize]?
    }
    
    let id: UUID
    
    let type: ItemType
    let name: String
    let items: [Item]
    
    static var placeholder: Category {
        let items = (1...7).map { _ in Category.Item(id: UUID(), name: "XXXXX", price: Double.random(in: 1...999), prefix: nil, suffix: nil, visibilityScope: .both, description: nil, servingSizes: nil) }
        let category = Category(id: UUID(), type: .drinks, name: "XXXXXX", items: items)
        return category
    }
}

extension UTType {
    static var durigobills: UTType = UTType(exportedAs: "com.durigo.bills")
}

struct BillHistoryItemCopy: Identifiable, Codable {
    
    enum Status: String, Codable, Equatable {
        case paidByCash
        case paidByUPI
        case paidByCard
        case pending
    }
    
    let id: UUID
    var date: Date
    var tableNumber: Int
    var items: [MenuItem]
    var paymentStatus: Status
    var waiter: String
    
    init(id: UUID, date: Date = Date(), items: [MenuItem], tableNumber: Int, paymentStatus: Status = .pending,  waiter: String) {
        self.id = id
        self.date = date
        self.items = items
        self.tableNumber = tableNumber
        self.paymentStatus = paymentStatus
        self.waiter = waiter
    }
    
    init(billHistoryItem: BillHistoryItem) {
        self.id = billHistoryItem.id
        self.date = billHistoryItem.date
        self.items = billHistoryItem.items
        self.tableNumber = billHistoryItem.tableNumber
        self.paymentStatus = Status(rawValue: billHistoryItem.paymentStatus.rawValue) ?? .pending
        self.waiter = billHistoryItem.waiter
    }
    
    func convertToBillHistoryItem() -> BillHistoryItem {
        BillHistoryItem(id: self.id, date: self.date, items: self.items, tableNumber: self.tableNumber, paymentStatus: BillHistoryItemStatus(rawValue: self.paymentStatus.rawValue) ?? .pending, waiter: self.waiter)
    }
}

struct DurigoBills: Codable, Transferable {
    
    static var transferRepresentation: some TransferRepresentation {
        CodableRepresentation(contentType: .durigobills)
    }
    let items: [BillHistoryItemCopy]
}


