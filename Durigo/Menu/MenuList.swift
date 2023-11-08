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
                    var present = item.name.lowercased().contains(searchQuery.lowercased())
                    
                    if let subtext = item.subtext {
                        present = present || subtext.lowercased().contains(searchQuery.lowercased())
                    }
                    return present
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
            HStack {
                TextField("Menu Item", text: $searchQuery)
                    .autocorrectionDisabled()
                    .padding()
                Button(action: {
                    searchQuery = ""
                }) {
                    Image(systemName: "x.circle")
                        .padding()
                }
            }
                
                .overlay(RoundedRectangle(cornerRadius: 6).stroke(lineWidth: 1))
                .padding()
            let items = getFilteredResults() ?? [Category.placeholder, Category.placeholder]
            List(items) { category in
                Section {
                    ForEach(category.menus) { menuItem in
                        HStack {
                            HStack {
                                if let quantity = $menuLoader.billItems.first(where: { $0.id == menuItem.id })?.quantity {
                                    Text("\(quantity.wrappedValue)")
                                        .bold()
                                } else {
                                    Text("0").hidden()
                                }
                            }
                            .frame(width: 14)
                            Text(menuItem.name)
                                .bold()
                            if let subtext = menuItem.subtext {
                                Text("(\(subtext))")
                                    .italic()
                            }
                            Spacer()
                            HStack {
                                if let quantity = $menuLoader.billItems.first(where: { $0.id == menuItem.id })?.quantity {
                                    
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
                                            menuLoader.billItems.append(MenuItem(id: menuItem.id, name: name, quantity: 1, price: menuItem.price))
                                        }
#if os(iOS)
                                        let impactMed = UIImpactFeedbackGenerator(style: .medium)
                                        impactMed.impactOccurred()
#endif
                                    }) {
                                        VStack{}
                                            .padding(4)
                                    }
                                }
                            }
                            .frame(width: 94)
                            
                            
                            Text("\(menuItem.price)")
                            
                            
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
