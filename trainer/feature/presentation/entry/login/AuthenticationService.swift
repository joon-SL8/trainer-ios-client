//
//  AuthenticationService.swift
//  mobile
//
//  Created by Joon Lee on 11/26/25.
//

import Foundation
import Combine
import libfitness

class AuthenticationService: ObservableObject {
    @Published var isAuthenticated: Bool = false
    @Published var currentUser: User?
    @Published var errorMessage: String?

    @Published var registrationProgress: RegStep?
    @Published var isRegistering: Bool = false

    private var registrationData: (username: String, fullName: String, weight: Double, ftp: Int, age: Int)?

    func login(username: String, password: String) {
        print("Attempting login for \(username)")
        if username == "test@example.com" && password == "password" {
            isAuthenticated = true
            currentUser = User(username: username, fullName: "Test User", weight: 70, ftp: 250, age: 30)
            errorMessage = nil
            print("Login successful for \(username)")
        } else {
            errorMessage = "We're sorry, the username and/or the password doesn't match our record."
            print("Login failed for \(username)")
        }
    }

    func forceAuthenticate(username: String) {
        print("Forcing authentication for \(username)")
        isAuthenticated = true
        currentUser = User(username: username, fullName: "Test User (Demo)", weight: 70, ftp: 250, age: 30)
        errorMessage = nil
        print("Forced authentication successful for \(username)")
    }

    func register(username: String, password: String, fullName: String, weight: Double, ftp: Int, age: Int) {
        self.registrationData = (username: username, fullName: fullName, weight: weight, ftp: ftp, age: age)
        let profileInput = RegistrationProfileInput(
            username: username,
            password: password,
            fullname: fullName,
            age: Int32(age),
            ftp: Int32(ftp),
            weight: Int32(weight)
        )
    }

    func updateUser(fullName: String, weight: Double, ftp: Int, age: Int) {
        guard var user = currentUser else { return }
        user.fullName = fullName
        user.weight = weight
        user.ftp = ftp
        user.age = age
        currentUser = user
        print("User profile updated for \(user.username)")
    }

    func logout() {
        isAuthenticated = false
        currentUser = nil
        errorMessage = nil
        print("User logged out")
    }
}

// Placeholder for a User struct
struct User: Identifiable {
    var id: String { username }
    let username: String
    var fullName: String
    var weight: Double
    var ftp: Int
    var age: Int
}
