import Foundation
import AuthenticationServices
import UIKit

public class StravaAuthorize: NSObject, ASWebAuthenticationPresentationContextProviding {
    private let clientId = "132336"
    private let redirectUri = "trainer://oauth"
    private let scope = "activity:write,read"
    
    private let oauthStravaScheme: URL
    private let oauthWebScheme: URL
    private let callbackURLScheme = "trainer"
    
    public override init() {
        let stravaUrlString = "strava://oauth/mobile/authorize?client_id=\(clientId)&redirect_uri=\(redirectUri.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)!)&response_type=code&approval_prompt=auto&scope=\(scope.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)!)"
        self.oauthStravaScheme = URL(string: stravaUrlString)!
        
        let webUrlString = "https://www.strava.com/oauth/mobile/authorize?client_id=\(clientId)&response_type=code&approval_prompt=auto&scope=\(scope.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)!)&redirect_uri=\(redirectUri.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)!)"
         self.oauthWebScheme = URL(string: webUrlString)!
        
        super.init()
    }
    
    public func authenticate(completion: @escaping (URL?, Error?) -> Void) {
        if UIApplication.shared.canOpenURL(oauthStravaScheme) {
            UIApplication.shared.open(oauthStravaScheme)
            // Note: Strava App auth usually returns via custom URL scheme handled in AppDelegate/SceneDelegate
            completion(nil, nil)
        } else {
            print("session starting with \(callbackURLScheme) - \(oauthWebScheme)")
            let session = ASWebAuthenticationSession(
                url: oauthWebScheme,
                callbackURLScheme: callbackURLScheme,
                completionHandler: { url, error in
                    if let url = url {
                        // Assuming processAppLinkContent is available in libfitness
                        // If it's not, you might need to handle the URL differently here.
                        // processAppLinkContent(url.absoluteString)
                        print("Authorization received: \(url)")
                    }
                    completion(url, error)
                }
            )
            session.presentationContextProvider = self
            session.start()
        }
    }
    
    public func presentationAnchor(for session: ASWebAuthenticationSession) -> ASPresentationAnchor {
        return UIApplication.shared.connectedScenes
            .filter { $0.activationState == .foregroundActive }
            .compactMap { $0 as? UIWindowScene }
            .first?.windows
            .first { $0.isKeyWindow } ?? ASPresentationAnchor()
    }
}
