import Foundation
import libfitness

public struct UpdateSessionUseCase {
    public init() {}
    
    public func invoke(session: libfitness.Session) async -> Int64 {
        // Implementation calling libfitness database manager
        let input = InsertSessionInfoInput(data: session)
        let result = try? await libfitness.UpdateSessionUseCase().invoke(input: input)

        return 1 // Mock returning ID
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
