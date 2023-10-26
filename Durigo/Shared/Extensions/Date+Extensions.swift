//
//  Date+Extensions.swift
//  pdf test
//
//  Created by Joshua Cardozo on 14/10/23.
//

import Foundation

extension Date {
    func getTimeInFormat(dateStyle: DateFormatter.Style, timeStyle: DateFormatter.Style) -> String {
        let currentDate = Date()

        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_IN")
        formatter.dateStyle = dateStyle
        formatter.timeStyle = timeStyle
        
        return formatter.string(from: currentDate)
    }
}
