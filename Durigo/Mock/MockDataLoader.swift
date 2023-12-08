//
//  MockDataLoader.swift
//  Durigo
//
//  Created by Joshua Cardozo on 08/12/23.
//

import Foundation

struct MockDataLoader {
    static func loadCategories() -> [Category] {
        guard let url = Bundle.main.url(forResource: "Categories", withExtension: "json") else {
            fatalError("Failed to locate categories.json in bundle.")
        }

        do {
            let data = try Data(contentsOf: url)
            let decoder = JSONDecoder()
            let categories = try decoder.decode([Category].self, from: data)
            return categories
        } catch {
            fatalError("Failed to decode categories.json: \(error)")
        }
    }
    
}
