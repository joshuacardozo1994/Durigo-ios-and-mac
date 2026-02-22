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
        var id: UUID
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
        var id: UUID
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

enum BillHistoryItemsSchemaV3: VersionedSchema {
    static var versionIdentifier = Schema.Version(1, 0, 2)

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
        var tags: [String]?
    }

    @Model
    class BillHistoryItem: Identifiable {
        var id: UUID
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

typealias MenuItem = BillHistoryItemsSchemaV3.MenuItem
typealias BillHistoryItem = BillHistoryItemsSchemaV3.BillHistoryItem
typealias BillHistoryItemStatus = BillHistoryItemsSchemaV3.Status

enum BillHistoryItemsMigrationPlan: SchemaMigrationPlan {
    static var schemas: [any VersionedSchema.Type] {
        [BillHistoryItemsSchemaV1.self, BillHistoryItemsSchemaV2.self, BillHistoryItemsSchemaV3.self]
    }
    
    static var savedV1BillHistoryItems = [BillHistoryItemsSchemaV1.BillHistoryItem]()
    static var savedV2BillHistoryItems = [BillHistoryItemsSchemaV2.BillHistoryItem]()
    
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
    
    static let migrateV2toV3 = MigrationStage.custom(
        fromVersion: BillHistoryItemsSchemaV2.self,
        toVersion: BillHistoryItemsSchemaV3.self,
        willMigrate: { context in
            let oldBillHistoryItems = try context.fetch(FetchDescriptor<BillHistoryItemsSchemaV2.BillHistoryItem>())
            savedV2BillHistoryItems = oldBillHistoryItems
            oldBillHistoryItems.forEach { oldBillHistoryItem in
                context.delete(oldBillHistoryItem)
            }
            try context.save()
        }, didMigrate: { context in
            savedV2BillHistoryItems.forEach { oldBillHistoryItem in
                let items = oldBillHistoryItem.items.map { oldMenuItem in
                    BillHistoryItemsSchemaV3.MenuItem(
                        id: oldMenuItem.id,
                        name: oldMenuItem.name,
                        prefix: oldMenuItem.prefix,
                        suffix: oldMenuItem.suffix,
                        quantity: oldMenuItem.quantity,
                        price: oldMenuItem.price,
                        servingSize: oldMenuItem.servingSize,
                        tags: nil
                    )
                }
                let newStatus: BillHistoryItemsSchemaV3.Status
                switch oldBillHistoryItem.paymentStatus {
                case .paidByCash: newStatus = .paidByCash
                case .paidByUPI: newStatus = .paidByUPI
                case .paidByCard: newStatus = .paidByCard
                case .pending: newStatus = .pending
                }
                context.insert(BillHistoryItemsSchemaV3.BillHistoryItem(
                    id: oldBillHistoryItem.id,
                    date: oldBillHistoryItem.date,
                    items: items,
                    tableNumber: oldBillHistoryItem.tableNumber,
                    paymentStatus: newStatus,
                    waiter: oldBillHistoryItem.waiter
                ))
            }
            
            try context.save()
        }
    )
    
    static var stages: [MigrationStage] {
        [migrateV1toV2, migrateV2toV3]
    }
}
