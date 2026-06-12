//
//  DeeplinkSimulationUITests.swift
//  mobileUITests
//
//  Created by Gemini on 4/13/26.
//

import XCTest

final class DeeplinkSimulationUITests: XCTestCase {
    let app = XCUIApplication()

    override func setUpWithError() throws {
        continueAfterFailure = false
        app.launchArguments += ["--uitesting", "--clear-defaults"]
    }

    func testSimulationButtonOpensSheet() throws {
        app.launch()

        // 1. Verify Simulation button on LoginView
        let simulateButton = app.buttons["simulateDeeplinkButton"]
        XCTAssertTrue(simulateButton.waitForExistence(timeout: 5))
        simulateButton.tap()

        // 2. Verify Simulation Sheet appears
        let title = app.staticTexts["Deeplink Simulation"]
        XCTAssertTrue(title.waitForExistence(timeout: 5))
        
        let description = app.staticTexts["Select a destination from below"]
        XCTAssertTrue(description.waitForExistence(timeout: 5))

        XCTAssertTrue(app.buttons["Main View"].exists)
        XCTAssertTrue(app.buttons["Session View (Mock)"].exists)
    }

    func testSelectMainFromSheet() throws {
        app.launch()

        // 1. Open simulation sheet
        app.buttons["simulateDeeplinkButton"].tap()
        
        // 2. Select Main View
        app.buttons["Main View"].tap()

        // 3. Verify it goes to Main View
        // WeeklyCalendarView header text is "Calendar"
        XCTAssertTrue(app.staticTexts["Calendar"].waitForExistence(timeout: 10))
        
        // Ensure LoginView is gone
        XCTAssertFalse(app.buttons["simulateDeeplinkButton"].exists)
    }

    func testSelectSessionFromSheet() throws {
        app.launch()

        // 1. Open simulation sheet
        app.buttons["simulateDeeplinkButton"].tap()
        
        // 2. Select Session View (Mock)
        app.buttons["Session View (Mock)"].tap()

        // 3. Verify Session View is visible
        let sessionHeader = app.staticTexts["sessionHeader"]
        XCTAssertTrue(sessionHeader.waitForExistence(timeout: 10))

        // 4. Verify mock indicator (blue dot) is present
        let mockIndicator = app.otherElements["mockIndicator"]
        XCTAssertTrue(mockIndicator.waitForExistence(timeout: 5))
        
        // 5. Verify back button works (going back to Main)
        app.navigationBars.buttons.element(boundBy: 0).tap()
        XCTAssertTrue(app.staticTexts["Calendar"].waitForExistence(timeout: 5))
    }
    
    func testCustomSchemeDeeplink() throws {
        // Test skjline://simulate directly via launch arguments
        app.launchArguments += ["--deeplink", "skjline://simulate"]
        app.launch()
        
        // Verify sheet appears automatically
        let title = app.staticTexts["Deeplink Simulation"]
        XCTAssertTrue(title.waitForExistence(timeout: 5))
    }

    func testCustomSchemeSessionMockDeeplink() throws {
        // Test skjline://session?mock=true directly
        app.launchArguments += ["--deeplink", "skjline://session?mock=true"]
        app.launch()
        
        // Verify Session View with mock indicator
        XCTAssertTrue(app.staticTexts["sessionHeader"].waitForExistence(timeout: 10))
        XCTAssertTrue(app.otherElements["mockIndicator"].waitForExistence(timeout: 5))
    }
}
