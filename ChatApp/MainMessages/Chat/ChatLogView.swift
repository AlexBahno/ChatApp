//
//  ChatLogView.swift
//  ChatApp
//
//  Created by Alexandr Bahno on 23.06.2023.
//

import SwiftUI
import Firebase
import FirebaseFirestoreSwift


class ChatLogViewModel: ObservableObject {
    @Published var chatText = ""
    @Published var errorMessage = ""
    @Published var chatMessages = [ChatMessage]()
    var chatUser: ChatUser?
    var firestoreListener: ListenerRegistration?
    
    init(chatUser: ChatUser?) {
        self.chatUser = chatUser
        
        fetchMessages()
    }
    
    func fetchMessages() {
        guard let fromId = FirebaseManager.shared.auth.currentUser?.uid else {return}
        guard let toId = chatUser?.uid else {return}
        
        firestoreListener?.remove()
        chatMessages.removeAll()
        
        firestoreListener = FirebaseManager.shared.firestore
            .collection("messages")
            .document(fromId)
            .collection(toId)
            .order(by: FirebaseConstants.timestamp)
            .addSnapshotListener { snapshot, error in
                if let error = error {
                    self.errorMessage = "Failed to listen for messages: \(error.localizedDescription)"
                    print(error.localizedDescription)
                    return
                }
                
                snapshot?.documentChanges.forEach({ change in
                    if change.type == .added {
                        do {
                            let message = try change.document.data(as: ChatMessage.self)
                            self.chatMessages.append(message)
                        } catch {
                            print(error)
                        }
                    }
                })
                DispatchQueue.main.async {
                    self.count += 1
                }
            }
    }
    
    func handleSend() {
        guard let fromId = FirebaseManager.shared.auth.currentUser?.uid else {return}
        guard let toId = chatUser?.uid else {return}
        
        let document = FirebaseManager.shared.firestore
            .collection("messages")
            .document(fromId)
            .collection(toId)
            .document()
        
        let messageData = [FirebaseConstants.fromId: fromId,
                           FirebaseConstants.toId: toId,
                           FirebaseConstants.text:self.chatText,
                           FirebaseConstants.timestamp: Timestamp()] as [String: Any]
        
        document.setData(messageData) { error in
            if let error = error {
                self.errorMessage = "Failed to save message into Firebase: \(error.localizedDescription)"
            }
            print("Successfully saved current user sending message")
            
            self.persistRecentMessage()
            
            self.chatText = ""
            self.count += 1
        }
        
        let recipientMessageDocument = FirebaseManager.shared.firestore
            .collection("messages")
            .document(toId)
            .collection(fromId)
            .document()

        recipientMessageDocument.setData(messageData) { error in
            if let error = error {
                self.errorMessage = "Failed to save message into Firebase: \(error.localizedDescription)"
            }
            print("Successfully saved recipient user recieve message")
        }
    }
    
    private func persistRecentMessage() {
        guard let chatUser = chatUser else {return}
        guard let uid = FirebaseManager.shared.auth.currentUser?.uid else {return}
        guard let toId = self.chatUser?.uid else {return}
        
        let document = FirebaseManager.shared.firestore
            .collection("recent_messages")
            .document(uid)
            .collection("messages")
            .document(toId)
        
        let data = [
            FirebaseConstants.timestamp: Timestamp(),
            FirebaseConstants.text: self.chatText,
            FirebaseConstants.fromId: uid,
            FirebaseConstants.toId: toId,
            FirebaseConstants.profileImageUrl: chatUser.profileImageUrl,
            FirebaseConstants.email: chatUser.email
        ] as [String : Any]
                
        document.setData(data) { error in
            if let error = error {
                self.errorMessage = "Failed to save recent message: \(error.localizedDescription)"
                print("Failed to save recent message: \(error.localizedDescription)")
                return
            }
        }
        
        let recipientDocument = FirebaseManager.shared.firestore
            .collection("recent_messages")
            .document(toId)
            .collection("messages")
            .document(uid)
        
        guard let currentUser = FirebaseManager.shared.currentUser else {return}
        let recipientDate = [
            FirebaseConstants.timestamp: Timestamp(),
            FirebaseConstants.text: self.chatText,
            FirebaseConstants.fromId: uid,
            FirebaseConstants.toId: toId,
            FirebaseConstants.profileImageUrl: currentUser.profileImageUrl,
            FirebaseConstants.email: currentUser.email
        ] as [String: Any]
        
        recipientDocument.setData(recipientDate) { error in
            if let error = error {
                self.errorMessage = "Failed to save recent message: \(error.localizedDescription)"
                print("Failed to save recent message: \(error.localizedDescription)")
                return
            }
        }
    }
    
    @Published var count = 0
}

struct ChatLogView: View {
    
//    let chatUser: ChatUser?
//    
//    init(chatUser: ChatUser?) {
//        self.chatUser = chatUser
//        self.vm = .init(chatUser: chatUser)
//    }
    
    @ObservedObject var vm: ChatLogViewModel
    
    var body: some View {
        VStack {
            messagesView
            chatBottomBar
            Text(vm.errorMessage)
        }
        .navigationTitle(vm.chatUser?.email ?? "")
        .navigationBarTitleDisplayMode(.inline)
        .onDisappear {
            vm.firestoreListener?.remove()
        }
    }
    
    static let emptyScrollToString = "Empty"
    
    private var messagesView: some View {
        ScrollView {
            ScrollViewReader { proxy in
                VStack {
                    ForEach(vm.chatMessages) { message in
                        MessageView(message: message)
                    }
                    HStack { Spacer() }
                        .id(Self.emptyScrollToString)
                }
                .onReceive(vm.$count) { _ in
                    withAnimation(.easeOut(duration: 0.5)) {
                        proxy.scrollTo(Self.emptyScrollToString, anchor: .bottom)
                    }
                }
            }
        }
        .background(Color(.init(white: 0.95, alpha: 1)))
        .padding(.top, 1)
    }
    
    
    private var chatBottomBar: some View {
        HStack(spacing: 16) {
            Image(systemName: "photo.on.rectangle.angled")
                .font(.system(size: 24))
                .foregroundColor(Color(.darkGray))
            TextField("Write a message", text: $vm.chatText, axis: .vertical)
                .lineLimit(3)
                .textInputAutocapitalization(.sentences)
            Button {
                vm.handleSend()
            } label: {
                Text("Send")
                    .foregroundColor(.white)
            }
            .padding(.horizontal)
            .padding(.vertical, 8)
            .background(.blue)
            .cornerRadius(8)

        }
        .padding(.horizontal)
        .padding(.vertical, 8)
    }
}

struct MessageView: View {
    
    let message: ChatMessage
    
    var body: some View {
        VStack {
            if message.fromId == FirebaseManager.shared.auth.currentUser?.uid {
                HStack {
                    Spacer()
                    HStack {
                        Text(message.text)
                            .foregroundColor(.white)
                    }
                    .padding()
                    .background(.blue)
                    .cornerRadius(8)
                }
            } else {
                HStack {
                    HStack {
                        Text(message.text)
                            .foregroundColor(.black)
                    }
                    .padding()
                    .background(.white)
                    .cornerRadius(8)
                    Spacer()
                }
                
            }
        }
        .padding(.horizontal)
        .padding(.top, 8)
    }
}

struct ChatLogView_Previews: PreviewProvider {
    static var previews: some View {
//        NavigationView {
//            ChatLogView(chatUser: .init(userData: ["uid":"aXEx8qpIt1RMO0yXcsx2LMgzKWm","email":"test4@gmail.com"]))
//        }
        MainMessagesView()
    }
}
