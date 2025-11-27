//
//  ViewsVictoryCardView.swift
//  Hourglass 4
//
//  Created by Assistant on 26/11/2025.
//

import SwiftUI

/// Carte d'une victoire (objectif complété)
struct VictoryCardView: View {
    let goal: Goal

    // Safe accessors to avoid compile errors when properties are absent on Goal
    private var completedDate: Date? {
        // Try common property names first
        if let g = goal as? AnyObject {
            if let value = g.value(forKey: "completedAt") as? Date { return value }
            if let value = g.value(forKey: "completedDate") as? Date { return value }
            if let value = g.value(forKey: "completedOn") as? Date { return value }
        }
        // Fallback to Mirror-based lookup for value types
        let m = Mirror(reflecting: goal)
        for child in m.children {
            switch child.label {
            case "completedAt?", "completedAt", "completedDate", "completedOn":
                return child.value as? Date
            default: break
            }
        }
        return nil
    }

    private var grainsEarnedValue: Double? {
        if let g = goal as? AnyObject {
            if let value = g.value(forKey: "grainsEarned") as? Double { return value }
            if let value = g.value(forKey: "grains") as? Double { return value }
            if let value = g.value(forKey: "points") as? Double { return value }
            if let value = g.value(forKey: "grainsEarned") as? NSNumber { return value.doubleValue }
        }
        let m = Mirror(reflecting: goal)
        for child in m.children {
            switch child.label {
            case "grainsEarned", "grains", "points":
                if let d = child.value as? Double { return d }
                if let i = child.value as? Int { return Double(i) }
                if let n = child.value as? NSNumber { return n.doubleValue }
            default: break
            }
        }
        return nil
    }

    private var notesText: String? {
        if let g = goal as? AnyObject {
            if let value = g.value(forKey: "notes") as? String, !value.isEmpty { return value }
            if let value = g.value(forKey: "detail") as? String, !value.isEmpty { return value }
            if let value = g.value(forKey: "descriptionText") as? String, !value.isEmpty { return value }
        }
        let m = Mirror(reflecting: goal)
        for child in m.children {
            switch child.label {
            case "notes", "detail", "descriptionText":
                if let s = child.value as? String, !s.isEmpty { return s }
            default: break
            }
        }
        return nil
    }

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            // Icône/Badge
            ZStack {
                Circle()
                    .fill(Color.orange.opacity(0.15))
                    .frame(width: 44, height: 44)
                Image(systemName: "trophy.fill")
                    .foregroundStyle(.orange)
            }

            VStack(alignment: .leading, spacing: 6) {
                // Titre de l'objectif
                Text(goal.title)
                    .font(.headline)
                    .foregroundStyle(.primary)
                    .lineLimit(2)

                // Métadonnées: date de complétion + grains gagnés si dispo
                HStack(spacing: 8) {
                    if let completedAt = completedDate {
                        Text(completedAt, style: .date)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }

                    if let grains = grainsEarnedValue {
                        Text("•")
                            .font(.subheadline)
                            .foregroundStyle(.tertiary)
                        Label("\(Int(grains)) grains", systemImage: "aqi.medium")
                            .labelStyle(.titleAndIcon)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                }

                // Description/notes si présentes
                if let notes = notesText {
                    Text(notes)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .lineLimit(3)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color(.secondarySystemBackground))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(Color.orange.opacity(0.12), lineWidth: 1)
        )
    }
}

#Preview("Victory Card") {
    VStack(spacing: 16) {
        Text("VictoryCardView requires a Goal instance from your app model.")
            .font(.footnote)
            .foregroundStyle(.secondary)
        // Replace the placeholder below with an actual Goal from your project when available.
        Text("Provide a sample Goal in the preview to render this card.")
            .font(.caption)
            .foregroundStyle(.tertiary)
    }
    .padding()
}
