//
//  Color.Extensions.swift
//  Durigo
//
//  Created by Joshua Cardozo on 23/11/23.
//

import Foundation
import SwiftUI

extension Color {
    static func tableColor(tableNumber: Int?) -> Color {
        switch tableNumber {
        case 1: return Color.table1
        case 2: return Color.table2
        case 3: return Color.table3
        case 4: return Color.table4
        case 5: return Color.table5
        case 6: return Color.table6
        case 7: return Color.table7
        case 8: return Color.table8
        case 9: return Color.table9
        case 10: return Color.table10
        case 11: return Color.table11
        case 12: return Color.table12
        
        default: return Color.table1
        }
    }
}

extension Color {
    init(hex: UInt, alpha: Double = 1) {
        self.init(
            .sRGB,
            red: Double((hex >> 16) & 0xff) / 255,
            green: Double((hex >> 08) & 0xff) / 255,
            blue: Double((hex >> 00) & 0xff) / 255,
            opacity: alpha
        )
    }
}

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (1, 1, 1, 0)
        }

        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue:  Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}
