//
//  MenuList.swift
//  pdf test
//
//  Created by Joshua Cardozo on 15/10/23.
//

import SwiftUI

struct MenuList: View {
    @EnvironmentObject private var menuLoader: MenuLoader
    @State private var searchQuery = ""
    
    func getFilteredResults() -> [Category]? {
        guard let categories = menuLoader.menu else { return nil }
        if searchQuery.isEmpty {
            return categories
        } else {
            let filteredCategories = categories.map { category in
                Category(id: category.id, type: category.type, name: category.name, menus: category.menus.filter({ item in
                    item.name.lowercased().contains(searchQuery.lowercased())
                }))
                
                
            }
            print(filteredCategories)
            return filteredCategories.filter { category in
                !category.menus.isEmpty
            }
        }
    }
    
    @State private var quant = 0
    
    var body: some View {
        VStack {
            TextField("Menu Item", text: $searchQuery)
                .padding()
                .overlay(RoundedRectangle(cornerRadius: 6).stroke(lineWidth: 1))
                .padding()
            let items = getFilteredResults() ?? [Category.placeholder, Category.placeholder]
            List(items) { category in
                Section {
                    ForEach(category.menus) { menuItem in
                        HStack {
                            if let quantity = $menuLoader.billItems.first(where: { $0.id == menuItem.id })?.quantity {
                                Text("\(quantity.wrappedValue)")
                                    .bold()
                                    .padding(.trailing, 8)
                                let _ = print(quantity.wrappedValue)
                                Stepper("Quantity", value: quantity, in: 0...100)
                                    .labelsHidden()
                            } else {
                                Button(action: {
                                    if !menuLoader.billItems.contains(where: { $0.name == menuItem.name
                                    }) {
                                        var name = menuItem.name
                                        if let subtext = menuItem.subtext {
                                            name += " (\(subtext))"
                                        }
                                        menuLoader.billItems.append(MenuItem(id: menuItem.id, name: name, quantity: 1, price: menuItem.price ?? 0))
                                    }
                                    let impactMed = UIImpactFeedbackGenerator(style: .medium)
                                    impactMed.impactOccurred()
                                }) {
                                    Image(systemName: "circle")
                                        .padding(4)
                                }
                            }
                            
                            Text(menuItem.name)
                            if let subtext = menuItem.subtext {
                                Text("(\(subtext))")
                                    .italic()
                            }
                            Text("\(menuItem.price ?? 0)")
                                .bold()
                            Spacer()
                        }
                    }
                } header: {
                    Text(category.name)
                }
            }
        }
        
        .redacted(reason: menuLoader.menu == nil ? .placeholder : [])
        .task {
            await menuLoader.loadMenu()
        }
    }
}

struct MenuList_Previews: PreviewProvider {
    static var previews: some View {
        MenuList()
            .environmentObject(MenuLoader())
    }
}
