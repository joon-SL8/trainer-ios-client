import Foundation
import libfitness

public struct UpdateSessionUseCase {
    public init() {}
    
    public func invoke(session: libfitness.Session) async -> Int64 {
        // Implementation calling libfitness database manager
        let input = InsertSessionInfoInput(data: session)
        let result = try? await libfitness.UpdateSessionUseCase().invoke(input: input) as? UpdateSessionResult
        return Int64(result?.id ?? 0)
    }
}

public struct GetSessionUseCase {
    public init() {}
    
    public func invoke(input: GetSessionInfoInput) async -> [libfitness.Session] {
        do {
            let result = try await libfitness.GetSessionUseCase().invoke(input: input) as? GetSessionResult
            return result?.sessions ?? []
        } catch {
            print("Error fetching sessions: \(error)")
            return []
        }
    }
}

public struct UpdateSessionEntryUseCase {
    public init() {}
    public func invoke(entry: libfitness.SessionEntry) async {
        // Implementation calling libfitness database manager
        let input = InsertSessionEntryInput(data: entry)
        try? await libfitness.UpdateSessionEntryUseCase().invoke(input: input) as? UpdateSessionResult
    }
}

public struct PackDataRowUseCase {
    public init() {}
    public func invoke(sessionId: Int64, timestampStart: Int64, rows: [libfitness.SessionEntry]) async throws -> Any {
        return try await libfitness.PackDataRowUseCase().invoke(sessionId: sessionId, timestampStart: timestampStart, rows: rows)
    }
}

public struct PublishSessionActivityUseCase {
    public init() {}
    public func invoke(filename: String) async throws {
        // FIXME: Implement publishing
    }
}
