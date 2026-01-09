//
//  AppConstants.swift
//  Hourglass 4
//
//  Created by Corentin Soula on 13/11/2025.
//

import Foundation

/// Constantes globales de l'application HOURGLASS
enum AppConstants {
    
    // MARK: - Timing
    
    enum Timing {
        /// Heure de reset matinal (8h)
        static let morningResetHour = 8
        
        /// Heure de validation du soir (20h)
        static let eveningValidationHour = 20
        
        /// Durée de vie des photos (24h)
        static let photoExpirationHours = 24
        
        /// Fréquence des capsules temporelles (jours)
        static let timeCapsuleFrequencyDays = 100
    }
    
    // MARK: - Grains
    
    enum Grains {
        /// Nombre de grains de potentiel quotidien
        static let dailyPotential = 10
        
        /// Plafond quotidien pour les objectifs personnels
        static let dailyCap = 10.0
        
        /// Plafond mensuel (anti-gaming)
        static let monthlyCap = 380.0
        
        /// Coût d'un boost (Éclat)
        static let boostCost = 0.2
        
        /// Coût d'une transfusion
        static let transfusionCost = 1.0
        
        /// Coût d'un commentaire
        static let commentCost = 0.1
        
        /// Multiplicateur en mode Phénix
        static let phoenixMultiplier = 3.0
    }
    
    // MARK: - Phoenix Mode
    
    enum PhoenixMode {
        /// Nombre de jours consécutifs avec < 3 grains pour déclencher
        static let triggerDays = 14
        
        /// Seuil de grains par jour pour déclencher
        static let triggerThreshold = 3.0
        
        /// Nombre de grains nécessaires pour sortir
        static let exitGrainsNeeded = 200.0
        
        /// Jours d'inactivité pour déclencher
        static let inactivityDays = 14
    }
    
    // MARK: - Life Ratio
    
    enum LifeRatio {
        /// Seuil pour "Tu survis plus que tu ne vis"
        static let survivalThreshold = 30.0
        
        /// Seuil pour "Tu vis modérément"
        static let moderateThreshold = 50.0
        
        /// Seuil pour "Tu vis intensément"
        static let intenseThreshold = 70.0
        
        /// Au-dessus : "Tu vis exceptionnellement"
    }
    
    // MARK: - Seasons
    
    enum Seasons {
        /// Jours d'observation pour déterminer la saison
        static let observationPeriodDays = 30
        
        /// Seuil de grains/jour pour l'hiver
        static let winterThreshold = 4.0
        
        /// Seuil de grains/jour pour l'été
        static let summerThreshold = 7.0
    }
    
    // MARK: - Devaluation
    
    enum Devaluation {
        /// Phase 1 : Jours 1-30 (100%)
        static let phase1Range = 0...30
        static let phase1Multiplier = 1.0
        
        /// Phase 2 : Jours 31-90 (80%)
        static let phase2Range = 31...90
        static let phase2Multiplier = 0.8
        
        /// Phase 3 : Jours 91-180 (60%)
        static let phase3Range = 91...180
        static let phase3Multiplier = 0.6
        
        /// Phase 4 : Jours 181+ (50% - plancher)
        static let phase4Multiplier = 0.5
    }
    
    // MARK: - Social
    
    enum Social {
        /// Nombre minimum de membres pour un pacte d'amis
        static let friendsPactMinMembers = 3
        
        /// Nombre maximum de membres pour un pacte d'amis
        static let friendsPactMaxMembers = 10
        
        /// Nombre de membres pour un pacte de couple
        static let couplePactMembers = 2
        
        /// Durée de visibilité des posts dans le feed (heures)
        static let feedPostVisibilityHours = 24
        
        /// Nombre de posts maximum dans le Fil des Légendes
        static let legendaryFeedCount = 10
    }
    
    // MARK: - Notifications
    
    enum Notifications {
        /// Identifiant de la notification matinale
        static let morningResetID = "morning_reset"
        
        /// Identifiant de la notification du soir
        static let eveningValidationID = "evening_validation"
        
        /// Identifiant de base pour les streaks
        static let streakIDPrefix = "streak_"
        
        /// Identifiant du mode Phénix
        static let phoenixModeID = "phoenix_mode_activated"
        
