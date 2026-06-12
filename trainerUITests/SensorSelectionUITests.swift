import XCTest

final class SensorSelectionUITests: XCTestCase {

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
        XCTAssertTrue(app.buttons["sessionButton"].waitForExistence(timeout: 10))
    }

    func testSensorSelectionModalAppearance() throws {
        bypassLogin()
        let app = XCUIApplication()

        // Tap the Session button to trigger the modal
        app.buttons["sessionButton"].tap()

        // Verify modal title
        XCTAssertTrue(app.staticTexts["Select Sensor"].waitForExistence(timeout: 5))
        
        // Verify searching state
        XCTAssertTrue(app.staticTexts["Searching for sensors..."].waitForExistence(timeout: 2))
        
        // Wait for sensors to appear (mocked discovery takes ~5s total)
        XCTAssertTrue(app.buttons["H6 Heart Rate, Heart Rate, Discovered"].waitForExistence(timeout: 10))
        XCTAssertTrue(app.buttons["Kickr Bike, Power, Discovered"].waitForExistence(timeout: 10))
    }

    func testSensorConnectionInteraction() throws {
        bypassLogin()
        let app = XCUIApplication()

        app.buttons["sessionButton"].tap()
        
        // Wait for first sensor
        let heartRateButton = app.buttons["H6 Heart Rate, Heart Rate, Discovered"]
        XCTAssertTrue(heartRateButton.waitForExistence(timeout: 10))
        
        // Tap to connect
        heartRateButton.tap()
        
        // Verify connecting state (button should be disabled or label changed)
        // Note: The button label changes to "H6 Heart Rate, Heart Rate" + ProgressView (no status text)
        XCTAssertTrue(app.staticTexts["H6 Heart Rate"].exists)
        
        // Wait for connected state (3s delay in mock)
        XCTAssertTrue(app.buttons["H6 Heart Rate, Heart Rate, Connected"].waitForExistence(timeout: 10))
    }

    func testStartTrainingButtonAppearsOnlyWhenConnected() throws {
        bypassLogin()
        let app = XCUIApplication()

        app.buttons["sessionButton"].tap()
        
        // Button should not exist initially
        XCTAssertFalse(app.buttons["startTrainingButton"].exists)
        
        // Connect to a sensor
        let heartRateButton = app.buttons["H6 Heart Rate, Heart Rate, Discovered"]
        XCTAssertTrue(heartRateButton.waitForExistence(timeout: 10))
        heartRateButton.tap()
        
        // Wait for connection to complete
        XCTAssertTrue(app.buttons["H6 Heart Rate, Heart Rate, Connected"].waitForExistence(timeout: 10))
        
        // Button should now appear
        XCTAssertTrue(app.buttons["startTrainingButton"].exists)
    }
    
    func testNavigationToSessionView() throws {
        bypassLogin()
        let app = XCUIApplication()

        app.buttons["sessionButton"].tap()
        
        let heartRateButton = app.buttons["H6 Heart Rate, Heart Rate, Discovered"]
        XCTAssertTrue(heartRateButton.waitForExistence(timeout: 10))
        heartRateButton.tap()
        XCTAssertTrue(app.buttons["startTrainingButton"].waitForExistence(timeout: 10))
        
        // Navigate to Session
        app.buttons["startTrainingButton"].tap()
        
        // Verify SessionView is displayed (Wait for transition)
        XCTAssertTrue(app.staticTexts["Session"].waitForExistence(timeout: 10))
        
        // Verify indicator exists
        XCTAssertTrue(app.otherElements["sensorIndicator_H6_Heart_Rate"].exists)
    }
    
    func testSensorDisconnectionInSession() throws {
        bypassLogin()
        let app = XCUIApplication()

        app.buttons["sessionButton"].tap()
        let heartRateButton = app.buttons["H6 Heart Rate, Heart Rate, Discovered"]
        XCTAssertTrue(heartRateButton.waitForExistence(timeout: 10))
        heartRateButton.tap()
        XCTAssertTrue(app.buttons["startTrainingButton"].waitForExistence(timeout: 10))
        app.buttons["startTrainingButton"].tap()
        
        XCTAssertTrue(app.staticTexts["Session"].waitForExistence(timeout: 5))
        
        let indicator = app.otherElements["sensorIndicator_H6_Heart_Rate"]
        XCTAssertTrue(indicator.exists)
        
        // Tap to simulate disconnection
        indicator.tap()
        
        // Verify alert appears
        XCTAssertTrue(app.alerts["Sensor Disconnected"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.alerts["Sensor Disconnected"].staticTexts["H6 Heart Rate has been disconnected."].exists)
        
        // Dismiss alert
        app.alerts["Sensor Disconnected"].buttons["OK"].tap()
        
        // Verify exclamation mark or greyed out state (Accessibility identifier might still be there)
        XCTAssertTrue(indicator.exists)
        // In a real test, we might check for the Image existence if it has an ID
        XCTAssertTrue(app.images["exclamationmark.triangle.fill"].exists)
    }

    func testCloseModal() throws {
        bypassLogin()
        let app = XCUIApplication()

        app.buttons["sessionButton"].tap()
        XCTAssertTrue(app.staticTexts["Select Sensor"].waitForExistence(timeout: 5))
        
        let closeButton = app.buttons["xmark"]
        if closeButton.exists {
            closeButton.tap()
        } else {
            app.navigationBars.buttons.element(boundBy: 0).tap()
        }

        // Verify we are back on MainView
        XCTAssertTrue(app.buttons["sessionButton"].waitForExistence(timeout: 5))
    }
}
