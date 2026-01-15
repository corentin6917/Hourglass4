//
//  Goal.swift
//  Hourglass 4
//
//  Created by Corentin Soula on 13/11/2025.
//

import Foundation
import SwiftData

/// Représente un objectif quotidien défini par l'utilisateur
@Model
final class Goal {
    var id: UUID
    var title: String
    var goalDescription: String?
    var grainValue: Double
    var baseValue: Double // Valeur originale avant dévaluation
    var createdAt: Date
    var targetDate: Date // Jour cible (normallement aujourd'hui)
    
    /// État de l'objectif
    var status: GoalStatus
    
    /// Photo de preuve (stockée comme Data)
    @Attribute(.externalStorage)
    var proofImageData: Data?
    
    var validatedAt: Date?
    
    /// Catégorie de l'objectif
    var category: GoalCategory
    
    /// Compte le nombre de fois que cet objectif similaire a été accompli
    var repetitionCount: Int
    
    /// Phase de dévaluation (calculée selon repetitionCount)
    var devaluationPhase: DevaluationPhase {
        switch repetitionCount {
        case 0...30:
            return .phase1
        case 31...90:
            return .phase2
        case 91...180:
            return .phase3
        default:
            return .phase4
        }
    }
    
    /// Multiplicateur selon la phase
    var devaluationMultiplier: Double {
        switch devaluationPhase {
        case .phase1: return 1.0
        case .phase2: return 0.8
        case .phase3: return 0.6
        case .phase4: return 0.5
        }
    }
    
    /// Référence au propriétaire
    var owner: UserProfile?
    
    init(
        title: String,
        description: String? = nil,
        baseValue: Double,
        targetDate: Date = Date(),
        category: GoalCategory = .personal,
        repetitionCount: Int = 0
    ) {
        self.id = UUID()
        self.title = title
        self.goalDescription = description
        self.baseValue = baseValue
        self.grainValue = baseValue
        self.createdAt = Date()
        self.targetDate = targetDate
        self.status = .pending
        self.category = category
        self.repetitionCount = repetitionCount
        
        // Appliquer la dévaluation
        self.updateGrainValue()
    }
    
    func updateGrainValue() {
        self.grainValue = ceil(baseValue * devaluationMultiplier)
    }
    
    func validate(with imageData: Data) {
        self.status = .completed
        self.proofImageData = imageData
        self.validatedAt = Date()
    }
    
    func cancel() {
        self.status = .cancelled
    }
}

enum GoalStatus: String, Codable {
    case pending // En attente de validation
    case completed // Accompli
    case cancelled // Annulé
    case expired // Expiré (après 20h si non validé)
}

enum GoalCategory: String, Codable, CaseIterable {
    case physical // Sport, santé physique
    case social // Relations, appels, rencontres
    case creative // Art, musique, écriture
    case professional // Travail, projets
    case learning // Études, formation
    case personal // Développement personnel
    case household // Tâches ménagères, organisation
    
    var emoji: String {
        switch self {
        case .physical: return "🏃"
        case .social: return "👥"
        case .creative: return "🎨"
        case .professional: return "💼"
        case .learning: return "📚"
        case .personal: return "🌱"
        case .household: return "🏠"
        }
    }
    
    var displayName: String {
        switch self {
        case .physical: return "Physique"
        case .social: return "Social"
        case .creative: return "Créatif"
        case .professional: return "Professionnel"
        case .learning: return "Apprentissage"
        case .personal: return "Personnel"
        case .household: return "Maison"
        }
    }
}

enum DevaluationPhase: Int, Codable {
    case phase1 = 1 // Jours 1-30 : 100%
    case phase2 = 2 // Jours 31-90 : 80%
    case phase3 = 3 // Jours 91-180 : 60%
    case phase4 = 4 // Jours 181+ : 50% (plancher)
    
    var description: String {
        switch self {
        case .phase1: return "Nouveau défi (100%)"
        case .phase2: return "Habitude en formation (80%)"
        case .phase3: return "Habitude établie (60%)"
        case .phase4: return "Routine (50%)"
        }
    }
}
