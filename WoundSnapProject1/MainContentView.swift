//
//  MainContentView.swift
//  WoundSnapProject1
//
//  Created by Syed Taha Shah on 12/7/25.
//


import SwiftUI

struct MainContentView: View {
    @Binding var userLoggedIn: Bool
    @State private var selection = 0

    var body: some View {
        TabView(selection: $selection) {
            PublicFeedView(userLoggedIn: $userLoggedIn)
                .tabItem {
                    Label("Feed", systemImage: "house.fill")
                }
                .tag(0)

            PostImageView()
                .tabItem {
                    Label("Post", systemImage: "plus.circle.fill")
                }
                .tag(1)

            ContentViewAI()
                .tabItem {
                    Label("Analyzer", systemImage: "cross.case.fill")
                }
                .tag(2)
        }
    }
}