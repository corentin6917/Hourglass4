//
//  LockScreenWidget.swift
//  HourglassWidget
//
//  Widget pour l'écran verrouillé avec objectifs en cours
//

import WidgetKit
import SwiftUI

// MARK: - Lock Screen Provider
struct LockScreenProvider: TimelineProvider {
    func placeholder(in context: Context) -> LockScreenEntry {
        LockScreenEntry(
            date: Date(),
            pendingGoals: [
                PendingGoal(title: "Course 5km", emoji: "🏃", grains: 3),
                PendingGoal(title: "Méditation", emoji: "🧘", grains: 2)
            ],
            timeUntilDeadline: 14400
        )
    }

    func getSnapshot(in context: Context, completion: @escaping (LockScreenEntry) -> ()) {
        let goals = SharedDataManager.shared.getPendingGoals()
        let entry = LockScreenEntry(
            date: Date(),
            pendingGoals: goals,
            timeUntilDeadline: SharedDataManager.shared.timeUntilDeadline
        )
        completion(entry)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<LockScreenEntry>) -> ()) {
        var entries: [LockScreenEntry] = []
        let currentDate = Date()

        // Rafraîchir toutes les 15 minutes
        for minuteOffset in stride(from: 0, to: 120, by: 15) {
            let entryDate = Calendar.current.date(byAdding: .minute, value: minuteOffset, to: currentDate)!
            let goals = SharedDataManager.shared.getPendingGoals()
            let entry = LockScreenEntry(
                date: entryDate,
                pendingGoals: goals,
                timeUntilDeadline: SharedDataManager.shared.timeUntilDeadline
            )
            entries.append(entry)
        }

        let timeline = Timeline(entries: entries, policy: .atEnd)
        completion(timeline)
    }
}

// MARK: - Lock Screen Entry
struct LockScreenEntry: TimelineEntry {
    let date: Date
    let pendingGoals: [PendingGoal]
    let timeUntilDeadline: TimeInterval

    var hasGoals: Bool {
        !pendingGoals.isEmpty
    }

    var firstGoal: PendingGoal? {
        pendingGoals.first
    }

    var goalsCount: Int {
        pendingGoals.count
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

    var isUrgent: Bool {
        return timeUntilDeadline < 3600 && hasGoals // Moins d'1h
    }
}

// MARK: - Circular Widget (Lock Screen)
struct CircularLockScreenView: View {
    var entry: LockScreenProvider.Entry

    var body: some View {
        ZStack {
            AccessoryWidgetBackground()

            VStack(spacing: 2) {
                if entry.hasGoals {
                    Text(entry.firstGoal?.emoji ?? "⭐")
                        .font(.system(size: 20))
                    Text("\(entry.goalsCount)")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(entry.isUrgent ? .red : .orange)
                } else {
                    Text("✓")
                        .font(.system(size: 24))
                        .foregroundColor(.green)
                }
            }
        }
        .widgetURL(URL(string: "hourglass://validate-goal"))
    }
}

// MARK: - Rectangular Widget (Lock Screen)
struct RectangularLockScreenView: View {
    var entry: LockScreenProvider.Entry

    var body: some View {
        ZStack {
            AccessoryWidgetBackground()

            if entry.hasGoals {
                VStack(alignment: .leading, spacing: 4) {
                    // Première ligne : nombre d'objectifs + temps
                    HStack {
                        Text("\(entry.goalsCount) objectif\(entry.goalsCount > 1 ? "s" : "")")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(entry.isUrgent ? .red : .primary)

                        Spacer()

                        if entry.timeUntilDeadline > 0 {
                            Text(entry.deadlineText)
                                .font(.system(size: 12, weight: .bold))
                                .foregroundColor(entry.isUrgent ? .red : .orange)
                        }
                    }

                    // Deuxième ligne : premier objectif
                    if let goal = entry.firstGoal {
                        HStack(spacing: 4) {
                            Text(goal.emoji)
                                .font(.system(size: 12))
                            Text(goal.title)
                                .font(.system(size: 12))
                                .lineLimit(1)
                            Spacer()
                            Text("+\(goal.grains)")
                                .font(.system(size: 11, weight: .semibold))
                                .foregroundColor(.orange)
                        }
                    }

                    // Troisième ligne : autres objectifs si plusieurs
                    if entry.goalsCount > 1 {
                        Text("+ \(entry.goalsCount - 1) autre\(entry.goalsCount > 2 ? "s" : "")")
                            .font(.system(size: 10))
                            .foregroundColor(.secondary)
                    }
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
            } else {
                HStack {
                    Text("✓")
                        .font(.system(size: 16))
                    Text("Tout validé !")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.green)
                }
                .padding()
            }
        }
        .widgetURL(URL(string: "hourglass://validate-goal"))
    }
}

// MARK: - Inline Widget (Lock Screen)
struct InlineLockScreenView: View {
    var entry: LockScreenProvider.Entry

