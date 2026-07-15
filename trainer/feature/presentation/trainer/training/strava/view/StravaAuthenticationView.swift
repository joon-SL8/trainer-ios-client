import SwiftUI

struct StravaAuthenticationView: View {
    @StateObject private var viewModel = StravaAuthenticationViewModel()
    @Environment(\.presentationMode) var presentationMode
    
    let workoutFile: String?
    let sessionId: String?
    
    var body: some View {
        VStack(spacing: 0) {
            Text("Strava Authentication")
                .font(.title2)
                .bold()
                .padding(.top, 48)

            Spacer()

            Image("strava_icon_512")
                .resizable()
                .scaledToFit()
                .frame(maxWidth: .infinity)
                .padding(.horizontal, 48)

            Text("Strava authentication is essential for publishing your activity")
                .font(.body)
                .padding(.top, 24)
                .padding(.horizontal, 48)

            Button(action: {
                viewModel.authenticate(workoutFile: workoutFile, sessionId: sessionId)
            }) {
                Text("Authenticate")
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity, maxHeight: 48)
                    .background(Color.orange)
                    .cornerRadius(10)
            }
            .padding(.top, 64)
            .padding(.horizontal, 48)
            
            Spacer()
        }
        .fullScreenCover(isPresented: $viewModel.isAuthenticating) {
            ZStack {
                Color.black.opacity(0.4).edgesIgnoringSafeArea(.all)
                VStack {
                    ProgressView("Authenticating with Strava...")
                        .padding()
                        .background(Color.white)
                        .cornerRadius(10)
                }
            }
        }
    }
}
