//
//  NotificationPermissionManager.swift
//  Hourglass 4
//
//  Gère les permissions et l'état des notifications push
//

import Foundation
import Combine
import UserNotifications

@MainActor
class NotificationPermissionManager: ObservableObject {
    static let shared = NotificationPermissionManager()

    @Published var authorizationStatus: UNAuthorizationStatus = .notDetermined

    private init() {
        Task {
            await checkAuthorizationStatus()
        }
    }

    func checkAuthorizationStatus() async {
        let settings = await UNUserNotificationCenter.current().notificationSettings()
        authorizationStatus = settings.authorizationStatus
    }

    func requestAuthorization() async -> Bool {
        do {
            let granted = try await UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound])
            await checkAuthorizationStatus()
            return granted
        } catch {
            print("Erreur lors de la demande d'autorisation de notifications: \(error)")
            return false
        }
    }

    var isAuthorized: Bool {
        return authorizationStatus == .authorized || authorizationStatus == .provisional
    }

    var shouldShowPermissionPrompt: Bool {
        return authorizationStatus == .notDetermined || authorizationStatus == .denied
    }
}
