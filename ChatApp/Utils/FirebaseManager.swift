//
//  FirebaseManager.swift
//  ChatApp
//
//  Created by Alexandr Bahno on 19.06.2023.
//

import Foundation
import Firebase
import FirebaseStorage

class FirebaseManager: NSObject {
    let auth: Auth
    let storage: Storage
    let firestore: Firestore
    
    var currentUser: ChatUser?
    
    static let shared = FirebaseManager()
    
    override init() {
        self.auth = Auth.auth()
        self.storage = Storage.storage()
        self.firestore = Firestore.firestore()
        
        super.init()
    }
}
