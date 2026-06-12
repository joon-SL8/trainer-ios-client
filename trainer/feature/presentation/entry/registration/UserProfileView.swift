import SwiftUI

struct UserProfileView: View {
    @EnvironmentObject var authService: AuthenticationService
    @Environment(\.presentationMode) var presentationMode

    @State private var fullName = ""
    @State private var weight = ""
    @State private var ftp = ""
    @State private var age = ""
    @State private var password = ""
    @State private var showAlert = false
    @State private var validationError = ""

    var body: some View {
        ZStack {
            VStack(spacing: 20) {
                Spacer()
                
                Image(systemName: "person.circle")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 100, height: 100)
                    .padding(.bottom, 10)
                
                Text(authService.currentUser?.username ?? "")
                    .font(.headline)
                
                HStack {
                    Text("Please let us know about yourself")
                        .font(.caption)
                        .foregroundColor(.gray)
                    Spacer()
                }
                .padding(.horizontal)
                
                VStack(alignment: .leading) {
                    Text("Password")
                        .font(.caption)
                        .foregroundColor(.gray)
                    SecureField("Enter new password", text: $password)
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(5)
                
                VStack(alignment: .leading) {
                    Text("Full Name")
                        .font(.caption)
                        .foregroundColor(.gray)
                    TextField("", text: $fullName)
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(5)
                
                VStack(alignment: .leading) {
                    Text("Weight (kg)")
                        .font(.caption)
                        .foregroundColor(.gray)
                    TextField("", text: $weight)
                        .keyboardType(.decimalPad)
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(5)
                
                VStack(alignment: .leading) {
                    Text("FTP (watts)")
                        .font(.caption)
                        .foregroundColor(.gray)
                    TextField("", text: $ftp)
                        .keyboardType(.numberPad)
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(5)
                
                VStack(alignment: .leading) {
                    Text("Age")
                        .font(.caption)
                        .foregroundColor(.gray)
                    TextField("", text: $age)
                        .keyboardType(.numberPad)
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(5)
                
                Button("Save") {
                    handleUpdate()
                }
                .padding()
                .frame(maxWidth: .infinity)
                .background(Color.green)
                .foregroundColor(.white)
                .cornerRadius(5)
                
                Spacer()
            }
            .padding()
            .onAppear(perform: loadUserData)
            .alert(isPresented: $showAlert) {
                let errorMessage = authService.errorMessage ?? validationError
                return Alert(
                    title: Text("Update Failed"),
                    message: Text(errorMessage),
                    dismissButton: .default(Text("OK")) {
                        authService.errorMessage = nil
                        validationError = ""
                    }
                )
            }
            .onReceive(authService.$errorMessage) { errorMessage in
                if errorMessage != nil {
                    showAlert = true
                }
            }
            .navigationTitle("Profile")
            .navigationBarTitleDisplayMode(.large)
        }
    }

    private func loadUserData() {
        if let user = authService.currentUser {
            fullName = user.fullName
            weight = String(user.weight)
            ftp = String(user.ftp)
            age = String(user.age)
        }
    }

    private func handleUpdate() {
        guard let weightValue = Double(weight),
              let ftpValue = Int(ftp),
              let ageValue = Int(age) else {
            validationError = "Please enter valid numbers for weight, FTP, and age."
            showAlert = true
            return
        }

        authService.updateUser(fullName: fullName, weight: weightValue, ftp: ftpValue, age: ageValue)
        presentationMode.wrappedValue.dismiss()
    }
}

#Preview {
    let authService = AuthenticationService()
    authService.currentUser = User(username: "test@example.com", fullName: "Test User", weight: 80.5, ftp: 280, age: 35)
    return UserProfileView()
        .environmentObject(authService)
}
