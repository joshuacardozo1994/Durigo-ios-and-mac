//
//  BillHistoryList.swift
//  Durigo
//
//  Created by Joshua Cardozo on 19/11/23.
//

import SwiftUI
import SwiftData

struct BillHistoryList: View {
    @Query(sort: \BillHistoryItem.date, order: .reverse) var billHistoryItems: [BillHistoryItem]
    var body: some View {
        NavigationStack {
            VStack {
                List {
                    ForEach(billHistoryItems) { billHistoryItem in
                        NavigationLink {
                            BillHistory(billHistoryItem: billHistoryItem)
                        } label: {
                            VStack(alignment: .leading) {
                                HStack {
                                    Text("\(billHistoryItem.items.count) items")
                                    Text("Total: \(billHistoryItem.items.getTotal().asCurrencyString() ?? "")")
                                }
                                .bold()
                                Text(billHistoryItem.date.getTimeInFormat(dateStyle: .long, timeStyle: .short))
                                
                            }
                        }
                        
                    }
                }
            }
            .navigationTitle("History")
        }
    }
}

#Preview {
    BillHistoryList()
}
