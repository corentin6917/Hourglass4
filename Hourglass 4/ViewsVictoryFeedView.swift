//
//  VictoryFeedView.swift
//  Hourglass 4
//
//  Created by Corentin Soula on 26/11/2025.
//

import SwiftUI

/// Période d'affichage des victoires
enum VictoryPeriod: String, CaseIterable, Identifiable {
    case today
    case thisWeek
    case thisMonth
    case thisYear
    case allTime

    var id: String { rawValue }
}

/// Audience de visibilité des victoires
enum VictoryAudience: String, CaseIterable, Identifiable {
    case friends
    case `public`
    case me

    var id: String { rawValue }
}

/// Vue du Fil des Victoires - Affiche l'historique des accomplissements
struct VictoryFeedView: View {
    let viewModel: HourglassViewModel?
    @State private var showProfile = false
    @State private var audience: VictoryAudience = .friends
    @State private var period: VictoryPeriod = .thisWeek
    
    var completedGoals: [Goal] {
        // Récupère tous les objectifs complétés
        viewModel?.userProfile?.goals.filter { $0.status == .completed } ?? []
    }
    
    var totalGrainsEarned: Double {
        viewModel?.userProfile?.totalGrainsEarned ?? 0.0
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    // En-tête style maquette
                    VictoryFeedHeaderView()
                        .padding(.top, 4)
                    
                    // Filtres en capsules
                    VictoryFilterBar(audience: $audience, period: $period)
                        .padding(.horizontal)
                    
                    // Bannière d'information jaune
                    EphemeralPhotosInfoBanner()
                        .padding(.horizontal)
                    
                    // Liste des victoires ou état vide
                    if completedGoals.isEmpty {
                        VictoryEmptyStateView()
                            .padding(.horizontal)
                    } else {
                        LazyVStack(spacing: 12) {
                            ForEach(completedGoals) { goal in
                                VictoryCardView(goal: goal)
                                    .padding(.horizontal)
                            }
                        }
                        .padding(.top, 4)
                    }
                }
                .padding(.vertical, 12)
            }
            .background(
                LinearGradient(
                    gradient: Gradient(colors: [Color(.systemBackground), Color.orange.opacity(0.03)]),
                    startPoint: UnitPoint.top,
                    endPoint: UnitPoint.bottom
                )
                .ignoresSafeArea()
            )
            .navigationTitle("")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showProfile = true
                    } label: {
                        Image(systemName: "person.circle")
                    }
                }
            }
            .sheet(isPresented: $showProfile) {
                Text("Profil à venir")
            }
        }
    }
}

#Preview {
    VictoryFeedView(viewModel: nil)
}

// MARK: - Empty State View for Victory Feed
struct VictoryEmptyStateView: View {
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: "sparkles")
                .font(.system(size: 40, weight: .semibold))
                .foregroundStyle(.secondary)
                .padding(.bottom, 4)

            Text("Aucune victoire pour l'instant")
                .font(.headline)
                .multilineTextAlignment(.center)

            Text("Complétez un objectif pour voir vos victoires ici.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color(.secondarySystemBackground))
        )
    }
}

#Preview("Empty state") {
    ScrollView {
        VictoryEmptyStateView()
            .padding()
    }
    .background(Color(.systemBackground))
}
