//
//  DurigoApp.swift
//  Durigo
//
//  Created by Joshua Cardozo on 27/10/23.
//

import SwiftUI
import TipKit

@main
struct DurigoApp: App {
    var body: some Scene {
        WindowGroup {
            BillGenerator()
                .task {
                    try? Tips.configure([
                        .displayFrequency(.daily),
                        .datastoreLocation(.applicationDefault)
                    ])
                }
        }
    }
}
