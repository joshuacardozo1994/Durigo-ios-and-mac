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

    /// Picker minimum: 5 years ago. The earliest *cached* bill is no longer the
    /// floor — bills are now paginated, so locking to the cache made the filter
    /// shrink to a few weeks. The user can pull older bills in via Bill History.
    private var pickerLowerBound: Date {
        Calendar.current.date(byAdding: .year, value: -5, to: Date()) ?? Date.distantPast
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    DatePicker(
                        "From",
                        selection: $startDate,
                        in: pickerLowerBound...Date(),
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
                        startDate = billHistoryItems.first?.date ?? pickerLowerBound
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
