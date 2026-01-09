//
//  HourglassTodayView.swift
//  Hourglass 4
//
//  Dashboard minimaliste "Today View" - Focus sur aujourd'hui
//

import SwiftUI

struct HourglassTodayView: View {
    let viewModel: HourglassViewModel?
    @StateObject private var goalManager = GoalManager.shared
    @State private var showProfile = false
    @State private var animateProgress = false
    @State private var historicalData: [(date: Date, earned: Double, potential: Double)] = []

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
        max(10, Int(potentialGrainsToday.rounded(.up)))
    }

    var earnedGrainsDisplay: Int {
        min(totalGrainsDisplay, Int(todayGrains.rounded(.down)))
    }

    var motivationalMessage: String {
        let grains = Int(todayGrains)
        if grains == 0 {
            return "Commence ta journée"
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
                        // Header élégant
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

                        // Card principale avec cercle de progression
                        ZStack {
                            RoundedRectangle(cornerRadius: 32)
                                .fill(.white)
                                .shadow(color: .black.opacity(0.08), radius: 20, x: 0, y: 10)

                            VStack(spacing: 32) {
                                // Anneau de grains minimaliste
                                ZStack {
                                    GrainRingView(
                                        totalCount: totalGrainsDisplay,
                                        filledCount: earnedGrainsDisplay,
                                        color: ratioColor,
                                        animate: animateProgress
                                    )

                                    VStack(spacing: 10) {
                                        Text("\(earnedGrainsDisplay)")
                                            .font(.system(size: 64, weight: .bold))
                                            .foregroundStyle(
                                                LinearGradient(
                                                    colors: [ratioColor, ratioColor.opacity(0.8)],
                                                    startPoint: .top,
                                                    endPoint: .bottom
                                                )
                                            )

                                        Text("grains gagnés")
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                            .textCase(.uppercase)
                                            .tracking(1.2)
                                    }
                                }
                                .padding(.top, 32)

                                // Stats des grains avec design cards
                                HStack(spacing: 16) {
                                    // Grains gagnés
                                    VStack(spacing: 8) {
                                        Text(String(format: "%.1f", todayGrains))
                                            .font(.system(size: 32, weight: .bold))
                                            .foregroundStyle(.orange)

                                        Text("grains gagnés")
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                    }
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 20)
                                    .background(
                                        RoundedRectangle(cornerRadius: 16)
                                            .fill(Color.orange.opacity(0.08))
                                    )

                                    // Potentiel
                                    VStack(spacing: 8) {
                                        Text(String(format: "%.1f", potentialGrainsToday))
                                            .font(.system(size: 32, weight: .bold))
                                            .foregroundStyle(.secondary)

                                        Text("potentiel")
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                    }
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 20)
                                    .background(
                                        RoundedRectangle(cornerRadius: 16)
                                            .fill(Color.gray.opacity(0.08))
                                    )
                                }
                                .padding(.horizontal, 20)

                                // Message motivationnel
                                Text(motivationalMessage)
                                    .font(.title3)
                                    .fontWeight(.semibold)
                                    .foregroundStyle(ratioColor)
                                    .padding(.bottom, 24)
                            }
                        }
                        .padding(.horizontal, 24)

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
                }
            }
            .refreshable {
                await goalManager.loadTodayGoals()
                historicalData = await goalManager.loadCurrentWeekData()
            }
        }
    }
}

// MARK: - Anneau de grains

struct GrainRingView: View {
    let totalCount: Int
    let filledCount: Int
    let color: Color
    let animate: Bool

    var body: some View {
        GeometryReader { proxy in
            let size = min(proxy.size.width, proxy.size.height)
            let radius = size / 2 - 14
            let count = max(1, totalCount)

            ZStack {
                ForEach(0..<count, id: \.self) { index in
                    let angle = (Double(index) / Double(count)) * (2 * Double.pi) - (Double.pi / 2)
                    let x = (size / 2) + cos(angle) * radius
                    let y = (size / 2) + sin(angle) * radius
                    let isFilled = index < filledCount
                    let dotSize: CGFloat = isFilled ? 10 : 8

                    Circle()
                        .fill(isFilled ? color : Color.gray.opacity(0.18))
                        .frame(width: dotSize, height: dotSize)
                        .shadow(color: isFilled ? color.opacity(0.35) : .clear, radius: isFilled ? 3 : 0, x: 0, y: 2)
                        .opacity(animate ? 1 : 0)
                        .scaleEffect(animate ? 1 : 0.6)
                        .position(x: x, y: y)
                        .animation(.easeOut(duration: 0.4).delay(Double(index) * 0.015), value: animate)
                }
            }
        }
        .frame(width: 250, height: 250)
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
        VStack(spacing: 12) {
            // Card avec effet de profondeur
            ZStack {
                RoundedRectangle(cornerRadius: 20)
                    .fill(isToday ? color.opacity(0.12) : Color.white)
                    .shadow(color: .black.opacity(isToday ? 0.12 : 0.06), radius: isToday ? 12 : 8, x: 0, y: isToday ? 6 : 4)

                VStack(spacing: 16) {
                    // Jour
                    Text(day)
                        .font(.system(size: 20, weight: isToday ? .bold : .semibold))
                        .foregroundStyle(isToday ? color : .secondary)

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
            .frame(width: 110, height: 180)

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
            }
        }
        .scaleEffect(isToday ? 1.05 : 1.0)
        .animation(.spring(duration: 0.4), value: isToday)
    }
}

#Preview {
    HourglassTodayView(viewModel: nil)
}
