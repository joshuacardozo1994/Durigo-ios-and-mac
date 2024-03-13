//
//  MenuLoader.swift
//  pdf test
//
//  Created by Joshua Cardozo on 15/10/23.
//

import SwiftUI


@Observable class MenuLoader: ObservableObject {
    private let session = NetworkHelper.shared.currentSession
    
    var menu: [Category]?
    var billID = UUID()
    var tableNumber: Int?
    var waiter: String?
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
        tableNumber = nil
        waiter = nil
        billID = UUID()
    }

    @MainActor
    func loadMenu() async {
        guard var components = URLComponents(string: Config.shared.serverURL) else { return }
        components.path = "/api/categories"
        guard let url = components.url else { return }
        print("url", url)
        do {
            let (data, _) = try await session.data(from: url)
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
            let _ = try decoder.decode([Category].self, from: data)
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
            let _ = try decoder.decode([Category].self, from: data)
        } catch {
            print("error", #file, #function, #line)
        }
        
    }

}
