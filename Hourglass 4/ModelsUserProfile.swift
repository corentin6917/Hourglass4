//
//  UserProfile.swift
//  Hourglass 4
//
//  Created by Corentin Soula on 13/11/2025.
//

import Foundation
import SwiftData

/// Profil utilisateur principal
@Model
final class UserProfile {
    var id: UUID
    var username: String
    var joinDate: Date
    
    /// Relation avec les grains
    @Relationship(deleteRule: .cascade, inverse: \Grain.owner)
    var grains: [Grain]
    
    /// Relation avec les objectifs
    @Relationship(deleteRule: .cascade, inverse: \Goal.owner)
    var goals: [Goal]
    
    /// Statistiques
    var totalGrainsEarned: Double
    var currentStreak: Int // Jours consécutifs avec au moins 1 grain
    var longestStreak: Int
    
    /// Saison de vie actuelle
    var currentSeason: LifeSeason
    var seasonStartDate: Date
    
    /// Mode Phénix
    var isInPhoenixMode: Bool
    var phoenixModeStartDate: Date?
    var phoenixModeGrainsNeeded: Double // Grains nécessaires pour sortir du mode Phénix
    
    /// Capsules temporelles
    @Relationship(deleteRule: .cascade)
    var timeCapsules: [TimeCapsule]
    
    init(username: String) {
        self.id = UUID()
        self.username = username
        self.joinDate = Date()
        self.grains = []
        self.goals = []
        self.totalGrainsEarned = 0
        self.currentStreak = 0
        self.longestStreak = 0
        self.currentSeason = .spring
        self.seasonStartDate = Date()
        self.isInPhoenixMode = false
        self.phoenixModeGrainsNeeded = 0
        self.timeCapsules = []
    }
    
    /// Calcule le ratio de vie
    func lifeRatio() -> Double {
        let daysOnApp = AppTimeZone.calendar.dateComponents([.day], from: joinDate, to: Date()).day ?? 0
        guard daysOnApp > 0 else { return 0 }
        
        let maxPossibleGrains = Double(daysOnApp) * 10.0
        return (totalGrainsEarned / maxPossibleGrains) * 100.0
    }
    
    /// Interprétation du ratio
    func ratioInterpretation() -> String {
        let ratio = lifeRatio()
        switch ratio {
        case ..<30:
            return "Tu survis plus que tu ne vis"
        case 30..<50:
            return "Tu vis modérément"
        case 50..<70:
            return "Tu vis intensément"
        default:
            return "Tu vis exceptionnellement"
        }
    }
    
    /// Grains gagnés aujourd'hui
    func grainsEarnedToday() -> Double {
        let calendar = AppTimeZone.calendar
        let today = calendar.startOfDay(for: Date())
        
        return grains
            .filter { $0.type == .earned }
            .filter { grain in
                guard let earnedDate = grain.earnedDate else { return false }
                return calendar.isDate(earnedDate, inSameDayAs: today)
            }
            .reduce(0) { $0 + $1.value }
    }
    
    /// Objectifs en attente aujourd'hui
    func todaysPendingGoals() -> [Goal] {
        let calendar = AppTimeZone.calendar
        let today = calendar.startOfDay(for: Date())
        
        return goals.filter { goal in
            calendar.isDate(goal.targetDate, inSameDayAs: today) &&
            goal.status == .pending
        }
    }
    
    /// Objectifs complétés aujourd'hui
    func todaysCompletedGoals() -> [Goal] {
        let calendar = AppTimeZone.calendar
        let today = calendar.startOfDay(for: Date())
        
        return goals.filter { goal in
            calendar.isDate(goal.targetDate, inSameDayAs: today) &&
            goal.status == .completed
        }
    }
    
    /// Vérifier si l'utilisateur doit entrer en mode Phénix
    func shouldEnterPhoenixMode() -> Bool {
        // Critère 1 : < 3 grains/jour pendant 14 jours
        let calendar = AppTimeZone.calendar
        let twoWeeksAgo = calendar.date(byAdding: .day, value: -14, to: Date())!
        
        let recentGrains = grains
            .filter { $0.type == .earned }
            .filter { grain in
                guard let earnedDate = grain.earnedDate else { return false }
                return earnedDate >= twoWeeksAgo
            }
        
        let avgGrainsPerDay = Double(recentGrains.count) / 14.0
        if avgGrainsPerDay < 3.0 {
            return true
        }
        
        // Critère 2 : Ratio qui baisse de 10% en un mois
        // (À implémenter avec historique)
        
        // Critère 3 : Aucune victoire depuis 2 semaines
        let lastCompletedGoal = goals
            .filter { $0.status == .completed }
            .max(by: { $0.validatedAt ?? Date.distantPast < $1.validatedAt ?? Date.distantPast })
        
        if let lastGoal = lastCompletedGoal,
           let validatedAt = lastGoal.validatedAt,
           validatedAt < twoWeeksAgo {
            return true
        }
        
        return false
    }
    
    /// Activer le mode Phénix
    func enterPhoenixMode() {
        isInPhoenixMode = true
        phoenixModeStartDate = Date()
        phoenixModeGrainsNeeded = 200.0 // 200 grains pour sortir
        currentSeason = .winter // Le mode Phénix commence toujours en hiver
        seasonStartDate = Date()
    }
    
    /// Sortir du mode Phénix
    func exitPhoenixMode() {
        isInPhoenixMode = false
        phoenixModeStartDate = nil
        phoenixModeGrainsNeeded = 0
        currentSeason = .spring // Renaissance
        seasonStartDate = Date()
    }
}

/// Saisons de vie
enum LifeSeason: String, Codable, CaseIterable {
    case winter = "winter" // < 4 grains/jour
    case spring = "spring" // Progression positive
    case summer = "summer" // > 7 grains/jour
    case autumn = "autumn" // Baisse après un été
    
    var emoji: String {
        switch self {
        case .winter: return "🌨️"
        case .spring: return "🌸"
        case .summer: return "☀️"
        case .autumn: return "🍂"
        }
    }
    
    var displayName: String {
        switch self {
        case .winter: return "Hiver"
        case .spring: return "Printemps"
        case .summer: return "Été"
        case .autumn: return "Automne"
        }
    }
    
    var color: String {
        switch self {
        case .winter: return "blue"
        case .spring: return "green"
        case .summer: return "yellow"
        case .autumn: return "orange"
        }
    }
    
    var message: String {
        switch self {
        case .winter:
            return "Tu es en Hiver. C'est normal. L'hiver finit toujours."
        case .spring:
            return "Tu renais. Le printemps arrive."
        case .summer:
            return "Tu vis pleinement. Profite de cet été."
        case .autumn:
            return "Période de réflexion. L'automne est une saison de sagesse."
        }
    }
}
