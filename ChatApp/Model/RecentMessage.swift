//
//  RecentMessage.swift
//  ChatApp
//
//  Created by Alexandr Bahno on 27.06.2023.
//

import Foundation
import Firebase
import FirebaseFirestoreSwift

struct RecentMessage: Codable, Identifiable {
    
    @DocumentID var id: String?
    let text, fromId, toId: String
    let email, profileImageUrl: String
    let timestamp: Timestamp
    
    var username: String {
        email.components(separatedBy: "@").first ?? email
    }
    
    var timeAgo: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: timestamp.dateValue(), relativeTo: Date())
    }
}
