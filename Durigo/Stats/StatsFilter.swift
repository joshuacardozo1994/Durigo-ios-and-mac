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
    @Query private var billHistoryItems: [BillHistoryItem]
    var body: some View {
        let firstDate = billHistoryItems.map({ $0.date }).min() ?? Date()
        Form {
            Button(action: {
                        startDate = firstDate
                    endDate = Date()
                    }) {
                        HStack {
                            Image(systemName: "arrow.clockwise")

                            Text("Reset")
                                
                        }
                        .fontWeight(.semibold)
                        .padding()
                        .foregroundColor(.white)
                        .background(Color.red)
                        .cornerRadius(8)
                    }
            
        
            Section("FROM") {
                DatePicker(
                        "Start Date",
                        selection: $startDate,
                        in: firstDate...Date(),
                        displayedComponents: [.date, .hourAndMinute]
                    )
                    .datePickerStyle(.graphical)
            }
            Section("To") {
                DatePicker(
                        "Start Date",
                        selection: $endDate,
                        in: startDate...Date(),
                        displayedComponents: [.date, .hourAndMinute]
                    )
                    .datePickerStyle(.graphical)
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
