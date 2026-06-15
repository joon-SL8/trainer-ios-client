import Foundation

public struct RawMRCViewRoute: Hashable {
    public let filePath: String
    
    public init(filePath: String) {
        self.filePath = filePath
    }
}
