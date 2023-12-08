//
//  DurigoTests.swift
//  DurigoTests
//
//  Created by Joshua Cardozo on 27/10/23.
//

import XCTest

final class DurigoTests: XCTestCase {
    
    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }
    
    func testExample() throws {
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct results.
        // Any test you write for XCTest can be annotated as throws and async.
        // Mark your test throws to produce an unexpected failure when your test encounters an uncaught error.
        // Mark your test async to allow awaiting for asynchronous code to complete. Check the results with assertions afterwards.
    }
    
    func testShouldFilterMenuWithQuery() {
        // Case 1: Exact match
        XCTAssertTrue(Helper.shouldFilterMenuWithQuery(searchQuery: "Pizza", itemName: "Pizza", itemSuffix: nil))

        // Case 2: Item name contains the search string
        XCTAssertTrue(Helper.shouldFilterMenuWithQuery(searchQuery: "Burger", itemName: "Cheeseburger", itemSuffix: nil))

        // Case 3: Item name does not contain the search string
        XCTAssertFalse(Helper.shouldFilterMenuWithQuery(searchQuery: "Pasta", itemName: "Pizza", itemSuffix: nil))

        // Case 4: Similar string within threshold
        XCTAssertTrue(Helper.shouldFilterMenuWithQuery(searchQuery: "CheeseBurgeri", itemName: "CheeseBurger", itemSuffix: nil))

        // Case 5: Similar string but beyond threshold
        XCTAssertFalse(Helper.shouldFilterMenuWithQuery(searchQuery: "CheeseBurger", itemName: "CheeseBur", itemSuffix: nil))

        // Case 6: Suffix matches the search string
        XCTAssertTrue(Helper.shouldFilterMenuWithQuery(searchQuery: "Special", itemName: "Pizza", itemSuffix: "Pizza Special"))

        // Case 7: Neither item name nor suffix match
        XCTAssertFalse(Helper.shouldFilterMenuWithQuery(searchQuery: "Special", itemName: "Burger", itemSuffix: "Burger Deluxe"))

        // Add more test cases to cover different scenarios
    }
    
    func testQuantityAndStringExtraction() {
        // Case 1: "4 sanna"
        var result = Helper.extractNumberAndString(from: "4 sanna")
        XCTAssertEqual(result.0, 4)
        XCTAssertEqual(result.1, "sanna")
        
        // Case 2: "4"
        result = Helper.extractNumberAndString(from: "4")
        XCTAssertEqual(result.0, 4)
        XCTAssertNil(result.1)
        
        // Case 3: "sanna"
        result = Helper.extractNumberAndString(from: "sanna")
        XCTAssertNil(result.0)
        XCTAssertEqual(result.1, "sanna")
        
        // Case 4: "sanna 4"
        result = Helper.extractNumberAndString(from: "sanna 4")
        XCTAssertEqual(result.0, 4)
        XCTAssertEqual(result.1, "sanna")
        
        // Case 5: Empty String
        result = Helper.extractNumberAndString(from: "")
        XCTAssertNil(result.0)
        XCTAssertNil(result.1)
        
        // Add more test cases as needed
        
    }
    
    func testPerformanceExample() throws {
        // This is an example of a performance test case.
        measure {
            // Put the code you want to measure the time of here.
        }
    }
    
}
