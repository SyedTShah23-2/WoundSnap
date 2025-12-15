//
//  SignUpView.swift
//  WoundSnapProject1
//
//  Created by Syed Taha Shah on 12/7/25.
//


import SwiftUI
import ParseSwift

struct SignUpView: View {
    @Binding var userLoggedIn: Bool
    @State private var displayName = ""
    @State private var email = ""
    @State private var password = ""
    @State private var errorMessage = ""

    var body: some View {
        VStack(spacing: 20) {
            TextField("Display Name", text: $displayName)
                .padding()
                .background(Color.gray.opacity(0.1))
                .cornerRadius(8)

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

            Button("Sign Up") {
                signUp()
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(Color.green)
            .foregroundColor(.white)
            .cornerRadius(8)
        }
        .padding()
        .navigationTitle("Sign Up")
    }

    private func signUp() {
        var newUser = User()
        newUser.username = email
        newUser.password = password
        newUser.email = email
        newUser.displayName = displayName

        newUser.signup { result in
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