        /// Identifiant de base pour les capsules
        static let timeCapsuleIDPrefix = "time_capsule_"
    }
    
    // MARK: - UI
    
    enum UI {
        /// Durée des animations standard (secondes)
        static let standardAnimationDuration = 0.3
        
        /// Durée de l'animation de chute des grains (secondes)
        static let grainFallAnimationDuration = 2.0
        
        /// Durée de l'animation d'évaporation (secondes)
        static let grainEvaporationDuration = 1.5
        
        /// Rayon de coin standard
        static let standardCornerRadius = 15.0
        
        /// Rayon de coin pour les cartes
        static let cardCornerRadius = 20.0
        
        /// Opacité des arrière-plans
        static let backgroundOpacity = 0.1
    }
    
    // MARK: - Storage
    
    enum Storage {
        /// Qualité de compression JPEG pour les photos (0.0 - 1.0)
        static let imageCompressionQuality = 0.7
        
        /// Nombre maximum de photos dans une capsule temporelle
        static let maxCapsulePhotos = 10
    }
    
    // MARK: - Validation
    
    enum Validation {
        /// Longueur minimale pour un titre d'objectif
        static let goalTitleMinLength = 3
        
        /// Longueur maximale pour un titre d'objectif
        static let goalTitleMaxLength = 100
        
        /// Longueur maximale pour une description d'objectif
        static let goalDescriptionMaxLength = 500
        
        /// Nombre maximum d'objectifs par jour
        static let maxGoalsPerDay = 10
    }
}

// MARK: - App Configuration

/// Configuration de l'application
struct AppConfig {
    
    /// Version de l'application
    static let version = "1.0.0"
    
    /// Build number
    static let build = "1"
    
    /// Nom de l'application
    static let appName = "HOURGLASS"
    
    /// URL du backend (à configurer)
    static let backendURL = "https://api.hourglass.app" // TODO: Remplacer par l'URL réelle
    
    /// Activer le mode debug
    static var isDebugMode: Bool {
        #if DEBUG
        return true
        #else
        return false
        #endif
    }
    
    /// Activer les logs verbeux
    static let verboseLogging = isDebugMode
    
    /// Simuler les horaires (pour les tests)
    static var simulateTimeSlots = false
    
    /// Version minimale iOS requise
    static let minimumIOSVersion = "17.0"
}

// MARK: - Error Types

/// Erreurs spécifiques à l'application
enum HourglassError: Error, LocalizedError {
    case invalidGoalTitle
    case goalLimitReached
    case invalidImageData
    case photoNotProvided
    case insufficientGrains
    case userProfileNotFound
    case networkError(String)
    case dataCorruption
    
    var errorDescription: String? {
        switch self {
        case .invalidGoalTitle:
            return "Le titre de l'objectif est invalide"
        case .goalLimitReached:
            return "Tu as atteint le nombre maximum d'objectifs pour aujourd'hui"
        case .invalidImageData:
            return "L'image fournie est invalide"
        case .photoNotProvided:
            return "Tu dois fournir une photo pour valider cet objectif"
        case .insufficientGrains:
            return "Tu n'as pas assez de grains pour cette action"
        case .userProfileNotFound:
            return "Profil utilisateur introuvable"
        case .networkError(let message):
            return "Erreur réseau : \(message)"
        case .dataCorruption:
            return "Les données sont corrompues"
        }
    }
}

// MARK: - Helper Extensions

extension Date {
    /// Retourne vrai si la date est aujourd'hui
    var isToday: Bool {
        AppTimeZone.calendar.isDateInToday(self)
    }
    
    /// Retourne vrai si la date est dans le passé
    var isPast: Bool {
        self < Date()
    }
    
    /// Retourne le début de la journée
    var startOfDay: Date {
        AppTimeZone.calendar.startOfDay(for: self)
    }
    
    /// Retourne la fin de la journée
    var endOfDay: Date {
        var components = DateComponents()
        components.day = 1
        components.second = -1
        return AppTimeZone.calendar.date(byAdding: components, to: startOfDay) ?? self
    }
}

extension Double {
    /// Arrondit à 0.5 près (pour les valeurs de grains)
    var roundedToHalf: Double {
        (self * 2).rounded() / 2
    }
}
