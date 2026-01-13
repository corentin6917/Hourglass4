//
//  HourglassTodayView.swift
//  Hourglass 4
//
//  Dashboard minimaliste "Today View" - Focus sur aujourd'hui
//

import SwiftUI
import FirebaseAuth
import FirebaseFirestore

struct HourglassTodayView: View {
    let viewModel: HourglassViewModel?
    @StateObject private var goalManager = GoalManager.shared
    @State private var showProfile = false
    @State private var animateProgress = false
    @State private var historicalData: [(date: Date, earned: Double, potential: Double)] = []
    @State private var heritageTotal: Double = 0
    @State private var activeDaysTotal: Int = 0
    @State private var isLoadingHeritage = false
    @State private var dailyBudget: Double = 10.0 // Budget quotidien adaptatif

    var lifeRatio: Double {
        let earned = earnedGrainsToday
        let potential = potentialGrainsToday
        return potential > 0 ? (earned / potential) : 0.0
    }

    var todayGrains: Double {
        earnedGrainsToday
    }

    // Calculer les grains depuis Firebase
    var earnedGrainsToday: Double {
        goalManager.todayGoals
            .filter { $0.status == .completed }
            .reduce(0) { $0 + $1.grainValue }
    }

    var potentialGrainsToday: Double {
        let pending = goalManager.todayGoals
            .filter { $0.status == .pending }
            .reduce(0) { $0 + $1.grainValue }
        return max(pending, 10.0) // Minimum 10 grains de potentiel
    }

    var ratioColor: Color {
        if lifeRatio < 0.3 {
            return Color(red: 1.0, green: 0.4, blue: 0.3)
        } else if lifeRatio < 0.7 {
            return .orange
        } else {
            return Color(red: 1.0, green: 0.6, blue: 0.0)
        }
    }

    var appCalendar: Calendar {
        AppTimeZone.calendar
    }

    var totalGrainsDisplay: Int {
        Int(dailyBudget.rounded()) // Utilise le budget quotidien adaptatif
    }

    var earnedGrainsDisplay: Int {
        min(totalGrainsDisplay, Int(todayGrains.rounded(.down)))
    }

    var totalHeritage: Double {
        heritageTotal
    }

    var todayObjectivesCount: Int {
        goalManager.todayGoals.count
    }

    var motivationalMessage: String {
        let grains = Int(todayGrains)
        if grains == 0 {
            return "Ta journée t'attend"
        } else if grains < 5 {
            return "Continue comme ça"
        } else if grains < 8 {
            return "Excellente journée"
        } else {
            return "Journée parfaite !"
        }
    }

    var formattedDate: String {
        AppTimeZone.formatDate(Date(), style: .long)
    }

