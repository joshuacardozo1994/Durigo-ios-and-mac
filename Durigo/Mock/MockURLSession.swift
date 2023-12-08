//
//  MockURLSession.swift
//  Durigo
//
//  Created by Joshua Cardozo on 08/12/23.
//

import Foundation

struct MockURLSession {
    
    static func get() -> URLSession {
        // Step 2: Use a custom URLSessionConfiguration
        let configurationWithMock = URLSessionConfiguration.default
        configurationWithMock.protocolClasses?.insert(MockURLProtocol.self, at: 0)
        
        
        // To use for URLSession
        return URLSession(configuration: configurationWithMock)
    }
}
