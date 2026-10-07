import Foundation
import Combine
import MessageUI
import libfitness

@MainActor
class CalendarDetailViewModel: ObservableObject {
    @Published var sessionEntries: [libfitness.SessionEntry] = []
    @Published var isLoading: Bool = false
    @Published var isUploading: Bool = false
    @Published var isEmailing: Bool = false
    @Published var emailError: String? = nil
    @Published var showMailComposer: Bool = false
    @Published var showActivityView: Bool = false
    @Published var mailAttachmentData: Data? = nil
    @Published var mailAttachmentFilename: String = "workout.fit"
    @Published var fitFileURLForSharing: URL? = nil
    
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
    
    func emailFitFile() {
        Task {
            await MainActor.run { isEmailing = true }
            do {
                let url = try await SessionUploadService.getOrCreateFitFile(sessionId: session.id, sessionTimestamp: session.sessionDate)
                let data = try Data(contentsOf: url)
                let filename = url.lastPathComponent
                
                await MainActor.run {
                    self.mailAttachmentData = data
                    self.mailAttachmentFilename = filename
                    self.fitFileURLForSharing = url
                    self.isEmailing = false
                    
                    if MFMailComposeViewController.canSendMail() {
                        self.showMailComposer = true
                    } else {
                        self.showActivityView = true
                    }
                }
            } catch {
                await MainActor.run {
                    self.emailError = error.localizedDescription
                    self.isEmailing = false
                }
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
