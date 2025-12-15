//
//  Post.swift
//  WoundSnapProject1
//
//  Created by Syed Taha Shah on 12/7/25.
//


import SwiftUI
import ParseSwift

struct Post: ParseObject, Identifiable {
    var originalData: Data?

    var objectId: String?
    var createdAt: Date?
    var updatedAt: Date?
    var ACL: ParseACL?

    var image: ParseFile?
    var category: String?
    var userName: String?
    var description: String?        // user-provided description
    var mlDescription: String?      // ML model description
    var comments: [Comment]?

    // Use objectId as the id for Identifiable
    var id: String { objectId ?? UUID().uuidString }
}