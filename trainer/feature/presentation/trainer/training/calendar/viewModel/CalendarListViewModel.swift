import Foundation
import Combine
import libfitness

@MainActor
class CalendarListViewModel: ObservableObject {
    @Published var sessions: [libfitness.Session] = []
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    
    // Publish update event to trigger refresh in parent
    let didUpdateSessions = PassthroughSubject<Void, Never>()

    private var calendar = Calendar.current

    let date: Date
    private let getSessionUseCase = GetSessionUseCase()
    
    // ... (keep init and loadSessions)

    var needsUpload: Bool {
        sessions.contains { SessionStatus.status(for: $0) != .synced }
    }
    
    func uploadAll() {
        Task {
            isLoading = true
            for session in sessions {
                await processSession(session)
            }
            await loadSessions()
            await MainActor.run {
                self.isLoading = false
                self.didUpdateSessions.send()
            }
        }
    }
    
    func processSession(_ session: libfitness.Session) async {
        let status = SessionStatus.status(for: session)
        switch status {
        case .needsProcessing:
            // Implement fit-file generation
            // ... (As per feat/fit-generate branch logic)
            // Then proceed to upload
            await upload(session)
        case .needsUpload:
            await upload(session)
        case .synced:
            break
        }
    }
    
    private func upload(_ session: libfitness.Session) async {
        // Implement strava upload
        // ... (As per feat/fit-generate branch logic)
    }

    init(date: Date) {
        self.date = date
        loadSessions()
    }

    func loadSessions() {
        isLoading = true
        errorMessage = nil

        Task {
             // Fetch sessions for the full week range (inclusive of the entire start and end days)
             let startOfDay = calendar.startOfDay(for: date)
             // Adding 1 day to the last day to get the start of the day after the last day
             let startOfNextDay = calendar.date(byAdding: .day, value: 1, to: calendar.startOfDay(for: date))!
    
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

            let fetchedSessions = await getSessionUseCase.invoke(input: input)
            
            await MainActor.run {
                self.sessions = fetchedSessions
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
