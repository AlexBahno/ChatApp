//
//  ChatAppApp.swift
//  ChatApp
//
//  Created by Alexandr Bahno on 16.06.2023.
//

import SwiftUI
import FirebaseCore



class AppDelegate: NSObject, UIApplicationDelegate {
  func application(_ application: UIApplication,
                   didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
      FirebaseApp.configure()
      return true
  }
}


@main
struct ChatApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate
    var body: some Scene {
        WindowGroup {
//            LoginView(didCompleteLoginProcess: {
//
//            })
            MainMessagesView()
        }
    }
}
