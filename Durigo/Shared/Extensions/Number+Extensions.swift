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
    
    func formatNumberWithFraction() -> String {
        let integerPart = Int(self)
        let fractionalPart = self - Double(integerPart)

        if fractionalPart == 0.5 {
            return integerPart == 0 ? "½" : "\(integerPart)½"
        } else {
            return "\(integerPart)"
        }
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
