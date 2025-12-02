//
//  Hourglass_4App.swift
//  Hourglass 4
//
//  Created by Corentin Soula on 29/10/2025.
//

import SwiftUI
import UIKit
import SwiftData
import FirebaseCore
import FirebaseAuth

class AppDelegate: NSObject, UIApplicationDelegate {
    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil) -> Bool {
        FirebaseConfiguration.shared.setLoggerLevel(.debug) // Logs détaillés pour debug Firestore/Auth
        FirebaseApp.configure()
        Auth.auth().addStateDidChangeListener { _, user in
            guard user != nil else { return }
            Task { try? await UserManager.shared.ensureCurrentUserProfile() }
        }
        return true
    }
}

@main
struct Hourglass_4App: App {

    // Enregistre l'AppDelegate pour l'initialisation de Firebase
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    // Configuration de SwiftData
    let modelContainer: ModelContainer

    init() {
        do {
            modelContainer = try ModelContainer(
                for: UserProfile.self,
                     Grain.self,
                     Goal.self,
                     TimeCapsule.self,
                     SocialInteraction.self,
                     SocialPact.self
            )
        } catch {
            fatalError("Impossible de créer le ModelContainer: \(error)")
        }
    }

    var body: some Scene {
        WindowGroup {
            RootView(modelContext: modelContainer.mainContext)
                .modelContainer(modelContainer)
        }
    }
}
