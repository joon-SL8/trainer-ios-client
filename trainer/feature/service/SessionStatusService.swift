import Foundation
import libfitness

public enum SessionStatus {
    case needsProcessing // Missing filename
    case needsUpload // Has filename, missing published
    case synced // Has filename and published

    public static func status(for session: libfitness.Session) -> SessionStatus {
        // According to build error, these are not optionals.
        // sessionFilename is likely empty string if not set.
        if session.sessionFilename.isEmpty {
            return .needsProcessing
        }
        
        // sessionPublished is likely 0 if not set.
        if session.sessionPublished == 0 {
            return .needsUpload
        }
        
        return .synced
    }
}
