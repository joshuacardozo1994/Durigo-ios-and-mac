//
//  BillGenerator.swift
//  pdf test
//
//  Created by Joshua Cardozo on 15/10/23.
//

import SwiftUI

extension BillGenerator {
    struct BillItem: View {
        @Binding var name: String
        @Binding var quantity: Int
        @Binding var price: Int
        var body: some View {
            HStack {
                Text("\(quantity)")
                    .bold()
                    .padding(.trailing, 8)
                Stepper("Quantity", value: $quantity, in: 1...100)
                    .labelsHidden()
                TextField("Name", text: $name)
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)
                Spacer()
                TextField("Price", value: $price, format: .number)
                    .keyboardType(.numberPad)
                    .bold()
                    .frame(width: 35)
            }
        }
    }
}

struct BillGenerator: View {
    @StateObject private var menuLoader = MenuLoader()
    @State private var showingBillClearAlert = false
    @State private var isShowingMenuList = false
    var body: some View {
        NavigationStack {
            let _ = print(menuLoader.billItems)
            VStack {
                List($menuLoader.billItems, editActions: .delete) { $item in
                    BillItem(name: $item.name, quantity: $item.quantity, price: $item.price)
                   
                }
                HStack {
                    Text("\(menuLoader.billItems.count) Items")
                    Spacer()
                    Text("Total: \(menuLoader.billItems.getTotal())")
                }
                .padding(.horizontal)
                    .font(.title)
                    .bold()
            }
            .sheet(isPresented: $isShowingMenuList, content: {
                MenuList()
            })
            .environmentObject(menuLoader)
            
            .alert("Are you sure you want to clear the bill", isPresented: $showingBillClearAlert) {
                Button("Clear", role: .destructive) {
                    menuLoader.billItems = [MenuItem]()
                }
                        Button("Cancel", role: .cancel) { }
                    }
            .toolbar {
                ToolbarItemGroup(placement: .navigationBarLeading) {
                    Button(action: {
                        showingBillClearAlert.toggle()
                    }) {
                        Text("Clear")
                    }
                    .disabled(menuLoader.billItems.isEmpty)
                    Button(action: {
                        let newId = menuLoader.billItems.reduce(300) { partialResult, item in
                            return max(item.id, partialResult)
                        }
                        menuLoader.billItems.append(MenuItem(id: newId + 1, name: "Item to be added", quantity: 1, price: 0))
                    }) {
                        Text("Add new item")
                    }
                }
                ToolbarItemGroup(placement: .navigationBarTrailing) {
                    Button(action: {
                        isShowingMenuList.toggle()
                    }) {
                        Image(systemName: "plus.circle.fill")
                            .font(.title)
                    }
                    NavigationLink {
                        BillPreview(billItems: menuLoader.billItems)
                    } label: {
                        Image(systemName: "printer.fill")
                            .font(.title)
                    }
                    .disabled(menuLoader.billItems.isEmpty || menuLoader.billItems.reduce(false, { partialResult, item in
                        return partialResult || item.price == 0
                    }))
                }
               
                
            }
            .task {
                await menuLoader.loadMenu()
            }
        }
        
    }
}

struct BillGenerator_Previews: PreviewProvider {
    static var previews: some View {
        BillGenerator()
    }
}
