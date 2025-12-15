//
//  WoundSnapProject1App.swift
//  WoundSnapProject1
//
//  Created by Syed Taha Shah on 12/7/25.
//

import SwiftUI
import ParseSwift

@main
struct WoundSnapProject1App: App {

    init() {
        ParseSwift.initialize(
            applicationId: "5QmzpWyoavgR0IS4ZeNNqSucwQVQaCz3lAMYw7RI",
            clientKey: "wFQgWde8MeaBmnLSx4OIvQtoUkJCvGVPRT3JUIan",
            serverURL: URL(string: "https://parseapi.back4app.com")!
        )
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
