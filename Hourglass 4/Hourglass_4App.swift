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
import FirebaseMessaging
import UserNotifications
import WidgetKit

class AppDelegate: NSObject, UIApplicationDelegate, UNUserNotificationCenterDelegate, MessagingDelegate {
    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil) -> Bool {
        FirebaseConfiguration.shared.setLoggerLevel(.debug) // Logs détaillés pour debug Firestore/Auth
        FirebaseApp.configure()
        UNUserNotificationCenter.current().delegate = self
        Messaging.messaging().delegate = self
        registerForRemoteNotificationsIfAuthorized()
        Auth.auth().addStateDidChangeListener { _, user in
            guard user != nil else { return }
            Task {
                try? await UserManager.shared.ensureCurrentUserProfile()
                if let token = Messaging.messaging().fcmToken {
                    try? await UserManager.shared.updateFcmToken(token)
                }
                FriendManager.shared.startFriendRequestsListener()
            }
        }
        // Rafraîchir le widget après l'initialisation Firebase
        DispatchQueue.main.async {
            WidgetUpdateHelper.shared.updateWidgetFromFirebase()
        }

        // Configurer les notifications intelligentes
        Task {
            await SmartNotificationManager.shared.setupSmartNotifications()
        }

        return true
    }

    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        Messaging.messaging().apnsToken = deviceToken
    }

    func userNotificationCenter(_ center: UNUserNotificationCenter,
                                willPresent notification: UNNotification,
                                withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        let userInfo = notification.request.content.userInfo
        if let type = userInfo["type"] as? String, type == "friend_request" {
            completionHandler([.banner, .sound, .badge])
        } else {
            completionHandler([])
        }
    }

    func userNotificationCenter(_ center: UNUserNotificationCenter,
                                didReceive response: UNNotificationResponse,
                                withCompletionHandler completionHandler: @escaping () -> Void) {
        let userInfo = response.notification.request.content.userInfo

        switch response.actionIdentifier {
        case "VALIDATE_ACTION", "URGENT_VALIDATE":
            if let action = userInfo["action"] as? String, action == "validate-goal" {
                NotificationCenter.default.post(
                    name: NSNotification.Name("OpenValidateGoal"),
                    object: nil
                )
            }

        case "REMIND_ACTION":
            Task {
                let content = UNMutableNotificationContent()
                content.title = "⏰ Rappel : Objectifs à valider"
                content.body = "Il te reste 45 minutes avant 20h !"
                content.sound = .default

                let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 900, repeats: false)
                let request = UNNotificationRequest(
                    identifier: "remind_15min",
                    content: content,
                    trigger: trigger
                )

                try? await center.add(request)
            }

        case UNNotificationDefaultActionIdentifier:
            if let action = userInfo["action"] as? String, action == "validate-goal" {
                NotificationCenter.default.post(
                    name: NSNotification.Name("OpenValidateGoal"),
                    object: nil
                )
            }

        default:
            break
        }

        if let victoryId = userInfo["victoryId"] as? String, !victoryId.isEmpty {
            NotificationCenter.default.post(name: .switchToVictoryFeed, object: nil)
            NotificationCenter.default.post(
                name: .openVictoryFromNotification,
                object: nil,
                userInfo: ["victoryId": victoryId]
            )
        }
        completionHandler()
    }

    func messaging(_ messaging: Messaging, didReceiveRegistrationToken fcmToken: String?) {
        guard let fcmToken, !fcmToken.isEmpty else { return }
        Task { try? await UserManager.shared.updateFcmToken(fcmToken) }
    }

    private func registerForRemoteNotificationsIfAuthorized() {
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            guard settings.authorizationStatus == .authorized || settings.authorizationStatus == .provisional else { return }
            DispatchQueue.main.async {
                UIApplication.shared.registerForRemoteNotifications()
            }
        }
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
                .environmentObject(TutorialManager.shared)
                .handleDeepLinks() // Gère les deep links depuis les widgets
        }
    }
}
