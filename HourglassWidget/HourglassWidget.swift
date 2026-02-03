//
//  HourglassWidget.swift
//  HourglassWidget
//
//  Widget iOS pour afficher les statistiques quotidiennes
//

import WidgetKit
import SwiftUI

struct Provider: TimelineProvider {
    func placeholder(in context: Context) -> WidgetEntry {
        WidgetEntry(
            date: Date(),
            grainsToday: 7,
            grainsYesterday: 5,
            currentStreak: 12,
            pendingGoals: 2,
            completedGoals: 3,
            timeUntilDeadline: 14400 // 4h en secondes
        )
    }

    func getSnapshot(in context: Context, completion: @escaping (WidgetEntry) -> ()) {
        let entry = WidgetEntry(
            date: Date(),
            grainsToday: SharedDataManager.shared.grainsToday,
            grainsYesterday: SharedDataManager.shared.grainsYesterday,
            currentStreak: SharedDataManager.shared.currentStreak,
            pendingGoals: SharedDataManager.shared.pendingGoals,
            completedGoals: SharedDataManager.shared.completedGoals,
            timeUntilDeadline: SharedDataManager.shared.timeUntilDeadline
        )
        completion(entry)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<WidgetEntry>) -> ()) {
        var entries: [WidgetEntry] = []

        let currentDate = Date()
        let data = SharedDataManager.shared

        // Rafraîchir toutes les 15 minutes
        for minuteOffset in stride(from: 0, to: 120, by: 15) {
            let entryDate = Calendar.current.date(byAdding: .minute, value: minuteOffset, to: currentDate)!
            let entry = WidgetEntry(
                date: entryDate,
                grainsToday: data.grainsToday,
                grainsYesterday: data.grainsYesterday,
                currentStreak: data.currentStreak,
                pendingGoals: data.pendingGoals,
                completedGoals: data.completedGoals,
                timeUntilDeadline: data.timeUntilDeadline
            )
            entries.append(entry)
        }

        let timeline = Timeline(entries: entries, policy: .atEnd)
        completion(timeline)
    }
}

struct WidgetEntry: TimelineEntry {
    let date: Date
    let grainsToday: Int
    let grainsYesterday: Int
    let currentStreak: Int
    let pendingGoals: Int
    let completedGoals: Int
    let timeUntilDeadline: TimeInterval

    var progressPercentage: Double {
        return Double(grainsToday) / 10.0
    }

    var isUrgent: Bool {
        return timeUntilDeadline < 3600 && pendingGoals > 0 // Moins d'1h
    }

    var deadlineText: String {
        let hours = Int(timeUntilDeadline / 3600)
        let minutes = Int((timeUntilDeadline.truncatingRemainder(dividingBy: 3600)) / 60)

        if timeUntilDeadline <= 0 {
            return "Terminé"
        } else if hours > 0 {
            return "\(hours)h\(minutes)m"
        } else {
            return "\(minutes)m"
        }
    }
}

// MARK: - Small Widget View
struct SmallWidgetView: View {
    var entry: Provider.Entry

    var body: some View {
        ZStack {
            // Background gradient
            LinearGradient(
                colors: [Color.orange.opacity(0.1), Color.orange.opacity(0.05)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            VStack(spacing: 8) {
                // Streak avec flamme
                HStack(spacing: 4) {
                    Image(systemName: "flame.fill")
                        .foregroundColor(.orange)
                        .font(.system(size: 14))
                    Text("\(entry.currentStreak)")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.orange)
                    Spacer()
                }

                Spacer()

                // Grains géant
                VStack(spacing: 4) {
                    Text("\(entry.grainsToday)")
                        .font(.system(size: 48, weight: .black))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [.orange, .yellow],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )

                    Text("grains")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.secondary)
                }

                Spacer()

                // Comparaison avec hier
                if entry.grainsToday > entry.grainsYesterday {
                    HStack(spacing: 4) {
                        Image(systemName: "arrow.up.right")
                            .font(.system(size: 10))
                        Text("+\(entry.grainsToday - entry.grainsYesterday) vs hier")
                            .font(.system(size: 10, weight: .semibold))
                    }
                    .foregroundColor(.green)
                } else if entry.grainsToday < entry.grainsYesterday {
                    HStack(spacing: 4) {
                        Image(systemName: "arrow.down.right")
                            .font(.system(size: 10))
                        Text("\(entry.grainsYesterday - entry.grainsToday) vs hier")
                            .font(.system(size: 10, weight: .semibold))
                    }
                    .foregroundColor(.red)
                } else {
                    HStack(spacing: 4) {
                        Image(systemName: "equal")
                            .font(.system(size: 10))
                        Text("Comme hier")
                            .font(.system(size: 10, weight: .semibold))
                    }
                    .foregroundColor(.secondary)
                }
            }
            .padding(12)
        }
    }
}

