//
//  MainViewNavigationUITests 2.swift
//  mobile
//
//  Created by Joon Lee on 11/27/25.
//

import XCTest

final class MainViewNavigationUITests: XCTestCase {

    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.

        // In UI tests it is usually best to stop immediately when a failure occurs.
        continueAfterFailure = false

        // In UI tests it’s important to make sure the tests run in a clean state,
        // without leaving "stuff" over from previous runs.
        let app = XCUIApplication()
        app.launchArguments = ["--uitesting"] // Custom launch argument for UI testing
        app.launch()
    }

    private func bypassLogin() {
        let app = XCUIApplication()
        let bypassButton = app.buttons["bypassLoginButton"]
        if bypassButton.waitForExistence(timeout: 10) {
            // Small delay to ensure the button is ready to be tapped
            Thread.sleep(forTimeInterval: 1.0)
            bypassButton.tap()
        }
        
        // Wait for MainView to appear by checking for Session button
        XCTAssertTrue(app.buttons["sessionButton"].waitForExistence(timeout: 10), "Failed to bypass login and reach MainView")
    }

    func testExample() throws {
        // UI tests must launch the application that they test.
        // Handled in setUpWithError()
    }

    func testSessionButtonNavigatesToSessionView() throws {
        bypassLogin()
        let app = XCUIApplication()

        // Tap the Session button
        app.buttons["sessionButton"].tap()

        // Verify that the SessionView is displayed by checking for its title
        XCTAssertTrue(app.staticTexts["Session"].waitForExistence(timeout: 10))
    }

    func testCalendarButtonNavigatesToCalendarView() throws {
        bypassLogin()
        let app = XCUIApplication()

        // Tap the Calendar button
        app.buttons["calendarButton"].tap()

        // Verify that the CalendarView is displayed by checking for its title
        XCTAssertTrue(app.staticTexts["Calendar"].waitForExistence(timeout: 10))
    }

    func testLibraryButtonNavigatesToLibraryView() throws {
        bypassLogin()
        let app = XCUIApplication()

        // Tap the Library button
        XCTAssertTrue(app.buttons["libraryButton"].waitForExistence(timeout: 10))
        app.buttons["libraryButton"].tap()

        // Verify that the LibraryView is displayed by checking for its title
        XCTAssertTrue(app.staticTexts["Library"].waitForExistence(timeout: 10))
    }

    func testDeeplinkToSession() throws {
        let app = XCUIApplication()
        app.launchArguments = ["--uitesting", "--deeplink", "http://skjline.mobile/session"]
        app.launch()
        
        // App should be launched and showing the LoginView (since it's not authenticated)
        bypassLogin()
        
        // Give the app time to process the stored deeplink after login
        Thread.sleep(forTimeInterval: 5.0)
        
        // Wait for Session view to appear (activeDeeplink should have triggered it)
        XCTAssertTrue(app.staticTexts["Session"].waitForExistence(timeout: 20))
    }

    func testDeeplinkToCalendar() throws {
        let app = XCUIApplication()
        app.launchArguments = ["--uitesting", "--deeplink", "http://skjline.mobile/calendar"]
        app.launch()
        
        bypassLogin()
        
        Thread.sleep(forTimeInterval: 5.0)
        
        XCTAssertTrue(app.staticTexts["Calendar"].waitForExistence(timeout: 20))
    }

    func testDeeplinkToLibrary() throws {
        let app = XCUIApplication()
        app.launchArguments = ["--uitesting", "--deeplink", "http://skjline.mobile/library"]
        app.launch()
        
        bypassLogin()
        
        Thread.sleep(forTimeInterval: 5.0)
        
        XCTAssertTrue(app.staticTexts["Library"].waitForExistence(timeout: 20))
    }
}
