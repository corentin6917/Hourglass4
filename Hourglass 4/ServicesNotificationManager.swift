//
//  NotificationManager.swift
//  Hourglass 4
//
//  Created by Corentin Soula on 13/11/2025.
//

import UserNotifications
import Foundation

/// Gestionnaire des notifications locales pour HOURGLASS
final class NotificationManager {
    static let shared = NotificationManager()
    
    private init() {}

    private var notificationsEnabled: Bool {
        UserDefaults.standard.object(forKey: "settings.notificationsEnabled") as? Bool ?? true
    }

    private var soundsEnabled: Bool {
        UserDefaults.standard.object(forKey: "settings.soundsEnabled") as? Bool ?? true
    }

    private var calmModeEnabled: Bool {
        UserDefaults.standard.object(forKey: "settings.calmModeEnabled") as? Bool ?? false
    }
    
    // MARK: - Authorization
    
    func requestAuthorization() async throws -> Bool {
        let center = UNUserNotificationCenter.current()
        let settings = await center.notificationSettings()
        
        if settings.authorizationStatus == .notDetermined {
            return try await center.requestAuthorization(options: [.alert, .badge, .sound])
        }
        
        return settings.authorizationStatus == .authorized
    }
    
    // MARK: - Schedule Daily Notifications
    
    func scheduleDailyNotifications() async throws {
        let center = UNUserNotificationCenter.current()
        
        // Annuler les notifications existantes
        center.removeAllPendingNotificationRequests()

        guard notificationsEnabled else {
            center.removeAllDeliveredNotifications()
            return
        }
        
        // Notification du matin (8h)
        try await scheduleMorningNotification()
        
        // Notification du soir (20h)
        if !calmModeEnabled {
            try await scheduleEveningNotification()
        }
    }
    
    private func scheduleMorningNotification() async throws {
        let content = UNMutableNotificationContent()
        content.title = "Grains Disponibles ⏳"
        content.body = "Tes 10 grains t'attendent. Quels sont tes objectifs aujourd'hui ?"
        content.sound = soundsEnabled ? .default : nil
        content.badge = 1

        // Déclencher à 8h tous les jours
        var dateComponents = DateComponents()
        dateComponents.hour = 8
        dateComponents.minute = 0
        
        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
        let request = UNNotificationRequest(
            identifier: "morning_reset",
            content: content,
            trigger: trigger
        )
        
        try await UNUserNotificationCenter.current().add(request)
    }
    
    private func scheduleEveningNotification() async throws {
        let content = UNMutableNotificationContent()
        content.title = "Le Fil s'est rafraîchi ✨"
        content.body = "Tes amis ont partagé leurs accomplissements. Va les voir !"
        content.sound = soundsEnabled ? .default : nil
        content.badge = 1

        // Déclencher à 21h tous les jours
        var dateComponents = DateComponents()
        dateComponents.hour = 21
        dateComponents.minute = 0

        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
        let request = UNNotificationRequest(
            identifier: "feed_refresh",
            content: content,
            trigger: trigger
        )

        try await UNUserNotificationCenter.current().add(request)
    }
    
    // MARK: - Special Notifications
    
    func sendStreakNotification(days: Int) async throws {
        guard notificationsEnabled else { return }

        let content = UNMutableNotificationContent()
        content.title = "🔥 Streak de \(days) jours !"
        content.body = "Continue comme ça, tu es sur une belle lancée."
        content.sound = soundsEnabled ? .default : nil
        
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        let request = UNNotificationRequest(
            identifier: "streak_\(days)",
            content: content,
            trigger: trigger
        )
        
        try await UNUserNotificationCenter.current().add(request)
    }
    
    func sendPhoenixModeNotification() async throws {
        guard notificationsEnabled else { return }

        let content = UNMutableNotificationContent()
        content.title = "🔥 Mode Phénix Activé"
        content.body = "Tu es en reconstruction. Chaque petit pas compte triple maintenant."
        content.sound = soundsEnabled ? .default : nil
        
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        let request = UNNotificationRequest(
            identifier: "phoenix_mode_activated",
            content: content,
            trigger: trigger
        )
        
        try await UNUserNotificationCenter.current().add(request)
    }
    
    func sendTimeCapsuleNotification(dayCount: Int) async throws {
        guard notificationsEnabled else { return }

        let content = UNMutableNotificationContent()
        content.title = "📦 Nouvelle Capsule Temporelle"
        content.body = "Ta capsule du jour \(dayCount) est prête à être découverte."
        content.sound = soundsEnabled ? .default : nil
        
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        let request = UNNotificationRequest(
            identifier: "time_capsule_\(dayCount)",
            content: content,
            trigger: trigger
        )
        
        try await UNUserNotificationCenter.current().add(request)
    }
}
