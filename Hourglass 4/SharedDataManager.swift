//
//  SharedDataManager.swift
//  Hourglass 4
//
//  Gère le partage de données entre l'app principale et le widget
//

import Foundation
import WidgetKit

class SharedDataManager {
    static let shared = SharedDataManager()

    // IMPORTANT: Remplacer par votre App Group ID après configuration
    // Format: group.com.votrecompany.hourglass4
    private let appGroupID = "group.com.hourglass.hourglass4"

    private var sharedDefaults: UserDefaults? {
        UserDefaults(suiteName: appGroupID)
    }

    // MARK: - Keys
    private enum Keys {
        static let grainsToday = "widget_grains_today"
        static let grainsYesterday = "widget_grains_yesterday"
        static let currentStreak = "widget_current_streak"
        static let pendingGoals = "widget_pending_goals"
        static let completedGoals = "widget_completed_goals"
        static let lastUpdateDate = "widget_last_update_date"
        static let pendingGoalsList = "widget_pending_goals_list"
    }

    // MARK: - Read Data
    var grainsToday: Int {
        sharedDefaults?.integer(forKey: Keys.grainsToday) ?? 0
    }

    var grainsYesterday: Int {
        sharedDefaults?.integer(forKey: Keys.grainsYesterday) ?? 0
    }

    var currentStreak: Int {
        sharedDefaults?.integer(forKey: Keys.currentStreak) ?? 0
    }

    var pendingGoals: Int {
        sharedDefaults?.integer(forKey: Keys.pendingGoals) ?? 0
    }

    var completedGoals: Int {
        sharedDefaults?.integer(forKey: Keys.completedGoals) ?? 0
    }

    var timeUntilDeadline: TimeInterval {
        let calendar = Calendar.current
        let now = Date()

        var components = calendar.dateComponents([.year, .month, .day], from: now)
        components.hour = 20
        components.minute = 0
        components.second = 0

        guard let deadline = calendar.date(from: components) else {
            return 0
        }

        if now > deadline {
            return 0
        }

        return deadline.timeIntervalSince(now)
    }

    func getPendingGoals() -> [PendingGoal] {
        guard let data = sharedDefaults?.data(forKey: Keys.pendingGoalsList),
              let goals = try? JSONDecoder().decode([PendingGoal].self, from: data) else {
            return []
        }
        return goals
    }

    // MARK: - Write Data
    func updateWidgetData(
        grainsToday: Int,
        grainsYesterday: Int,
        currentStreak: Int,
        pendingGoals: Int,
        completedGoals: Int,
        pendingGoalsList: [PendingGoal] = []
    ) {
        sharedDefaults?.set(grainsToday, forKey: Keys.grainsToday)
        sharedDefaults?.set(grainsYesterday, forKey: Keys.grainsYesterday)
        sharedDefaults?.set(currentStreak, forKey: Keys.currentStreak)
        sharedDefaults?.set(pendingGoals, forKey: Keys.pendingGoals)
        sharedDefaults?.set(completedGoals, forKey: Keys.completedGoals)
        sharedDefaults?.set(Date(), forKey: Keys.lastUpdateDate)

        if let encoded = try? JSONEncoder().encode(pendingGoalsList) {
            sharedDefaults?.set(encoded, forKey: Keys.pendingGoalsList)
        }

        WidgetCenter.shared.reloadAllTimelines()
    }

    func refreshWidget() {
        WidgetCenter.shared.reloadAllTimelines()
    }

    func clearWidgetData() {
        sharedDefaults?.removeObject(forKey: Keys.grainsToday)
        sharedDefaults?.removeObject(forKey: Keys.grainsYesterday)
        sharedDefaults?.removeObject(forKey: Keys.currentStreak)
        sharedDefaults?.removeObject(forKey: Keys.pendingGoals)
        sharedDefaults?.removeObject(forKey: Keys.completedGoals)
        sharedDefaults?.removeObject(forKey: Keys.lastUpdateDate)
        sharedDefaults?.removeObject(forKey: Keys.pendingGoalsList)

        WidgetCenter.shared.reloadAllTimelines()
    }
}

// MARK: - PendingGoal Model (partagé entre app et widget)
struct PendingGoal: Codable {
    let title: String
    let emoji: String
    let grains: Int
}
