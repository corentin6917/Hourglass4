//
//  GoalSuggestionEngine.swift
//  Hourglass 4
//
//  Created by Corentin Soula on 13/11/2025.
//

import Foundation

/// Moteur de suggestion et d'évaluation des objectifs
/// Attribue automatiquement une valeur en grains à chaque objectif
struct GoalSuggestionEngine {
    
    // MARK: - Valeur de Base par Catégorie
    
    private static let categoryBaseValues: [GoalCategory: ClosedRange<Double>] = [
        .physical: 1.5...5.0,      // Sport et santé physique
        .social: 2.0...6.0,        // Relations sociales importantes
        .creative: 2.0...7.0,      // Création artistique valorisée
        .professional: 3.0...8.0,  // Travail et projets pros
        .learning: 2.5...6.0,      // Apprentissage et études
        .personal: 1.5...5.0,      // Développement personnel
        .household: 0.5...2.0      // Tâches quotidiennes
    ]
    
    // MARK: - Calcul de la Valeur
    
    static func calculateGrainValue(
        for title: String,
        category: GoalCategory,
        estimatedDuration: TimeInterval? = nil,
        difficulty: Difficulty = .medium
    ) -> Double {
        
        // 1. Obtenir la plage de base pour la catégorie
        guard let baseRange = categoryBaseValues[category] else {
            return 2.0 // Valeur par défaut
        }
        
        // 2. Déterminer une valeur de base selon la difficulté
        let baseValue: Double
        switch difficulty {
        case .easy:
            baseValue = baseRange.lowerBound
        case .medium:
            baseValue = (baseRange.lowerBound + baseRange.upperBound) / 2
        case .hard:
            baseValue = baseRange.upperBound
        }
        
        // 3. Ajuster selon la durée estimée (si fournie)
        var adjustedValue = baseValue
        if let duration = estimatedDuration {
            let hours = duration / 3600
            if hours > 2 {
                adjustedValue *= 1.5
            } else if hours > 1 {
                adjustedValue *= 1.2
            }
        }
        
        // 4. Analyser les mots-clés dans le titre pour affiner
        let keywords = analyzeKeywords(in: title)
        for keyword in keywords {
            adjustedValue *= keyword.multiplier
        }
        
        // 5. Arrondir à 0.5 près
        return round(adjustedValue * 2) / 2
    }
    
    // MARK: - Analyse des Mots-Clés
    
    private static func analyzeKeywords(in text: String) -> [Keyword] {
        let lowercased = text.lowercased()
        var detectedKeywords: [Keyword] = []
        
        for keyword in allKeywords {
            if lowercased.contains(keyword.word) {
                detectedKeywords.append(keyword)
            }
        }
        
        return detectedKeywords
    }
    
    private static let allKeywords: [Keyword] = [
        // Intensité physique
        Keyword(word: "marathon", multiplier: 2.0),
        Keyword(word: "semi-marathon", multiplier: 1.8),
        Keyword(word: "10km", multiplier: 1.5),
        Keyword(word: "5km", multiplier: 1.3),
        Keyword(word: "course", multiplier: 1.2),
        Keyword(word: "musculation", multiplier: 1.3),
        Keyword(word: "yoga", multiplier: 1.1),
        
        // Durée
        Keyword(word: "2h", multiplier: 1.4),
        Keyword(word: "1h", multiplier: 1.2),
        Keyword(word: "30min", multiplier: 1.0),
        
        // Projets importants
        Keyword(word: "lancer", multiplier: 2.5),
        Keyword(word: "créer", multiplier: 1.8),
        Keyword(word: "terminer", multiplier: 1.5),
        Keyword(word: "finir", multiplier: 1.3),
        
        // Social
        Keyword(word: "appeler", multiplier: 1.3),
        Keyword(word: "voir", multiplier: 1.2),
        Keyword(word: "rencontrer", multiplier: 1.5),
        Keyword(word: "famille", multiplier: 1.4),
        
        // Petites tâches
        Keyword(word: "promener", multiplier: 0.7),
        Keyword(word: "ranger", multiplier: 0.6),
        Keyword(word: "nettoyer", multiplier: 0.8)
    ]
    