    var body: some View {
        NavigationStack {
            ZStack {
                // Background gradient élégant
                LinearGradient(
                    colors: [
                        Color.white,
                        Color.orange.opacity(0.05)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 24) {
                        // Header
                        HStack {
                            VStack(alignment: .leading, spacing: 6) {
                                Text("Sablier")
                                    .font(.system(size: 36, weight: .bold))
                                    .foregroundStyle(
                                        LinearGradient(
                                            colors: [.orange, Color(red: 1.0, green: 0.6, blue: 0.0)],
                                            startPoint: .leading,
                                            endPoint: .trailing
                                        )
                                    )

                                Text(formattedDate)
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                            }

                            Spacer()
                            CurrentUserAvatarButton(size: 44) {
                                showProfile = true
                            }
                        }
                        .padding(.horizontal, 24)
                        .padding(.top, 16)

                        // Carte "Ton Sablier"
                        ZStack {
                            RoundedRectangle(cornerRadius: 32)
                                .fill(.ultraThinMaterial)
                                .background(
                                    RoundedRectangle(cornerRadius: 32)
                                        .fill(
                                            LinearGradient(
                                                colors: [
                                                    Color.white.opacity(0.78),
                                                    Color.orange.opacity(0.16)
                                                ],
                                                startPoint: .topLeading,
                                                endPoint: .bottomTrailing
                                            )
                                        )
                                )
                                .overlay {
                                    RoundedRectangle(cornerRadius: 32)
                                        .stroke(Color.white.opacity(0.6), lineWidth: 1)
                                }
                                .shadow(color: .black.opacity(0.12), radius: 22, x: 0, y: 12)

                            VStack(spacing: 20) {
                                VStack(spacing: 6) {
                                    Text("Ton Sablier")
                                        .font(.system(size: 22, weight: .bold))
                                        .foregroundStyle(.primary)
                                    Text("Mesure ton intensité de vie")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }

                                GrainClockView(
                                    total: totalGrainsDisplay,
                                    filled: earnedGrainsDisplay,
                                    color: ratioColor,
                                    value: String(format: "%.1f", todayGrains)
                                )

                                Text(motivationalMessage)
                                    .font(.caption)
                                    .fontWeight(.semibold)
                                    .foregroundStyle(.orange)
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 8)
                                    .background(
                                        Capsule()
                                            .fill(Color.orange.opacity(0.12))
                                    )

                                VStack(spacing: 12) {
                                    SablierPrimaryTile(
                                        icon: "sparkles",
                                        title: "Héritage total",
                                        value: "\(Int(totalHeritage))"
                                    )

                                    HStack(spacing: 12) {
                                    SablierMiniTile(
                                        icon: "calendar",
                                        title: "Jours actifs",
                                        value: isLoadingHeritage ? "…" : "\(activeDaysTotal)"
                                    )

                                        SablierMiniTile(
                                            icon: "tray",
                                            title: "Disponibles",
                                            value: String(format: "%.1f", max(potentialGrainsToday - todayGrains, 0))
                                        )

                                        SablierMiniTile(
                                            icon: "hourglass",
                                            title: "Aujourd'hui",
                                            value: "\(earnedGrainsDisplay)/\(totalGrainsDisplay)"
                                        )
                                    }
                                }
                            }
                            .padding(24)
                        }
                        .padding(.horizontal, 24)

                        // Bouton motivationnel si 0 objectifs créés
                        if todayObjectivesCount == 0 {
                            Button {
                                // Rediriger vers l'onglet Objectifs
                                NotificationCenter.default.post(name: .switchToObjectivesTab, object: nil)
                            } label: {
                                VStack(spacing: 12) {
                                    Text("Ta journée t'attend")
                                        .font(.headline)
                                        .fontWeight(.semibold)

                                    Text("Quel sera ton premier objectif ?")
                                        .font(.subheadline)
                                }
                                .foregroundStyle(.white)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, 32)
                                .padding(.vertical, 20)
                                .frame(maxWidth: .infinity)
                                .background {
                                    RoundedRectangle(cornerRadius: 20)
                                        .fill(
                                            LinearGradient(
                                                colors: [.orange, Color(red: 1.0, green: 0.6, blue: 0.0)],
                                                startPoint: .leading,
                                                endPoint: .trailing
                                            )
                                        )
                                        .shadow(color: .orange.opacity(0.3), radius: 12, x: 0, y: 6)
                                }
                            }
                            .padding(.horizontal, 24)
                            .padding(.vertical, 8)
                        } else if lifeRatio < 0.5 {
                            Text("Chaque objectif accompli te rapproche d'une vie plus intense.")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, 40)
                                .padding(.vertical, 16)
                        }

                        // Historique des 7 derniers jours avec vraies données
                        VStack(alignment: .leading, spacing: 20) {
                            Text("Historique de la semaine")
                                .font(.title3)
                                .fontWeight(.bold)
                                .foregroundStyle(.primary)
                                .padding(.horizontal, 24)

                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 16) {
                                    ForEach(Array(historicalData.enumerated()), id: \.offset) { index, dayData in
                                        let calendar = appCalendar
                                        let weekdaySymbols = ["Dimanche", "Lundi", "Mardi", "Mercredi", "Jeudi", "Vendredi", "Samedi"]
                                        let weekday = calendar.component(.weekday, from: dayData.date)
                                        let dayString = weekdaySymbols[weekday - 1]
                                        let ratio = dayData.potential > 0 ? (dayData.earned / dayData.potential) : 0.0
                                        let isToday = calendar.isDateInToday(dayData.date)

                                        HistoricalDayCard(
                                            day: dayString,
                                            earned: dayData.earned,
                                            potential: dayData.potential,
                                            ratio: ratio,
                                            isToday: isToday
                                        )
                                    }
                                }
                                .padding(.horizontal, 24)
                            }
                        }

