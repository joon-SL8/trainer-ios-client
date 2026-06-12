import XCTest
@testable import mobile

final class WeeklyCalendarViewModelTests: XCTestCase {
    var viewModel: WeeklyCalendarViewModel!
    let calendar = Calendar.current
    let today = Date()

    override func setUp() {
        super.setUp()
        viewModel = WeeklyCalendarViewModel()
    }

    override func tearDown() {
        viewModel = nil
        super.tearDown()
    }

    func testInitialWeekContainsToday() {
        let todayStartOfDay = calendar.startOfDay(for: today)
        let containsToday = viewModel.currentWeek.contains { date in
            calendar.isDate(date, inSameDayAs: todayStartOfDay)
        }
        XCTAssertTrue(containsToday, "The current week should contain today upon initialization")
    }

    func testWeekStartsOnSunday() {
        let firstDay = viewModel.currentWeek[0]
        let weekday = calendar.component(.weekday, from: firstDay)
        XCTAssertEqual(weekday, 1, "The first day of the week should be Sunday (1)")
    }

    func testWeekHasSevenDays() {
        XCTAssertEqual(viewModel.currentWeek.count, 7, "The week should have exactly 7 days")
    }

    func testNavigateForward() {
        let initialStartOfWeek = viewModel.currentWeek[0]
        viewModel.navigateForward()
        let nextStartOfWeek = viewModel.currentWeek[0]
        
        let expectedNextWeekStart = calendar.date(byAdding: .weekOfYear, value: 1, to: initialStartOfWeek)!
        XCTAssertEqual(calendar.startOfDay(for: nextStartOfWeek), calendar.startOfDay(for: expectedNextWeekStart))
    }

    func testNavigateBackward() {
        let initialStartOfWeek = viewModel.currentWeek[0]
        viewModel.navigateBackward()
        let lastStartOfWeek = viewModel.currentWeek[0]
        
        let expectedLastWeekStart = calendar.date(byAdding: .weekOfYear, value: -1, to: initialStartOfWeek)!
        XCTAssertEqual(calendar.startOfDay(for: lastStartOfWeek), calendar.startOfDay(for: expectedLastWeekStart))
    }

    func testForwardNavigationLimit() {
        // Navigate 2 weeks forward
        viewModel.navigateForward()
        viewModel.navigateForward()
        XCTAssertFalse(viewModel.canNavigateForward, "Should not be able to navigate more than 2 weeks forward")
        
        let lastWeekStart = viewModel.currentWeek[0]
        viewModel.navigateForward()
        XCTAssertEqual(viewModel.currentWeek[0], lastWeekStart, "Week should not change when limit is reached")
    }

    func testBackwardNavigationLimit() {
        // Navigate back 13 weeks (approx 3 months)
        for _ in 0..<13 {
            viewModel.navigateBackward()
        }
        XCTAssertFalse(viewModel.canNavigateBackward, "Should not be able to navigate more than 3 months back")
        
        let lastWeekStart = viewModel.currentWeek[0]
        viewModel.navigateBackward()
        XCTAssertEqual(viewModel.currentWeek[0], lastWeekStart, "Week should not change when limit is reached")
    }

    func testIsToday() {
        XCTAssertTrue(viewModel.isToday(today))
        if let yesterday = calendar.date(byAdding: .day, value: -1, to: today) {
            XCTAssertFalse(viewModel.isToday(yesterday))
        }
    }

    func testIsFuture() {
        if let tomorrow = calendar.date(byAdding: .day, value: 1, to: today) {
            XCTAssertTrue(viewModel.isFuture(tomorrow))
        }
        XCTAssertFalse(viewModel.isFuture(today))
        if let yesterday = calendar.date(byAdding: .day, value: -1, to: today) {
            XCTAssertFalse(viewModel.isFuture(yesterday))
        }
    }

    func testIsPast() {
        if let yesterday = calendar.date(byAdding: .day, value: -1, to: today) {
            XCTAssertTrue(viewModel.isPast(yesterday))
        }
        XCTAssertFalse(viewModel.isPast(today))
        if let tomorrow = calendar.date(byAdding: .day, value: 1, to: today) {
            XCTAssertFalse(viewModel.isPast(tomorrow))
        }
    }
}
