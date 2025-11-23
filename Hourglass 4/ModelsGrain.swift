//
//  Grain.swift
//  Hourglass 4
//
//  Created by Corentin Soula on 13/11/2025.
//

import Foundation
import SwiftData

/// Représente un grain de sable dans le sablier
/// Peut être blanc (potentiel) ou doré (accumulé)
@Model
final class Grain {
    var id: UUID
    var type: GrainType
    var value: Double
    var earnedDate: Date?
    var source: GrainSource
    
    /// Référence au propriétaire
    var owner: UserProfile?
    
    init(
        type: GrainType,
        value: Double,
        earnedDate: Date? = nil,
        source: GrainSource = .goal
    ) {
        self.id = UUID()
        self.type = type
        self.value = value
        self.earnedDate = earnedDate
        self.source = source
    }
}

enum GrainType: String, Codable {
    case potential // Blanc - dans la partie haute
    case earned // Doré - dans la partie basse (héritage)
    case evaporated // Perdu
}

enum GrainSource: String, Codable {
    case goal // Objectif personnel
    case boost // Éclat reçu d'un ami
    case transfusion // Transfusion reçue
    case exceptional // Événement exceptionnel
    case phoenixMode // Triple points en mode Phénix
}
