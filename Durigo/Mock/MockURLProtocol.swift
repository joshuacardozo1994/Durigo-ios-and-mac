//
//  File.swift
//  Durigo
//
//  Created by Joshua Cardozo on 08/12/23.
//

import Foundation

class MockURLProtocol: URLProtocol {

    // A dictionary of mock data, where keys are URL path eg. "/weather?country=SG"
    static var mockData = [String: Data]()

    override class func canInit(with task: URLSessionTask) -> Bool {
        return true
    }

    override class func canInit(with request: URLRequest) -> Bool {
        return true
    }

    override class func canonicalRequest(for request: URLRequest) -> URLRequest {
        return request
    }

    override func startLoading() {
        if let url = request.url {
            let path: String
            if let queryString = url.query {
                path = url.relativePath + "?" + queryString
            } else {
                path = url.relativePath
            }
            let data = MockURLProtocol.mockData[path]!
            client?.urlProtocol(self, didLoad: data)
            client?.urlProtocol(self, didReceive: HTTPURLResponse(), cacheStoragePolicy: .allowed)
        }
        client?.urlProtocolDidFinishLoading(self)
    }

    override func stopLoading() {}

}
