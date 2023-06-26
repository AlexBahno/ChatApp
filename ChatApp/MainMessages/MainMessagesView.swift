//
//  MainMessagesView.swift
//  ChatApp
//
//  Created by Alexandr Bahno on 19.06.2023.
//

import SwiftUI
import SDWebImageSwiftUI


class MainMessagesViewModel: ObservableObject {
    
    @Published var errorMessage = ""
    @Published var chatUser: ChatUser?
    @Published var isUserCurrentlyLoggedOut = false

    init() {
        Task.init {
            try await fetchCurrentUser()
        }
        self.isUserCurrentlyLoggedOut =
                        FirebaseManager.shared.auth.currentUser?.uid == nil
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
            
            guard let userData = snapshot.data() else {
                self.errorMessage = "Cannot convert data from db"
                return
            }
            self.chatUser = .init(userData: userData)
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
    
    var body: some View {
        NavigationView {
            VStack {
                customNavBar
                messageView
                
                NavigationLink("", isActive: $shouldNavigateToChatLogView) {
                    ChatLogView(chatUser: self.chatUser)
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
                Task.init {
                    try await self.vm.fetchCurrentUser()
                }
            })
        }
    }
    
    
    private var messageView: some View {
        ScrollView {
            ForEach(0..<10, id: \.self) { num in
                VStack {
                    Button {
                        shouldNavigateToChatLogView.toggle()
                    } label: {
                        HStack(spacing: 16) {
                            Image(systemName: "person.fill")
                                .font(.system(size: 32))
                                .padding(8)
                                .overlay {
                                    RoundedRectangle(cornerRadius: 44)
                                        .stroke(style: StrokeStyle(lineWidth: 1))
                                }
                            VStack (alignment: .leading) {
                                Text("Username")
                                    .font(.system(size: 16, weight: .bold))
                                Text("Mesage sent to user")
                                    .font(.system(size: 14))
                                    .foregroundColor(.gray.opacity(0.8))
                            }
                            Spacer()
                            Text("22d")
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
