import Combine
import Foundation
import SwiftUI
import libfitness

class StravaAuthenticationViewModel: ObservableObject {
    @Published var isAuthenticating: Bool = false
    @Published var errorMessage: String?
    private var cancellables = Set<AnyCancellable>()
    private let router: NavigationRouter

    init(router: NavigationRouter) {
        self.router = router
        NotificationCenter.default.publisher(for: UIApplication.willEnterForegroundNotification)
            .sink { [weak self] _ in
                self?.resetAuthenticationState()
            }
            .store(in: &cancellables)
    }

    func resetAuthenticationState() {
        if isAuthenticating {
            print("Resetting Strava authentication state")
            isAuthenticating = false
        }
    }

    func authenticate(workoutFile: String? = nil, sessionId: String? = nil) {
        print("Strava authentication starting...")
        isAuthenticating = true
        errorMessage = nil

        // Persist context to storage
        let defaults = UserDefaults.standard
        defaults.set(workoutFile, forKey: "StravaAuth_WorkoutFile")
        defaults.set(sessionId, forKey: "StravaAuth_SessionId")

        let deeplink = "trainer"
        print("Strava authentication triggered with deeplink: \(deeplink)")

        // Use the updated library method to get the Authorize object with deeplink
        let stravaAuthorize = Authorize_iosKt.getStravaAuthorize(deeplink: deeplink)
        try? stravaAuthorize.authenticate()
    }
}
