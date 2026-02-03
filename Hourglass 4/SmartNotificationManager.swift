//
//  SmartNotificationManager.swift
//  Hourglass 4
//
//  Notifications intelligentes avec objectifs en cours et actions rapides
//

import UserNotifications
import Foundation
import FirebaseFirestore

class SmartNotificationManager {
    static let shared = SmartNotificationManager()

    private init() {}

    // MARK: - Configuration

    func setupSmartNotifications() async {
        let center = UNUserNotificationCenter.current()
        let settings = await center.notificationSettings()
        let status = settings.authorizationStatus

        guard status == .authorized || status == .provisional else {
            print("ℹ️ Notifications non autorisées: prompt custom affiché dans l'app")
            return
        }

        // Les permissions sont déjà accordées, on planifie simplement.
        await scheduleSmartNotifications()
    }

    // MARK: - Notifications Intelligentes

    func scheduleSmartNotifications() async {
        let center = UNUserNotificationCenter.current()

        // Supprimer les anciennes
        center.removeAllPendingNotificationRequests()

        // 1. Notification de rappel à 19h (si objectifs non validés)
        await scheduleEveningReminder()

        // 2. Notification urgente à 19h45 (si < 15min)
        await scheduleUrgentReminder()

        // 3. Notification quotidienne à 8h (nouveaux objectifs)
        await scheduleMorningMotivation()
    }

    // MARK: - Notification du Soir (19h) ⭐ PRINCIPALE

    private func scheduleEveningReminder() async {
        // Récupérer les objectifs en cours
        let pendingGoals = await getPendingGoals()

        guard !pendingGoals.isEmpty else { return }

        let content = UNMutableNotificationContent()

        // Titre selon le nombre d'objectifs
        if pendingGoals.count == 1 {
            content.title = "⏰ 1h restante !"
        } else {
            content.title = "⏰ 1h restante pour \(pendingGoals.count) objectifs"
        }

        // Corps avec liste des objectifs
        var body = ""
        for (index, goal) in pendingGoals.prefix(3).enumerated() {
            body += "\(goal.emoji) \(goal.title) (+\(goal.grains) grains)"
            if index < min(2, pendingGoals.count - 1) {
                body += "\n"
            }
        }

        if pendingGoals.count > 3 {
            body += "\n+ \(pendingGoals.count - 3) autre(s)"
        }

        content.body = body
        content.sound = .default
        content.badge = NSNumber(value: pendingGoals.count)
        content.categoryIdentifier = "VALIDATE_GOALS"

        // Deep link pour ouvrir la caméra
        content.userInfo = ["action": "validate-goal"]

        // Ajouter des actions (boutons)
        let validateAction = UNNotificationAction(
            identifier: "VALIDATE_ACTION",
            title: "📸 Valider maintenant",
            options: [.foreground]
        )

        let remindAction = UNNotificationAction(
            identifier: "REMIND_ACTION",
            title: "⏰ Me rappeler dans 15 min",
            options: []
        )

        let category = UNNotificationCategory(
            identifier: "VALIDATE_GOALS",
            actions: [validateAction, remindAction],
            intentIdentifiers: [],
            options: []
        )

        UNUserNotificationCenter.current().setNotificationCategories([category])

        // Trigger à 19h tous les jours
        var dateComponents = DateComponents()
        dateComponents.hour = 19
        dateComponents.minute = 0

        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)

        let request = UNNotificationRequest(
            identifier: "evening_reminder_19h",
            content: content,
            trigger: trigger
        )

