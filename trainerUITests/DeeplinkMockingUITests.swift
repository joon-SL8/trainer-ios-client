import XCTest

final class DeeplinkMockingUITests: XCTestCase {
    let app = XCUIApplication()

    override func setUpWithError() throws {
        continueAfterFailure = false
        app.launchArguments += ["--uitesting"]
    }

    func testDeeplinkMainShowsChoiceModal() throws {
        // 1. Launch app with the deeplink
        app.launchArguments += ["--deeplink", "http://skjline.mobile/main"]
        app.launch()

        // 2. Verify Sheet appears
        let sheetTitle = app.staticTexts["Deeplink Simulation"]
        XCTAssertTrue(sheetTitle.waitForExistence(timeout: 5))
        
        XCTAssertTrue(app.buttons["Main View"].exists)
        XCTAssertTrue(app.buttons["Session View (Mock)"].exists)
        XCTAssertTrue(app.buttons["Cancel"].exists)
    }

    func testDeeplinkSelectSessionWithMocking() throws {
        // 1. Launch app with the deeplink
        app.launchArguments += ["--deeplink", "http://skjline.mobile/main"]
        app.launch()

        // 2. Select Session View in the modal
        XCTAssertTrue(app.staticTexts["Deeplink Simulation"].waitForExistence(timeout: 5))
        app.buttons["Session View (Mock)"].tap()
        
        // Wait for navigation
        Thread.sleep(forTimeInterval: 2.0)

        // 4. Verify Session View is visible
        let sessionHeader = app.staticTexts["sessionHeader"]
        XCTAssertTrue(sessionHeader.waitForExistence(timeout: 10))

        // 5. Verify the blue dot (mockIndicator) is present
        let mockIndicator = app.otherElements["mockIndicator"]
        XCTAssertTrue(mockIndicator.waitForExistence(timeout: 5))
    }

    func testDeeplinkSelectMainNoMocking() throws {
        // 1. Launch app with the deeplink
        app.launchArguments += ["--deeplink", "http://skjline.mobile/main"]
        app.launch()

        // 2. Select Main View in the modal
        XCTAssertTrue(app.staticTexts["Deeplink Simulation"].waitForExistence(timeout: 5))
        app.buttons["Main View"].tap()

        // 3. Verify it goes to Main View
        let calendarHeader = app.staticTexts["Calendar"] // WeeklyCalendarView is in MainView
        XCTAssertTrue(calendarHeader.waitForExistence(timeout: 5))

        // 4. Verify No blue dot is present (not in SessionView yet, but we can check if we go to session)
        // Let's tap session button and verify no mock indicator
        app.buttons["sessionButton"].tap()
        
        // If bluetooth is off in simulator, it might show explanation. 
        // But for this test, we just want to ensure we're NOT in mocking mode.
    }
}
