//
//  Comment.swift
//  WoundSnapProject1
//
//  Created by Syed Taha Shah on 12/7/25.
//


import SwiftUI
import ParseSwift

struct Comment: ParseObject, Identifiable {
    var originalData: Data?
    
    var objectId: String?
    var createdAt: Date?
    var updatedAt: Date?
    var ACL: ParseACL?
    
    var id: String { objectId ?? UUID().uuidString } // Use computed property
    var text: String?
    var userName: String?
}