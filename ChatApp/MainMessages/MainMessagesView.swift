//
//  MainMessagesView.swift
//  ChatApp
//
//  Created by Alexandr Bahno on 19.06.2023.
//

import SwiftUI
import SDWebImageSwiftUI
import Firebase
import FirebaseFirestoreSwift


class MainMessagesViewModel: ObservableObject {
    
    @Published var errorMessage = ""
    @Published var chatUser: ChatUser?
    @Published var isUserCurrentlyLoggedOut = false
    @Published var recentMessages = [RecentMessage]()
    private var firestoreListener: ListenerRegistration?

    init() {
        DispatchQueue.main.async {
            self.isUserCurrentlyLoggedOut =
                            FirebaseManager.shared.auth.currentUser?.uid == nil
        }
        Task.init {
            try await fetchCurrentUser()
        }
        fetchRecentMessages()
    }
    
    func fetchRecentMessages() {
        guard let uid = FirebaseManager.shared.auth.currentUser?.uid else {return}
        
        firestoreListener?.remove()
        self.recentMessages.removeAll()
        
        firestoreListener = FirebaseManager.shared.firestore
            .collection("recent_messages")
            .document(uid)
            .collection("messages")
            .order(by: FirebaseConstants.timestamp)
            .addSnapshotListener { querySnapshot, error in
                if let error = error {
                    self.errorMessage = "Failed to fetch recent messages: \(error.localizedDescription)"
                    return
                }
                querySnapshot?.documentChanges.forEach({ change in
                    let docId = change.document.documentID
                    
                    if let index = self.recentMessages.firstIndex(where: { rm in
                        return rm.id == docId
                    }) {
                        self.recentMessages.remove(at: index)
                    }
                    
                    do {
                        let rm = try change.document.data(as: RecentMessage.self)
                        self.recentMessages.insert(rm, at: 0)
                    } catch {
                        print(error)
                    }
                })
            }
    }
    
    func fetchCurrentUser() async throws {
        guard let uid = FirebaseManager.shared.auth.currentUser?.uid else {
            self.errorMessage = "Cannot find user with this id"
            return
        }
        
        do {
            let snapshot = try await FirebaseManager.shared.firestore
                .collection("users")
                .document(uid)
                .getDocument()
            
            guard let userData = snapshot.data() else { return }
            
            DispatchQueue.main.async {
                self.chatUser = .init(userData: userData)
                FirebaseManager.shared.currentUser = self.chatUser
            }
        } catch {
            errorMessage = error.localizedDescription
        }
    }
    

    func handleSignOut() {
        isUserCurrentlyLoggedOut.toggle()
        try? FirebaseManager.shared.auth.signOut()
    }
}

struct MainMessagesView: View {
    @State private var shouldShowLogOutOptions = false
    
    @State private var shouldNavigateToChatLogView = false
    
    @ObservedObject private var vm = MainMessagesViewModel()
    
    private var chatLogViewModel = ChatLogViewModel(chatUser: nil)
    
    var body: some View {
        NavigationView {
            VStack {
                customNavBar
                messageView
                
                NavigationLink("", isActive: $shouldNavigateToChatLogView) {
                    ChatLogView(vm: chatLogViewModel)
                }

            }
            .overlay(
                newMessageButton, alignment: .bottom)
            .toolbar(.hidden, for: .navigationBar)
        }
    }
    
