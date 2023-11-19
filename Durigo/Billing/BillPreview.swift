//
//  ContentView.swift
//  pdf test
//
//  Created by Joshua Cardozo on 09/10/23.
//

import SwiftUI

struct GroupedMenu: Identifiable, Equatable {
    let id: Int
    let items: [MenuItem]
}

struct BillPreview: View {
    let maxItemCount = 18
    let billItems: [MenuItem]
    var body: some View {
        let groupedArray: [GroupedMenu] = stride(from: 0, to: billItems.count, by: maxItemCount).map { index in
            
            GroupedMenu(id: index, items: Array(billItems[index ..< min(index + maxItemCount, billItems.count)]))
        }
        VStack {
            
            TabView {
                ForEach(groupedArray) { group in
                    Bill(currentMenuItems: group.items, first: groupedArray.first == group, finalTotal: groupedArray.last == group ? billItems.getTotal() : nil)
                        .frame(width: 420, height: 595)
                        .background(Color.white)
                }
            }
            #if os(iOS)
            .tabViewStyle(.page)
            #endif
            HStack {
                Spacer()
                ShareLink("Export PDF", item: render())
                    .padding()
                    .background(Color.white)
                    .cornerRadius(6)
                    .padding()
            }
        }
        .background(Color.gray.opacity(0.5))
    }
    
    @MainActor func render() -> URL {
        // 1: Save it to our documents directory
        let url = URL.documentsDirectory.appending(path: "Bill.pdf")
        
        // 2: PDF size
        var box = CGRect(x: 0, y: 0, width: 420, height: 595)
        
        // 3: Create the CGContext for our PDF pages
        guard let pdf = CGContext(url as CFURL, mediaBox: &box, nil) else {
            return url
        }
        
        let groupedArray: [GroupedMenu] = stride(from: 0, to: billItems.count, by: maxItemCount).map { index in
            
            GroupedMenu(id: index, items: Array(billItems[index ..< min(index + maxItemCount, billItems.count)]))
        }
        
        // 4: Render each page
        for group in groupedArray {
            
            pdf.beginPDFPage(nil)
            
            let renderer = ImageRenderer(content:
                                            Bill(currentMenuItems: group.items, first: groupedArray.first == group, finalTotal: groupedArray.last == group ? billItems.getTotal() : nil).frame(width: 420, height: 595)
            )
            
            renderer.render { size, context in
                context(pdf)
            }
            
            pdf.endPDFPage()
            
        }
        pdf.closePDF()
        
        
        return url
    }
}

struct BillPreview_Previews: PreviewProvider {
    static var previews: some View {
        BillPreview(billItems: [
            MenuItem(id: UUID(), name: "Soda", quantity: 1, price: 20),
            MenuItem(id: UUID(), name: "Fresh Lemon Soda", quantity: 2, price: 90),
            MenuItem(id: UUID(), name: "Virgin Mojito", quantity: 1, price: 220),
            MenuItem(id: UUID(), name: "Chonok", quantity: 1, price: 500),
            MenuItem(id: UUID(), name: "Chilli Chicken", quantity: 2, price: 250),
            MenuItem(id: UUID(), name: "Chicken Pulao", quantity: 1, price: 200),
            MenuItem(id: UUID(), name: "Beef Soup", quantity: 1, price: 160),
            MenuItem(id: UUID(), name: "Mackerel", quantity: 2, price: 180),
            MenuItem(id: UUID(), name: "Ice Cream", quantity: 1, price: 100),
            MenuItem(id: UUID(), name: "Caramel Pudding", quantity: 1, price: 100),
            MenuItem(id: UUID(), name: "Pankcakes", quantity: 2, price: 100),
            MenuItem(id: UUID(), name: "Item 12", quantity: 1, price: 100),
            MenuItem(id: UUID(), name: "Item 13", quantity: 1, price: 100),
            MenuItem(id: UUID(), name: "Item 14", quantity: 1, price: 100),
            MenuItem(id: UUID(), name: "Item 15", quantity: 1, price: 100),
            MenuItem(id: UUID(), name: "Item 16", quantity: 1, price: 100),
            MenuItem(id: UUID(), name: "Item 17", quantity: 1, price: 100),
            MenuItem(id: UUID(), name: "Item 18", quantity: 1, price: 100),
            MenuItem(id: UUID(), name: "Item 19", quantity: 1, price: 100),
            MenuItem(id: UUID(), name: "Item 20", quantity: 1, price: 100),
            MenuItem(id: UUID(), name: "Item 21", quantity: 1, price: 100)
        ])
    }
}
