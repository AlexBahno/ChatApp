//
//  ChatMessage.swift
//  ChatApp
//
//  Created by Alexandr Bahno on 26.06.2023.
//

import Foundation

struct ChatMessage: Identifiable {
    
    var id: String {
        documentId
    }
    
    let documentId: String
    let fromId, toId, text: String
    
    init(data: [String: Any], documentId: String) {
        self.documentId = documentId
        self.fromId = data[FirebaseConstants.fromId] as? String ?? ""
        self.toId = data[FirebaseConstants.toId] as? String ?? ""
        self.text = data[FirebaseConstants.text] as? String ?? ""
    }
}
