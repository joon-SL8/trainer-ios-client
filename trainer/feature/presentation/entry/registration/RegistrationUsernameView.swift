import SwiftUI
import libfitness

struct RegistrationUsernameView: View {
    @StateObject var viewModel: RegistrationViewModel
    @State private var navigateToProfile = false

    var body: some View {
        VStack(spacing: 20) {
            Text("Create Account")
                .font(.largeTitle)
                .bold()
                .padding(.bottom, 20)

            TextField("Username (Email)", text: $viewModel.username)
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(10)
                .keyboardType(.emailAddress)
                .autocapitalization(.none)

            SecureField("Password", text: $viewModel.password)
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(10)

            Button(action: {
                viewModel.intakeCredentials()
            }) {
                Text("Next")
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .cornerRadius(10)
            }
            .padding(.top, 10)

            Spacer()
        }
        .padding()
        .navigationTitle("Step 1 of 2")
        .navigationDestination(isPresented: $navigateToProfile) {
            RegistrationProfileView(registrationViewModel: viewModel.registrationViewModel)
        }
        .alert(isPresented: $viewModel.showValidationError) {
            Alert(
                title: Text("Validation Error"),
                message: Text(viewModel.validationError ?? "Unknown error"),
                dismissButton: .default(Text("OK"))
            )
        }
        .task {
            await viewModel.startObserving()
        }
        .onChange(of: viewModel.status) { state in
            if state == .profile {
                navigateToProfile = true
            }
        }
    }
}

struct RegistrationUsernameView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            RegistrationUsernameView(viewModel: RegistrationViewModel(registrationViewModel: libfitness.RegistrationViewModel()))
                .environmentObject(AuthenticationService())
        }
    }
}
