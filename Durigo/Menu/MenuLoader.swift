//
//  MenuLoader.swift
//  pdf test
//
//  Created by Joshua Cardozo on 15/10/23.
//

import SwiftUI


@Observable class MenuLoader: ObservableObject {
    private let session = URLSession.shared
    
    var menu: [Category]?
    var billID = UUID()
    var tableNumber: Int?
    private var _billItems: [MenuItem] = [MenuItem]()
    var billItems: [MenuItem] {
            get {
                return _billItems
            }
            set {
                _billItems = newValue.filter({ $0.quantity > 0 })
            }
        }
    
    func resetBill() {
        billItems.removeAll()
        tableNumber = 0
        billID = UUID()
    }

    @MainActor
    func loadMenu() async {
        do {
            let (data, _) = try await session.data(from: URL(string: "https://durigo.in/api/menu")!)
            let decoder = JSONDecoder()
            let menu = try decoder.decode([Category].self, from: data)
            self.menu = menu
        } catch {
            print("error", error, #file, #function, #line)
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
            print("error", #file, #function, #line)
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
            print("error", #file, #function, #line)
        }
        
    }

}
