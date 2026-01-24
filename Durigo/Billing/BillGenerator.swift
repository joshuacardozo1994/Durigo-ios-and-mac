//
//  BillGenerator.swift
//  pdf test
//
//  Created by Joshua Cardozo on 15/10/23.
//

import SwiftUI


struct TableDropdownSelector: View {
    var showIfSelected = false
    @Binding var selectedOption: Int?
    let options: [Int]

    private var allOptions: [Int] {
        [0] + options // 0 = Parcel
    }

    var body: some View {
        Picker(selection: Binding(
            get: { selectedOption ?? -1 },
            set: { selectedOption = $0 == -1 ? nil : $0 }
        )) {
            Text("Table").tag(-1)
            Text("Parcel").tag(0)
            ForEach(options, id: \.self) { option in
                Text("Table \(option)").tag(option)
            }
        } label: {
            HStack {
                if let selectedOption {
                    if selectedOption == 0 {
                        Text("\(showIfSelected ? "● " : "")Parcel")
                    } else {
                        Text("\(showIfSelected ? "● " : "")Table \(selectedOption)")
                    }
                } else {
                    Text("Table")
                }
            }
            .font(.title)
            .bold()
        }
        .pickerStyle(.menu)
        .tint(Color.primary)
        .accessibilityIdentifier("Table-Selector")
    }
}

struct WaiterDropdownSelector: View {
    var showIfSelected = false
    @Binding var selectedOption: String?
    let options: [String]

    var body: some View {
        Picker(selection: Binding(
            get: { selectedOption ?? "" },
            set: { selectedOption = $0.isEmpty ? nil : $0 }
        )) {
            Text("Waiter").tag("")
            Section("Waiters") {
                ForEach(Array(options.prefix(3)), id: \.self) { option in
                    Text(option).tag(option)
                }
            }
            Section("Admins") {
                ForEach(Array(options.suffix(3)), id: \.self) { option in
                    Text(option).tag(option)
                }
            }
        } label: {
            HStack {
                if let selectedOption {
                    Text("\(showIfSelected ? "● " : "")\(selectedOption)")
                } else {
                    Text("Waiter")
                }
            }
            .font(.title)
            .bold()
        }
        .pickerStyle(.menu)
        .tint(Color.primary)
        .accessibilityIdentifier("Waiter-Selector")
    }
}

/// Represents an individual item in the bill.
struct BillItem: View {
    @Binding var item: MenuItem

    var body: some View {
        HStack {
            Text(String(format: "%.1f", item.quantity))
                .bold()
                .padding(.trailing, 8)
                .accessibilityIdentifier("menu-item-quantity-Text-\(item.id.uuidString)")
                .onTapGesture {
                    item.quantity += 0.5
                }
            Stepper("Quantity", value: $item.quantity, in: 1...100)
                .labelsHidden()
                .accessibilityIdentifier("menu-item-quantity-Stepper-\(item.id.uuidString)")
            if let prefix = item.prefix {
                Text("(\(prefix))")
                    .accessibilityIdentifier("menu-item-prefix-Text-\(item.id.uuidString)")
            }
            if let servingSize = item.servingSize, servingSize.shouldDisplay {
                Text(servingSize.name)
            }
            TextField("Name", text: $item.name)
                .accessibilityIdentifier("menu-item-name-TextField-\(item.id.uuidString)")
                .lineLimit(2)
                .fixedSize(horizontal: false, vertical: true)
                
            Spacer()
            TextField("Price", value: $item.price, format: .number)
                .multilineTextAlignment(.trailing)
                .accessibilityIdentifier("menu-item-price-TextField-\(item.id.uuidString)")
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
    @EnvironmentObject private var menuLoader: MenuLoader
    @State private var showingBillClearAlert = false
    @State private var isShowingMenuList = false

    var body: some View {
        NavigationStack {
            VStack {
                HStack {
                    TableDropdownSelector(selectedOption: $menuLoader.tableNumber, options: Array(1...20))
                    Spacer()
                    WaiterDropdownSelector(selectedOption: $menuLoader.waiter, options: ["Alcin", "Anthony", "Antone", "Amanda", "Monica", "Joshua"])
                }
                .padding(.horizontal)
                .padding(.top)
                billItemsList
                totalSection
            }
            .navigationTitle("")
            .sheet(isPresented: $isShowingMenuList) {
                MenuList()
            }
            
            .alert("Are you sure you want to clear the bill", isPresented: $showingBillClearAlert) {
                Button("Clear", role: .destructive) {
                    menuLoader.resetBill()
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
            #else
            .toolbar {
                ToolbarItemGroup(placement: .primaryAction) {
                    clearButton
                    addItemButton
                }
                ToolbarItemGroup(placement: .secondaryAction) {
                    menuButton
                    printButton
                }
            }
            #endif
            .task {
                await menuLoader.loadMenu()
            }
        }
    }

    /// View for the list of bill items.
    private var billItemsList: some View {
        List($menuLoader.billItems, editActions: [.delete, .move]) { $item in
            BillItem(item: $item)
        }
    }

    /// View for displaying total count and price.
    private var totalSection: some View {
        HStack {
            Text("\(menuLoader.billItems.count) Items")
                .accessibilityIdentifier("bill generator items count")
            Spacer()
            Text("Total: \(menuLoader.billItems.getTotal())")
                .accessibilityIdentifier("bill generator items total")
        }
        .padding(.horizontal)
        .font(.title)
        .bold()
    }

    /// Button to clear all items.
    private var clearButton: some View {
        Button(action: {
        #if os(iOS)
            UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
        #endif
            showingBillClearAlert.toggle()
        }) {
            Image(systemName: "trash.fill")
        }
        .disabled(menuLoader.billItems.isEmpty)
        .accessibilityIdentifier("clearBill")
    }

    /// Button to add a new item.
    private var addItemButton: some View {
        Button(action: {
            menuLoader.billItems.append(MenuItem(id: UUID(), name: "", quantity: 1, price: 0))
        }) {
            Image(systemName: "plus.circle.fill")
        }
        .accessibilityIdentifier("addItemButton")
    }

    /// Button to show the menu list.
    private var menuButton: some View {
        Button(action: {
            isShowingMenuList.toggle()
        }) {
            Image(systemName: "book.pages.fill")
        }
        .accessibilityIdentifier("showMenuButton")
    }

    /// Button to preview the bill.
    private var printButton: some View {
        NavigationLink {
            BillPreview(tableNumber: menuLoader.tableNumber, waiter: menuLoader.waiter ?? "Unknown", billID: menuLoader.billID, billItems: menuLoader.billItems)
        } label: {
            Image(systemName: "printer.fill")
        }
        .disabled(menuLoader.billItems.isEmpty || menuLoader.billItems.contains { $0.price == 0 } ||
                  menuLoader.tableNumber == nil || menuLoader.waiter == nil
        )
        .accessibilityIdentifier("print-bill")
    }
}



struct BillGenerator_Previews: PreviewProvider {
    static var previews: some View {
        BillGenerator()
            .environmentObject(MenuLoader())
            .environmentObject(Navigation())
    }
}
