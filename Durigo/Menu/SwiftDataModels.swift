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
    
    enum PaymentType: Codable {
        case cash
        case upi
        case card
    }
    
    enum Status: Codable, Equatable {
        case paid(PaymentType)
        case pending
    }

    @Model
    class BillHistoryItem: Identifiable {
        let id: UUID
        var date: Date
        var tableNumber: Int
        var items: [MenuItem]
        var paymentStatus: Status
        var waiter: String
        
        init(id: UUID, items: [MenuItem], tableNumber: Int, paymentStatus: Status = .pending,  waiter: String) {
            self.id = id
            self.date = Date()
            self.items = items
            self.tableNumber = tableNumber
            self.paymentStatus = paymentStatus
            self.waiter = waiter
        }
    }
}

typealias BillHistoryItem = BillHistoryItemsSchemaV2.BillHistoryItem

enum BillHistoryItemsMigrationPlan: SchemaMigrationPlan {
    static var schemas: [any VersionedSchema.Type] {
        [BillHistoryItemsSchemaV1.self, BillHistoryItemsSchemaV2.self]
    }
    
    
    static let migrateV1toV2 = MigrationStage.custom(
        fromVersion: BillHistoryItemsSchemaV1.self,
        toVersion: BillHistoryItemsSchemaV2.self,
        willMigrate: { context in
            let oldBillHistoryItems = try context.fetch(FetchDescriptor<BillHistoryItemsSchemaV1.BillHistoryItem>())
            
            oldBillHistoryItems.forEach { oldBillHistoryItem in
                context.delete(oldBillHistoryItem)
            }
            try context.save()
            
        }, didMigrate: { context in
            context.insert(BillHistoryItem(id: UUID(), items: [MenuItem(id: UUID(), name: "Item name", prefix: nil, suffix: nil, quantity: 1, price: 100, servingSize: nil)], tableNumber: 1, paymentStatus: .pending, waiter: "unknown"))
            try context.save()
        }
    )
    
    static var stages: [MigrationStage] {
        [migrateV1toV2]
    }
}
