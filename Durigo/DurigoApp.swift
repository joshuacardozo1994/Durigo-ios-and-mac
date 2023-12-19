//
//  DurigoApp.swift
//  Durigo
//
//  Created by Joshua Cardozo on 27/10/23.
//

import SwiftUI
import TipKit
import SwiftData

@main
struct DurigoApp: App {
    let container: ModelContainer
    
    init() {
        do {
            container = try ModelContainer(
                for: BillHistoryItem.self,
                migrationPlan: BillHistoryItemsMigrationPlan.self
            )
        } catch {
            fatalError("Failed to initialize model container.")
        }
    }
    
    var body: some Scene {
        WindowGroup {
            Home()
        }
        .modelContainer(container)
    }
}
