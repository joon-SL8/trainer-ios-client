import Foundation
import libfitness

public struct TAndCService {
    public init() {}

    // LibfitnessTAndCAgreement seems to have an 'invoke' method that takes a LibfitnessTAndC type.
    // It also has static or companion access.
    public func getStatus(type: libfitness.TAndC) async -> libfitness.TAndCAgreement? {
        let usecase = libfitness.GetTAndCStatusUseCase()

        do {
            return try usecase.invoke(type: type)
        } catch {
            print("Error getting T&C status: \(error)")
            return nil
        }
    }

    public func update(type: libfitness.TAndC, isAgreed: Bool) async {
        let timestamp = Int64(Date().timeIntervalSince1970 * 1000)

        // Needs a dateAgreed as LibfitnessKotlinInstant.
        // Assuming current time is fine.
        let usecase = libfitness.SetTAndCStatusUseCase()
        usecase.invoke(type: type, isAgreed: isAgreed, dateAgreed: timestamp)
    }

    public func getContent(type: libfitness.TAndC) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = AppConstants.DateFormats.standard
        let dateString = formatter.string(from: Date())
        
        let config = libfitness.TAndCConfiguration.init(
            appName: AppConstants.Legal.appName,
            effectiveDate: dateString,
            lastUpdated: dateString,
            legalContactEmail: AppConstants.Legal.legalContactEmail,
            websiteUrl: AppConstants.Legal.websiteUrl,
            privacyContactEmail: AppConstants.Legal.privacyContactEmail
        )

        // Use the constant for terms of use
        let template = libfitness.TAndC.companion.TERMS_OF_USE
        return libfitness.TAndCKt.replaceTAndCPlaceholders(template, config: config)
    }
}
