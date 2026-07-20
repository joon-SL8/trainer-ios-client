import Combine
import SwiftUI
import libfitness

class WeeklyCalendarViewModel: ObservableObject {
    @Published var currentWeek: [Date] = []
    @Published var selectedDate: Date = Date()
    @Published var headerTitle: String = ""
    @Published var canNavigateForward: Bool = true
    @Published var canNavigateBackward: Bool = true

    @Published var sessions: [Date: libfitness.Session] = [:]

    private var calendar = Calendar.current
    private let today = Date()
    private let getSessionUseCase = GetSessionUseCase()

    init() {
        calendar.firstWeekday = 1  // Sunday
        Task { await updateWeek(for: today) }
    }

    func updateWeek(for date: Date) async {
        let startOfWeek = calendar.dateComponents(
            [.calendar, .yearForWeekOfYear, .weekOfYear],
            from: date
        ).date!
        var week: [Date] = []
        for i in 0..<7 {
            if let day = calendar.date(
                byAdding: .day,
                value: i,
                to: startOfWeek
            ) {
                week.append(day)
            }
        }
        self.currentWeek = week
        self.selectedDate = date

        await fetchSessions(for: week)

        updateHeaderTitle(for: week[0])
        updateNavigationLimits(for: week[0])
    }

    private func fetchSessions(for week: [Date]) async {
        guard let start = week.first, let end = week.last else { return }

        // Fetch sessions for the full week range (inclusive of the entire start and end days)
        let startOfDay = calendar.startOfDay(for: start)
        // Adding 1 day to the last day to get the start of the day after the last day
        let startOfNextDay = calendar.date(byAdding: .day, value: 1, to: calendar.startOfDay(for: end))!

        let input = GetSessionInfoInput(
            id: nil,
            name: nil,
            dateFrom: KotlinLong(
                value: Int64(startOfDay.timeIntervalSince1970 * 1000)
            ),
            dateTo: KotlinLong(
                value: Int64(startOfNextDay.timeIntervalSince1970 * 1000)
            )
        )

        let fetched = (try! await getSessionUseCase.invoke(input: input)) as! GetSessionResult
        var history: [Date: libfitness.Session] = [:]
        for session in fetched.sessions {
            let epoch = TimeInterval(session.sessionDate) / 1000.0
            let sessionDate = Date(timeIntervalSince1970: epoch)
            let startOfDay = calendar.startOfDay(for: sessionDate)
            
            history[startOfDay] = session
        }
        
        await MainActor.run {
            self.sessions = history
        }
    }

    private func updateHeaderTitle(for date: Date) {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
        self.headerTitle = formatter.string(from: date)
    }

    private func updateNavigationLimits(for startOfWeek: Date) {
        // Limit: 3 months back
        if let threeMonthsAgo = calendar.date(
            byAdding: .month,
            value: -3,
            to: today
        ),
            let startOfThreeMonthsAgo = calendar.dateComponents(
                [.calendar, .yearForWeekOfYear, .weekOfYear],
                from: threeMonthsAgo
            ).date
        {
            self.canNavigateBackward = startOfWeek > startOfThreeMonthsAgo
        }

        // Limit: 2 weeks forward
        if let twoWeeksFromNow = calendar.date(
            byAdding: .weekOfYear,
            value: 2,
            to: today
        ),
            let startOfTwoWeeksFromNow = calendar.dateComponents(
                [.calendar, .yearForWeekOfYear, .weekOfYear],
                from: twoWeeksFromNow
            ).date
        {
            self.canNavigateForward = startOfWeek < startOfTwoWeeksFromNow
        }
    }

    func navigateForward() {
        guard canNavigateForward else { return }
        if let nextWeek = calendar.date(
            byAdding: .weekOfYear,
            value: 1,
            to: currentWeek[0]
        ) {
            Task { await updateWeek(for: nextWeek) }
        }
    }

    func navigateBackward() {
        guard canNavigateBackward else { return }
        if let lastWeek = calendar.date(
            byAdding: .weekOfYear,
            value: -1,
            to: currentWeek[0]
        ) {
            Task { await updateWeek(for: lastWeek) }
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
        let startOfDay = calendar.startOfDay(for: date)
        return sessions[startOfDay] != nil
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
