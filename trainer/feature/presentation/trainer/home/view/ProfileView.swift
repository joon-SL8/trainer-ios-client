import SwiftUI
import libfitness

struct ProfileView: View {
    @Environment(\.presentationMode) var presentationMode
    @EnvironmentObject var authService: AuthenticationService
    @EnvironmentObject var router: NavigationRouter
    @Binding var showProfile: Bool
    @State private var showLogoutAlert = false
    
    // New threshold state
    @State private var pauseThreshold = "20"
    private let getProfileUseCase = GetCustomProfileUseCase()
    private let updateProfileUseCase = UpdateCustomProfileUseCase()

    var body: some View {
        VStack(spacing: 20) {
            Text("Menu")
                .font(.largeTitle)
                .padding(.top, 40)
            
            // New Setting
            VStack(alignment: .leading) {
                Text("Session Pause Threshold (s)")
                    .font(.caption)
                    .foregroundColor(.gray)
                TextField("20", text: $pauseThreshold)
                    .keyboardType(.numberPad)
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(5)
                    .onChange(of: pauseThreshold) { newValue in
                        Task {
                            _ = try? await updateProfileUseCase.invoke(input: UpdateCustomInput(key: "detect_pause", value: newValue))
                        }
                    }
            }
            .padding(.horizontal)

            Button(action: {
                presentationMode.wrappedValue.dismiss()
                showProfile = true
            }) {
                HStack {
                    Image(systemName: "person.fill")
                    Text("Profile")
                }
                .font(.headline)
                .foregroundColor(.white)
                .padding()
                .frame(maxWidth: .infinity)
                .background(Color.blue)
                .cornerRadius(10)
            }
            .padding(.horizontal)

            Button(action: {
                presentationMode.wrappedValue.dismiss()
                router.navigate(to: Route.stravaAuth(workoutFile: nil, sessionId: nil))
            }) {
                HStack {
                    Image(systemName: "link")
                    Text("Strava Authentication")
                }
                .font(.headline)
                .foregroundColor(.white)
                .padding()
                .frame(maxWidth: .infinity)
                .background(Color.orange)
                .cornerRadius(10)
            }
            .padding(.horizontal)

            Button(action: {
                showLogoutAlert = true
            }) {
                HStack {
                    Image(systemName: "arrow.right.to.line")
                    Text("Logout")
                }
                .font(.headline)
                .foregroundColor(.white)
                .padding()
                .frame(maxWidth: .infinity)
                .background(Color.red)
                .cornerRadius(10)
            }
            .padding(.horizontal)
            .alert(isPresented: $showLogoutAlert) {
                Alert(
                    title: Text("Logout"),
                    message: Text("Are you sure you want to logout?"),
                    primaryButton: .destructive(Text("Confirm")) {
                        authService.logout()
                    },
                    secondaryButton: .cancel()
                )
            }

            Spacer()
        }
        .onAppear(perform: loadSettings)
    }
    
    private func loadSettings() {
        Task {
            if let savedThreshold = await getProfileUseCase.invoke(key: "detect_pause") {
                await MainActor.run {
                    pauseThreshold = savedThreshold
                }
            }
        }
    }
}

#Preview {
    ProfileView(showProfile: .constant(false))
        .environmentObject(AuthenticationService())
}
