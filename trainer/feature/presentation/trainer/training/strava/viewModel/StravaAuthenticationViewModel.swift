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

        print("Strava authentication triggered")

        // Use the native Swift StravaAuthorize class
        let stravaAuthorize = StravaAuthorize()
        stravaAuthorize.authenticate { [weak self] url, error in
            DispatchQueue.main.async {
                if let error = error {
                    self?.isAuthenticating = false
                    self?.errorMessage = error.localizedDescription
                } else if let url = url {
                    // Extract code from URL
                    if let code = URLComponents(url: url, resolvingAgainstBaseURL: false)?
                        .queryItems?.first(where: { $0.name == "code" })?.value {
                        print("Authorization code received: \(code)")
                        self?.resolveCodeToJWT(code: code)
                    } else {
                        self?.isAuthenticating = false
                        self?.errorMessage = "No authorization code found in callback URL."
                    }
                } else {
                    self?.isAuthenticating = false
                }
            }
        }
    }

    private func resolveCodeToJWT(code: String) {
        let resolveUseCase = libfitness.AuthorizationResolveCodeUseCase()
        Task {
            // Assuming invoke returns a Bool indicating success of JWT resolution/storage
            let success = try? await resolveUseCase.invoke(code: code)
            await MainActor.run {
                self.isAuthenticating = false
                if (success == true) {
                    print("Successfully resolved and stored JWT.")
                    self.router.navigateBack()
                } else {
                    self.errorMessage = "Failed to resolve or store the JWT token."
                }
            }
        }
    }

    private func storeJWT(_ jwt: String) -> Bool {
        // Hypothetical storage implementation
        // Replace with actual storage logic (e.g., Keychain)
        UserDefaults.standard.set(jwt, forKey: "Strava_JWT")
        return true // Return true if storage was successful
    }
}
