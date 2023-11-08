//
//  SwiftUIView.swift
//  Durigo
//
//  Created by Joshua Cardozo on 09/11/23.
//

import TipKit

struct AddItemFromMenu: Tip {
    var title: Text {
        Text("Add a menu item to bill")
    }
 
    var message: Text? {
        Text("You can add a menu item to the bill")
    }
 
        var image: Image? {
        Image(systemName: "book.fill")
    }
}

#Preview {
    VStack {
        Text("Hi")
    }
    .task {
        try? Tips.configure([
            .displayFrequency(.immediate),
            .datastoreLocation(.applicationDefault)
        ])
    }
    .popoverTip(AddItemFromMenu())
}
