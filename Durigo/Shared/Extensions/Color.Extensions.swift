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
