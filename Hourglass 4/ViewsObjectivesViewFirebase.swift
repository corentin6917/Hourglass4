//
//  ObjectivesViewFirebase.swift
//  Hourglass 4
//
//  Vue des Objectifs avec Firebase - MÊME DESIGN mais avec stockage Firebase
//

import SwiftUI

/// Vue des Objectifs - Gestion des objectifs quotidiens avec Firebase
struct ObjectivesViewFirebase: View {
    @StateObject private var goalManager = GoalManager.shared
    @State private var showNewGoal = false
    @State private var showProfile = false
    @State private var dailyBudget: Double = 10.0
    @State private var showBudgetInfo = false

    var todayGoals: [FirebaseGoal] {
        goalManager.todayGoals
    }

    var potentialAllocated: Double {
        // Seulement les objectifs validés comptent dans le potentiel alloué
        completedGoals.reduce(0) { $0 + $1.grainValue }
    }

    var potentialRemaining: Double {
        // Le potentiel restant = budget quotidien - grains gagnés
        dailyBudget - potentialAllocated
    }

    var completedGoals: [FirebaseGoal] {
        todayGoals.filter { $0.status == .completed }
    }

    var pendingGoals: [FirebaseGoal] {
        todayGoals.filter { $0.status == .pending }
    }

    var grainsEarned: Double {
        completedGoals.reduce(0) { $0 + $1.grainValue }
    }

    var formattedDate: String {
        AppTimeZone.formatDate(Date(), style: .long)
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color(uiColor: .systemGroupedBackground)
                    .ignoresSafeArea()

                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 20) {
                        HStack {
                            VStack(alignment: .leading, spacing: 6) {
                                Text("Objectifs")
                                    .font(.system(size: 34, weight: .bold))
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

                            CurrentUserAvatarButton(size: 42) {
                                showProfile = true
                            }
                        }
                        .padding(.horizontal, 24)
                        .padding(.top, 12)

                        ObjectiveBudgetCard(
                            allocated: potentialAllocated,
                            remaining: potentialRemaining,
                            totalBudget: dailyBudget
                        ) {
                            showBudgetInfo = true
                        }
                        .padding(.horizontal, 24)

                        InlineInfoBannerView(
                            text: "Règles : 1 à 3 objectifs par jour, pour un maximum de 10 grains au total.",
                            tint: .orange
                        )
                        .padding(.horizontal, 24)

                        HStack(spacing: 12) {
                            ObjectiveQuickStat(
                                icon: "clock",
                                value: "\(pendingGoals.count)",
                                label: "En cours",
                                color: .gray
                            )

                            ObjectiveQuickStat(
                                icon: "checkmark.circle.fill",
                                value: String(format: "%.1f", grainsEarned),
                                label: "Gagnés",
                                color: .green
                            )

                            ObjectiveQuickStat(
                                icon: "flag.fill",
                                value: "\(completedGoals.count)/\(todayGoals.count)",
                                label: "Objectifs",
                                color: .orange
                            )
                        }
                        .padding(.horizontal, 24)

                        if todayGoals.count < 3 && potentialRemaining > 0 {
                            Button {
                                showNewGoal = true
                            } label: {
                                HStack(spacing: 10) {
                                    Image(systemName: "plus")
                                        .font(.subheadline)
                                    Text("Nouvel objectif (\(todayGoals.count)/3)")
                                        .font(.subheadline)
                                        .fontWeight(.semibold)
                                }
                                .foregroundStyle(.white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 12)
                                .background {
                                    Capsule()
                                        .fill(
                                            LinearGradient(
                                                colors: [.orange, Color(red: 1.0, green: 0.6, blue: 0.0)],
                                                startPoint: .leading,
                                                endPoint: .trailing
                                            )
                                        )
                                        .shadow(color: .orange.opacity(0.3), radius: 8, x: 0, y: 4)
                                }
                            }
                            .padding(.horizontal, 24)
                        }

                        if pendingGoals.isEmpty && completedGoals.isEmpty {
                            VStack(spacing: 12) {
                                Image(systemName: "target")
                                    .font(.system(size: 34))
                                    .foregroundStyle(.orange)
                                Text("Aucun objectif pour aujourd'hui")
                                    .font(.headline)
                                Text("Ajoute ton premier objectif pour commencer.")
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                                    .multilineTextAlignment(.center)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 24)
                            .padding(.horizontal, 24)
                            .background {
                                RoundedRectangle(cornerRadius: 20)
                                    .fill(Color(uiColor: .systemBackground))
                                    .shadow(color: .black.opacity(0.06), radius: 12, x: 0, y: 6)
                            }
                            .padding(.horizontal, 24)
                        } else {
                            VStack(alignment: .leading, spacing: 16) {
                                if !pendingGoals.isEmpty {
                                    Text("En cours")
                                        .font(.headline)
                                        .padding(.horizontal, 24)

                                    ForEach(pendingGoals) { goal in
                                        FirebaseGoalCard(goal: goal)
                                            .padding(.horizontal, 24)
                                            .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                                Button(role: .destructive) {
                                                    Task {
                                                        try? await goalManager.deleteGoal(goal)
                                                    }
                                                } label: {
                                                    Label("Supprimer", systemImage: "trash")
                                                }
                                            }
                                    }
                                }

                                if !completedGoals.isEmpty {
                                    Text("Validés")
                                        .font(.headline)
                                        .padding(.horizontal, 24)

                                    ForEach(completedGoals) { goal in
                                        FirebaseGoalCard(goal: goal)
                                            .padding(.horizontal, 24)
                                            .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                                Button(role: .destructive) {
                                                    Task {
                                                        try? await goalManager.deleteGoal(goal)
                                                    }
                                                } label: {
                                                    Label("Supprimer", systemImage: "trash")
                                                }
                                            }
                                    }
                                }
                            }
                        }

