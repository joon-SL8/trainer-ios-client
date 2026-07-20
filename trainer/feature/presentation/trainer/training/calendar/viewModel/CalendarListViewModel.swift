import Foundation
import Combine
import libfitness

class CalendarListViewModel: ObservableObject {
    @Published var sessions: [libfitness.Session] = []
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?

    private var calendar = Calendar.current

    let date: Date
    private let getSessionUseCase = GetSessionUseCase()

    init(date: Date) {
        self.date = date
        loadSessions()
    }

    func loadSessions() {
        isLoading = true
        errorMessage = nil

        Task {
            // Implementation calling libfitness database manager
            // Fetch sessions for the full week range (inclusive of the entire start and end days)
            let startOfDay = calendar.startOfDay(for: date)
            // Adding 1 day to the last day to get the start of the day after the last day
            let startOfNextDay = calendar.date(byAdding: .day, value: 1, to: calendar.startOfDay(for: date))!

            let input = GetSessionInfoInput(
                id: nil,
                name: nil,
                dateFrom: KotlinLong(value: Int64(startOfDay.timeIntervalSince1970 * 1000)),
                dateTo: KotlinLong(value: Int64(startOfNextDay.timeIntervalSince1970 * 1000))
            )

            let fetchedSessions = await getSessionUseCase.invoke(input: input)
            
            DispatchQueue.main.async {
                self.sessions = fetchedSessions.sessions
                self.isLoading = false
            }
        }
    }
    
    var dateString: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: date)
    }
}
