//
//  BillGenerator.swift
//  pdf test
//
//  Created by Joshua Cardozo on 15/10/23.
//

import SwiftUI

/// Represents an individual item in the bill.
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
                .multilineTextAlignment(.trailing)
            #if os(iOS)
                .keyboardType(.numberPad)
            #endif
                .bold()
                .frame(width: 35)
        }
    }
}

/// Main view for generating bills.
struct BillGenerator: View {
    @StateObject private var menuLoader = MenuLoader()
    @State private var showingBillClearAlert = false
    @State private var isShowingMenuList = false

    var body: some View {
        NavigationStack {
            VStack {
                billItemsList
                totalSection
            }
            .navigationTitle("Bill")
            .sheet(isPresented: $isShowingMenuList) {
                MenuList()
            }
            .environmentObject(menuLoader)
            .alert("Are you sure you want to clear the bill", isPresented: $showingBillClearAlert) {
                Button("Clear", role: .destructive) {
                    menuLoader.billItems.removeAll()
                }
                Button("Cancel", role: .cancel) {}
            }
            #if os(iOS)
            .toolbar {
                ToolbarItemGroup(placement: .navigationBarLeading) {
                    EditButton()
                    clearButton
                    addItemButton
                }
                ToolbarItemGroup(placement: .navigationBarTrailing) {
                    menuButton
                    printButton
                }
            }
            #endif
            .task {
                await menuLoader.loadMenu()
            }
        }
        .accessibilityIdentifier("BillGenerator")
    }

    /// View for the list of bill items.
    private var billItemsList: some View {
        List($menuLoader.billItems, editActions: [.delete, .move]) { $item in
            BillItem(name: $item.name, quantity: $item.quantity, price: $item.price)
        }
    }

    /// View for displaying total count and price.
    private var totalSection: some View {
        HStack {
            Text("\(menuLoader.billItems.count) Items")
            Spacer()
            Text("Total: \(menuLoader.billItems.getTotal())")
        }
        .padding(.horizontal)
        .font(.title)
        .bold()
    }

    /// Button to clear all items.
    private var clearButton: some View {
        Button(action: {
            showingBillClearAlert.toggle()
        }) {
            Image(systemName: "trash.fill")
        }
        .disabled(menuLoader.billItems.isEmpty)
    }

    /// Button to add a new item.
    private var addItemButton: some View {
        Button(action: {
            menuLoader.billItems.append(MenuItem(id: UUID(), name: "Item to be added", quantity: 1, price: 0))
        }) {
            Image(systemName: "plus.circle.fill")
        }
//        .popoverTip(AddNewItemToBill())
    }

    /// Button to show the menu list.
    private var menuButton: some View {
        Button(action: {
            isShowingMenuList.toggle()
        }) {
            Image(systemName: "book.pages.fill")
        }
    }

    /// Button to preview the bill.
    private var printButton: some View {
        NavigationLink {
            BillPreview(billItems: menuLoader.billItems)
        } label: {
            Image(systemName: "printer.fill")
        }
        .disabled(menuLoader.billItems.isEmpty || menuLoader.billItems.contains { $0.price == 0 })
    }
}

struct BillGenerator_Previews: PreviewProvider {
    static var previews: some View {
        BillGenerator()
    }
}
