//
//  Navigation.swift
//  Durigo
//
//  iOS navigation structure mirroring the web's sidebar groups:
//  Overview / Operations / Management / Analytics + a top-level Settings.
//
//  iPhone uses the first 4 entries as bottom tabs and a "More" tab for the
//  rest; iPad shows the full grouped list in the sidebar.
//

import SwiftUI

enum NavigationItem: Hashable, CaseIterable, Identifiable {
    case dashboard
    case pos
    case kitchen
    case billing
    case reservations
    case menu
    case modifiers
    case discounts
    case inventory
    case users
    case reports
    case settings

    var id: Self { self }

    var title: String {
        switch self {
        case .dashboard:    "Dashboard"
        case .pos:          "POS"
        case .kitchen:      "Kitchen"
        case .billing:      "Billing"
        case .reservations: "Reservations"
        case .menu:         "Menu"
        case .modifiers:    "Modifiers"
        case .discounts:    "Discounts"
        case .inventory:    "Inventory"
        case .users:        "Users"
        case .reports:      "Reports"
        case .settings:     "Settings"
        }
    }

    var icon: String {
        switch self {
        case .dashboard:    "square.grid.2x2"
        case .pos:          "cart"
        case .kitchen:      "fork.knife"
        case .billing:      "doc.text"
        case .reservations: "calendar"
        case .menu:         "book"
        case .modifiers:    "tag"
        case .discounts:    "ticket"
        case .inventory:    "shippingbox"
        case .users:        "person.2"
        case .reports:      "chart.bar.doc.horizontal"
        case .settings:     "gearshape"
        }
    }
}

enum NavigationSection: CaseIterable, Identifiable {
    case overview
    case operations
    case management
    case analytics

    var id: Self { self }

    var title: String {
        switch self {
        case .overview:   "Overview"
        case .operations: "Operations"
        case .management: "Management"
        case .analytics:  "Analytics"
        }
    }

    var items: [NavigationItem] {
        switch self {
        case .overview:   [.dashboard]
        case .operations: [.pos, .kitchen, .billing, .reservations]
        case .management: [.menu, .modifiers, .discounts, .inventory, .users]
        case .analytics:  [.reports]
        }
    }
}

/// Items shown as bottom tabs on iPhone (compact). Everything else lives
/// behind the "More" tab.
let iPhoneRootTabs: [NavigationItem] = [
    .dashboard,
    .pos,
    .billing,
    .reports,
]

@Observable class Navigation: ObservableObject {
    /// Resolved from `--start-tab=` launch args. Used as both the initial
    /// `selection` and (on iPhone) the deep-link target for the More tab's
    /// NavigationStack — exposing this as a static lets Home compute its
    /// initial morePath synchronously at @State init time.
    static func argDerivedSelection() -> NavigationItem {
        let args = CommandLine.arguments
        if args.contains("--start-tab=dashboard")     { return .dashboard }
        if args.contains("--start-tab=pos")           { return .pos }
        if args.contains("--start-tab=kitchen")       { return .kitchen }
        if args.contains("--start-tab=billing")       { return .billing }
        if args.contains("--start-tab=history")       { return .billing }      // back-compat
        if args.contains("--start-tab=reservations")  { return .reservations }
        if args.contains("--start-tab=menu")          { return .menu }
        if args.contains("--start-tab=modifiers")     { return .modifiers }
        if args.contains("--start-tab=discounts")     { return .discounts }
        if args.contains("--start-tab=inventory")     { return .inventory }
        if args.contains("--start-tab=users")         { return .users }
        if args.contains("--start-tab=reports")       { return .reports }
        if args.contains("--start-tab=stats")         { return .dashboard }    // back-compat
        if args.contains("--start-tab=settings")      { return .settings }
        return .pos
    }

    var selection: NavigationItem = Navigation.argDerivedSelection()

    /// True when the iPhone shell should show the "More" sheet because the
    /// selected item isn't one of the four bottom tabs.
    var isInMoreTab: Bool { !iPhoneRootTabs.contains(selection) && selection != .settings }
}
