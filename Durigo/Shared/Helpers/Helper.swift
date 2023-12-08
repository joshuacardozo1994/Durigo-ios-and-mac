//
//  Helper.swift
//  Durigo
//
//  Created by Joshua Cardozo on 07/12/23.
//

import Foundation

struct Helper {
    private static func levenshteinDistance(a: String, b: String) -> Int {
        let aCount = a.count
        let bCount = b.count
        var matrix = Array(repeating: Array(repeating: 0, count: bCount + 1), count: aCount + 1)
    
        for i in 0...aCount {
            matrix[i][0] = i
        }
    
        for j in 0...bCount {
            matrix[0][j] = j
        }
    
        for i in 1...aCount {
            for j in 1...bCount {
                let cost = a[a.index(a.startIndex, offsetBy: i - 1)] ==
                           b[b.index(b.startIndex, offsetBy: j - 1)] ? 0 : 1
                matrix[i][j] = min(
                    matrix[i - 1][j] + 1,      // Deletion
                    matrix[i][j - 1] + 1,      // Insertion
                    matrix[i - 1][j - 1] + cost // Substitution
                )
            }
        }
    
        return matrix[aCount][bCount]
    }
    
    private static func areStringsSimilar(a: String, b: String, threshold: Int = 2) -> Bool {
        return levenshteinDistance(a: a, b: b) <= threshold
    }
    
    static func extractNumberAndString(from input: String) -> (Int?, String?) {
        let regex = try! NSRegularExpression(pattern: "(\\d+)|(\\D+)")
        let nsString = input as NSString
        let results = regex.matches(in: input, range: NSRange(location: 0, length: nsString.length))

        var number: Int?
        var string: String?

        for match in results {
            let numberRange = match.range(at: 1)
            if numberRange.location != NSNotFound {
                number = Int(nsString.substring(with: numberRange))
                continue
            }

            let stringRange = match.range(at: 2)
            if stringRange.location != NSNotFound {
                string = (string ?? "") + nsString.substring(with: stringRange).trimmingCharacters(in: .whitespaces)
            }
        }

        return (number, string)
    }
    
    static func shouldFilterMenuWithQuery(searchQuery: String, itemName: String, itemSuffix: String?) -> Bool {
        let (_, searchString) = Helper.extractNumberAndString(from: searchQuery.lowercased())
        if let searchString, searchString.count > 1 {
            
            let present = itemName.lowercased().contains(searchString) || Helper.areStringsSimilar(a: itemName.lowercased(), b: searchString)
            if let suffix = itemSuffix {
                return present || suffix.lowercased().contains(searchString) || Helper.areStringsSimilar(a: suffix.lowercased(), b: searchString)
            }
            return present
        } else {
            return false
        }
    }
}
