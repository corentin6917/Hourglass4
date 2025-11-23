//
//  TimeCapsule.swift
//  Hourglass 4
//
//  Created by Corentin Soula on 13/11/2025.
//

import Foundation
import SwiftData

/// Capsule temporelle générée tous les 100 jours
@Model
final class TimeCapsule {
    var id: UUID
    var createdAt: Date
    var dayCount: Int // Nombre de jours depuis le début (ex: 100, 200, 300...)
    
    /// Statistiques de la période
    var totalGrainsInPeriod: Double
    var averageGrainsPerDay: Double
    var startRatio: Double
    var endRatio: Double
    
    /// Top 10 photos de victoires (stockées comme Data)
    @Attribute(.externalStorage)
    var topVictoryImages: [Data]
    
    /// Saisons traversées
    var seasonsExperienced: [String] // ["winter", "spring", "summer"]
    
    /// Message à soi-même (optionnel)
    var personalMessage: String?
    
    /// Graphique de progression (Data représentant un graphique)
    @Attribute(.externalStorage)
    var progressGraphData: Data?
    
    /// Est-ce que la capsule a été vue ?
    var hasBeenViewed: Bool
    
    init(
        dayCount: Int,
        totalGrainsInPeriod: Double,
        averageGrainsPerDay: Double,
        startRatio: Double,
        endRatio: Double,
        topVictoryImages: [Data] = [],
        seasonsExperienced: [String] = [],
        personalMessage: String? = nil
    ) {
        self.id = UUID()
        self.createdAt = Date()
        self.dayCount = dayCount
        self.totalGrainsInPeriod = totalGrainsInPeriod
        self.averageGrainsPerDay = averageGrainsPerDay
        self.startRatio = startRatio
        self.endRatio = endRatio
        self.topVictoryImages = topVictoryImages
        self.seasonsExperienced = seasonsExperienced
        self.personalMessage = personalMessage
        self.hasBeenViewed = false
    }
}
