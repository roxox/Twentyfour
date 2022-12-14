//
//  AuthenticationService.swift
//  Twentyfour
//
//  Created by Sebastian Fox on 30.09.22.
//

import Foundation
import FirebaseAuth

enum AuthenticationState {
    case unauthenticated
    case authenticating
    case authenticated
}

class AuthenticationService: ObservableObject {
    // MARK: - Output
    @Published var authenticationState: AuthenticationState = .unauthenticated
    @Published var errorMessage: String = ""
    @Published var user: User?
    
    init() {
        registerAuthStateListener()
    }
    
    @MainActor
    func signIn(withEmail email: String, password: String) async -> Bool {
        authenticationState = .authenticating
        do {
            try await Auth.auth().signIn(withEmail: email, password: password)
            return true
        }
        catch {
            await MainActor.run {
                errorMessage = error.localizedDescription
                authenticationState = .unauthenticated
            }
            print(error)
            return false
        }
    }
    
    @MainActor
    func signUp(withEmail email: String, password: String) async -> Bool {
        authenticationState = .authenticating
        do {
            try await Auth.auth().createUser(withEmail: email, password: password)
            return true
        }
        catch {
            await MainActor.run {
                errorMessage = error.localizedDescription
                authenticationState = .unauthenticated
            }
            print(error)
            return false
        }
    }
    
    func signOut() {
        do  {
            try Auth.auth().signOut()
        }
        catch {
            print(error)
        }
    }
    
    private var handle: AuthStateDidChangeListenerHandle?
    
    private func registerAuthStateListener() {
        if handle == nil {
            handle = Auth.auth().addStateDidChangeListener { auth, user in
                Task {
                    await MainActor.run {
                        self.user = user
                        
                        if let user = user {
                            self.authenticationState = .authenticated
                            print("User \(user.uid) signed in. Email: \(user.email ?? "(no email address set)"), anonymous: \(user.isAnonymous)")
                        }
                        else {
                            self.authenticationState = .unauthenticated
                            print("User signed out.")
                        }
                    }
                }
            }
        }
    }
    
}

