//
//  HourglassViewModel.swift
//  Hourglass 4
//
//  Created by Corentin Soula on 13/11/2025.
//

import Foundation
import SwiftData
import Combine

/// ViewModel principal pour gérer le sablier et l'état de l'application
final class HourglassViewModel: ObservableObject {
    @Published var userProfile: UserProfile?
    @Published var currentDayGrains: [Grain] = []
    @Published var todayGoals: [Goal] = []
    
    private var modelContext: ModelContext
    
    // Constantes de temps
    private let morningResetHour = 8
    private let eveningValidationHour = 20
    
    init(modelContext: ModelContext) {
        self.modelContext = modelContext
        loadOrCreateUserProfile()
        setupDailyNotifications()
    }
    
    // MARK: - User Profile Management
    
    func initializeUserIfNeeded() {
        // Cette méthode peut être appelée depuis onAppear
        // Le profil est déjà initialisé dans init()
    }
    
    private func loadOrCreateUserProfile() {
        let descriptor = FetchDescriptor<UserProfile>()
        
        do {
            let profiles = try modelContext.fetch(descriptor)
            if let existingProfile = profiles.first {
                userProfile = existingProfile
            } else {
                // Créer un nouveau profil
                let newProfile = UserProfile(username: "User") // À personnaliser
                modelContext.insert(newProfile)
                try modelContext.save()
                userProfile = newProfile
            }
        } catch {
            print("Erreur lors du chargement du profil: \(error)")
        }
        
        // Charger les données du jour
        loadTodayData()
    }
    
    private func loadTodayData() {
        guard let profile = userProfile else { return }
        
        todayGoals = profile.todaysPendingGoals() + profile.todaysCompletedGoals()
        
        // Charger les grains du jour
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        
        currentDayGrains = profile.grains.filter { grain in
            guard let earnedDate = grain.earnedDate else { return false }
            return calendar.isDate(earnedDate, inSameDayAs: today)
        }
    }
    
    // MARK: - Morning Reset (8h)
    
    func performMorningReset() {
        guard let profile = userProfile else { return }
        
        // Créer 10 grains blancs de potentiel
        for _ in 0..<10 {
            let grain = Grain(type: .potential, value: 1.0, source: .goal)
            grain.owner = profile
            modelContext.insert(grain)
            profile.grains.append(grain)
        }
        
        do {
            try modelContext.save()
            loadTodayData()
        } catch {
            print("Erreur lors du reset matinal: \(error)")
        }
    }
    
    // MARK: - Evening Validation (20h)
    
    func performEveningValidation() {
        guard let profile = userProfile else { return }
        
        // 1. Calculer les grains gagnés aujourd'hui
        let completedGoals = profile.todaysCompletedGoals()
        var grainsToEarn: Double = 0
        
        for goal in completedGoals {
            grainsToEarn += goal.grainValue
        }
        
        // Appliquer le plafond quotidien (10 grains max pour les objectifs personnels)
        let baseGrains = min(grainsToEarn, 10.0)
        
        // 2. Convertir les grains blancs en grains dorés
        let potentialGrains = profile.grains.filter { $0.type == .potential }
        var remainingGrains = baseGrains
        
        for grain in potentialGrains.prefix(Int(ceil(baseGrains))) {
            if remainingGrains >= 1.0 {
                grain.type = .earned
                grain.earnedDate = Date()
                remainingGrains -= 1.0
            } else if remainingGrains > 0 {
                grain.type = .earned
                grain.earnedDate = Date()
                grain.value = remainingGrains
                remainingGrains = 0
            }
        }
        
        // 3. Évaporer les grains non gagnés
        let unearnedGrains = profile.grains.filter { $0.type == .potential }
        for grain in unearnedGrains {
            grain.type = .evaporated
        }
        
        // 4. Mettre à jour les statistiques
        profile.totalGrainsEarned += baseGrains
        
        // 5. Mettre à jour la streak
        if baseGrains > 0 {
            profile.currentStreak += 1
            if profile.currentStreak > profile.longestStreak {
                profile.longestStreak = profile.currentStreak
            }
        } else {
            profile.currentStreak = 0
        }
        
        // 6. Expirer les objectifs non validés
        let pendingGoals = profile.todaysPendingGoals()
        for goal in pendingGoals {
            goal.status = .expired
        }
        
        // 7. Vérifier si besoin d'entrer en mode Phénix
        if profile.shouldEnterPhoenixMode() && !profile.isInPhoenixMode {
            profile.enterPhoenixMode()
        }
        
        // 8. Vérifier si sortie du mode Phénix
        if profile.isInPhoenixMode {
            let phoenixGrains = profile.grains
                .filter { $0.type == .earned }
                .filter { grain in
                    guard let earnedDate = grain.earnedDate,
                          let startDate = profile.phoenixModeStartDate else { return false }
                    return earnedDate >= startDate
                }
                .reduce(0) { $0 + $1.value }
            
            if phoenixGrains >= profile.phoenixModeGrainsNeeded {
                profile.exitPhoenixMode()
            }
        }
        
        // 9. Sauvegarder
        do {
            try modelContext.save()
            loadTodayData()
        } catch {
            print("Erreur lors de la validation du soir: \(error)")
        }
    }
    
