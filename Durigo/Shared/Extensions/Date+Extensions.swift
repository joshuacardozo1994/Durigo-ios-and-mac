//
//  Date+Extensions.swift
//  pdf test
//
//  Created by Joshua Cardozo on 14/10/23.
//

import Foundation

extension Date {
    func getTimeInFormat(dateStyle: DateFormatter.Style, timeStyle: DateFormatter.Style) -> String {

        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_IN")
        formatter.dateStyle = dateStyle
        formatter.timeStyle = timeStyle
        
        return formatter.string(from: self)
    }
}

extension Date {
    
    private func isTimeBetween12AMAnd6AM() -> Bool {
        let calendar = Calendar.current
        
        // Extract the hour component from the date
        let hour = calendar.component(.hour, from: Date())
        
        // Check if the hour is between 0 and 3 (0 is 12 AM, and 3 is 3 AM)
        return hour >= 0 && hour < 6
    }
    
    private func isDateBetween11AMAndNow(date: Date, yesterday: Bool) -> Bool {
        let calendar = Calendar.current

        // Get the current date and time
        let now = Date()
        
        // Calculate day's date
        guard let day = calendar.date(byAdding: .day, value: yesterday ? -1 : 0, to: now) else { return false }
        
        // Set day's date to 11 AM
        var components = calendar.dateComponents([.year, .month, .day], from: day)
        components.hour = 11
        components.minute = 0
        components.second = 0
        guard let day11AM = calendar.date(from: components) else { return false }

        // Check if the given date is between yesterday at 11 AM and now
        return date >= day11AM && date <= now
    }
    
    func isBetweenOperatingHoursToday() -> Bool {
        return isDateBetween11AMAndNow(date: self, yesterday: isTimeBetween12AMAnd6AM())
    }
}
