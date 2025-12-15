//
//  LoginView.swift
//  WoundSnapProject1
//
//  Created by Syed Taha Shah on 12/7/25.
//


import SwiftUI
import ParseSwift

struct LoginView: View {
    @Binding var userLoggedIn: Bool
    @State private var email = ""
    @State private var password = ""
    @State private var errorMessage = ""
    @State private var showSignUp = false

    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                TextField("Email", text: $email)
                    .keyboardType(.emailAddress)
                    .autocapitalization(.none)
                    .padding()
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(8)

                SecureField("Password", text: $password)
                    .padding()
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(8)

                if !errorMessage.isEmpty {
                    Text(errorMessage)
                        .foregroundColor(.red)
                        .multilineTextAlignment(.center)
                }

                Button("Log In") {
                    login()
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.blue)
                .foregroundColor(.white)
                .cornerRadius(8)

                NavigationLink(isActive: $showSignUp) {
                    SignUpView(userLoggedIn: $userLoggedIn)
                } label: {
                    Button("Create Account") {
                        showSignUp = true
                    }
                }
            }
            .padding()
            .navigationTitle("Login")
        }
    }

    private func login() {
        User.login(username: email, password: password) { result in
            switch result {
            case .success(_):
                DispatchQueue.main.async {
                    userLoggedIn = true
                }
            case .failure(let error):
                errorMessage = error.localizedDescription
            }
        }
    }
}