    // MARK: - Goal Management
    
    func addGoal(_ goal: Goal) {
        guard let profile = userProfile else { return }
        
        goal.owner = profile
        modelContext.insert(goal)
        profile.goals.append(goal)
        
        do {
            try modelContext.save()
            loadTodayData()
        } catch {
            print("Erreur lors de l'ajout de l'objectif: \(error)")
        }
    }
    
    func createGoal(
        title: String,
        description: String? = nil,
        category: GoalCategory,
        baseValue: Double
    ) {
        guard let profile = userProfile else { return }
        
        // Compter les répétitions d'objectifs similaires
        let similarGoals = profile.goals.filter {
            $0.title.lowercased() == title.lowercased() && $0.status == .completed
        }
        
        let goal = Goal(
            title: title,
            description: description,
            baseValue: baseValue,
            category: category,
            repetitionCount: similarGoals.count
        )
        
        goal.owner = profile
        modelContext.insert(goal)
        profile.goals.append(goal)
        
        do {
            try modelContext.save()
            loadTodayData()
        } catch {
            print("Erreur lors de la création de l'objectif: \(error)")
        }
    }
    
    func validateGoal(_ goal: Goal, with imageData: Data) {
        guard let profile = userProfile else { return }
        
        goal.validate(with: imageData)
        
        // Appliquer le multiplicateur Phénix si nécessaire
        if profile.isInPhoenixMode {
            goal.grainValue *= 3.0 // Triple en mode Phénix
        }
        
        do {
            try modelContext.save()
            loadTodayData()
        } catch {
            print("Erreur lors de la validation de l'objectif: \(error)")
        }
    }
    
    func deleteGoal(_ goal: Goal) {
        modelContext.delete(goal)
        
        do {
            try modelContext.save()
            loadTodayData()
        } catch {
            print("Erreur lors de la suppression de l'objectif: \(error)")
        }
    }
    
    // MARK: - Notifications
    
    private func setupDailyNotifications() {
        Task {
            do {
                let authorized = try await NotificationManager.shared.requestAuthorization()
                if authorized {
                    try await NotificationManager.shared.scheduleDailyNotifications()
                }
            } catch {
                print("Erreur lors de la configuration des notifications: \(error)")
            }
        }
    }
    
    // MARK: - Helpers
    
    func currentTimeSlot() -> TimeSlot {
        let hour = Calendar.current.component(.hour, from: Date())
        
        if hour >= morningResetHour && hour < eveningValidationHour {
            return .daytime
        } else if hour >= eveningValidationHour {
            return .evening
        } else {
            return .night
        }
    }
    
    func potentialGrainsToday() -> Double {
        return todayGoals
            .filter { $0.status == .pending }
            .reduce(0) { $0 + $1.grainValue }
    }
    
    func earnedGrainsToday() -> Double {
        return todayGoals
            .filter { $0.status == .completed }
            .reduce(0) { $0 + $1.grainValue }
    }
}

enum TimeSlot {
    case night // Minuit - 8h
    case daytime // 8h - 20h
    case evening // 20h - Minuit
    
    var description: String {
        switch self {
        case .night:
            return "Nuit - Repos"
        case .daytime:
            return "Journée - Action"
        case .evening:
            return "Soir - Validation"
        }
    }
}
