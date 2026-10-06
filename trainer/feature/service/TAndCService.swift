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

        let template: String
        if type == .safetyDisclaimer {
            template = libfitness.SafetyDisclaimer.companion.SAFETY_DISCLAIMER
        } else if type == .privacyPolicy {
            template = libfitness.PrivacyPolicy.companion.PRIVACY_POLICY
        } else {
            template = libfitness.TermsOfUse.companion.TERMS_OF_USE
        }
        let content = libfitness.TAndCKt.replaceTAndCPlaceholders(template, config: config)
        print("TAndCService getContent for type \(type): length = \(content.count), preview = \(content.prefix(100))")
        print("\(template)")
        return content
    }

    public func getSessionBeginWarningContent() -> String {
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

        let template = libfitness.SessionBeginWarning.companion.SESSION_BEGIN_WARNING
        let content = libfitness.TAndCKt.replaceTAndCPlaceholders(template, config: config)
        print("TAndCService getSessionBeginWarningContent: length = \(content.count)")
        return content
    }
}
