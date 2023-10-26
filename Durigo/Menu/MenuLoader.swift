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

}
