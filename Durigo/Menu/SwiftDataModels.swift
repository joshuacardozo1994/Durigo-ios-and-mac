//
//  SwiftDataModels.swift
//  Durigo
//
//  Created by Joshua Cardozo on 20/12/23.
//

import Foundation
import SwiftData

enum BillHistoryItemsSchemaV1: VersionedSchema {
    static var versionIdentifier = Schema.Version(1, 0, 0)

    static var models: [any PersistentModel.Type] {
        [BillHistoryItem.self]
    }
    
    enum Status: String, Codable {
        case paid
        case pending
    }
    
    struct MenuItem: Identifiable, Equatable, Hashable, Codable {
        var id: UUID
        var name: String
        var prefix: String?
        var suffix: String?
        var quantity: Int
        var price: Int
        var servingSize: Category.Item.ServingSize?
    }

    @Model
    class BillHistoryItem: Identifiable {
        let id: UUID
        var date: Date
        var tableNumber: Int?
        var items: [MenuItem]
        var paymentStatus: Status
        
        init(id: UUID, items: [MenuItem], tableNumber: Int) {
            self.id = id
            self.date = Date()
            self.items = items
            self.tableNumber = tableNumber
            self.paymentStatus = Status.pending
        }
    }
}

enum BillHistoryItemsSchemaV2: VersionedSchema {
    static var versionIdentifier = Schema.Version(1, 0, 1)

    static var models: [any PersistentModel.Type] {
        [BillHistoryItem.self]
    }
    
    enum Status: String, Codable, Equatable {
        case paidByCash
        case paidByUPI
        case paidByCard
        case pending
    }
    
    struct MenuItem: Identifiable, Equatable, Hashable, Codable {
        var id: UUID
        var name: String
        var prefix: String?
        var suffix: String?
        var quantity: Double
        var price: Double
        var servingSize: Category.Item.ServingSize?
    }

    @Model
    class BillHistoryItem: Identifiable {
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
        
        var totalAmount: Double {
            return items.reduce(0) { $0 + $1.price * $1.quantity }
        }
    }
}

typealias MenuItem = BillHistoryItemsSchemaV2.MenuItem
typealias BillHistoryItem = BillHistoryItemsSchemaV2.BillHistoryItem
typealias BillHistoryItemStatus = BillHistoryItemsSchemaV2.Status

enum BillHistoryItemsMigrationPlan: SchemaMigrationPlan {
    static var schemas: [any VersionedSchema.Type] {
        [BillHistoryItemsSchemaV1.self, BillHistoryItemsSchemaV2.self]
    }
    
    static var savedV1BillHistoryItems = [BillHistoryItemsSchemaV1.BillHistoryItem]()
    
    static let migrateV1toV2 = MigrationStage.custom(
        fromVersion: BillHistoryItemsSchemaV1.self,
        toVersion: BillHistoryItemsSchemaV2.self,
        willMigrate: { context in
            let oldBillHistoryItems = try context.fetch(FetchDescriptor<BillHistoryItemsSchemaV1.BillHistoryItem>())
            savedV1BillHistoryItems = oldBillHistoryItems
            oldBillHistoryItems.forEach { oldBillHistoryItem in
                context.delete(oldBillHistoryItem)
            }
            try context.save()
        }, didMigrate: { context in
            savedV1BillHistoryItems.forEach { oldBillHistoryItem in
                let items = oldBillHistoryItem.items.map { oldMenuItem in
                    BillHistoryItemsSchemaV2.MenuItem(id: oldMenuItem.id, name: oldMenuItem.name, prefix: oldMenuItem.prefix, suffix: oldMenuItem.suffix, quantity: Double(oldMenuItem.quantity), price: Double(oldMenuItem.price), servingSize: oldMenuItem.servingSize)
                }
                context.insert(BillHistoryItemsSchemaV2.BillHistoryItem(id: oldBillHistoryItem.id, items: items, tableNumber: oldBillHistoryItem.tableNumber ?? 0, paymentStatus: oldBillHistoryItem.paymentStatus == .pending ? .pending : .paidByCash, waiter: "unknown"))
            }
            
            try context.save()
        }
    )
    
    static var stages: [MigrationStage] {
        [migrateV1toV2]
    }
}
