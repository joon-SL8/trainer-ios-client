import XCTest

final class BluetoothHardwareUnsupportedUITests: XCTestCase {

    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    private func launchApp(withUnsupportedHardware: Bool = false, clearDefaults: Bool = true) {
        let app = XCUIApplication()
        app.launchArguments = ["--uitesting"]
        
        if clearDefaults {
            app.launchArguments.append("--clear-defaults")
        }
        
        if withUnsupportedHardware {
            app.launchArguments.append("--mock-bluetooth-unsupported")
        }
        app.launch()
    }

    private func bypassLogin() {
        let app = XCUIApplication()
        let bypassButton = app.buttons["bypassLoginButton"]
        if bypassButton.waitForExistence(timeout: 10) {
            bypassButton.tap()
        }
        XCTAssertTrue(app.buttons["sessionButton"].waitForExistence(timeout: 10))
    }

    func testUnsupportedHardwareModalAppearance() throws {
        launchApp(withUnsupportedHardware: true)
        bypassLogin()
        
        let app = XCUIApplication()
        
        // 1. Verify Full-screen modal appearance
        print("UI Testing: Waiting for modal...")
        let modalHeader = app.staticTexts["Limited Access Mode"]
        XCTAssertTrue(modalHeader.waitForExistence(timeout: 10), "Modal header 'Limited Access Mode' should exist")
        
        let continueButton = app.buttons["Continue to Limited App"]
        XCTAssertTrue(continueButton.exists, "Continue button should exist")
        continueButton.tap()

        // 2. Verify Session button is visually in warning state (check for exclamation icon)
        XCTAssertTrue(app.images["exclamationmark.triangle.fill"].exists)
    }

    func testModalDoesNotReappearOnSecondLaunch() throws {
        // First launch to set the flag
        launchApp(withUnsupportedHardware: true, clearDefaults: true)
        bypassLogin()

        let app = XCUIApplication()
        if app.buttons["Continue to Limited App"].waitForExistence(timeout: 10) {
            app.buttons["Continue to Limited App"].tap()
        }

        // Second launch without clearing defaults
        launchApp(withUnsupportedHardware: true, clearDefaults: false)
        bypassLogin()

        // Modal should NOT appear
        XCTAssertFalse(app.staticTexts["Limited Access Mode"].exists)
    }
}
