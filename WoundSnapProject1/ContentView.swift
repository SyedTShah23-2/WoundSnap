//
//  ContentView.swift
//  WoundSnapProject1
//
//  Created by Syed Taha Shah on 12/7/25.
//

import SwiftUI
import ParseSwift

struct ContentView: View {
    @AppStorage("isLoggedIn") private var userLoggedIn = false
    @State private var hasCheckedCurrentUser = false
    
    var body: some View {
        Group {
            if !hasCheckedCurrentUser {
                ProgressView()
                    .onAppear {
                        userLoggedIn = User.current != nil
                        hasCheckedCurrentUser = true
                    }
            } else if userLoggedIn {
                MainContentView(userLoggedIn: $userLoggedIn)
            } else {
                LoginView(userLoggedIn: $userLoggedIn)
            }
        }
    }
}
