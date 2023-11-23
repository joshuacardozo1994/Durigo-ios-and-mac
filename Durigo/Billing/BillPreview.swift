//
//  ContentView.swift
//  pdf test
//
//  Created by Joshua Cardozo on 09/10/23.
//

import SwiftUI
import SwiftData



struct GroupedMenu: Identifiable, Equatable {
    let id: Int
    let items: [MenuItem]
}

struct BillPreview: View {
    @Query var billHistoryItems: [BillHistoryItem]
    @Environment(\.modelContext) var modelContext
    let tableNumber: Int?
    let maxItemCount = 19
    let billID: UUID
    let billItems: [MenuItem]
    @State private var isShareSheetShowing = false
    var body: some View {
        let groupedArray: [GroupedMenu] = stride(from: 0, to: billItems.count, by: maxItemCount).map { index in
            
            GroupedMenu(id: index, items: Array(billItems[index ..< min(index + maxItemCount, billItems.count)]))
        }
        VStack {
            TabView {
                ForEach(groupedArray) { group in
                    Bill(currentMenuItems: group.items, tableNumber: tableNumber, first: groupedArray.first == group, finalTotal: groupedArray.last == group ? billItems.getTotal() : nil)
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
        .onAppear {
            if let presentbillHistoryItem = billHistoryItems.first(where: { $0.id == billID }) {
                presentbillHistoryItem.tableNumber = tableNumber
                presentbillHistoryItem.items = billItems
                presentbillHistoryItem.date = Date()
            } else {
                if let tableNumber {
                    modelContext.insert(BillHistoryItem( items: billItems, tableNumber: tableNumber))
                }
            }
            
        }
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
                                            Bill(currentMenuItems: group.items, tableNumber: tableNumber, first: groupedArray.first == group, finalTotal: groupedArray.last == group ? billItems.getTotal() : nil).frame(width: 420, height: 595)
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
#if DEBUG
#Preview {
    do {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: BillHistoryItem.self, configurations: config)

        return BillPreview(tableNumber: 1, billID: UUID(), billItems: PreviewData.menuItems)
            .modelContainer(container)
    } catch {
        fatalError("Failed to create model container.")
    }
}
#endif
