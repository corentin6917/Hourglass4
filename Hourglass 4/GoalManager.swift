//
//  GoalManager.swift
//  Hourglass 4
//
//  Manager pour la gestion des objectifs dans Firebase
//

import Foundation
import Combine
import FirebaseAuth
import FirebaseFirestore

class GoalManager: ObservableObject {
    static let shared = GoalManager()

    private let db = Firestore.firestore()

    @Published var todayGoals: [FirebaseGoal] = []
    @Published var isLoading = false

    private init() {}

    // MARK: - Créer un objectif

    func createGoal(
        title: String,
        description: String?,
        category: GoalCategory,
        baseValue: Double
    ) async throws -> FirebaseGoal {
        guard let currentUser = Auth.auth().currentUser else {
            print("❌ GoalManager: Utilisateur non connecté")
            throw NSError(domain: "GoalManager", code: 401, userInfo: [NSLocalizedDescriptionKey: "Utilisateur non connecté"])
        }

        print("✅ GoalManager: Utilisateur connecté - UID: \(currentUser.uid)")

        let goal = FirebaseGoal(
            userId: currentUser.uid,
            title: title,
            goalDescription: description,
            category: category,
            baseValue: baseValue,
            grainValue: baseValue,
            status: .pending,
            createdAt: Date()
        )

        print("📝 GoalManager: Création de l'objectif - ID: \(goal.goalId), Titre: \(goal.title)")

        try await db.collection("goals").document(goal.goalId).setData(goal.dictionary)

        print("✅ GoalManager: Objectif sauvegardé dans Firebase")

        // Recharger les objectifs
        await loadTodayGoals()

        return goal
    }

    // MARK: - Charger les objectifs du jour

    func loadTodayGoals() async {
        guard let currentUser = Auth.auth().currentUser else {
            print("❌ loadTodayGoals: Utilisateur non connecté")
            return
        }

        print("🔄 loadTodayGoals: Début du chargement pour UID: \(currentUser.uid)")

        await MainActor.run {
            isLoading = true
        }

        do {
            let calendar = AppTimeZone.calendar
            let today = calendar.startOfDay(for: Date())
            let tomorrow = calendar.date(byAdding: .day, value: 1, to: today)!

            print("📅 loadTodayGoals: Plage de dates - De: \(today) à \(tomorrow)")

            let snapshot = try await db.collection("goals")
                .whereField("userId", isEqualTo: currentUser.uid)
                .whereField("createdAt", isGreaterThanOrEqualTo: Timestamp(date: today))
                .whereField("createdAt", isLessThan: Timestamp(date: tomorrow))
                .order(by: "createdAt", descending: false)
                .getDocuments()

            print("📊 loadTodayGoals: \(snapshot.documents.count) documents trouvés")

            let goals = snapshot.documents.compactMap { FirebaseGoal.from(document: $0) }

            print("✅ loadTodayGoals: \(goals.count) objectifs chargés")
            goals.forEach { goal in
                print("   - \(goal.title) (ID: \(goal.goalId), Statut: \(goal.status))")
            }

            await MainActor.run {
                self.todayGoals = goals
                self.isLoading = false
                print("🎯 loadTodayGoals: todayGoals mis à jour avec \(goals.count) objectifs")
            }
        } catch {
            print("❌ Erreur de chargement des objectifs: \(error.localizedDescription)")
            await MainActor.run {
                self.isLoading = false
            }
        }
    }

    // MARK: - Valider un objectif

    func validateGoal(_ goal: FirebaseGoal, photoURL: String) async throws {
        guard let currentUser = Auth.auth().currentUser else {
            throw NSError(domain: "GoalManager", code: 401)
        }

        // Mettre à jour le statut et sauvegarder l'URL de la photo
        try await db.collection("goals").document(goal.goalId).updateData([
            "status": GoalStatus.completed.rawValue,
            "completedAt": Timestamp(date: Date()),
            "photoURL": photoURL
        ])

        // Recharger les objectifs
        await loadTodayGoals()
    }

    // MARK: - Supprimer un objectif

    func deleteGoal(_ goal: FirebaseGoal) async throws {
        try await db.collection("goals").document(goal.goalId).delete()

        // Recharger les objectifs
        await loadTodayGoals()
    }

    // MARK: - Historique (fréquence perso)

    func countRecentGoals(matching title: String, withinDays days: Int) async -> Int {
        guard let currentUser = Auth.auth().currentUser else {
            return 0
        }

        let normalized = normalizeTitle(title)
        guard !normalized.isEmpty else { return 0 }

        let startDate = AppTimeZone.calendar.date(byAdding: .day, value: -days, to: Date()) ?? Date()

        do {
            let snapshot = try await db.collection("goals")
                .whereField("userId", isEqualTo: currentUser.uid)
                .whereField("createdAt", isGreaterThanOrEqualTo: Timestamp(date: startDate))
                .getDocuments()

            return snapshot.documents.compactMap { FirebaseGoal.from(document: $0) }
                .filter { normalizeTitle($0.title) == normalized }
                .count
        } catch {
            print("❌ Erreur fréquence objectifs: \(error.localizedDescription)")
            return 0
        }
    }