    // MARK: - Suggestions d'Upgrade
    
    static func suggestUpgrade(for goal: Goal, userProfile: UserProfile) -> GoalUpgradeSuggestion? {
        // Si l'objectif a été répété beaucoup de fois, suggérer une amélioration
        guard goal.repetitionCount > 30 else { return nil }
        
        let suggestions: [GoalUpgradeSuggestion] = [
            .init(
                originalGoal: goal.title,
                upgradedGoal: upgradeGoalTitle(goal.title),
                newGrainValue: goal.baseValue * 1.5,
                reason: "Tu maîtrises \(goal.title). Prêt pour le niveau suivant ?"
            )
        ]
        
        return suggestions.first
    }
    
    private static func upgradeGoalTitle(_ title: String) -> String {
        // Exemples d'upgrades
        if title.contains("30min") {
            return title.replacingOccurrences(of: "30min", with: "45min")
        } else if title.contains("5km") {
            return title.replacingOccurrences(of: "5km", with: "10km")
        } else if title.contains("1h") {
            return title.replacingOccurrences(of: "1h", with: "1h30")
        }
        
        // Sinon, ajouter "Version avancée"
        return "\(title) - Version avancée"
    }
    
    // MARK: - Suggestions Contextuelles
    
    static func suggestGoalsForUser(_ profile: UserProfile) -> [GoalSuggestion] {
        var suggestions: [GoalSuggestion] = []
        
        // Analyser les catégories peu utilisées
        let goalsByCategory = Dictionary(grouping: profile.goals) { $0.category }
        
        for category in GoalCategory.allCases {
            let goalsInCategory = goalsByCategory[category] ?? []
            if goalsInCategory.isEmpty || goalsInCategory.count < 5 {
                suggestions.append(contentsOf: defaultSuggestionsFor(category: category))
            }
        }
        
        return suggestions
    }
    
    private static func defaultSuggestionsFor(category: GoalCategory) -> [GoalSuggestion] {
        switch category {
        case .physical:
            return [
                GoalSuggestion(title: "Courir 30 min", category: .physical, estimatedValue: 2.0),
                GoalSuggestion(title: "Faire 20 pompes", category: .physical, estimatedValue: 1.5),
                GoalSuggestion(title: "Marcher 10 000 pas", category: .physical, estimatedValue: 2.5)
            ]
        case .social:
            return [
                GoalSuggestion(title: "Appeler un ami", category: .social, estimatedValue: 3.0),
                GoalSuggestion(title: "Déjeuner avec famille", category: .social, estimatedValue: 4.0)
            ]
        case .creative:
            return [
                GoalSuggestion(title: "Écrire 500 mots", category: .creative, estimatedValue: 3.0),
                GoalSuggestion(title: "Dessiner 30 min", category: .creative, estimatedValue: 2.5)
            ]
        case .professional:
            return [
                GoalSuggestion(title: "Finir le rapport", category: .professional, estimatedValue: 5.0),
                GoalSuggestion(title: "Répondre aux emails", category: .professional, estimatedValue: 2.0)
            ]
        case .learning:
            return [
                GoalSuggestion(title: "Étudier 1h", category: .learning, estimatedValue: 3.0),
                GoalSuggestion(title: "Lire 30 pages", category: .learning, estimatedValue: 2.5)
            ]
        case .personal:
            return [
                GoalSuggestion(title: "Méditer 15 min", category: .personal, estimatedValue: 2.0),
                GoalSuggestion(title: "Journaling", category: .personal, estimatedValue: 1.5)
            ]
        case .household:
            return [
                GoalSuggestion(title: "Ranger la chambre", category: .household, estimatedValue: 1.0),
                GoalSuggestion(title: "Faire la vaisselle", category: .household, estimatedValue: 0.5)
            ]
        }
    }
}

// MARK: - Supporting Types

enum Difficulty {
    case easy
    case medium
    case hard
}

struct Keyword {
    let word: String
    let multiplier: Double
}

struct GoalSuggestion {
    let title: String
    let category: GoalCategory
    let estimatedValue: Double
}

struct GoalUpgradeSuggestion {
    let originalGoal: String
    let upgradedGoal: String
    let newGrainValue: Double
    let reason: String
}