                        Spacer(minLength: 40)
                    }
                }
            }
            .navigationBarHidden(true)
            .sheet(isPresented: $showProfile) {
                ProfileView(viewModel: viewModel)
            }
            .onAppear {
                animateProgress = true
                Task {
                    await goalManager.loadTodayGoals()
                    historicalData = await goalManager.loadCurrentWeekData()
                    await loadHeritageAndActiveDays()
                    dailyBudget = await goalManager.getDailyGrainsBudget()
                }
            }
            .refreshable {
                await goalManager.loadTodayGoals()
                historicalData = await goalManager.loadCurrentWeekData()
                await loadHeritageAndActiveDays()
                dailyBudget = await goalManager.getDailyGrainsBudget()
            }
        }
    }

    private func loadHeritageAndActiveDays() async {
        guard let currentUserId = Auth.auth().currentUser?.uid else { return }

        isLoadingHeritage = true
        let db = Firestore.firestore()
        do {
            let snapshot = try await db.collection("goals")
                .whereField("userId", isEqualTo: currentUserId)
                .whereField("status", isEqualTo: GoalStatus.completed.rawValue)
                .getDocuments()

            var total: Double = 0
            var activeDays = Set<Date>()
            let calendar = AppTimeZone.calendar

            for doc in snapshot.documents {
                let data = doc.data()
                total += data["grainValue"] as? Double ?? 0.0

                let completedAt = (data["completedAt"] as? Timestamp)?.dateValue()
                let createdAt = (data["createdAt"] as? Timestamp)?.dateValue()
                let date = completedAt ?? createdAt ?? Date()
                if let day = calendar.date(from: calendar.dateComponents([.year, .month, .day], from: date)) {
                    activeDays.insert(day)
                }
            }

            await MainActor.run {
                heritageTotal = total
                activeDaysTotal = activeDays.count
                isLoadingHeritage = false
            }
        } catch {
            await MainActor.run {
                isLoadingHeritage = false
            }
        }
    }
}

// MARK: - Carte de statistique avec icône

struct StatCardWithIcon: View {
    let icon: String
    let value: String
    let label: String
    let color: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Icône en haut
            Circle()
                .fill(color.opacity(0.15))
                .frame(width: 44, height: 44)
                .overlay {
                    Image(systemName: icon)
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundStyle(color)
                }

            VStack(alignment: .leading, spacing: 6) {
                // Valeur
                Text(value)
                    .font(.system(size: 28, weight: .bold))
                    .foregroundStyle(.primary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)

                // Label
                Text(label)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(20)
        .background {
            RoundedRectangle(cornerRadius: 20)
                .fill(Color(uiColor: .systemBackground))
                .shadow(color: .black.opacity(0.06), radius: 12, x: 0, y: 6)
        }
    }
}

// MARK: - Stat tile "Ton Sablier"

struct SablierStatTile: View {
    let icon: String
    let title: String
    let value: String

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Image(systemName: icon)
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(.orange)

            Text(value)
                .font(.system(size: 20, weight: .bold))
                .foregroundStyle(.primary)
                .lineLimit(1)
                .minimumScaleFactor(0.7)

            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
        .background {
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white.opacity(0.7))
                .overlay {
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.white.opacity(0.7), lineWidth: 1)
                }
        }
    }
}

struct SablierPrimaryTile: View {
    let icon: String
    let title: String
    let value: String

    var body: some View {
        HStack(spacing: 12) {
            Circle()
                .fill(Color.orange.opacity(0.18))
                .frame(width: 38, height: 38)
                .overlay {
                    Image(systemName: icon)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(.orange)
                }

            VStack(alignment: .leading, spacing: 4) {
                Text(value)
                    .font(.system(size: 26, weight: .bold))
                    .foregroundStyle(.primary)
                Text(title)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()
        }
        .padding(14)
        .background {
            RoundedRectangle(cornerRadius: 18)
                .fill(Color.white.opacity(0.85))
                .overlay {
                    RoundedRectangle(cornerRadius: 18)
                        .stroke(Color.orange.opacity(0.14), lineWidth: 1)
                }
        }
    }
}

struct SablierMiniTile: View {
    let icon: String
    let title: String
    let value: String

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(.orange)

            Text(value)
                .font(.system(size: 16, weight: .bold))
                .foregroundStyle(.primary)
                .lineLimit(1)
                .minimumScaleFactor(0.7)

            Text(title)
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .background {
            RoundedRectangle(cornerRadius: 14)
                .fill(Color.white.opacity(0.8))
                .overlay {
                    RoundedRectangle(cornerRadius: 14)
                        .stroke(Color.orange.opacity(0.12), lineWidth: 1)
                }
        }
    }
}

// MARK: - Intensité ring

struct GrainClockView: View {
    let total: Int
    let filled: Int
    let color: Color
    let value: String

