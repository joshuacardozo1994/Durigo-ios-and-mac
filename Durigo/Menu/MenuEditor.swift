//
//  MenuEditor.swift
//  Durigo
//
//  Created by Joshua Cardozo on 29/10/23.
//

import SwiftUI

struct MenuEditor: View {
    @StateObject private var menuLoader = MenuLoader()
    var body: some View {
        NavigationStack {
            
        }
        .task {
            await menuLoader.loadServerMenu()
        }
    }
}

#Preview {
    MenuEditor()
}
