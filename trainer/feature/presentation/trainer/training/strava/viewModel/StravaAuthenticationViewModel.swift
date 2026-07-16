import Combine
import Foundation
import SwiftUI
import libfitness

class StravaAuthenticationViewModel: ObservableObject {
    @Published var isAuthenticating: Bool = false
    @Published var errorMessage: String?

    func authenticate(workoutFile: String? = nil, sessionId: String? = nil) {
        print("Strava authentication starting...")
        isAuthenticating = true
        errorMessage = nil

        // Define your app's deeplink scheme/path
        var components = URLComponents()
        components.scheme = "trainer"
        components.host = "session"
        
        var queryItems = [URLQueryItem]()
        if let workoutFile = workoutFile {
            components.path = "/trainer/\(workoutFile)"
        }
        
        if let sessionId = sessionId {
            queryItems.append(URLQueryItem(name: "sessionId", value: sessionId))
        }
        
        if !queryItems.isEmpty {
            components.queryItems = queryItems
        }
        
        let deeplink = components.url?.absoluteString ?? "trainer://session"

        // Use the updated library method to get the Authorize object with deeplink
        let stravaAuthorize = Authorize_iosKt.getStravaAuthorize(deeplink: deeplink)

        // Trigger the authentication process
        stravaAuthorize.authenticate()

        print("Strava authentication triggered with deeplink: \(deeplink)")
    }
}