    private var customNavBar: some View {
        VStack {
            HStack(spacing: 16) {
                
                WebImage(url: URL(string: vm.chatUser?.profileImageUrl ?? ""))
                    .resizable()
                    .scaledToFill()
                    .frame(width: 50, height: 50)
                    .clipped()
                    .cornerRadius(44)
                    .overlay {
                        RoundedRectangle(cornerRadius: 44)
                            .stroke(style: StrokeStyle(lineWidth: 1))
                            .foregroundColor(Color(.label))
                    }
                
                
                VStack(alignment: .leading, spacing: 4) {
                    let email = vm.chatUser?.email.replacingOccurrences(of: "@gmail.com", with: "") ?? ""
                    
                    Text(email)
                        .font(.system(size: 24, weight: .bold))
                    HStack {
                        Circle()
                            .foregroundColor(.green)
                            .frame(width: 14)
                        Text("online")
                            .font(.system(size: 12))
                            .foregroundColor(.gray.opacity(0.8))
                    }
                }
                
                Spacer()
                Button {
                    shouldShowLogOutOptions.toggle()
                } label: {
                    Image(systemName: "gear")
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(Color(.label))
                }
            }
            .padding()
            .confirmationDialog("Settings", isPresented: $shouldShowLogOutOptions, titleVisibility: .visible) {
                Button(role: .destructive) {
                    vm.handleSignOut()
                } label: {
                    Text("Sign Out")
                }

            } message: {
                Text("What do you want to do?")
            }
            Divider()
        }
        .fullScreenCover(isPresented: $vm.isUserCurrentlyLoggedOut) {
            LoginView(didCompleteLoginProcess: {
                self.vm.isUserCurrentlyLoggedOut = false
                self.vm.fetchRecentMessages()
                Task.init {
                    try await self.vm.fetchCurrentUser()
                }
            })
        }
    }
    
    
    private var messageView: some View {
        ScrollView {
            ForEach(vm.recentMessages) { recentMessage in
                VStack {
                    Button {
                        let uid = FirebaseManager.shared.auth.currentUser?.uid == recentMessage.fromId ? recentMessage.toId : recentMessage.fromId
                        self.chatUser = .init(userData: [
                            FirebaseConstants.email: recentMessage.email,
                            FirebaseConstants.profileImageUrl: recentMessage.profileImageUrl,
                            FirebaseConstants.uid: uid
                        ])
                        self.chatLogViewModel.chatUser = self.chatUser
                        self.chatLogViewModel.fetchMessages()
                        shouldNavigateToChatLogView.toggle()
                    } label: {
                        HStack(spacing: 16) {
                            WebImage(url: URL(string: recentMessage.profileImageUrl))
                                .resizable()
                                .scaledToFill()
                                .frame(width: 64, height: 64)
                                .clipped()
                                .cornerRadius(64)
                                .overlay(RoundedRectangle(cornerRadius: 64)
                                    .stroke(Color(.label), style: StrokeStyle(lineWidth: 1)))
                            
                            VStack (alignment: .leading, spacing: 8) {
                                Text(recentMessage.username)
                                    .font(.system(size: 16, weight: .bold))
                                    .multilineTextAlignment(.leading)
                                Text(recentMessage.text)
                                    .font(.system(size: 14))
                                    .foregroundColor(.gray.opacity(0.8))
                                    .multilineTextAlignment(.leading)
                                    .lineLimit(2)
                            }
                            Spacer()
                            Text(recentMessage.timeAgo)
                                .font(.system(size: 14, weight: .semibold))
                        }
                    }
                    .foregroundColor(Color(.label))
                    Divider()
                        .padding(.vertical, 8)
                }.padding(.horizontal)
            }.padding(.bottom, 50)
        }
    }
    
    @State var shouldShowNewMessageScreen = false
    
    private var newMessageButton: some View {
        Button {
            shouldShowNewMessageScreen.toggle()
        } label: {
            HStack {
                Spacer()
                Text("+ New Message")
                    .font(.system(size: 16, weight: .bold))
                Spacer()
            }
            .foregroundColor(.white)
            .padding(.vertical)
            .background(Color.blue)
            .cornerRadius(32)
            .padding(.horizontal)
            .shadow(radius: 15)
        }
        .fullScreenCover(isPresented: $shouldShowNewMessageScreen) {
            CreateNewMessageView(didSelectNewUser: { user in
                print(user.email)
                self.chatUser = user
                self.chatLogViewModel.chatUser = user
                self.chatLogViewModel.fetchMessages()
                shouldNavigateToChatLogView.toggle()
            })
        }
    }
    
    @State var chatUser: ChatUser?
}

struct MainMessagesView_Previews: PreviewProvider {
    static var previews: some View {
//        MainMessagesView()
//            .preferredColorScheme(.dark)
        
        MainMessagesView()
    }
}
