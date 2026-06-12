import SwiftUI
import libfitness

struct RegistrationProfileView: View {
    @StateObject var viewModel: RegistrationViewModel
    @Environment(\.presentationMode) var presentationMode
    @EnvironmentObject var authService: AuthenticationService
    
    init(registrationViewModel: libfitness.RegistrationViewModel) {
        _viewModel = StateObject(wrappedValue: RegistrationViewModel(registrationViewModel: registrationViewModel))
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                Text("Athlete Profile")
                    .font(.largeTitle)
                    .bold()
                    .padding(.bottom, 10)
                
                Text("Tell us a bit more about yourself to customize your experience.")
                    .font(.subheadline)
                    .foregroundColor(.gray)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)

                VStack(alignment: .leading, spacing: 8) {
                    Text("Full Name")
                        .font(.caption)
                        .foregroundColor(.gray)
                    TextField("John Doe", text: $viewModel.fullName)
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(10)
                }

                VStack(alignment: .leading, spacing: 8) {
                    Text("Age")
                        .font(.caption)
                        .foregroundColor(.gray)
                    TextField("e.g. 30", text: $viewModel.age)
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(10)
                        .keyboardType(.numberPad)
                }

                VStack(alignment: .leading, spacing: 8) {
                    Text("Weight (kg)")
                        .font(.caption)
                        .foregroundColor(.gray)
                    TextField("e.g. 75.5", text: $viewModel.weight)
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(10)
                        .keyboardType(.decimalPad)
                }

                VStack(alignment: .leading, spacing: 8) {
                    Text("FTP (watts)")
                        .font(.caption)
                        .foregroundColor(.gray)
                    TextField("e.g. 250", text: $viewModel.ftp)
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(10)
                        .keyboardType(.numberPad)
                }

                Button(action: {
                    viewModel.intakeProfile()
                }) {
                    Text("Complete Registration")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.green)
                        .cornerRadius(10)
                }
                .padding(.top, 10)

                Button(action: {
                    presentationMode.wrappedValue.dismiss()
                }) {
                    Text("Back")
                        .font(.subheadline)
                        .foregroundColor(.blue)
                }
                .padding(.top, 5)
            }
            .padding()
        }
        .task {
            print("RegistrationProfileView: Appearing, starting task")
            await viewModel.startObserving()
        }
        .onChange(of: viewModel.status) { newStatus in
            print("RegistrationProfileView: status changed to \(newStatus)")
            if newStatus == .complete {
                print("RegistrationProfileView: Triggering navigation")
                authService.isAuthenticated = true
            }
        }
        .navigationTitle("Step 2 of 2")
        .navigationBarBackButtonHidden(true) 
        .alert(isPresented: $viewModel.showValidationError) {
            Alert(
                title: Text("Validation Error"),
                message: Text(viewModel.validationError ?? "Please check your entries."),
                dismissButton: .default(Text("OK"))
            )
        }
    }
}

struct RegistrationProfileView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            RegistrationProfileView(registrationViewModel: libfitness.RegistrationViewModel())
                .environmentObject(AuthenticationService())
        }
    }
}
