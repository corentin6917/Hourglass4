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

    var todayGoals: [FirebaseGoal] {
        goalManager.todayGoals
    }

    var potentialAllocated: Double {
        todayGoals.reduce(0) { $0 + $1.grainValue }
    }

    var potentialRemaining: Double {
        10.0 - potentialAllocated
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
                    // Section: Potentiel du Jour
                    PotentialCardView(
                        allocated: potentialAllocated,
                        remaining: potentialRemaining
                    )
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
            .task {
                await goalManager.loadTodayGoals()
            }
            .refreshable {
                await goalManager.loadTodayGoals()
            }
        }
    }
}

#Preview {
    ObjectivesViewFirebase()
}