// MARK: - Medium Widget View
struct MediumWidgetView: View {
    var entry: Provider.Entry

    var body: some View {
        ZStack {
            // Background
            LinearGradient(
                colors: [Color.orange.opacity(0.08), Color.orange.opacity(0.03)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            HStack(spacing: 16) {
                // Section gauche - Grains
                VStack(alignment: .leading, spacing: 8) {
                    // Streak
                    HStack(spacing: 4) {
                        Image(systemName: "flame.fill")
                            .foregroundColor(.orange)
                        Text("\(entry.currentStreak) jours")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(.orange)
                    }

                    Spacer()

                    // Grains du jour
                    VStack(alignment: .leading, spacing: 4) {
                        Text("\(entry.grainsToday)")
                            .font(.system(size: 42, weight: .black))
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [.orange, .yellow],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )

                        Text("grains aujourd'hui")
                            .font(.system(size: 11, weight: .medium))
                            .foregroundColor(.secondary)
                    }

                    // Progress bar
                    GeometryReader { geometry in
                        ZStack(alignment: .leading) {
                            RoundedRectangle(cornerRadius: 4)
                                .fill(Color.gray.opacity(0.2))
                                .frame(height: 6)

                            RoundedRectangle(cornerRadius: 4)
                                .fill(
                                    LinearGradient(
                                        colors: [.orange, .yellow],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .frame(width: geometry.size.width * min(entry.progressPercentage, 1.0), height: 6)
                        }
                    }
                    .frame(height: 6)

                    Text("\(Int(entry.progressPercentage * 100))% de l'objectif")
                        .font(.system(size: 9, weight: .medium))
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                Divider()

                // Section droite - Stats
                VStack(spacing: 12) {
                    // Objectifs complétés
                    VStack(spacing: 4) {
                        Text("\(entry.completedGoals)")
                            .font(.system(size: 28, weight: .bold))
                            .foregroundColor(.green)
                        Text("validés")
                            .font(.system(size: 10, weight: .medium))
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(8)
                    .background(Color.green.opacity(0.1))
                    .cornerRadius(8)

                    // Objectifs en attente
                    VStack(spacing: 4) {
                        Text("\(entry.pendingGoals)")
                            .font(.system(size: 28, weight: .bold))
                            .foregroundColor(entry.isUrgent ? .red : .orange)
                        Text("en attente")
                            .font(.system(size: 10, weight: .medium))
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(8)
                    .background((entry.isUrgent ? Color.red : Color.orange).opacity(0.1))
                    .cornerRadius(8)

                    // Countdown
                    if entry.timeUntilDeadline > 0 {
                        HStack(spacing: 4) {
                            Image(systemName: "clock.fill")
                                .font(.system(size: 10))
                            Text(entry.deadlineText)
                                .font(.system(size: 11, weight: .bold))
                        }
                        .foregroundColor(entry.isUrgent ? .red : .secondary)
                    }
                }
                .frame(width: 100)
            }
            .padding(16)
        }
    }
}

// MARK: - Large Widget View
struct LargeWidgetView: View {
    var entry: Provider.Entry

    var body: some View {
        ZStack {
            // Background
            LinearGradient(
                colors: [Color.orange.opacity(0.08), Color.orange.opacity(0.03)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            VStack(spacing: 16) {
                // Header avec streak
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Hourglass")
                            .font(.system(size: 18, weight: .bold))
                            .foregroundColor(.primary)

                        HStack(spacing: 4) {
                            Image(systemName: "flame.fill")
                                .foregroundColor(.orange)
                            Text("\(entry.currentStreak) jours de suite")
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundColor(.orange)
                        }
                    }

                    Spacer()

                    // Countdown urgent
                    if entry.timeUntilDeadline > 0 {
                        VStack(spacing: 2) {
                            Text(entry.deadlineText)
                                .font(.system(size: 20, weight: .bold))
                                .foregroundColor(entry.isUrgent ? .red : .orange)
                            Text("jusqu'à 20h")
                                .font(.system(size: 10, weight: .medium))
                                .foregroundColor(.secondary)
                        }
                        .padding(8)
                        .background((entry.isUrgent ? Color.red : Color.orange).opacity(0.15))
                        .cornerRadius(8)
                    }
                }

                Divider()

                // Grains géants avec progress
                VStack(spacing: 12) {
                    HStack(alignment: .firstTextBaseline, spacing: 8) {
                        Text("\(entry.grainsToday)")
                            .font(.system(size: 64, weight: .black))
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [.orange, .yellow],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )

                        Text("/ 10")
                            .font(.system(size: 32, weight: .medium))
                            .foregroundColor(.secondary)
                    }

                    Text("grains gagnés aujourd'hui")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.secondary)

                    // Progress bar élégante
                    GeometryReader { geometry in
                        ZStack(alignment: .leading) {
                            RoundedRectangle(cornerRadius: 6)
                                .fill(Color.gray.opacity(0.2))
                                .frame(height: 12)

                            RoundedRectangle(cornerRadius: 6)
                                .fill(
                                    LinearGradient(
                                        colors: [.orange, .yellow],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .frame(width: geometry.size.width * min(entry.progressPercentage, 1.0), height: 12)
                        }
                    }
                    .frame(height: 12)
                }

                // Stats en grille
                HStack(spacing: 12) {
                    // Validés
                    StatCard(
                        icon: "checkmark.circle.fill",
                        value: "\(entry.completedGoals)",
                        label: "Validés",
                        color: .green
                    )

                    // En attente
                    StatCard(
                        icon: "clock.fill",
                        value: "\(entry.pendingGoals)",
                        label: "En attente",
                        color: entry.isUrgent ? .red : .orange
                    )

                    // Hier
                    StatCard(
                        icon: "calendar",
                        value: "\(entry.grainsYesterday)",
                        label: "Hier",
                        color: .blue
                    )
                }

                // Message motivationnel
                if entry.pendingGoals > 0 && entry.isUrgent {
                    HStack(spacing: 8) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundColor(.red)
                        Text("Dépêche-toi ! \(entry.pendingGoals) objectif\(entry.pendingGoals > 1 ? "s" : "") à valider")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(.red)
                    }
                    .padding(8)
                    .frame(maxWidth: .infinity)
                    .background(Color.red.opacity(0.1))
                    .cornerRadius(8)
                } else if entry.grainsToday >= 10 {
                    HStack(spacing: 8) {
                        Image(systemName: "star.fill")
                            .foregroundColor(.orange)
                        Text("Objectif atteint ! Continue comme ça 🔥")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(.orange)
                    }
                    .padding(8)
                    .frame(maxWidth: .infinity)
                    .background(Color.orange.opacity(0.1))
                    .cornerRadius(8)
                }
            }
            .padding(16)
        }
    }
}

// MARK: - Stat Card Component
struct StatCard: View {
    let icon: String
    let value: String
    let label: String
    let color: Color

    var body: some View {
        VStack(spacing: 6) {
            Image(systemName: icon)
                .font(.system(size: 18))
                .foregroundColor(color)

            Text(value)
                .font(.system(size: 22, weight: .bold))
                .foregroundColor(color)

            Text(label)
                .font(.system(size: 10, weight: .medium))
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(color.opacity(0.1))
        .cornerRadius(10)
    }
}

// MARK: - Widget Configuration
struct HourglassWidgetEntryView : View {
    var entry: Provider.Entry
    @Environment(\.widgetFamily) var family

    var body: some View {
        switch family {
        case .systemSmall:
            SmallWidgetView(entry: entry)
        case .systemMedium:
            MediumWidgetView(entry: entry)
        case .systemLarge:
            LargeWidgetView(entry: entry)
        default:
            SmallWidgetView(entry: entry)
        }
    }
}

@main
struct HourglassWidget: Widget {
    let kind: String = "HourglassWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: Provider()) { entry in
            HourglassWidgetEntryView(entry: entry)
                .containerBackground(Color.clear, for: .widget)
        }
        .configurationDisplayName("Hourglass")
        .description("Suis tes grains et objectifs en temps réel")
        .supportedFamilies([.systemSmall, .systemMedium, .systemLarge])
    }
}

// MARK: - Previews
#Preview(as: .systemSmall) {
    HourglassWidget()
} timeline: {
    WidgetEntry(date: .now, grainsToday: 7, grainsYesterday: 5, currentStreak: 12, pendingGoals: 2, completedGoals: 3, timeUntilDeadline: 3600)
    WidgetEntry(date: .now, grainsToday: 10, grainsYesterday: 8, currentStreak: 25, pendingGoals: 0, completedGoals: 5, timeUntilDeadline: 0)
}

#Preview(as: .systemMedium) {
    HourglassWidget()
} timeline: {
    WidgetEntry(date: .now, grainsToday: 7, grainsYesterday: 5, currentStreak: 12, pendingGoals: 2, completedGoals: 3, timeUntilDeadline: 3600)
}

#Preview(as: .systemLarge) {
    HourglassWidget()
} timeline: {
    WidgetEntry(date: .now, grainsToday: 3, grainsYesterday: 7, currentStreak: 5, pendingGoals: 4, completedGoals: 1, timeUntilDeadline: 1800)
}
