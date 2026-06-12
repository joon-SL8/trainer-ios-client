import Foundation

public enum SessionState: String, CaseIterable, Identifiable {
    case idle
    case active
    case paused
    case completed
    
    public var id: Self { self }
}
