//
//  FirebaseGoalsView.swift
//  Hourglass 4
//
//  Vue principale des objectifs avec Firebase
//

import SwiftUI

struct FirebaseGoalsView: View {
    @StateObject private var goalManager = GoalManager.shared
    @State private var showCreateGoal = false

    var pendingGoals: [FirebaseGoal] {
        goalManager.todayGoals.filter { $0.status == .pending }
    }

    var completedGoals: [FirebaseGoal] {
        goalManager.todayGoals.filter { $0.status == .completed }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Header
                    VStack(spacing: 8) {
                        Text("⏳")
                            .font(.system(size: 60))

                        Text("HOURGLASS")
                            .font(.title)
                            .fontWeight(.bold)

                        Text("Tes Objectifs du Jour")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.top)

                    if goalManager.isLoading {
                        ProgressView("Chargement...")
                            .padding()
                    } else {
                        // En cours
                        if !pendingGoals.isEmpty {
                            VStack(alignment: .leading, spacing: 12) {
                                HStack {
                                    Image(systemName: "clock")
                                        .foregroundStyle(.orange)
                                    Text("En cours (\(pendingGoals.count))")
                                        .font(.headline)
                                }
                                .padding(.horizontal)

                                ForEach(pendingGoals) { goal in
                                    FirebaseGoalCard(goal: goal)
                                        .padding(.horizontal)
                                }
                            }
                        }

                        // Gagnés
                        if !completedGoals.isEmpty {
                            VStack(alignment: .leading, spacing: 12) {
                                HStack {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundStyle(.green)
                                    Text("Gagnés (\(completedGoals.count))")
                                        .font(.headline)
                                }
                                .padding(.horizontal)

                                ForEach(completedGoals) { goal in
                                    FirebaseGoalCard(goal: goal)
                                        .padding(.horizontal)
                                }
                            }
                        }

                        // Empty state
                        if goalManager.todayGoals.isEmpty {
                            VStack(spacing: 16) {
                                Image(systemName: "target")
                                    .font(.system(size: 60))
                                    .foregroundStyle(.orange.opacity(0.5))

                                Text("Aucun objectif pour aujourd'hui")
                                    .font(.headline)

                                Text("Crée ton premier objectif pour commencer à gagner des grains!")
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                                    .multilineTextAlignment(.center)
                                    .padding(.horizontal)
                            }
                            .padding(.vertical, 40)
                        }

                        // Bouton ajouter
                        Button {
                            showCreateGoal = true
                        } label: {
                            Label("Nouvel Objectif", systemImage: "plus.circle.fill")
                                .font(.headline)
                                .foregroundStyle(.white)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background {
                                    RoundedRectangle(cornerRadius: 15)
                                        .fill(Color.orange)
                                }
                        }
                        .padding(.horizontal)
                        .padding(.top)
                    }
                }
                .padding(.vertical)
            }
            .navigationTitle("Objectifs")
            .navigationBarTitleDisplayMode(.inline)
            .refreshable {
                await goalManager.loadTodayGoals()
            }
            .task {
                await goalManager.loadTodayGoals()
            }
            .sheet(isPresented: $showCreateGoal) {
                FirebaseCreateGoalView()
            }
        }
    }
}

#Preview {
    FirebaseGoalsView()
}
