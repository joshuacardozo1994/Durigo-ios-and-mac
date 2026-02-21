//
//  StatsFilter.swift
//  Durigo
//
//  Created by Joshua Cardozo on 21/01/24.
//

import SwiftUI
import SwiftData

struct StatsFilter: View {
    @Binding var startDate: Date
    @Binding var endDate: Date
    @Query(sort: \BillHistoryItem.date, order: .forward) private var billHistoryItems: [BillHistoryItem]
    var body: some View {
        let firstDate = billHistoryItems.first?.date ?? Date()
        NavigationStack {
            Form {
                Section {
                    DatePicker(
                        "From",
                        selection: $startDate,
                        in: firstDate...Date(),
                        displayedComponents: [.date, .hourAndMinute]
                    )
                    .datePickerStyle(.graphical)
                }
                
                Section {
                    DatePicker(
                        "To",
                        selection: $endDate,
                        in: startDate...Date(),
                        displayedComponents: [.date, .hourAndMinute]
                    )
                    .datePickerStyle(.graphical)
                }
            }
            .navigationTitle("Filter")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Reset") {
                        startDate = firstDate
                        endDate = Date()
                    }
                    .foregroundStyle(.red)
                }
            }
        }
    }
}

#Preview {
    #if DEBUG
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: BillHistoryItem.self, configurations: config)
    
    PreviewData.billHistoryItems.forEach { billHistoryItem in
        container.mainContext.insert(billHistoryItem)
    }
    #endif
    return StatsFilter(startDate: .constant(Date()), endDate: .constant(Date()))
#if DEBUG
        .modelContainer(container)
#endif
}
