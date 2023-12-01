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
                Category(id: category.id, type: category.type, name: category.name, items: category.items.filter({ item in
                    var present = item.name.lowercased().contains(searchQuery.lowercased())
                    
                    if let suffix = item.suffix {
                        present = present || suffix.lowercased().contains(searchQuery.lowercased())
                    }
                    return present
                }))
                
                
            }
            return filteredCategories.filter { category in
                !category.items.isEmpty
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
                    ForEach(category.items.filter({ [Category.Item.VisibilityScope.bill, Category.Item.VisibilityScope.both].contains($0.visibilityScope)  })) { menuItem in
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
                            Text(menuItem.prefix != nil ? "(\(menuItem.prefix ?? "")) " : "")
                                .italic()
                            +
                            Text(menuItem.name)
                                .bold()
                            +
                            Text(menuItem.suffix != nil ? " (\(menuItem.suffix ?? ""))" : "")
                                .italic()
                            
                            Spacer()
                            HStack {
                                if let quantity = $menuLoader.billItems.first(where: { $0.id == menuItem.id })?.quantity {
                                    
                                    Stepper("Quantity", value: quantity, in: 0...100)
                                        .labelsHidden()
                                    
                                } else {
                                    Button(action: {
                                        if !menuLoader.billItems.contains(where: { $0.id == menuItem.id
                                        }) {
                                            var name = menuItem.name
                                            if let suffix = menuItem.suffix {
                                                name += " (\(suffix))"
                                            }
                                            menuLoader.billItems.append(MenuItem(id: menuItem.id, name: name, prefix: menuItem.prefix, suffix: menuItem.suffix, quantity: 1, price: menuItem.price))
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
