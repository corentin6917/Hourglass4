//
//  SocialInteraction.swift
//  Hourglass 4
//
//  Created by Corentin Soula on 13/11/2025.
//

import Foundation
import SwiftData

/// Représente une interaction sociale (boost, transfusion, commentaire)
@Model
final class SocialInteraction {
    var id: UUID
    var type: InteractionType
    var grainValue: Double
    var createdAt: Date
    
    /// Émetteur et récepteur (IDs pour l'instant, à connecter avec UserProfile plus tard)
    var senderID: String
    var receiverID: String
    
    /// Message optionnel (pour les commentaires)
    var message: String?
    
    init(
        type: InteractionType,
        grainValue: Double,
        senderID: String,
        receiverID: String,
        message: String? = nil
    ) {
        self.id = UUID()
        self.type = type
        self.grainValue = grainValue
        self.createdAt = Date()
        self.senderID = senderID
        self.receiverID = receiverID
        self.message = message
    }
}

enum InteractionType: String, Codable {
    case boost // Éclat de grain (0.2 grain)
    case transfusion // Transfusion complète (1+ grain)
    case comment // Commentaire (0.1 grain)
    
    var cost: Double {
        switch self {
        case .boost: return 0.2
        case .transfusion: return 1.0
        case .comment: return 0.1
        }
    }
    
    var emoji: String {
        switch self {
        case .boost: return "⭐"
        case .transfusion: return "💉"
        case .comment: return "💬"
        }
    }
}

/// Représente un pacte social (couple ou groupe d'amis)
@Model
final class SocialPact {
    var id: UUID
    var type: PactType
    var createdAt: Date
    var name: String
    
    /// Membres du pacte (IDs)
    var memberIDs: [String]
    
    /// Objectif de grains collectif (optionnel)
    var collectiveGoalGrains: Double?
    var collectiveGoalDeadline: Date?
    
    /// Est-ce que le pacte est actif ?
    var isActive: Bool
    
    init(
        type: PactType,
        name: String,
        memberIDs: [String],
        collectiveGoalGrains: Double? = nil,
        collectiveGoalDeadline: Date? = nil
    ) {
        self.id = UUID()
        self.type = type
        self.createdAt = Date()
        self.name = name
        self.memberIDs = memberIDs
        self.collectiveGoalGrains = collectiveGoalGrains
        self.collectiveGoalDeadline = collectiveGoalDeadline
        self.isActive = true
    }
}

enum PactType: String, Codable {
    case couple // Pacte de couple (2 personnes)
    case friends // Pacte d'amis (3-10 personnes)
    
    var emoji: String {
        switch self {
        case .couple: return "💑"
        case .friends: return "👯"
        }
    }
}
