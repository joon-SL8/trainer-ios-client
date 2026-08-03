import Foundation
import Combine
import libfitness

@MainActor
class CalendarDetailViewModel: ObservableObject {
    @Published var sessionEntries: [libfitness.SessionEntry] = []
    @Published var isLoading: Bool = false
    @Published var isUploading: Bool = false
    
    let session: libfitness.Session
    private let getSessionEntryUseCase = GetSessionEntryUseCase()
    private let analysis = libfitness.Analysis()
    
    var needsUpload: Bool {
        SessionStatus.status(for: session) != .synced
    }

    private var powerList: [KotlinDouble] {
        sessionEntries.map { KotlinDouble(value: Double($0.power)) }
    }
    
    var tss: Double? {
        guard sessionEntries.count > 30 else { return nil }
        return analysis.calculateTssForPowerList(powers: powerList, durationSeconds: Int64(powerList.count))
    }

    var np: Double? {
        guard sessionEntries.count > 30 else { return nil }
        return analysis.normalizedPower(power: powerList)
    }
    
    init(session: libfitness.Session) {
        self.session = session
        loadEntries()
    }
    
    func upload() {
        Task {
            await MainActor.run { isUploading = true }
            
            do {
                try await SessionUploadService().uploadSession(sessionId: session.id, sessionTimestamp: session.sessionDate)
                
                await MainActor.run { isUploading = false }
            } catch {
                // Handle error
                print("Error uploading session: \(error)")
                await MainActor.run { isUploading = false }
            }
        }
    }
    
    func loadEntries() {
        isLoading = true
        
        Task {
            let input = GetSessionEntryInput(sessionId: session.id)
            let result = try? await GetSessionEntryUseCase().invoke(input: input) as? GetSessionEntriesResult
            if (result != nil && result!.entries.count > 0) {
                DispatchQueue.main.async {
                    self.sessionEntries = result?.entries ?? []
                    self.isLoading = false
                }
            }
        }
    }
}
