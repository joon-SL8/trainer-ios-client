import XCTest

final class LibrarySessionNavigationUITests: XCTestCase {

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
        XCTAssertTrue(app.buttons["sessionButton"].waitForExistence(timeout: 10), "Failed to bypass login and reach MainView")
        
        // Handle potential "Unsupported Hardware" modal
        let dismissButton = app.buttons["Dismiss"]
        if dismissButton.waitForExistence(timeout: 2) {
            dismissButton.tap()
        }
    }

    func testStartSessionFromLibraryDetail() throws {
        bypassLogin()
        let app = XCUIApplication()

        // 1. Navigate to Library
        let libraryButton = app.buttons["libraryButton"]
        XCTAssertTrue(libraryButton.waitForExistence(timeout: 10))
        libraryButton.tap()
        
        // 2. Select a workout file
        // Try to find a cell that contains a file name (not just a directory)
        let anyCell = app.cells.firstMatch
        XCTAssertTrue(anyCell.waitForExistence(timeout: 10), "No items found in library. Debug: \(app.debugDescription)")
        
        // In the mock, let's just tap the first item.
        let workoutName = anyCell.staticTexts.firstMatch.label
        anyCell.tap()
        
        // 3. Verify we are in LibraryDetailView and wait for parsing
        // If it's a directory, we might need to tap again. 
        // For simplicity, let's assume the first tap was a file if we see the detail view elements.
        let startButton = app.buttons["startSessionButton"]
        if !startButton.waitForExistence(timeout: 5) {
            // Maybe we tapped a directory? Try tapping another item inside.
            let subCell = app.cells.firstMatch
            if subCell.waitForExistence(timeout: 5) {
                subCell.tap()
            }
        }
        
        XCTAssertTrue(startButton.waitForExistence(timeout: 10), "Start Session button not found in detail view. Debug: \(app.debugDescription)")
        startButton.tap()
        
        // 5. Verify Sensor Selection Modal appears
        XCTAssertTrue(app.staticTexts["Select Sensor"].waitForExistence(timeout: 5))
        
        // 6. Connect to a mock sensor
        let heartRateButton = app.buttons["H6 Heart Rate, Heart Rate, Discovered"]
        XCTAssertTrue(heartRateButton.waitForExistence(timeout: 10))
        heartRateButton.tap()
        
        // 7. Wait for connection and Start Training button
        XCTAssertTrue(app.buttons["H6 Heart Rate, Heart Rate, Connected"].waitForExistence(timeout: 10))
        let startTrainingButton = app.buttons["startTrainingButton"]
        XCTAssertTrue(startTrainingButton.exists)
        startTrainingButton.tap()
        
        // 8. Verify SessionView is displayed
        XCTAssertTrue(app.staticTexts["Workout Session"].waitForExistence(timeout: 10))
    }
}
