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

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    // Section: Potentiel du Jour avec icône info
                    ZStack(alignment: .topTrailing) {
                        PotentialCardView(
                            allocated: potentialAllocated,
                            remaining: potentialRemaining,
                            totalBudget: dailyBudget
                        )

                        // Icône "i" d'information
                        Button {
                            showBudgetInfo = true
                        } label: {
                            Image(systemName: "info.circle.fill")
                                .font(.system(size: 20))
                                .foregroundStyle(.orange)
                                .padding(8)
                        }
                    }
                    .padding(.horizontal)

                    // Règles
                    InfoBannerView(
                        text: "Règles : Tu dois définir entre 1 et 3 objectifs par jour, pour un maximum de 10 grains au total.",
                        tint: .orange
                    )
                    .padding(.horizontal)

                    // Statistiques en cartes
                    HStack(spacing: 12) {
                        ObjectiveStatCard(
                            icon: "clock",
                            value: "\(pendingGoals.count)",
                            label: "En cours",
                            color: .gray
                        )

                        ObjectiveStatCard(
                            icon: "checkmark.circle",
                            value: String(format: "%.1f", grainsEarned),
                            label: "Gagnés",
                            color: .green
                        )

                        ObjectiveStatCard(
                            icon: "arrow.up.right",
                            value: "\(completedGoals.count)/\(todayGoals.count)",
                            label: "Objectifs",
                            color: .orange
                        )
                    }
                    .padding(.horizontal)

                    // Bouton Nouvel Objectif
                    if todayGoals.count < 3 && potentialRemaining > 0 {
                        Button {
                            showNewGoal = true
                        } label: {
                            HStack {
                                Image(systemName: "plus.circle.fill")
                                    .font(.title2)

                                Text("Nouvel Objectif (\(todayGoals.count)/3)")
                                    .font(.headline)
                            }
                            .foregroundStyle(.orange)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background {
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Color.orange.opacity(0.1))
                            }
                        }
                        .padding(.horizontal)
                    }

                    // Liste des objectifs
                    if !todayGoals.isEmpty {
                        VStack(alignment: .leading, spacing: 16) {
                            Text("Objectifs d'aujourd'hui")
                                .font(.headline)
                                .padding(.horizontal)

                            ForEach(todayGoals) { goal in
                                FirebaseGoalCard(goal: goal)
                                    .padding(.horizontal)
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

                    Spacer(minLength: 40)
                }
                .padding(.vertical)
            }
            .navigationTitle("Mes Objectifs")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showProfile = true
                    } label: {
                        Circle()
                            .fill(Color.orange.gradient)
                            .frame(width: 36, height: 36)
                            .overlay {
                                Text("CS")
                                    .font(.caption)
                                    .fontWeight(.bold)
                                    .foregroundStyle(.white)
                            }
                    }
                }
            }
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