                        Spacer(minLength: 40)
                    }
                    .padding(.vertical, 8)
                }
            }
            .navigationBarHidden(true)
            .sheet(isPresented: $showNewGoal) {
                FirebaseCreateGoalView()
            }
            .sheet(isPresented: $showProfile) {
                ProfileView(viewModel: nil)
            }
            .sheet(isPresented: $showBudgetInfo) {
                BudgetInfoSheet(currentBudget: dailyBudget)
            }
            .task {
                await goalManager.loadTodayGoals()
                dailyBudget = await goalManager.getDailyGrainsBudget()
            }
            .refreshable {
                await goalManager.loadTodayGoals()
                dailyBudget = await goalManager.getDailyGrainsBudget()
            }
        }
    }
}

// MARK: - Budget Info Sheet

struct BudgetInfoSheet: View {
    let currentBudget: Double
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    // Header
                    VStack(spacing: 12) {
                        Image(systemName: "chart.line.uptrend.xyaxis")
                            .font(.system(size: 50))
                            .foregroundStyle(.orange)

                        Text("Grains Adaptatifs")
                            .font(.title2)
                            .fontWeight(.bold)

                        Text("Ton budget quotidien: \(Int(currentBudget)) grains")
                            .font(.headline)
                            .foregroundStyle(.orange)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.bottom)

