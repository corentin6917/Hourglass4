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
                VStack(spacing: 24) {
                    // Header compact
                    HStack(spacing: 10) {
                        Image(systemName: "sparkles")
                            .font(.title2)
                            .foregroundStyle(.orange)
                        Text("HOURGLASS")
                            .font(.headline)
                        Spacer()
                    }
                    .padding(.horizontal)
                    .padding(.top, 12)

                    VStack(spacing: 6) {
                        Text("Fil des Victoires")
                            .font(.system(size: 30, weight: .bold))
                        Text("Les accomplissements de la communauté")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity, alignment: .center)

                    // Segmented pills
                    SegmentedVictoryPicker(audience: $audience, period: $period)
                        .padding(.horizontal)

                    // Info banner
                    EphemeralPhotosInfoBanner()
                        .padding(.horizontal)

                    // Contenu centré
                    Group {
                        if completedGoals.isEmpty {
                            VictoryEmptyStateView()
                        } else {
                            LazyVStack(spacing: 12) {
                                ForEach(completedGoals) { goal in
                                    VictoryCardView(goal: goal)
                                        .padding(.horizontal)
                                }
                            }
                        }
                    }
                    .frame(maxWidth: 700)
                    .padding(.horizontal)
                }
                .padding(.vertical, 24)
            }
            .background(
                LinearGradient(
                    colors: [
                        Color(red: 1.0, green: 0.98, blue: 0.94),
                        Color.white
                    ],
                    startPoint: .top,
                    endPoint: .bottom
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
                ProfileView(viewModel: viewModel)
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
            ZStack {
                Circle()
                    .fill(Color.orange.opacity(0.12))
                    .frame(width: 100, height: 100)
                Image(systemName: "sparkles")
                    .font(.system(size: 40, weight: .semibold))
                    .foregroundStyle(.orange)
            }

            Text("Aucune victoire visible")
                .font(.title3).bold()
                .multilineTextAlignment(.center)

            Text("Les photos de tes amis deviennent visibles à partir de 20h et restent 24h.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 24)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 24)
    }
}

#Preview("Empty state") {
    ScrollView {
        VictoryEmptyStateView()
            .padding()
    }
    .background(Color(.systemBackground))
}

// MARK: - Segmented Picker

struct SegmentedVictoryPicker: View {
    @Binding var audience: VictoryAudience
    @Binding var period: VictoryPeriod

    var body: some View {
        HStack(spacing: 12) {
            SegmentButton(
                title: "Mes Complices",
                systemImage: "person.2.fill",
                isSelected: audience == .friends
            ) {
                audience = .friends
            }

            SegmentButton(
                title: "Cette semaine",
                systemImage: "trophy.fill",
                isSelected: period == .thisWeek
            ) {
                period = .thisWeek
            }
        }
        .padding(8)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(Color.white)
                .shadow(color: .black.opacity(0.06), radius: 8, y: 2)
        )
    }
}

private struct SegmentButton: View {
    let title: String
    let systemImage: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                Image(systemName: systemImage)
                Text(title)
                .fontWeight(.semibold)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 10)
            .foregroundStyle(isSelected ? .white : .primary)
            .background(
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(isSelected ? Color.orange : Color.white)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .stroke(Color.orange.opacity(isSelected ? 0 : 0.2), lineWidth: 1)
            )
        }
    }
}
