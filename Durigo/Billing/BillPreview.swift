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
    @EnvironmentObject private var menuLoader: MenuLoader
    let tableNumber: Int?
    let waiter: String
    let maxItemCount = 19
    let billID: UUID
    let billItems: [MenuItem]
    @State private var pdfURL: URL?
    @State private var isGeneratingPDF = false

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
                if isGeneratingPDF {
                    ProgressView()
                        .padding()
                } else if let pdfURL {
                    ShareLink("Export PDF", item: pdfURL)
                } else {
                    Button("Generate PDF") {
                        generatePDF()
                    }
                }
            }
            .padding()
        }
        .background(Color.gray.opacity(0.5))
        .onAppear {
            if let presentbillHistoryItem = billHistoryItems.first(where: { $0.id == billID }) {
                if let tableNumber {
                    presentbillHistoryItem.tableNumber = tableNumber
                }
                presentbillHistoryItem.items = billItems
                presentbillHistoryItem.waiter = waiter
            } else {
                if let tableNumber {
                    modelContext.insert(BillHistoryItem( id: billID, items: billItems, tableNumber: tableNumber, waiter: waiter))
                }
            }
            // Start generating PDF in background
            generatePDF()
        }
        .onChange(of: billHistoryItems, { oldValue, newValue in
//            let pendingBillsCount = (newValue.filter { $0.paymentStatus == .pending }).count
//            UNUserNotificationCenter.current().setBadgeCount(pendingBillsCount)
        })
    }

    private func generatePDF() {
        guard !isGeneratingPDF else { return }
        isGeneratingPDF = true

        Task {
            let url = await render()
            await MainActor.run {
                pdfURL = url
                isGeneratingPDF = false
            }
        }
    }

    @MainActor func render() async -> URL {
        // 1: Save it to our documents directory
        let url = URL.documentsDirectory.appending(path: "Bill.pdf")

        // 2: PDF size - must match the frame size used in preview
        let pageWidth: CGFloat = 420
        let pageHeight: CGFloat = 595
        var box = CGRect(x: 0, y: 0, width: pageWidth, height: pageHeight)

        // 3: Create the CGContext for our PDF pages
        guard let pdf = CGContext(url as CFURL, mediaBox: &box, nil) else {
            return url
        }

        let groupedArray: [GroupedMenu] = stride(from: 0, to: billItems.count, by: maxItemCount).map { index in
            GroupedMenu(id: index, items: Array(billItems[index ..< min(index + maxItemCount, billItems.count)]))
        }

        // 4: Render each page - use Task.yield() to prevent blocking
        for (index, group) in groupedArray.enumerated() {
            pdf.beginPDFPage(nil)

            let billView = Bill(
                currentMenuItems: group.items,
                tableNumber: tableNumber,
                first: groupedArray.first == group,
                finalTotal: groupedArray.last == group ? billItems.getTotal() : nil
            )
            .frame(width: pageWidth, height: pageHeight)
            .background(Color.white)

            let renderer = ImageRenderer(content: billView)
            // Set scale to 1.0 to match PDF point size exactly
            renderer.scale = 1.0
            // Set proposed size to ensure consistent layout
            renderer.proposedSize = ProposedViewSize(width: pageWidth, height: pageHeight)

            renderer.render { size, context in
                context(pdf)
            }

            pdf.endPDFPage()

            // Yield to allow UI updates between pages
            if index < groupedArray.count - 1 {
                await Task.yield()
            }
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

        return BillPreview(tableNumber: 1, waiter: "Anthony", billID: UUID(), billItems: PreviewData.menuItems)
            .modelContainer(container)
    } catch {
        fatalError("Failed to create model container.")
    }
}
#endif
