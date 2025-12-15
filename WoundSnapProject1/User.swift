//
//  User.swift
//  WoundSnapProject1
//
//  Created by Syed Taha Shah on 12/7/25.
//


import Foundation
import SwiftUI
import ParseSwift

struct User: ParseUser {

    // REQUIRED PARSEUSER PROPERTIES
    var objectId: String?
    var username: String?
    var email: String?
    var password: String?
    var createdAt: Date?
    var updatedAt: Date?
    var ACL: ParseACL?

    // REQUIRED FOR ParseUser
    var authData: [String : [String : String]?]?
    var emailVerified: Bool?
    var originalData: Data?

    // CUSTOM FIELDS
    var displayName: String?

    // REQUIRED EMPTY INITIALIZER
    init() {}
}