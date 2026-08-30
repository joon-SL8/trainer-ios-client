import Foundation
import libfitness

public struct TAndCService {
    public init() {}
    
    // LibfitnessTAndCAgreement seems to have an 'invoke' method that takes a LibfitnessTAndC type.
    // It also has static or companion access.
    public func getStatus(type: libfitness.TAndC) async -> libfitness.TAndCAgreement? {
        let usecase = libfitness.GetTAndCStatusUseCase()
        return usecase.invoke(type: type)
    }
    
    public func update(type: libfitness.TAndC, isAgreed: Bool) async {
        let timestamp = Int64(Date().timeIntervalSince1970 * 1000)

        // Needs a dateAgreed as LibfitnessKotlinInstant.
        // Assuming current time is fine.
        let usecase = libfitness.SetTAndCStatusUseCase()
        usecase.invoke(type: type, isAgreed: isAgreed, dateAgreed: timestamp)
    }
}