        do {
            try await UNUserNotificationCenter.current().add(request)
            print("✅ Notification 19h programmée")
        } catch {
            print("❌ Erreur notification 19h: \(error)")
        }
    }

    // MARK: - Notification Urgente (19h45) 🚨

    private func scheduleUrgentReminder() async {
        let pendingGoals = await getPendingGoals()

        guard !pendingGoals.isEmpty else { return }

        let content = UNMutableNotificationContent()
        content.title = "🚨 URGENT : 15 minutes restantes !"
        content.body = "\(pendingGoals.count) objectif(s) à valider avant 20h\nTa streak de \(await getCurrentStreak()) jours est en danger ! 🔥"
        content.sound = UNNotificationSound.defaultCritical // Son fort
        content.badge = NSNumber(value: pendingGoals.count)
        content.categoryIdentifier = "URGENT_VALIDATE"
        content.userInfo = ["action": "validate-goal"]

        // Action urgente
        let validateAction = UNNotificationAction(
            identifier: "URGENT_VALIDATE",
            title: "📸 VALIDER MAINTENANT",
            options: [.foreground]
        )

        let category = UNNotificationCategory(
            identifier: "URGENT_VALIDATE",
            actions: [validateAction],
            intentIdentifiers: [],
            options: []
        )

        UNUserNotificationCenter.current().setNotificationCategories([category])

        // Trigger à 19h45
        var dateComponents = DateComponents()
        dateComponents.hour = 19
        dateComponents.minute = 45

        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)

        let request = UNNotificationRequest(
            identifier: "urgent_reminder_1945",
            content: content,
            trigger: trigger
        )

        do {
            try await UNUserNotificationCenter.current().add(request)
            print("✅ Notification urgente 19h45 programmée")
        } catch {
            print("❌ Erreur notification urgente: \(error)")
        }
    }

    // MARK: - Notification du Matin (8h)

    private func scheduleMorningMotivation() async {
        let content = UNMutableNotificationContent()
        content.title = "Tes grains t'attendent"
        content.body = "Fixe tes objectifs du jour."
        content.sound = .default
        content.userInfo = ["action": "create-goal"]

        var dateComponents = DateComponents()
        dateComponents.hour = 8
        dateComponents.minute = 0

        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)

        let request = UNNotificationRequest(
            identifier: "morning_motivation",
            content: content,
            trigger: trigger
        )

        do {
            try await UNUserNotificationCenter.current().add(request)
            print("✅ Notification matinale programmée")
        } catch {
            print("❌ Erreur notification matin: \(error)")
        }
    }

    // MARK: - Notifications Instantanées

    /// Envoyer une notification immédiate avec les objectifs en cours
    func sendObjectivesReminder() async {
        let pendingGoals = await getPendingGoals()

        guard !pendingGoals.isEmpty else { return }

        let content = UNMutableNotificationContent()
        content.title = "📋 \(pendingGoals.count) objectif(s) en attente"

        var body = ""
        for goal in pendingGoals.prefix(3) {
            body += "\(goal.emoji) \(goal.title)\n"
        }
        content.body = body
        content.sound = .default
        content.categoryIdentifier = "VALIDATE_GOALS"
        content.userInfo = ["action": "validate-goal"]

        let request = UNNotificationRequest(
            identifier: UUID().uuidString,
            content: content,
            trigger: nil // Immédiat
        )

        do {
            try await UNUserNotificationCenter.current().add(request)
        } catch {
            print("❌ Erreur notification immédiate: \(error)")
        }
    }

    /// Notification quand objectif complété
    func sendGoalCompletedNotification(goal: Goal) async {
        let content = UNMutableNotificationContent()
        content.title = "✅ Objectif validé !"
        content.body = "\(goal.category.emoji) \(goal.title) (+\(Int(goal.grainValue)) grains)"
        content.sound = .default

        let request = UNNotificationRequest(
            identifier: UUID().uuidString,
            content: content,
            trigger: nil
        )

        do {
            try await UNUserNotificationCenter.current().add(request)
        } catch {
            print("❌ Erreur notification complétée: \(error)")
        }
    }

    /// Notification streak cassée
    func sendStreakLostNotification() async {
        let content = UNMutableNotificationContent()
        content.title = "💔 Streak perdue"
        content.body = "Ta série s'est arrêtée. Recommence dès demain ! 💪"
        content.sound = .default

        let request = UNNotificationRequest(
            identifier: UUID().uuidString,
            content: content,
            trigger: nil
        )

        do {
            try await UNUserNotificationCenter.current().add(request)
        } catch {
            print("❌ Erreur notification streak: \(error)")
        }
    }

    // MARK: - Helpers

    private func getPendingGoals() async -> [PendingGoalNotif] {
        guard let userId = UserManager.shared.currentUserId else { return [] }

        let goals = await GoalManager.shared.todayGoals
        let pending = goals.filter { $0.status == .pending }

        return pending.map { goal in
            PendingGoalNotif(
                title: goal.title,
                emoji: goal.category.emoji,
                grains: Int(goal.grainValue)
            )
        }
    }

    private func getCurrentStreak() async -> Int {
        guard let userId = UserManager.shared.currentUserId else { return 0 }

        let db = Firestore.firestore()
        do {
            let doc = try await db.collection("users").document(userId).getDocument()
            return doc.data()?["currentStreak"] as? Int ?? 0
        } catch {
            return 0
        }
    }
}

// MARK: - Models

struct PendingGoalNotif {
    let title: String
    let emoji: String
    let grains: Int
}
