import SwiftUI
import Combine

class WeeklyCalendarViewModel: ObservableObject {
    @Published var currentWeek: [Date] = []
    @Published var selectedDate: Date = Date()
    @Published var headerTitle: String = ""
    @Published var canNavigateForward: Bool = true
    @Published var canNavigateBackward: Bool = true

    private var calendar = Calendar.current
    private let today = Date()

    init() {
        calendar.firstWeekday = 1 // Sunday
        updateWeek(for: today)
    }

    func updateWeek(for date: Date) {
        let startOfWeek = calendar.dateComponents([.calendar, .yearForWeekOfYear, .weekOfYear], from: date).date!
        var week: [Date] = []
        for i in 0..<7 {
            if let day = calendar.date(byAdding: .day, value: i, to: startOfWeek) {
                week.append(day)
            }
        }
        self.currentWeek = week
        self.selectedDate = date
        updateHeaderTitle(for: week[0])
        updateNavigationLimits(for: week[0])
    }

    private func updateHeaderTitle(for date: Date) {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
        self.headerTitle = formatter.string(from: date)
    }

    private func updateNavigationLimits(for startOfWeek: Date) {
        // Limit: 3 months back
        if let threeMonthsAgo = calendar.date(byAdding: .month, value: -3, to: today),
           let startOfThreeMonthsAgo = calendar.dateComponents([.calendar, .yearForWeekOfYear, .weekOfYear], from: threeMonthsAgo).date {
            self.canNavigateBackward = startOfWeek > startOfThreeMonthsAgo
        }

        // Limit: 2 weeks forward
        if let twoWeeksFromNow = calendar.date(byAdding: .weekOfYear, value: 2, to: today),
           let startOfTwoWeeksFromNow = calendar.dateComponents([.calendar, .yearForWeekOfYear, .weekOfYear], from: twoWeeksFromNow).date {
            self.canNavigateForward = startOfWeek < startOfTwoWeeksFromNow
        }
    }

    func navigateForward() {
        guard canNavigateForward else { return }
        if let nextWeek = calendar.date(byAdding: .weekOfYear, value: 1, to: currentWeek[0]) {
            updateWeek(for: nextWeek)
        }
    }

    func navigateBackward() {
        guard canNavigateBackward else { return }
        if let lastWeek = calendar.date(byAdding: .weekOfYear, value: -1, to: currentWeek[0]) {
            updateWeek(for: lastWeek)
        }
    }

    func isToday(_ date: Date) -> Bool {
        calendar.isDate(date, inSameDayAs: today)
    }

    func isFuture(_ date: Date) -> Bool {
        date > calendar.startOfDay(for: today) && !isToday(date)
    }

    func isPast(_ date: Date) -> Bool {
        date < calendar.startOfDay(for: today)
    }

    func hasActivity(on date: Date) -> Bool {
        // Placeholder logic: Monday, Wednesday, Friday have activities
        let weekday = calendar.component(.weekday, from: date)
        return [2, 4, 6].contains(weekday) && !isFuture(date)
    }

    func dayAbbreviation(for date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEE"
        return formatter.string(from: date).uppercased()
    }

    func dayNumber(for date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "d"
        return formatter.string(from: date)
    }
}
