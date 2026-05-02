//
//  Navigation.swift
//  Durigo
//
//  Created by Joshua Cardozo on 20/11/23.
//

import SwiftUI

enum TabItems {
    case billHistoryList
    case billGenerator
    case stats
    case reports
    case menuGenerator
}

@Observable class Navigation: ObservableObject {
    var tabSelection: TabItems = {
        // Allow UI tests / screenshot scripts to land on a specific tab via launch arg.
        let args = CommandLine.arguments
        if args.contains("--start-tab=history") { return .billHistoryList }
        if args.contains("--start-tab=stats") { return .stats }
        if args.contains("--start-tab=reports") { return .reports }
        if args.contains("--start-tab=menu") { return .menuGenerator }
        return .billGenerator
    }()
}
