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
    @State private var showSablierInfo = false

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
                                Button {
                                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                        showSablierInfo.toggle()
                                    }
                                } label: {
                                    Text("Sablier")
                                        .font(.system(size: 28, weight: .bold))
                                        .foregroundStyle(
                                            LinearGradient(
                                                colors: [.orange, Color(red: 1.0, green: 0.6, blue: 0.0)],
                                                startPoint: .leading,
                                                endPoint: .trailing
                                            )
                                        )
                                }
                                .buttonStyle(.plain)

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

                        if showSablierInfo {
                            VStack(alignment: .leading, spacing: 0) {
                                InfoBubbleTriangleUp()
                                    .fill(Color(uiColor: .systemBackground))
                                    .frame(width: 20, height: 10)
                                    .shadow(color: .orange.opacity(0.15), radius: 4, x: 0, y: -2)

                                VStack(alignment: .leading, spacing: 10) {
                                    HStack(spacing: 8) {
                                        Image(systemName: "hourglass.circle.fill")
                                            .font(.subheadline)
                                            .foregroundStyle(
                                                LinearGradient(
                                                    colors: [.orange, Color(red: 1.0, green: 0.6, blue: 0.0)],
                                                    startPoint: .topLeading,
                                                    endPoint: .bottomTrailing
                                                )
                                            )

                                        Text("Ton sablier")
                                            .font(.system(size: 14, weight: .semibold))
                                    }

                                    Text("Il représente ton potentiel du jour. Gagne des grains en validant tes objectifs, et le budget se remet à zéro chaque matin.")
                                        .font(.system(size: 12))
                                        .foregroundStyle(.secondary)
                                        .fixedSize(horizontal: false, vertical: true)
                                }
                                .padding(14)
                                .background {
                                    RoundedRectangle(cornerRadius: 16)
                                        .fill(Color(uiColor: .systemBackground))
                                        .shadow(color: .orange.opacity(0.25), radius: 16, x: 0, y: 8)
                                }
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.horizontal, 24)
                            .transition(.scale.combined(with: .opacity))
                            .onTapGesture {
                                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                    showSablierInfo = false
                                }
                            }
                        }

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
                                    value: "\(Int(ceil(todayGrains)))"
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
                                            value: "\(Int(ceil(max(potentialGrainsToday - todayGrains, 0))))"
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

                        // Bouton CTA si 0 objectifs créés aujourd'hui
                        if todayObjectivesCount == 0 {
                            Button {
                                // Rediriger vers l'onglet Objectifs
                                NotificationCenter.default.post(name: .switchToObjectivesTab, object: nil)
                            } label: {
                                Text("Commencer")
                                    .font(.headline)
                                    .fontWeight(.semibold)
                                    .foregroundStyle(.white)
                                    .padding(.horizontal, 28)
                                    .padding(.vertical, 14)
                                    .frame(maxWidth: .infinity)
                                    .background {
                                        RoundedRectangle(cornerRadius: 18)
                                            .fill(
                                                LinearGradient(
                                                    colors: [.orange, Color(red: 1.0, green: 0.6, blue: 0.0)],
                                                    startPoint: .leading,
                                                    endPoint: .trailing
                                                )
                                            )
                                            .shadow(color: .orange.opacity(0.28), radius: 10, x: 0, y: 5)
                                    }
                            }
                            .padding(.horizontal, 24)
                            .padding(.vertical, 8)
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
                                            date: dayData.date,
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
    let date: Date
    let earned: Double
    let potential: Double
    let ratio: Double
    let isToday: Bool

    @State private var showDayDetail = false

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
            Button {
                showDayDetail = true
            } label: {
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
                        Text("\(Int(ceil(earned)))")
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
            }
            .buttonStyle(.plain)

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
        .sheet(isPresented: $showDayDetail) {
            DayDetailView(date: date, day: day, earned: earned, potential: potential, ratio: ratio, color: color)
        }
    }
}
// MARK: - Vue de détail du jour

struct DayDetailView: View {
    let date: Date
    let day: String
    let earned: Double
    let potential: Double
    let ratio: Double
    let color: Color

    @Environment(\.dismiss) private var dismiss
    @State private var dayGoals: [FirebaseGoal] = []
    @State private var isLoading = true