    var body: some View {
        GeometryReader { proxy in
            let size = min(proxy.size.width, proxy.size.height)
            let radius = size / 2 - 12
            let markers = max(5, min(15, total)) // Nombre de points = budget quotidien (entre 5 et 15)

            ZStack {
                Circle()
                    .stroke(Color.orange.opacity(0.12), lineWidth: 8)

                Circle()
                    .trim(from: 0, to: total > 0 ? min(1, Double(filled) / Double(total)) : 0)
                    .stroke(
                        LinearGradient(
                            colors: [color.opacity(0.9), color],
                            startPoint: .top,
                            endPoint: .bottom
                        ),
                        style: StrokeStyle(lineWidth: 8, lineCap: .round)
                    )
                    .rotationEffect(.degrees(-90))

                ForEach(0..<markers, id: \.self) { index in
                    let angle = (Double(index) / Double(markers)) * (2 * Double.pi) - (Double.pi / 2)
                    let x = (size / 2) + cos(angle) * radius
                    let y = (size / 2) + sin(angle) * radius
                    let threshold = Int(round(Double(total) * (Double(index + 1) / Double(markers))))
                    let isFilled = filled >= max(1, threshold)

                    Circle()
                        .fill(isFilled ? color : Color.orange.opacity(0.18))
                        .frame(width: 6, height: 6)
                        .position(x: x, y: y)
                }

                VStack(spacing: 6) {
                    Text(value)
                        .font(.system(size: 34, weight: .bold))
                        .foregroundStyle(.orange)
                    Text("grains")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .frame(width: size, height: size)
        }
        .frame(width: 150, height: 150)
    }
}

// MARK: - Card pour l'historique quotidien

struct HistoricalDayCard: View {
    let day: String
    let earned: Double
    let potential: Double
    let ratio: Double
    let isToday: Bool

    var color: Color {
        if ratio < 0.3 {
            return Color(red: 1.0, green: 0.4, blue: 0.3)
        } else if ratio < 0.7 {
            return .orange
        } else {
            return Color(red: 1.0, green: 0.6, blue: 0.0)
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            // Card avec effet de profondeur
            ZStack {
                RoundedRectangle(cornerRadius: 20)
                    .fill(
                        LinearGradient(
                            colors: [
                                Color.white.opacity(0.78),
                                Color.orange.opacity(0.16)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .overlay {
                        RoundedRectangle(cornerRadius: 20)
                            .stroke(Color.white.opacity(0.6), lineWidth: 1)
                    }
                    .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: 6)

                VStack(spacing: 16) {
                    // Jour
                    Text(day)
                        .font(.system(size: 17, weight: isToday ? .bold : .semibold))
                        .foregroundStyle(isToday ? .primary : .secondary)
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)

                    // Cercle de progression amélioré
                    ZStack {
                        Circle()
                            .stroke(
                                LinearGradient(
                                    colors: [
                                        color.opacity(0.15),
                                        color.opacity(0.05)
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 8
                            )
                            .frame(width: 70, height: 70)

                        Circle()
                            .trim(from: 0, to: ratio)
                            .stroke(
                                LinearGradient(
                                    colors: [color, color.opacity(0.7)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                style: StrokeStyle(lineWidth: 8, lineCap: .round)
                            )
                            .frame(width: 70, height: 70)
                            .rotationEffect(.degrees(-90))

                        VStack(spacing: 2) {
                            Text(String(format: "%.0f%%", ratio * 100))
                                .font(.system(size: 16, weight: .bold))
                                .foregroundStyle(color)
                        }
                    }

                    // Stats
                    VStack(spacing: 4) {
                        Text(String(format: "%.1f", earned))
                            .font(.system(size: 18, weight: .bold))
                            .foregroundStyle(color)

                        Text("grains")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                }
                .padding(.vertical, 16)
                .padding(.horizontal, 12)
            }
            .scaleEffect(isToday ? 1.02 : 1.0)

            // Badge "Aujourd'hui"
            if isToday {
                Text("Aujourd'hui")
                    .font(.caption2)
                    .fontWeight(.bold)
                    .foregroundStyle(.white)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(
                        Capsule()
                            .fill(
                                LinearGradient(
                                    colors: [.orange, Color(red: 1.0, green: 0.6, blue: 0.0)],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                    )
                    .shadow(color: .orange.opacity(0.3), radius: 6, x: 0, y: 3)
                    .padding(.top, 10)
            }
        }
        .frame(width: 110, height: isToday ? 240 : 180)
        .animation(.spring(duration: 0.4), value: isToday)
    }
}


#Preview {
    HourglassTodayView(viewModel: nil)
}
