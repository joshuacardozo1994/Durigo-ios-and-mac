//
//  Models.swift
//  pdf test
//
//  Created by Joshua Cardozo on 14/10/23.
//

import Foundation

struct MenuItem: Identifiable, Equatable {
    var id: Int
    var name: String
    var quantity: Int
    var price: Int
    
}

extension Array where Element == MenuItem {
    func getTotal() -> Int {
      
        self.reduce(0) { partialResult, item in
            return partialResult + (item.price*item.quantity)
        }
    }
}

enum FoodType: Int, Decodable {
    case drinks = 1
    case food = 2
}

struct Category: Decodable, Identifiable {
    struct Dish: Decodable, Identifiable {
        let id: Int
        let name: String
        let price: Int?
        let subtext: String?
    }
    
    let id: Int
    let type: FoodType
    let name: String
    let dishes: [Dish]
    
    static var placeholder: Category {
        let dishes = (1...7).map { _ in Category.Dish(id: Int.random(in: 1...1000), name: "XXXXX", price: Int.random(in: 1...999), subtext: nil) }
        let category = Category(id: Int.random(in: 1...1000), type: .drinks, name: "XXXXXX", dishes: dishes)
        return category
    }
}
