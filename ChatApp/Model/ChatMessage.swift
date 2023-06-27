//
//  ChatMessage.swift
//  ChatApp
//
//  Created by Alexandr Bahno on 26.06.2023.
//

import Foundation
import Firebase
import FirebaseFirestoreSwift

struct ChatMessage: Codable, Identifiable {
    
    @DocumentID var id: String?
    let fromId, toId, text: String
    let timestamp: Timestamp
}
