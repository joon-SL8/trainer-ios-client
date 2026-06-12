//
//  LoginView.swift
//  mobile
//
//  Created by Joon Lee on 11/26/25.
//

import SwiftUI
import libfitness

struct LoginView: View {
    @EnvironmentObject var authService: AuthenticationService
    @State private var username = ""
    @State private var password = ""
    @State private var showErrorAlert = false

    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                Spacer()

                Image(systemName: "person.circle.fill") // Placeholder for profile image
                    .resizable()
                    .scaledToFit()
                    .frame(width: 100, height: 100)
                    .foregroundColor(.gray)

                TextField("Username (Email)", text: $username)
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(5)
                    .keyboardType(.emailAddress)
                    .autocapitalization(.none)

                SecureField("Password", text: $password)
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(5)

                Button("Login") {
                    authService.login(username: username, password: password)
                }
                .padding()
                .frame(maxWidth: .infinity)
                .background(Color.blue)
                .foregroundColor(.white)
                .cornerRadius(5)

                NavigationLink {
                    RegistrationUsernameView(viewModel: RegistrationViewModel(registrationViewModel: libfitness.RegistrationViewModel()))
                } label: {
                    Text("Register")
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color.green)
                        .foregroundColor(.white)
                        .cornerRadius(5)
                }
                
                // --- Test Button for Deeplink ---
                Button("Simulate Deeplink") {
                    // This triggers the simulation sheet in mobileApp
                    NotificationCenter.default.post(name: .init("onOpenURL"), object: URL(string: "skjline://simulate"))
                }
                .accessibilityIdentifier("simulateDeeplinkButton")
                // ------------------------------------

                Spacer()
            }
            .padding()
            .navigationTitle("Welcome to\nSkjline Mobile")
            .alert(isPresented: $showErrorAlert) {
                Alert(
                    title: Text("Login Failed"),
                    message: Text(authService.errorMessage ?? "An unknown error occurred."),
                    dismissButton: .default(Text("OK")) {
                        authService.errorMessage = nil // Clear the error
                    }
                )
            }
            .onReceive(authService.$errorMessage) { errorMessage in
                if errorMessage != nil {
                    showErrorAlert = true
                }
            }
        }
    }
}

#Preview {
    LoginView()
        .environmentObject(AuthenticationService()) // Provide a mock for preview
}
