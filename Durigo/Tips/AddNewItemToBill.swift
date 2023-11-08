//
//  AddNewItemToBill.swift
//  Durigo
//
//  Created by Joshua Cardozo on 09/11/23.
//

import TipKit

struct AddNewItemToBill: Tip {
    var title: Text {
        Text("Add a new item to bill")
    }
 
    var message: Text? {
        Text("You can add a custom item to the bill, which is not present in the menu")
    }
 
        var image: Image? {
        Image(systemName: "note.text.badge.plus")
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
    .popoverTip(AddNewItemToBill())
}
