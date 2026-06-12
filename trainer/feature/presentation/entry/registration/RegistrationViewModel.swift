import SwiftUI
import Combine
import libfitness

enum RegResultState: Int {
    case initial = 1, credential, profile, complete, error
}

@MainActor
class RegistrationViewModel: ObservableObject {
    var registrationViewModel: libfitness.RegistrationViewModel
    
    @Published var status: RegResultState = .initial
    @Published var validationError: String?
    @Published var showValidationError: Bool = false
    
    // Credentials
    @Published var username = ""
    @Published var password = ""
    
    // Profile Data
    @Published var fullName = ""
    @Published var age = ""
    @Published var weight = ""
    @Published var ftp = ""
    
    private var cancellables = Set<AnyCancellable>()
    
    private var isObserving = false
    
    init(registrationViewModel: libfitness.RegistrationViewModel) {
        self.registrationViewModel = registrationViewModel
    }

    func startObserving() async {
        guard !isObserving else { 
            print("RegistrationViewModel: Already observing, skipping.")
            return 
        }
        isObserving = true
        defer { 
            isObserving = false 
            print("RegistrationViewModel: startObserving stopped")
        }

        print("RegistrationViewModel: startObserving started")

        for await state in registrationViewModel.task.getTaskProgress() {
            print("RegistrationViewModel: Received state: \(state)")

            if (state is SetProfile) {
                status = .profile
            } else if (state is SetAthleteProfile) {
                print("RegistrationViewModel: Athlete profile updated state received")
            } else if (state is Completed || state is Finish) {
                print("RegistrationViewModel: Registration COMPLETED")
                status = .complete
            } else if (state is Initial || state is ApplyCredential) {
                print("RegistrationViewModel: Initial/Credential state received, ignoring")
            } else {
                print("RegistrationViewModel: Unknown or Error state: \(state)")
                // We only set error if it's truly an unexpected terminal state or explicit error
                // For now, let's see what's being emitted before forcing status = .error
            }
        }
    }
    
    func validateCredentials() -> Bool {
        if !isValidEmail(username) {
            validationError = "Username must be a valid email address."
            showValidationError = true
            return false
        }
        
        if password.count <= 8 {
            validationError = "Password must be more than 8 characters long."
            showValidationError = true
            return false
        }
        
        return true
    }
    
    func validateProfile() -> Bool {
        if fullName.isEmpty {
            validationError = "Please enter your full name."
            showValidationError = true
            return false
        }
        
        guard let ageVal = Int(age), ageVal > 0 else {
            validationError = "Please enter a valid age."
            showValidationError = true
            return false
        }
        
        guard let weightVal = Double(weight), weightVal > 0 else {
            validationError = "Please enter a valid weight."
            showValidationError = true
            return false
        }
        
        guard let ftpVal = Int(ftp), ftpVal > 0 else {
            validationError = "Please enter a valid FTP."
            showValidationError = true
            return false
        }
        
        return true
    }
    
    func intakeCredentials() {
        guard validateCredentials() else { return }
        
        let credential = CredentialInput(
            username: username,
            password: password
        )
        
        registrationViewModel.intakeViewInput(
            regStep: ApplyCredential.shared,
            action: Register(input: credential)
        )
    }
    
    func intakeProfile() {
        guard validateProfile() else { return }
        
        let profile = AthleteProfileInput(
            name: fullName,
            age: Int32(age) ?? 0,
            ftp: Int32(ftp) ?? 0,
            weight: Int32(weight) ?? 0
        )
        
        registrationViewModel.intakeViewInput(
            regStep: SetAthleteProfile.shared,
            action: Register(input: profile)
        )
    }
    
    private func isValidEmail(_ email: String) -> Bool {
        let emailRegEx = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
        let emailPred = NSPredicate(format:"SELF MATCHES %@", emailRegEx)
        return emailPred.evaluate(with: email)
    }
}
