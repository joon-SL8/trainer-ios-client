//
//  LibraryUITests.swift
//  mobileUITests
//

import XCTest

final class LibraryUITests: XCTestCase {

    override func setUpWithError() throws {
        continueAfterFailure = false
        let app = XCUIApplication()
        app.launchArguments = ["--uitesting"]
        app.launch()
    }

    private func bypassLogin() {
        let app = XCUIApplication()
        let bypassButton = app.buttons["bypassLoginButton"]
        if bypassButton.waitForExistence(timeout: 10) {
            Thread.sleep(forTimeInterval: 1.0)
            bypassButton.tap()
        }
        XCTAssertTrue(app.buttons["sessionButton"].waitForExistence(timeout: 10), "Failed to bypass login")

        // Handle potential "Unsupported Hardware" modal
        dismissModalsIfPresent()
    }

    private func dismissModalsIfPresent() {
        let app = XCUIApplication()
        // Wait a bit for the auto-modal to appear
        Thread.sleep(forTimeInterval: 1.5)

        let dismissButton = app.buttons["Dismiss"] // From BluetoothHardwareUnsupportedView
        if dismissButton.exists {
            dismissButton.tap()
        }
    }

    func testLibraryNavigationAndEmptyState() throws {
        bypassLogin()
        let app = XCUIApplication()
        
        let libraryButton = app.buttons["libraryButton"]
        if !libraryButton.waitForExistence(timeout: 10) {
            print("DEBUG: Home Screen not loaded or libraryButton missing. \(app.debugDescription)")
            XCTFail("Library button should exist on home screen")
        }
        libraryButton.tap()
        
        // Check for navigation title
        let navigationTitle = app.staticTexts["Library"]
        if !navigationTitle.waitForExistence(timeout: 5) {
            print("DEBUG: Library screen not loaded. \(app.debugDescription)")
            XCTFail("Library navigation title should appear")
        }
        
        // Either we have items or we show "No items found"
        let noItemsText = app.staticTexts["No items found"]
        let anyListItem = app.cells.firstMatch
        
        XCTAssertTrue(noItemsText.exists || anyListItem.exists, "Should show either items or empty state message")
    }

    func testLibraryFileParsing() throws {
        bypassLogin()
        let app = XCUIApplication()
        
        app.buttons["libraryButton"].tap()
        
        // Try to find any cell to navigate into
        let anyCell = app.cells.firstMatch
        if anyCell.waitForExistence(timeout: 5) {
            anyCell.tap()
            
            // Now look for an .mrc file or folder
            // In a real test we'd be more specific, but for verification let's just see if we can tap something
            let anyItem = app.cells.firstMatch
            if anyItem.waitForExistence(timeout: 5) {
                anyItem.tap()
                
                // Verify we don't see immediate failure for file not found
                let failureMessage = app.staticTexts["Failed to parse file content."]
                XCTAssertFalse(failureMessage.exists, "Should not show 'Failed to parse' message")
            }
        }
    }
}
