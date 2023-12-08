//
//  NetworkHelper.swift
//  Durigo
//
//  Created by Joshua Cardozo on 08/12/23.
//

import Foundation

struct NetworkHelper {
    
    static let shared = NetworkHelper()
    
    private init() {
        if CommandLine.arguments.contains("ui-testing") {
            URLProtocol.registerClass(MockURLProtocol.self)
            do {
                MockURLProtocol.mockData["/api/menu"] = try JSONEncoder().encode(MockDataLoader.loadCategories())
            } catch {
                
            }
        }
    }
    
    var currentSession: URLSession {
        if CommandLine.arguments.contains("ui-testing") {
            // Step 2: Use a custom URLSessionConfiguration
            let configurationWithMock = URLSessionConfiguration.default
            configurationWithMock.protocolClasses?.insert(MockURLProtocol.self, at: 0)

            // To use for URLSession
            return URLSession(configuration: configurationWithMock)
        } else {
            return URLSession.shared
        }
    }
}
