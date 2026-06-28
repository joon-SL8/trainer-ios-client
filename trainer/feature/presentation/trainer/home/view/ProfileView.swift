import SwiftUI

struct ProfileView: View {
    @Environment(\.presentationMode) var presentationMode
    @EnvironmentObject var authService: AuthenticationService
    @EnvironmentObject var router: NavigationRouter
    @Binding var showProfile: Bool
    @State private var showLogoutAlert = false

    var body: some View {
        VStack(spacing: 20) {
            Text("Menu")
                .font(.largeTitle)
                .padding(.top, 40)

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
                router.navigate(to: Route.stravaAuth)
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
    }
}

#Preview {
    ProfileView(showProfile: .constant(false))
        .environmentObject(AuthenticationService())
}
