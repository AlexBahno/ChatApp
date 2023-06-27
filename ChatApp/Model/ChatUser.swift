//
//  ChatUser.swift
//  ChatApp
//
//  Created by Alexandr Bahno on 22.06.2023.
//

import Foundation
import FirebaseFirestoreSwift

struct ChatUser: Identifiable {
    
    var id: String {uid}
    let uid, email, profileImageUrl: String
    
    init(userData: [String: Any?]) {
        self.uid = userData[FirebaseConstants.uid] as? String ?? ""
        self.email = userData[FirebaseConstants.email] as? String ?? ""
        self.profileImageUrl = userData[FirebaseConstants.profileImageUrl] as? String ?? ""
    }
}
