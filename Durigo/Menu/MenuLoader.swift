//
//  MenuLoader.swift
//  pdf test
//
//  Created by Joshua Cardozo on 15/10/23.
//

import SwiftUI


class MenuLoader: ObservableObject {
    private let session = URLSession.shared
    
    @Published var menu: [Category]?
    
    @Published private var _billItems: [MenuItem] = [MenuItem]()
    var billItems: [MenuItem] {
            get {
                return _billItems
            }
            set {
                _billItems = newValue.filter({ $0.quantity > 0 })
            }
        }

    @MainActor
    func loadMenu() async {
        do {
            let (data, _) = try await session.data(from: URL(string: "https://durigo.in/api/menu")!)
            let decoder = JSONDecoder()
            let menu = try decoder.decode([Category].self, from: data)
            self.menu = menu
        } catch {
            print("error")
        }
        
    }
    
    @MainActor
    func loadServerMenu() async {
        enum CategoryType: String, Decodable {
            case food
            case drinks
        }
        struct Category: Decodable {
            let name: String
            let id: UUID
            let type: CategoryType
            let description: String?
        }
        do {
            let (data, _) = try await session.data(from: URL(string: "http://localhost:8080/categories")!)
            let decoder = JSONDecoder()
            let menu = try decoder.decode([Category].self, from: data)
            print("menu", menu)
        } catch {
            print("error")
        }
        
    }
    
    @MainActor
    func addCategory() async {
        enum CategoryType: String, Decodable {
            case food
            case drinks
        }
        struct Category: Decodable {
            let name: String
            let id: UUID
            let type: CategoryType
            let description: String?
        }
        do {
            let (data, _) = try await session.data(from: URL(string: "http://localhost:8080/categories")!)
            let decoder = JSONDecoder()
            let menu = try decoder.decode([Category].self, from: data)
            print("menu", menu)
        } catch {
            print("error")
        }
        
    }

}
