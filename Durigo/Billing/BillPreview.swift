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
    let billItems: [MenuItem]
    var body: some View {
        let groupedArray: [GroupedMenu] = stride(from: 0, to: billItems.count, by: 20).map { index in
            
            GroupedMenu(id: index, items: Array(billItems[index ..< min(index + 20, billItems.count)]))
        }
        VStack {
            HStack {
                Spacer()
                ShareLink("Export PDF", item: render())
                    .padding()
                    .background(Color.white)
                    .cornerRadius(6)
                    .padding()
            }
            TabView {
                ForEach(groupedArray) { group in
                    Bill(currentMenuItems: group.items, first: groupedArray.first == group, finalTotal: groupedArray.last == group ? billItems.getTotal() : nil)
                        .frame(width: 420, height: 595)
                        .background(Color.white)
                }
            }
            .tabViewStyle(.page)
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
        
        let groupedArray: [GroupedMenu] = stride(from: 0, to: billItems.count, by: 20).map { index in
            
            GroupedMenu(id: index, items: Array(billItems[index ..< min(index + 20, billItems.count)]))
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
            MenuItem(id: 0, name: "Soda", quantity: 1, price: 20),
            MenuItem(id: 1, name: "Fresh Lemon Soda", quantity: 2, price: 90),
            MenuItem(id: 2, name: "Virgin Mojito", quantity: 1, price: 220),
            MenuItem(id: 3, name: "Chonok", quantity: 1, price: 500),
            MenuItem(id: 4, name: "Chilli Chicken", quantity: 2, price: 250),
            MenuItem(id: 5, name: "Chicken Pulao", quantity: 1, price: 200),
            MenuItem(id: 6, name: "Beef Soup", quantity: 1, price: 160),
            MenuItem(id: 7, name: "Mackerel", quantity: 2, price: 180),
            MenuItem(id: 8, name: "Ice Cream", quantity: 1, price: 100),
            MenuItem(id: 9, name: "Caramel Pudding", quantity: 1, price: 100),
            MenuItem(id: 10, name: "Pankcakes", quantity: 2, price: 100),
            MenuItem(id: 11, name: "Item 12", quantity: 1, price: 100),
            MenuItem(id: 12, name: "Item 13", quantity: 1, price: 100),
            MenuItem(id: 13, name: "Item 14", quantity: 1, price: 100),
            MenuItem(id: 14, name: "Item 15", quantity: 1, price: 100),
            MenuItem(id: 15, name: "Item 16", quantity: 1, price: 100),
            MenuItem(id: 16, name: "Item 17", quantity: 1, price: 100),
            MenuItem(id: 17, name: "Item 18", quantity: 1, price: 100),
            MenuItem(id: 18, name: "Item 19", quantity: 1, price: 100),
            MenuItem(id: 19, name: "Item 20", quantity: 1, price: 100),
            MenuItem(id: 20, name: "Item 21", quantity: 1, price: 100)
        ])
    }
}