    var formattedDate: String {
        let formatter = DateFormatter()
        formatter.calendar = AppTimeZone.calendar
        formatter.timeZone = AppTimeZone.current
        formatter.locale = Locale(identifier: "fr_FR")
        formatter.dateFormat = "d MMMM yyyy"
        return formatter.string(from: date)
    }

    var body: some View {
        NavigationStack {
            ZStack {
                // Background gradient
                LinearGradient(
                    colors: [
                        color.opacity(0.08),
                        Color(uiColor: .systemBackground)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 24) {
                        // En-tête avec cercle de progression - Card moderne
                        VStack(spacing: 20) {
                            ZStack {
                                // Shadow circles pour effet 3D
                                Circle()
                                    .fill(color.opacity(0.1))
                                    .frame(width: 150, height: 150)
                                    .blur(radius: 20)

                                Circle()
                                    .stroke(
                                        LinearGradient(
                                            colors: [
                                                color.opacity(0.2),
                                                color.opacity(0.05)
                                            ],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        ),
                                        lineWidth: 16
                                    )
                                    .frame(width: 140, height: 140)

                                Circle()
                                    .trim(from: 0, to: ratio)
                                    .stroke(
                                        LinearGradient(
                                            colors: [color, color.opacity(0.6), color.opacity(0.8)],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        ),
                                        style: StrokeStyle(lineWidth: 16, lineCap: .round)
                                    )
                                    .frame(width: 140, height: 140)
                                    .rotationEffect(.degrees(-90))
                                    .shadow(color: color.opacity(0.4), radius: 8, x: 0, y: 4)

                                VStack(spacing: 6) {
                                    Text(String(format: "%.0f%%", ratio * 100))
                                        .font(.system(size: 38, weight: .heavy))
                                        .foregroundStyle(
                                            LinearGradient(
                                                colors: [color, color.opacity(0.7)],
                                                startPoint: .topLeading,
                                                endPoint: .bottomTrailing
                                            )
                                        )
                                }
                            }

                            VStack(spacing: 4) {
                                Text(day)
                                    .font(.title2)
                                    .fontWeight(.bold)
                                    .foregroundStyle(.primary)

                                Text(formattedDate)
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                                    .foregroundStyle(.secondary)
                            }
                        }
                        .padding(.vertical, 32)
                        .padding(.horizontal, 20)
                        .frame(maxWidth: .infinity)
                        .background {
                            RoundedRectangle(cornerRadius: 30)
                                .fill(
                                    LinearGradient(
                                        colors: [
                                            Color(uiColor: .systemBackground),
                                            color.opacity(0.05)
                                        ],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .shadow(color: .black.opacity(0.08), radius: 20, x: 0, y: 10)
                                .shadow(color: color.opacity(0.15), radius: 15, x: 0, y: 5)
                        }
                        .padding(.horizontal)
                        .padding(.top, 8)

                    // Statistiques du jour (liste minimale)
                    VStack(alignment: .leading, spacing: 10) {
                        StatLine(
                            color: .green,
                            value: "\(Int(ceil(earned)))",
                            title: "grains gagnés"
                        )

                        StatLine(
                            color: .orange,
                            value: "\(Int(ceil(potential)))",
                            title: "potentiel"
                        )

                        StatLine(
                            color: .blue,
                            value: "\(dayGoals.filter { $0.status == .completed }.count) / \(dayGoals.count)",
                            title: "objectifs complétés"
                        )
                    }
                    .padding(.horizontal)

                    // Liste des objectifs du jour
                    if isLoading {
                        ProgressView()
                            .padding()
                    } else if dayGoals.isEmpty {
                        VStack(spacing: 12) {
                            Image(systemName: "tray")
                                .font(.system(size: 40))
                                .foregroundStyle(.secondary)

                            Text("Aucun objectif ce jour-là")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                        .padding()
                    } else {
                        VStack(alignment: .leading, spacing: 16) {
                            Text("Objectifs du jour")
                                .font(.title3)
                                .fontWeight(.bold)
                                .foregroundStyle(.primary)
                                .padding(.horizontal)

                            ForEach(dayGoals) { goal in
                                DayGoalRow(goal: goal)
                                    .padding(.horizontal)
                            }
                        }
                    }

                        Spacer(minLength: 40)
                    }
                    .padding(.vertical)
                }
            }
            .navigationTitle("")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.title3)
                            .foregroundStyle(.secondary)
                            .symbolRenderingMode(.hierarchical)
                    }
                }
            }
            .toolbarBackground(.hidden, for: .navigationBar)
            .task {
                await loadDayGoals()
            }
        }
    }

    private func loadDayGoals() async {
        isLoading = true
        dayGoals = await GoalManager.shared.loadGoalsForDate(date)
        isLoading = false
    }
}

