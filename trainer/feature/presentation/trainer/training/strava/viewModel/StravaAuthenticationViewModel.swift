import Combine
import Foundation
import SwiftUI
import libfitness

class StravaAuthenticationViewModel: ObservableObject {
    @Published var isAuthenticating: Bool = false
    @Published var errorMessage: String?

    func authenticate() {
        print("Strava authentication starting...")
        isAuthenticating = true
        errorMessage = nil

        // Define your app's deeplink scheme/path
        // The error indicates ":" and "/" are not allowed in the scheme.
        let deeplink = "trainer"

        // Use the updated library method to get the Authorize object with deeplink
        let stravaAuthorize = Authorize_iosKt.getStravaAuthorize(deeplink: deeplink)

        // Trigger the authentication process
        stravaAuthorize.authenticate()

        print("Strava authentication triggered with deeplink: \(deeplink)")
    }
}

