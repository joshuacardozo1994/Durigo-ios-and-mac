//
//  MenuLoader.swift
//  pdf test
//
//  Loads the live menu from the web backend (/api/menu/full) and holds the
//  in-progress bill for the Bill Generator.
//

import SwiftUI

@Observable class MenuLoader: ObservableObject {
    private let urlSession = NetworkHelper.shared.currentSession

    var menu: [Category]?
    var billID = UUID()
    var tableNumber: Int?
    var waiter: String?
    private var _billItems: [MenuItem] = []
    var billItems: [MenuItem] {
        get { _billItems }
        set { _billItems = newValue.filter { $0.quantity > 0 } }
    }

    /// Holds a weak reference to the auth Session so we can read the current
    /// JWT cookie for menu fetches. Set this from views that have @Environment
    /// access (e.g. Home / BillGenerator).
    weak var authSession: Session?

    #if DEBUG
    func loadFromBundle() {
        self.menu = MockDataLoader.loadCategories()
    }
    #endif

    func resetBill() {
        billItems.removeAll()
        tableNumber = nil
        waiter = nil
        billID = UUID()
    }

    @MainActor
    func loadMenu() async {
        let baseString = Config.shared.serverURL.trimmingCharacters(in: CharacterSet(charactersIn: "/"))
        guard let url = URL(string: "\(baseString)/api/menu/full") else { return }
        var request = URLRequest(url: url)
        request.timeoutInterval = 30
        if let token = authSession?.token {
            request.setValue("auth-token=\(token)", forHTTPHeaderField: "Cookie")
        }
        do {
            let (data, response) = try await urlSession.data(for: request)
            if let http = response as? HTTPURLResponse, http.statusCode == 401 {
                authSession?.signOut()
                return
            }
            let decoder = JSONDecoder()
            let menu = try decoder.decode([Category].self, from: data)
            self.menu = menu
        } catch {
            print("MenuLoader.loadMenu error:", error)
        }
    }
}
