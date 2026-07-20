import Foundation
import libfitness

public struct UpdateSessionUseCase {
    public init() {}
    
    public func invoke(session: libfitness.Session) async {
        // Implementation calling libfitness database manager
        let input = InsertSessionInfoInput(data: session)
        try? await libfitness.UpdateSessionUseCase().invoke(input: input)
    }
}

public struct GetSessionUseCase {
    public init() {}

    public func invoke(input: GetSessionInfoInput) async -> GetSessionResult {
        return try! await libfitness.GetSessionUseCase().invoke(input: input) as! GetSessionResult
    }
}

public struct UpdateSessionEntryUseCase {
    public init() {}
    
    public func invoke(entry: libfitness.SessionEntry) async {
        // Implementation calling libfitness database manager
        let input = InsertSessionEntryInput(data: entry)
        let result = try? await libfitness.UpdateSessionEntryUseCase().invoke(input: input)
    }
}

public struct GetSessionEntryUseCase {
    public init() {}
    
    public func invoke(sessionId: Int64) async -> GetSessionEntriesResult {
        // Implementation calling libfitness database manager
        let input = GetSessionEntryInput(sessionId: sessionId)
        return try! await libfitness.GetSessionEntryUseCase().invoke(input: input) as! GetSessionEntriesResult
    }
}