    private func normalizeTitle(_ title: String) -> String {
        let trimmed = title.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        let parts = trimmed.split(whereSeparator: { $0.isWhitespace })
        return parts.joined(separator: " ")
    }

    // MARK: - Charger l'historique de la semaine en cours

    func loadCurrentWeekData() async -> [(date: Date, earned: Double, potential: Double)] {
        guard let currentUser = Auth.auth().currentUser else {
            print("❌ loadCurrentWeekData: Utilisateur non connecté")
            return []
        }

        print("🔄 loadCurrentWeekData: Chargement de l'historique de la semaine en cours")

        let calendar = AppTimeZone.calendar
        var historicalData: [(date: Date, earned: Double, potential: Double)] = []

        // Trouver le lundi de cette semaine
        let today = Date()
        var weekday = calendar.component(.weekday, from: today)
        // Convertir dimanche (1) en 7, et ajuster pour que lundi soit 1
        weekday = weekday == 1 ? 7 : weekday - 1

        let daysFromMonday = weekday - 1
        guard let monday = calendar.date(byAdding: .day, value: -daysFromMonday, to: calendar.startOfDay(for: today)) else {
            return []
        }

        print("📅 Lundi de cette semaine: \(monday.formatted(date: .abbreviated, time: .omitted))")

        do {
            // Charger les données du lundi au dimanche (7 jours)
            for dayOffset in 0..<7 {
                guard let date = calendar.date(byAdding: .day, value: dayOffset, to: monday) else { continue }
                let startOfDay = calendar.startOfDay(for: date)
                let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay)!

                let snapshot = try await db.collection("goals")
                    .whereField("userId", isEqualTo: currentUser.uid)
                    .whereField("createdAt", isGreaterThanOrEqualTo: Timestamp(date: startOfDay))
                    .whereField("createdAt", isLessThan: Timestamp(date: endOfDay))
                    .getDocuments()

                let goals = snapshot.documents.compactMap { FirebaseGoal.from(document: $0) }

                let earned = goals
                    .filter { $0.status == .completed }
                    .reduce(0) { $0 + $1.grainValue }

                let potential = goals
                    .filter { $0.status == .pending }
                    .reduce(0) { $0 + $1.grainValue }

                historicalData.append((date: startOfDay, earned: earned, potential: max(potential, 10.0)))

                print("📊 \(startOfDay.formatted(date: .abbreviated, time: .omitted)): \(earned) grains gagnés / \(potential) potentiel")
            }
        } catch {
            print("❌ Erreur lors du chargement de l'historique: \(error.localizedDescription)")
        }

        return historicalData
    }

    // MARK: - Système de Grains Adaptatifs

    /// Calcule le nombre de grains disponibles pour aujourd'hui basé sur les performances des 7 derniers jours
    func calculateAdaptiveGrainsBudget() async -> Double {
        guard let currentUser = Auth.auth().currentUser else {
            return 10.0 // Valeur par défaut
        }

        print("🧮 calculateAdaptiveGrainsBudget: Calcul du budget adaptatif")

        // Récupérer les données des 7 derniers jours
        let calendar = AppTimeZone.calendar
        let today = calendar.startOfDay(for: Date())
        let sevenDaysAgo = calendar.date(byAdding: .day, value: -7, to: today) ?? today

        do {
            let snapshot = try await db.collection("goals")
                .whereField("userId", isEqualTo: currentUser.uid)
                .whereField("createdAt", isGreaterThanOrEqualTo: Timestamp(date: sevenDaysAgo))
                .whereField("createdAt", isLessThan: Timestamp(date: today))
                .getDocuments()

            let goals = snapshot.documents.compactMap { FirebaseGoal.from(document: $0) }

            // Grouper par jour et calculer le ratio pour chaque jour
            var dailyRatios: [Double] = []

            for dayOffset in 0..<7 {
                guard let date = calendar.date(byAdding: .day, value: -dayOffset, to: today) else { continue }
                let startOfDay = calendar.startOfDay(for: date)
                let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay)!

                let dayGoals = goals.filter {
                    $0.createdAt >= startOfDay && $0.createdAt < endOfDay
                }

                let earned = dayGoals.filter { $0.status == .completed }.reduce(0.0) { $0 + $1.grainValue }
                let total = dayGoals.reduce(0.0) { $0 + $1.grainValue }

                if total > 0 {
                    let ratio = earned / total
                    dailyRatios.append(ratio)
                    print("   📊 Jour -\(dayOffset): \(earned)/\(total) = \(Int(ratio * 100))%")
                }
            }

            // Calculer la moyenne des ratios
            guard !dailyRatios.isEmpty else {
                print("   ℹ️ Pas assez de données, retour à 10 grains")
                return 10.0
            }

            let averageRatio = dailyRatios.reduce(0.0, +) / Double(dailyRatios.count)
            print("   📈 Moyenne sur 7 jours: \(Int(averageRatio * 100))%")

            let activeDaysCount = dailyRatios.count

            // Récupérer le budget actuel depuis le profil utilisateur
            let userDoc = try await db.collection("users").document(currentUser.uid).getDocument()
            let currentBudget = userDoc.data()?["dailyGrainsBudget"] as? Double ?? 10.0

            // Calculer l'ajustement basé sur la performance
            var adjustment: Double = 0.0

            switch averageRatio {
            case ..<0.40:
                adjustment = -1.0 // Réduction si perf faible
            case 0.40..<0.75:
                adjustment = 0.0  // Stable si perf moyenne
            default: // >= 0.75
                adjustment = activeDaysCount >= 5 ? 1.0 : 0.0 // Augmente seulement si assez de jours actifs
            }

            // Appliquer l'ajustement avec limites min/max
            var newBudget = currentBudget + adjustment
            newBudget = max(5.0, min(15.0, newBudget)) // Entre 5 et 15 grains

            print("   🎯 Budget actuel: \(currentBudget) → Nouveau: \(newBudget) (ajustement: \(adjustment))")

            // Sauvegarder le nouveau budget dans Firebase
            try await db.collection("users").document(currentUser.uid).setData([
                "dailyGrainsBudget": newBudget,
                "lastBudgetUpdate": Timestamp(date: Date())
            ], merge: true)

            return newBudget

        } catch {
            print("❌ Erreur lors du calcul du budget adaptatif: \(error.localizedDescription)")
            return 10.0
        }
    }

    /// Récupère le budget quotidien de grains pour l'utilisateur
    func getDailyGrainsBudget() async -> Double {
        guard let currentUser = Auth.auth().currentUser else {
            return 10.0
        }

        do {
            let userDoc = try await db.collection("users").document(currentUser.uid).getDocument()

            // Vérifier si le budget a été calculé aujourd'hui
            if let lastUpdate = (userDoc.data()?["lastBudgetUpdate"] as? Timestamp)?.dateValue() {
                let calendar = AppTimeZone.calendar
                if calendar.isDateInToday(lastUpdate) {
                    // Budget déjà à jour pour aujourd'hui
                    return userDoc.data()?["dailyGrainsBudget"] as? Double ?? 10.0
                }
            }

            // Recalculer le budget si pas à jour
            return await calculateAdaptiveGrainsBudget()

        } catch {
            print("❌ Erreur lors de la récupération du budget: \(error.localizedDescription)")
            return 10.0
        }
    }
}

