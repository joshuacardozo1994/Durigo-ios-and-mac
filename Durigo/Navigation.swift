//
//  Navigation.swift
//  Durigo
//
//  Created by Joshua Cardozo on 20/11/23.
//

import SwiftUI

enum TabItems: Hashable, CaseIterable {
    case billHistoryList
    case billGenerator
    case stats
    case reports
    case menuGenerator

    var title: String {
        switch self {
        case .billHistoryList: "History"
        case .billGenerator:   "Bill Generator"
        case .stats:           "Stats"
        case .reports:         "Reports"
        case .menuGenerator:   "Menu Generator"
        }
    }

    var icon: String {
        switch self {
        case .billHistoryList: "doc.text"
        case .billGenerator:   "plus.rectangle.on.rectangle"
        case .stats:           "chart.bar.fill"
        case .reports:         "chart.bar.doc.horizontal.fill"
        case .menuGenerator:   "doc.plaintext.fill"
        }
    }
}

@Observable class Navigation: ObservableObject {
    var tabSelection: TabItems = {
        let args = CommandLine.arguments
        if args.contains("--start-tab=history") { return .billHistoryList }
        if args.contains("--start-tab=stats") { return .stats }
        if args.contains("--start-tab=reports") { return .reports }
        if args.contains("--start-tab=menu") { return .menuGenerator }
        return .billGenerator
    }()
}
