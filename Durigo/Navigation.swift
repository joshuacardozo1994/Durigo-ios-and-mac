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
    case menuGenerator
    case stats
}

@Observable class Navigation: ObservableObject {
    var tabSelection = TabItems.billGenerator
}