// MARK: - Modèle Firebase pour les objectifs

struct FirebaseGoal: Identifiable, Codable {
    var id: String { goalId }
    let goalId: String
    let userId: String
    let title: String
    let goalDescription: String?
    let category: GoalCategory
    let baseValue: Double
    let grainValue: Double
    let status: GoalStatus
    let createdAt: Date
    let completedAt: Date?
    let photoURL: String?  // URL de la photo de validation

    init(
        goalId: String = UUID().uuidString,
        userId: String,
        title: String,
        goalDescription: String?,
        category: GoalCategory,
        baseValue: Double,
        grainValue: Double,
        status: GoalStatus,
        createdAt: Date,
        completedAt: Date? = nil,
        photoURL: String? = nil
    ) {
        self.goalId = goalId
        self.userId = userId
        self.title = title
        self.goalDescription = goalDescription
        self.category = category
        self.baseValue = baseValue
        self.grainValue = grainValue
        self.status = status
        self.createdAt = createdAt
        self.completedAt = completedAt
        self.photoURL = photoURL
    }

    var dictionary: [String: Any] {
        var dict: [String: Any] = [
            "goalId": goalId,
            "userId": userId,
            "title": title,
            "category": category.rawValue,
            "baseValue": baseValue,
            "grainValue": grainValue,
            "status": status.rawValue,
            "createdAt": Timestamp(date: createdAt)
        ]

        if let description = goalDescription {
            dict["goalDescription"] = description
        }

        if let completed = completedAt {
            dict["completedAt"] = Timestamp(date: completed)
        }

        if let photoURL = photoURL {
            dict["photoURL"] = photoURL
        }

        return dict
    }

    static func from(document: QueryDocumentSnapshot) -> FirebaseGoal? {
        let data = document.data()

        guard let goalId = data["goalId"] as? String,
              let userId = data["userId"] as? String,
              let title = data["title"] as? String,
              let categoryRaw = data["category"] as? String,
              let category = GoalCategory(rawValue: categoryRaw),
              let baseValue = data["baseValue"] as? Double,
              let grainValue = data["grainValue"] as? Double,
              let statusRaw = data["status"] as? String,
              let status = GoalStatus(rawValue: statusRaw),
              let createdAtTimestamp = data["createdAt"] as? Timestamp else {
            return nil
        }

        let completedAt = (data["completedAt"] as? Timestamp)?.dateValue()
        let photoURL = data["photoURL"] as? String

        return FirebaseGoal(
            goalId: goalId,
            userId: userId,
            title: title,
            goalDescription: data["goalDescription"] as? String,
            category: category,
            baseValue: baseValue,
            grainValue: grainValue,
            status: status,
            createdAt: createdAtTimestamp.dateValue(),
            completedAt: completedAt,
            photoURL: photoURL
        )
    }
}
