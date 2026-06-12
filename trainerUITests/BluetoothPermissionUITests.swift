import XCTest

final class BluetoothPermissionUITests: XCTestCase {

    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    private func launchApp(withDeniedBluetooth: Bool = false) {
        let app = XCUIApplication()
        app.launchArguments = ["--uitesting"]
        if withDeniedBluetooth {
            app.launchArguments.append("--mock-bluetooth-denied")
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

    func testBluetoothModalAppearsAutomaticallyWhenDenied() throws {
        launchApp(withDeniedBluetooth: true)
        bypassLogin()
        
        let app = XCUIApplication()
        
        // Modal should appear automatically on MainView
        XCTAssertTrue(app.staticTexts["Bluetooth is Required"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.buttons["Open Settings"].exists)
        XCTAssertTrue(app.buttons["Later"].exists)
    }

    func testBluetoothModalAppearsOnSessionButtonTapWhenDenied() throws {
        launchApp(withDeniedBluetooth: true)
        bypassLogin()
        
        let app = XCUIApplication()
        
        // Dismiss initially
        if app.buttons["Later"].waitForExistence(timeout: 5) {
            app.buttons["Later"].tap()
        }
        
        // Tap session button
        let sessionButton = app.buttons["sessionButton"]
        XCTAssertTrue(sessionButton.exists)
        sessionButton.tap()
        
        // Modal should reappear
        XCTAssertTrue(app.staticTexts["Bluetooth is Required"].waitForExistence(timeout: 5))
    }
}
