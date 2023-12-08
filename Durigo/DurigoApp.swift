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
    var body: some Scene {
        WindowGroup {
            Home()
        }
        .modelContainer(for: BillHistoryItem.self)
    }
}