    var body: some View {
        Group {
            if entry.hasGoals {
                HStack(spacing: 4) {
                    // Emoji du premier objectif
                    if let goal = entry.firstGoal {
                        Text(goal.emoji)
                        Text(goal.title)
                            .lineLimit(1)
                    }

                    // Compteur si plusieurs
                    if entry.goalsCount > 1 {
                        Text("+ \(entry.goalsCount - 1)")
                            .foregroundColor(.secondary)
                    }

                    // Temps restant
                    if entry.timeUntilDeadline > 0 {
                        Text("·")
                            .foregroundColor(.secondary)
                        Text(entry.deadlineText)
                            .foregroundColor(entry.isUrgent ? .red : .orange)
                    }
                }
                .font(.system(size: 14, weight: .medium))
            } else {
                HStack(spacing: 4) {
                    Text("✓")
                    Text("Objectifs validés")
                }
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.green)
            }
        }
        .widgetURL(URL(string: "hourglass://validate-goal"))
    }
}

// MARK: - Widget Configuration
struct LockScreenWidgetEntryView: View {
    var entry: LockScreenProvider.Entry
    @Environment(\.widgetFamily) var family

    var body: some View {
        switch family {
        case .accessoryCircular:
            CircularLockScreenView(entry: entry)
        case .accessoryRectangular:
            RectangularLockScreenView(entry: entry)
        case .accessoryInline:
            InlineLockScreenView(entry: entry)
        default:
            CircularLockScreenView(entry: entry)
        }
    }
}

@main
struct HourglassLockScreenWidget: Widget {
    let kind: String = "HourglassLockScreenWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: LockScreenProvider()) { entry in
            LockScreenWidgetEntryView(entry: entry)
                .containerBackground(Color.clear, for: .widget)
        }
        .configurationDisplayName("Objectifs en cours")
        .description("Vois tes objectifs à valider sur l'écran verrouillé")
        .supportedFamilies([
            .accessoryCircular,
            .accessoryRectangular,
            .accessoryInline
        ])
    }
}

// MARK: - Previews
#Preview("Circular", as: .accessoryCircular) {
    HourglassLockScreenWidget()
} timeline: {
    LockScreenEntry(
        date: .now,
        pendingGoals: [
            PendingGoal(title: "Course 5km", emoji: "🏃", grains: 3),
            PendingGoal(title: "Méditation", emoji: "🧘", grains: 2)
        ],
        timeUntilDeadline: 1800
    )
}

#Preview("Rectangular", as: .accessoryRectangular) {
    HourglassLockScreenWidget()
} timeline: {
    LockScreenEntry(
        date: .now,
        pendingGoals: [
            PendingGoal(title: "Course 5km", emoji: "🏃", grains: 3),
            PendingGoal(title: "Méditation", emoji: "🧘", grains: 2),
            PendingGoal(title: "Lecture", emoji: "📚", grains: 1)
        ],
        timeUntilDeadline: 3600
    )
}

#Preview("Inline", as: .accessoryInline) {
    HourglassLockScreenWidget()
} timeline: {
    LockScreenEntry(
        date: .now,
        pendingGoals: [
            PendingGoal(title: "Course 5km", emoji: "🏃", grains: 3)
        ],
        timeUntilDeadline: 7200
    )
}
