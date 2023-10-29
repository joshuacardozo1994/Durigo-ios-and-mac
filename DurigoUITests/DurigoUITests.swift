//
//  DurigoUITests.swift
//  DurigoUITests
//
//  Created by Joshua Cardozo on 27/10/23.
//

import XCTest

final class DurigoUITests: XCTestCase {
    
    let app = XCUIApplication()

    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.

        // In UI tests it is usually best to stop immediately when a failure occurs.
        continueAfterFailure = false
        app.launch()

        // In UI tests it’s important to set the initial state - such as interface orientation - required for your tests before they run. The setUp method is a good place to do this.
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func testExample() throws {
        // UI tests must launch the application that they test.
//        let app = XCUIApplication()
//        app.launch()

        // Use XCTAssert and related functions to verify your tests produce the correct results.
    }
    
    func testAddingCustomItem() throws {
            // Wait for the BillGenerator view to load
            let billGeneratorView = app.otherElements["BillGenerator"]
            let exists = NSPredicate(format: "exists == 1")

            expectation(for: exists, evaluatedWith: billGeneratorView, handler: nil)
            waitForExpectations(timeout: 5, handler: nil)

            // Assert that the "Add custom item" button exists
            let addCustomItemButton = app.buttons["Add custom item"]
            XCTAssertTrue(addCustomItemButton.exists, "The 'Add custom item' button does not exist.")
            
            // Click on the "Add custom item" button
            addCustomItemButton.tap()

            // Optionally, you can add further assertions to check if the item was added successfully
            // For example, you might check if the count of items in the list has increased
        }

    func testLaunchPerformance() throws {
        if #available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 7.0, *) {
            // This measures how long it takes to launch your application.
            measure(metrics: [XCTApplicationLaunchMetric()]) {
                XCUIApplication().launch()
            }
        }
    }
}
