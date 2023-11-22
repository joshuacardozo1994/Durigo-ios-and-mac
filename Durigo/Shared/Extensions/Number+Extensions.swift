//
//  Number+Extensions.swift
//  Durigo
//
//  Created by Joshua Cardozo on 23/11/23.
//

import Foundation

extension Double {
    func asCurrencyString(locale: Locale = .current) -> String? {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.locale = locale
        return formatter.string(from: NSNumber(value: self))
    }
}

extension Float {
    func asCurrencyString(locale: Locale = .current) -> String? {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.locale = locale
        return formatter.string(from: NSNumber(value: self))
    }
}

extension Int {
    func asCurrencyString(locale: Locale = .current) -> String? {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.locale = locale
        return formatter.string(from: NSNumber(value: self))
    }
}
