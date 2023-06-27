//
//  CreateNewMessageView.swift
//  ChatApp
//
//  Created by Alexandr Bahno on 22.06.2023.
//

import SwiftUI
import SDWebImageSwiftUI

class CreateNewMessageViewModel: ObservableObject {
    
    @Published var users = [ChatUser]()
    
    init() {
        Task.init {
           try? await fetchAllUsers()
        }
    }
    
    private func fetchAllUsers() async throws {
        let snapshot = try await FirebaseManager.shared.firestore
            .collection("users")
            .getDocuments()
        
        snapshot.documents.forEach { snapshot in
            do {
                let userData = snapshot.data()
                self.users.append(.init(userData: userData))
            }
        }
    }
}

struct CreateNewMessageView: View {
    
    let didSelectNewUser: (ChatUser) -> ()
    
    @Environment(\.dismiss) var dismiss
    
    @ObservedObject var vm = CreateNewMessageViewModel()
    
    var body: some View {
        NavigationView {
            ScrollView {
                ForEach(vm.users
                    .filter({ user in
                    user.uid != FirebaseManager.shared.auth.currentUser?.uid})
                ) { user in
                    Button {
                        dismiss()
                        didSelectNewUser(user)
                    } label: {
                        HStack(spacing: 16) {
                            WebImage(url: URL(string: user.profileImageUrl))
                                .resizable()
                                .scaledToFill()
                                .frame(width: 50, height: 50)
                                .clipped()
                                .cornerRadius(50)
                                .overlay {
                                    RoundedRectangle(cornerRadius: 50)
                                        .stroke(style: StrokeStyle(lineWidth: 2))
                                        .foregroundColor(Color(.label))
                                }
                            Text(user.email)
                                .foregroundColor(Color(.label))
                            Spacer()
                        }
                        .padding(.horizontal)
                        Divider()
                            .padding(.vertical, 5)
                    }
                }
            }.navigationTitle("New Message")
                .toolbar {
                    ToolbarItemGroup(placement: .navigationBarLeading) {
                        Button {
                            dismiss()
                        } label: {
                            Text("Cancel")
                        }
                    }
                }
        }
    }
}

struct CreateNewMessageView_Previews: PreviewProvider {
    static var previews: some View {
        MainMessagesView()
        //CreateNewMessageView()
    }
}
