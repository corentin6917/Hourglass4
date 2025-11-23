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
        
        // Notification du matin (8h)
        try await scheduleMorningNotification()
        
        // Notification du soir (20h)
        try await scheduleEveningNotification()
    }
    
    private func scheduleMorningNotification() async throws {
        let content = UNMutableNotificationContent()
        content.title = "⏳ Nouveaux Grains Disponibles"
        content.body = "Tes 10 grains t'attendent. Quels sont tes objectifs aujourd'hui ?"
        content.sound = .default
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
        content.title = "🌙 Temps de Valider"
        content.body = "Il est temps de valider tes victoires de la journée."
        content.sound = .default
        content.badge = 1
        
        // Déclencher à 20h tous les jours
        var dateComponents = DateComponents()
        dateComponents.hour = 20
        dateComponents.minute = 0
        
        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
        let request = UNNotificationRequest(
            identifier: "evening_validation",
            content: content,
            trigger: trigger
        )
        
        try await UNUserNotificationCenter.current().add(request)
    }
    
    // MARK: - Special Notifications
    
    func sendStreakNotification(days: Int) async throws {
        let content = UNMutableNotificationContent()
        content.title = "🔥 Streak de \(days) jours !"
        content.body = "Continue comme ça, tu es sur une belle lancée."
        content.sound = .default
        
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        let request = UNNotificationRequest(
            identifier: "streak_\(days)",
            content: content,
            trigger: trigger
        )
        
        try await UNUserNotificationCenter.current().add(request)
    }
    
    func sendPhoenixModeNotification() async throws {
        let content = UNMutableNotificationContent()
        content.title = "🔥 Mode Phénix Activé"
        content.body = "Tu es en reconstruction. Chaque petit pas compte triple maintenant."
        content.sound = .default
        
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        let request = UNNotificationRequest(
            identifier: "phoenix_mode_activated",
            content: content,
            trigger: trigger
        )
        
        try await UNUserNotificationCenter.current().add(request)
    }
    
    func sendTimeCapsuleNotification(dayCount: Int) async throws {
        let content = UNMutableNotificationContent()
        content.title = "📦 Nouvelle Capsule Temporelle"
        content.body = "Ta capsule du jour \(dayCount) est prête à être découverte."
        content.sound = .default
        
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        let request = UNNotificationRequest(
            identifier: "time_capsule_\(dayCount)",
            content: content,
            trigger: trigger
        )
        
        try await UNUserNotificationCenter.current().add(request)
    }
}
