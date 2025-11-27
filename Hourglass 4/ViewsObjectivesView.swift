//
//  ObjectivesView.swift
//  Hourglass 4
//
//  Created by Corentin Soula on 13/11/2025.
//

import SwiftUI

/// Vue des Objectifs - Gestion des objectifs quotidiens
struct ObjectivesView: View {
    let viewModel: HourglassViewModel?
    @State private var showNewGoal = false
    @State private var showProfile = false
    
    var todayGoals: [Goal] {
        viewModel?.todayGoals ?? []
    }
    
    var potentialAllocated: Double {
        todayGoals.reduce(0) { $0 + $1.grainValue }
    }
    
    var potentialRemaining: Double {
        10.0 - potentialAllocated
    }
    
    var completedGoals: [Goal] {
        todayGoals.filter { $0.status == .completed }
    }
    
    var pendingGoals: [Goal] {
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
                                GoalCardView(goal: goal, viewModel: viewModel)
                                    .padding(.horizontal)
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
                CreateGoalView(viewModel: viewModel)
            }
            .sheet(isPresented: $showProfile) {
                ProfileView(viewModel: viewModel)
            }
        }
    }
}

#Preview {
    ObjectivesView(viewModel: nil)
}
