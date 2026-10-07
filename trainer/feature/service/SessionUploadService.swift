import Foundation
import Combine
import libfitness

public enum PublishState {
    case idle
    case packing
    case uploading
    case completed
    case failed(String)
}

public class SessionUploadService: ObservableObject {
    @Published public var publishState: PublishState = .idle
    
    public init() {}
    
    public static func getOrCreateFitFile(sessionId: Int64, sessionTimestamp: Int64) async throws -> URL {
        let input = GetSessionEntryInput(sessionId: sessionId)
        let result = try? await GetSessionEntryUseCase().invoke(input: input) as? GetSessionEntriesResult
        let entries = result?.entries ?? []
        
        let packResult = try await PackDataRowUseCase()
            .invoke(sessionId: sessionId, timestampStart: sessionTimestamp, rows: entries)
            
        guard let dataReady = packResult as? DataUploadReady else {
            throw NSError(domain: "SessionUploadService", code: 2, userInfo: [NSLocalizedDescriptionKey: "Data preparation failed."])
        }
        
        let filename = dataReady.param.filename
        let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        let fileURL = documentsDirectory.appendingPathComponent(filename)
        
        let fitProcessor = IOSFitFileProcessor()
        _ = fitProcessor.loadFitFile(filename: filename)
        
        return fileURL
    }
    
    public func uploadSession(sessionId: Int64, sessionTimestamp: Int64) async throws {
        await MainActor.run { self.publishState = .packing }
        
        // 1. Fetch entries for this session
        let input = GetSessionEntryInput(sessionId: sessionId)
        let result = try? await GetSessionEntryUseCase().invoke(input: input) as? GetSessionEntriesResult
        let entries = result?.entries ?? []

        if entries.isEmpty {
            await MainActor.run { self.publishState = .failed("No session data to upload.") }
            throw NSError(domain: "SessionUploadService", code: 1, userInfo: [NSLocalizedDescriptionKey: "No session data to upload."])
        }
        
        // 2. Invoke PackDataRowUseCase
        let packResult = try await PackDataRowUseCase()
            .invoke(sessionId: sessionId, timestampStart: sessionTimestamp, rows: entries)
            
        guard let dataReady = packResult as? DataUploadReady else {
            await MainActor.run { self.publishState = .failed("Data preparation failed.") }
            throw NSError(domain: "SessionUploadService", code: 2, userInfo: [NSLocalizedDescriptionKey: "Data preparation failed."])
        }

        // Validate FIT file using IOSFitFileProcessor after packing
        let fitProcessor = IOSFitFileProcessor()
        let byteArray = fitProcessor.loadFitFile(filename: dataReady.param.filename)
        print("Validated FIT file \(dataReady.param.filename) with IOSFitFileProcessor: byte array size = \(byteArray.size)")

        // 3. Handle upload
        await MainActor.run { self.publishState = .uploading }

        // PublishSessionActivityUseCase handles the actual Strava upload
        try await PublishSessionActivityUseCase().invoke(
            title: "Indoor Cycling",
            sessionId: sessionId,
            startTime: sessionTimestamp,
            duration: Int64(entries.count * 1000),
            description: "Indoor Cycling Session with Skjline Trainer",
            filename: dataReady.param.filename
        )

        await MainActor.run { self.publishState = .completed }
    }
}
