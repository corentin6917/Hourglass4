//
//  WidgetUpdateHelper.swift
//  Hourglass 4
//
//  Helper pour mettre à jour le widget automatiquement
//

import Foundation
import FirebaseCore
import FirebaseFirestore
import WidgetKit

class WidgetUpdateHelper {
    static let shared = WidgetUpdateHelper()

    private init() {}

    /// Met à jour toutes les données du widget
    func updateWidget(from userProfile: UserProfile?) {
        guard let profile = userProfile else {
            SharedDataManager.shared.clearWidgetData()
            return
        }

        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())

        // Calculer les grains d'aujourd'hui
        let grainsToday = profile.grains
            .filter { $0.type == .earned }
            .filter { grain in
                guard let earnedDate = grain.earnedDate else { return false }
                return calendar.isDate(earnedDate, inSameDayAs: today)
            }
            .reduce(0.0) { $0 + $1.value }

        // Calculer les grains d'hier
        let yesterday = calendar.date(byAdding: .day, value: -1, to: today) ?? today
        let grainsYesterday = profile.grains
            .filter { $0.type == .earned }
            .filter { grain in
                guard let earnedDate = grain.earnedDate else { return false }
                return calendar.isDate(earnedDate, inSameDayAs: yesterday)
            }
            .reduce(0.0) { $0 + $1.value }

        // Compter les objectifs
        let todayGoals = profile.goals.filter { goal in
            calendar.isDate(goal.targetDate, inSameDayAs: today)
        }
        let pendingGoalsFiltered = todayGoals.filter { $0.status == .pending }
        let completedGoals = todayGoals.filter { $0.status == .completed }.count

        // Créer la liste des objectifs en cours pour le Lock Screen Widget
        let pendingGoalsList = pendingGoalsFiltered.map { goal in
            PendingGoal(
                title: goal.title,
                emoji: goal.category.emoji,
                grains: Int(goal.grainValue)
            )
        }

        // Mettre à jour le widget
        SharedDataManager.shared.updateWidgetData(
            grainsToday: Int(grainsToday),
            grainsYesterday: Int(grainsYesterday),
            currentStreak: profile.currentStreak,
            pendingGoals: pendingGoalsFiltered.count,
            completedGoals: completedGoals,
            pendingGoalsList: pendingGoalsList
        )
    }

    /// Met à jour le widget depuis Firebase (pour les données en temps réel)
    func updateWidgetFromFirebase() {
        guard FirebaseApp.app() != nil else {
            return
        }
        guard let userId = UserManager.shared.currentUserId else {
            return
        }

        let db = Firestore.firestore()
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())

        // Récupérer les stats du jour depuis Firebase
        db.collection("users").document(userId).getDocument { snapshot, error in
            guard let data = snapshot?.data(),
                  error == nil else {
                return
            }

            let grainsToday = data["dailyGrainsEarned"] as? Int ?? 0
            let grainsYesterday = data["yesterdayGrainsEarned"] as? Int ?? 0
            let currentStreak = data["currentStreak"] as? Int ?? 0

            // Compter les objectifs du jour
            Task {
                let goals = await GoalManager.shared.todayGoals
                let pendingGoalsFiltered = goals.filter { $0.status == .pending }
                let completed = goals.filter { $0.status == .completed }.count

                // Créer la liste des objectifs en cours pour le Lock Screen Widget
                let pendingGoalsList = pendingGoalsFiltered.map { goal in
                    PendingGoal(
                        title: goal.title,
                        emoji: goal.category.emoji,
                        grains: Int(goal.grainValue)
                    )
                }

                SharedDataManager.shared.updateWidgetData(
                    grainsToday: grainsToday,
                    grainsYesterday: grainsYesterday,
                    currentStreak: currentStreak,
                    pendingGoals: pendingGoalsFiltered.count,
                    completedGoals: completed,
                    pendingGoalsList: pendingGoalsList
                )
            }
        }
    }
}

// MARK: - Extension pour mettre à jour automatiquement
extension GoalManager {
    /// Appeler cette méthode après chaque modification d'objectif
    func refreshWidget() {
        WidgetUpdateHelper.shared.updateWidgetFromFirebase()
    }
}