// MARK: - Tuile de statistique compacte

struct StatTile: View {
    let icon: String
    let title: String
    let value: String
    let color: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [color.opacity(0.2), color.opacity(0.1)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 32, height: 32)

                    Image(systemName: icon)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [color, color.opacity(0.8)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                }

                Spacer()
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(value)
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.primary, .primary.opacity(0.8)],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )

                Text(title)
                    .font(.footnote)
                    .fontWeight(.regular)
                    .foregroundStyle(.secondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .background {
            RoundedRectangle(cornerRadius: 16)
                .fill(
                    LinearGradient(
                        colors: [
                            Color(uiColor: .systemBackground),
                            color.opacity(0.03)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .shadow(color: .black.opacity(0.04), radius: 8, x: 0, y: 4)
                .shadow(color: color.opacity(0.08), radius: 6, x: 0, y: 3)
        }
        .overlay {
            RoundedRectangle(cornerRadius: 16)
                .stroke(
                    LinearGradient(
                        colors: [color.opacity(0.15), color.opacity(0.05)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1
                )
        }
    }
}

struct StatLine: View {
    let color: Color
    let value: String
    let title: String

    var body: some View {
        HStack(spacing: 10) {
            Circle()
                .fill(color.opacity(0.25))
                .frame(width: 8, height: 8)

            Text(value)
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(.primary)

            Text(title)
                .font(.footnote)
                .foregroundStyle(.secondary)

            Spacer()
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Ligne d'objectif du jour

struct DayGoalRow: View {
    let goal: FirebaseGoal

    private var displayStatus: GoalStatus {
        if goal.status == .pending && isPastDay {
            return .expired
        }
        return goal.status
    }

    private var isPastDay: Bool {
        let calendar = AppTimeZone.calendar
        let goalDay = calendar.startOfDay(for: goal.createdAt)
        let today = calendar.startOfDay(for: Date())
        return goalDay < today
    }

    var statusIcon: String {
        switch displayStatus {
        case .completed: return "checkmark.circle.fill"
        case .pending: return "clock"
        case .cancelled: return "xmark.circle"
        case .expired: return "xmark.circle.fill"
        }
    }

    var statusColor: Color {
        switch displayStatus {
        case .completed: return .green
        case .pending: return .orange
        case .cancelled: return .gray
        case .expired: return Color(red: 1.0, green: 0.45, blue: 0.45)
        }
    }

    var body: some View {
        HStack(spacing: 14) {
            // Icon avec container circulaire moderne
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [statusColor.opacity(0.15), statusColor.opacity(0.08)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 40, height: 40)

                Image(systemName: statusIcon)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [statusColor, statusColor.opacity(0.8)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(goal.title)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundStyle(.primary)

                if let description = goal.goalDescription, !description.isEmpty {
                    Text(description)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 2) {
                Text("\(Int(ceil(goal.grainValue)))")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.orange, .orange.opacity(0.8)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )

                Text("grains")
                    .font(.caption2)
                    .fontWeight(.medium)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(16)
        .background {
            RoundedRectangle(cornerRadius: 16)
                .fill(
                    LinearGradient(
                        colors: [
                            Color(uiColor: .systemBackground),
                            statusColor.opacity(0.02)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .shadow(color: .black.opacity(0.06), radius: 10, x: 0, y: 4)
                .shadow(color: statusColor.opacity(0.08), radius: 6, x: 0, y: 2)
        }
        .overlay {
            RoundedRectangle(cornerRadius: 16)
                .stroke(
                    LinearGradient(
                        colors: [statusColor.opacity(0.12), statusColor.opacity(0.04)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1
                )
        }
    }
}

#Preview {
    HourglassTodayView(viewModel: nil)
}
