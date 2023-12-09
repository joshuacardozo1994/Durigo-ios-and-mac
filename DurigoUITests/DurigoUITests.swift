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
        app.launchArguments.append("ui-testing")
        app.launch()
        
        // In UI tests it’s important to set the initial state - such as interface orientation - required for your tests before they run. The setUp method is a good place to do this.
    }
    
    override func tearDownWithError() throws {
        print("Check this", app.debugDescription)
        UserDefaults.standard.removePersistentDomain(forName: Bundle.main.bundleIdentifier!)
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }
    
    func testExample() throws {
        // UI tests must launch the application that they test.
        //        let app = XCUIApplication()
        //        app.launch()
        
        // Use XCTAssert and related functions to verify your tests produce the correct results.
    }
    
    func testAddingCustomItem() throws {
        
        // Assert that the "Add custom item" button exists
        let addCustomItemButton = app.buttons["addItemButton"]
        XCTAssertTrue(addCustomItemButton.exists, "The 'Add custom item' button does not exist.")
        
        // Click on the "Add custom item" button
        addCustomItemButton.tap()
        
        let itemsText = app.staticTexts["bill generator items count"]
        XCTAssertTrue(itemsText.exists, "The items count text exists")
        XCTAssertEqual(itemsText.label, "1 Items", "The text is not as expected")
        
        let totalText = app.staticTexts["bill generator items total"]
        XCTAssertTrue(totalText.exists, "The total text exists")
        XCTAssertEqual(totalText.label, "Total: 0", "The text is not as expected")
    }
    
    func testDuplicateBill() throws {
        // Assert that the "Add custom item" button exists
        let addCustomItemButton = app.buttons["addItemButton"]
        XCTAssertTrue(addCustomItemButton.exists, "The 'Add custom item' button does not exist.")
        
        // Click on the "Add custom item" button
        addCustomItemButton.tap()
        
        let menuItemNameTextFieldPredicate = NSPredicate(format: "identifier BEGINSWITH 'menu-item-name-TextField'")
        let menuItemNameTextFieldTextFields = app.textFields.matching(menuItemNameTextFieldPredicate)
        
        let menuItemNameTextField = menuItemNameTextFieldTextFields.firstMatch
                
        let menuItemPriceTextFieldPredicate = NSPredicate(format: "identifier BEGINSWITH 'menu-item-price-TextField'")
        let menuItemPriceTextFieldTextFields = app.textFields.matching(menuItemPriceTextFieldPredicate)
        
        let menuItemPriceTextField = menuItemPriceTextFieldTextFields.firstMatch
        
        
        menuItemNameTextField.tap()
        menuItemNameTextField.typeText("Item 1")
        
        menuItemPriceTextField.tap()
        let price = Int(Date().timeIntervalSince1970)
        menuItemPriceTextField.typeText("\(price)")
        
        
        // Tap the button to open the menu
        let menuButton = app.staticTexts["Table-Selector"]
        if menuButton.exists {
            menuButton.tap()
        }

        // Now, select an option from the menu
        let menuOption = app.buttons["Table-Option-1"]
        if menuOption.waitForExistence(timeout: 5) {
            menuOption.tap()
        }
        
        
        let printBillLink = app.buttons["print-bill"]
        if printBillLink.exists {
            printBillLink.tap()
        }
        
        let backButton = app.navigationBars.buttons.element(boundBy: 0)
        if backButton.exists {
            backButton.tap()
        }
        
        if printBillLink.exists {
            printBillLink.tap()
        }
        
        if backButton.exists {
            backButton.tap()
        }
        
        let historyTabBarItem = app.tabBars.buttons["History"]
        if historyTabBarItem.exists {
            historyTabBarItem.tap()
        }
        
        let billHistoryItemPredicate = NSPredicate(format: "identifier BEGINSWITH 'BillHistoryList-Item'")
        let billHistoryItemTexts = app.staticTexts.matching(billHistoryItemPredicate)
        
        
        var arrPrices: [String] = []
        
        // Iterate through the elements
        for i in 0..<billHistoryItemTexts.count {
            let item = billHistoryItemTexts.element(boundBy: i)
            // Perform actions with item, e.g., print its label
            arrPrices.append(item.label)
        }
        
        XCTAssert(arrPrices.count == Set(arrPrices).count, "Duplicate Entries Present")
        
    }
    
    func testSpellingMistakesInSearch() throws {
        let showMenuButton = app.buttons["showMenuButton"]
        XCTAssertTrue(showMenuButton.exists, "The show menu button does not exist.")
        
        showMenuButton.tap()
        
        let menuItemSearchQueryTextField = app.textFields["menuItemSearchQueryTextField"]
        XCTAssertTrue(menuItemSearchQueryTextField.exists, "The menu item search query textfield exists")
        
        
        //Test for exact match
        menuItemSearchQueryTextField.tap()
        menuItemSearchQueryTextField.typeText("Soda")
        let sodaStaticText = app.staticTexts["menu-item-name-926E11D5-A2F8-4FCE-9252-C5E6D72F13BA"]
        XCTAssertTrue(sodaStaticText.exists, "Soda does not exist")
        
        app.buttons["clearSearchField"].tap()
        
        //test for loose match
        menuItemSearchQueryTextField.tap()
        menuItemSearchQueryTextField.typeText("Sooda")
        XCTAssertTrue(sodaStaticText.exists, "Soda does not exist")
        
        app.buttons["clearSearchField"].tap()
        
        //test for no match
        menuItemSearchQueryTextField.tap()
        menuItemSearchQueryTextField.typeText("Soodaaaa")
        XCTAssertFalse(sodaStaticText.exists, "Soda exists")
        
        app.buttons["clearSearchField"].tap()
        
        //test if quantity gets added
        menuItemSearchQueryTextField.tap()
        menuItemSearchQueryTextField.typeText("4 soda")
        XCTAssertTrue(sodaStaticText.exists, "Soda exists")
        sodaStaticText.tap()
        
        let window = app.windows.firstMatch

        let start = window.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.1))
        let end = window.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.9))

        start.press(forDuration: 0.1, thenDragTo: end)

        XCTAssertEqual(app.staticTexts["menu-item-quantity-Text-926E11D5-A2F8-4FCE-9252-C5E6D72F13BA"].label, "4")
        
        
    }
    
    func testClearBillClearsAllItems() throws {
        app.buttons["addItemButton"].tap()
        
        let textFieldPredicate = NSPredicate(format: "identifier BEGINSWITH 'menu-item-name-TextField'")
        let textField = app.textFields.matching(textFieldPredicate).firstMatch
        textField.tap()
        app.buttons["clearBill"].tap()
        
        let alert = app.alerts.firstMatch
        
        alert.buttons["Clear"].tap()
        
        XCTAssertFalse(textField.exists, "Bill is not cleared")
        
    }
    
    func testCategorySearch() throws {
        app.buttons["showMenuButton"].tap()
        let searchTextField = app.textFields["menuItemSearchQueryTextField"]
        searchTextField.tap()
        searchTextField.typeText("Beverages")
        
        let menuListItemsPredicate = NSPredicate(format: "identifier BEGINSWITH 'menu-item-name'")
        
        let menuListItems = app.staticTexts.matching(menuListItemsPredicate)
        
        XCTAssert(menuListItems.count > 0, "not all items are present")
        
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