                    // Explication
                    VStack(alignment: .leading, spacing: 16) {
                        InfoSection(
                            icon: "brain.head.profile",
                            title: "Comment ça marche ?",
                            description: "Ton budget quotidien s'adapte automatiquement à tes performances des 7 derniers jours pour te motiver et t'aider à progresser."
                        )

                        InfoSection(
                            icon: "arrow.down.circle",
                            title: "Performance faible (< 40%)",
                            description: "Si tu accomplis peu d'objectifs plusieurs jours de suite, ton budget diminue pour rendre le 100% atteignable et te remotiver."
                        )

                        InfoSection(
                            icon: "arrow.right.circle",
                            title: "Performance équilibrée (40-60%)",
                            description: "Tu maintiens un bon rythme! Ton budget reste stable."
                        )

                        InfoSection(
                            icon: "arrow.up.circle",
                            title: "Performance élevée (> 75%)",
                            description: "Excellent! Ton budget augmente progressivement pour te challenger davantage."
                        )

                        InfoSection(
                            icon: "sparkles",
                            title: "Limites du système",
                            description: "Budget minimum: 5 grains\nBudget maximum: 15 grains\nAjustement progressif: max ±2 grains par jour"
                        )
                    }
                    .padding(.horizontal)
                }
                .padding(.vertical, 24)
            }
            .navigationTitle("Grains Adaptatifs")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Fermer") {
                        dismiss()
                    }
                }
            }
        }
    }
}

// MARK: - Objective Budget Card

struct ObjectiveBudgetCard: View {
    let allocated: Double
    let remaining: Double
    let totalBudget: Double
    let onInfo: () -> Void

    private var totalCount: Int {
        max(1, Int(totalBudget.rounded(.up)))
    }

    private var allocatedCount: Int {
        min(totalCount, Int(allocated.rounded(.down)))
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Grains du jour")
                    .font(.subheadline)
                    .fontWeight(.semibold)

                Spacer()

                Button {
                    onInfo()
                } label: {
                    Image(systemName: "info.circle")
                        .foregroundStyle(.secondary)
                }
            }

            HStack(alignment: .firstTextBaseline, spacing: 6) {
                Text("\(Int(totalBudget))")
                    .font(.system(size: 40, weight: .bold))
                    .foregroundStyle(.orange)

                Text("grains")
                    .font(.title3)
                    .foregroundStyle(.orange)
            }

            GrainDotsRow(total: totalCount, filled: allocatedCount, color: .orange)

            HStack {
                Text("Alloués: \(String(format: "%.1f", allocated))")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                Spacer()

                Text("Restant: \(String(format: "%.1f", remaining))")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(20)
        .background {
            RoundedRectangle(cornerRadius: 22)
                .fill(Color(uiColor: .systemBackground))
                .shadow(color: .black.opacity(0.06), radius: 12, x: 0, y: 6)
        }
    }
}

struct GrainDotsRow: View {
    let total: Int
    let filled: Int
    let color: Color

    var body: some View {
        HStack(spacing: 6) {
            ForEach(0..<total, id: \.self) { index in
                Circle()
                    .fill(index < filled ? color : Color.gray.opacity(0.2))
                    .frame(width: 8, height: 8)
            }
        }
    }
}

// MARK: - Objective Quick Stat

struct ObjectiveQuickStat: View {
    let icon: String
    let value: String
    let label: String
    let color: Color

    var body: some View {
        VStack(spacing: 10) {
            Circle()
                .fill(color.opacity(0.15))
                .frame(width: 36, height: 36)
                .overlay {
                    Image(systemName: icon)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(color)
                }

            Text(value)
                .font(.headline)
                .fontWeight(.bold)
                .foregroundStyle(.primary)

            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 14)
        .background {
            RoundedRectangle(cornerRadius: 18)
                .fill(Color(uiColor: .systemBackground))
                .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 4)
        }
    }
}

struct InfoSection: View {
    let icon: String
    let title: String
    let description: String

    var body: some View {
        HStack(alignment: .top, spacing: 16) {
            Image(systemName: icon)
                .font(.system(size: 24))
                .foregroundStyle(.orange)
                .frame(width: 32)

            VStack(alignment: .leading, spacing: 8) {
                Text(title)
                    .font(.headline)
                    .fontWeight(.semibold)

                Text(description)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.orange.opacity(0.08))
        )
    }
}

#Preview {
    ObjectivesViewFirebase()
}
