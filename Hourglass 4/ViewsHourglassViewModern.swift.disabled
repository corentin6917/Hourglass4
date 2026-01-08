//
//  ViewsHourglassViewModern.swift
//  Hourglass 4
//
//  Version moderne et minimaliste de HourglassView - BeReal-inspired
//  Created on 2026-01-07
//

import SwiftUI

/// Vue principale du sablier - Design minimaliste moderne
struct HourglassViewModern: View {
    let viewModel: HourglassViewModel?
    @State private var showProfile = false
    @State private var showRatioInfo = false

    // MARK: - Computed Properties
    var lifeRatio: Double {
        let earned = viewModel?.earnedGrainsToday() ?? 0.0
        let potential = viewModel?.potentialGrainsToday() ?? 10.0
        return potential > 0 ? (earned / potential) : 0.0
    }

    var totalHeritage: Double {
        viewModel?.userProfile?.totalGrainsEarned ?? 0.0
    }

    var daysLived: Int {
        guard let profile = viewModel?.userProfile else { return 0 }
        let calendar = Calendar.current
        let days = calendar.dateComponents([.day], from: profile.seasonStartDate, to: Date()).day ?? 0
        return days
    }

    var availableGrains: Double {
        guard let profile = viewModel?.userProfile else { return 0.0 }
        let earnedGrains = profile.grains.filter { $0.type == .earned }.reduce(0) { $0 + $1.value }
        let evaporatedGrains = profile.grains.filter { $0.type == .evaporated }.reduce(0) { $0 + $1.value }
        return earnedGrains - evaporatedGrains
    }

    var todayProgress: Double {
        viewModel?.earnedGrainsToday() ?? 0.0
    }

    var potentialGrains: Double {
        viewModel?.potentialGrainsToday() ?? 10.0
    }

    var ratioMessage: String {
        if lifeRatio < 0.3 {
            return "Survie"
        } else if lifeRatio < 0.7 {
            return "Équilibre"
        } else {
            return "Plénitude"
        }
    }

    var ratioColor: Color {
        if lifeRatio < 0.3 {
            return Theme.Colors.error
        } else if lifeRatio < 0.7 {
            return Theme.Colors.accent
        } else {
            return Theme.Colors.success
        }
    }

    // MARK: - Body
    var body: some View {
        NavigationStack {
            ScrollView(showsIndicators: false) {
                VStack(spacing: Theme.Spacing.xLarge) {
                    // Header avec profil
                    headerView

                    // Ratio de vie - Hero section
                    ratioCardView

                    // Stats en grille minimaliste
                    statsGridView

                    Spacer(minLength: Theme.Spacing.xxxLarge)
                }
                .padding(.horizontal, Theme.Spacing.medium)
                .padding(.top, Theme.Spacing.small)
            }
            .background(Theme.Colors.background)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    profileButton
                }
            }
            .sheet(isPresented: $showProfile) {
                ProfileView(viewModel: viewModel)
            }
        }
    }

    // MARK: - Header
    private var headerView: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.xxSmall) {
            Text("Ton Sablier")
                .font(Theme.Typography.displaySmall)
                .foregroundColor(Theme.Colors.textPrimary)

            Text("Ta vie en temps réel")
                .font(Theme.Typography.bodyMedium)
                .foregroundColor(Theme.Colors.textSecondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: - Ratio Card (Hero)
    private var ratioCardView: some View {
        VStack(spacing: Theme.Spacing.large) {
            // Ratio percentage - Grand et bold
            VStack(spacing: Theme.Spacing.xSmall) {
                Text(String(format: "%.0f%%", lifeRatio * 100))
                    .font(.system(size: 96, weight: .bold, design: .rounded))
                    .foregroundColor(ratioColor)
                    .animation(Theme.Animation.spring, value: lifeRatio)

                Text(ratioMessage)
                    .font(Theme.Typography.titleMedium)
                    .foregroundColor(ratioColor)
            }

            // Progress bar - Très subtile
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    // Background
                    Capsule()
                        .fill(Theme.Colors.surface)
                        .frame(height: 6)

                    // Progress
                    Capsule()
                        .fill(ratioColor)
                        .frame(width: max(6, geometry.size.width * lifeRatio), height: 6)
                        .animation(Theme.Animation.spring, value: lifeRatio)
                }
            }
            .frame(height: 6)

            // Info contextuelle
            HStack {
                HStack(spacing: 4) {
                    Image(systemName: "circle.fill")
                        .font(.system(size: 8))
                        .foregroundColor(Theme.Colors.accent)

                    Text("\(String(format: "%.1f", todayProgress))")
                        .font(Theme.Typography.labelMedium)
                }
                .foregroundColor(Theme.Colors.textSecondary)

                Text("/")
                    .foregroundColor(Theme.Colors.textTertiary)

                Text("\(String(format: "%.0f", potentialGrains)) grains aujourd'hui")
                    .font(Theme.Typography.bodySmall)
                    .foregroundColor(Theme.Colors.textSecondary)

                Spacer()

                Button {
                    showRatioInfo = true
                } label: {
                    Image(systemName: "info.circle")
                        .font(.system(size: Theme.IconSize.medium))
                        .foregroundColor(Theme.Colors.textTertiary)
                }
            }
        }
        .padding(Theme.Spacing.xLarge)
        .background(Theme.Colors.surface)
        .cornerRadius(Theme.CornerRadius.xLarge)
        .overlay(
            RoundedRectangle(cornerRadius: Theme.CornerRadius.xLarge)
                .stroke(ratioColor.opacity(0.2), lineWidth: Theme.BorderWidth.regular)
        )
        .alert("Ratio de Vie", isPresented: $showRatioInfo) {
            Button("OK") { }
        } message: {
            Text("Le ratio de vie mesure la qualité de ta journée en comparant les grains gagnés au potentiel disponible.")
        }
    }

    // MARK: - Stats Grid
    private var statsGridView: some View {
        LazyVGrid(
            columns: [
                GridItem(.flexible(), spacing: Theme.Spacing.medium),
                GridItem(.flexible(), spacing: Theme.Spacing.medium)
            ],
            spacing: Theme.Spacing.medium
        ) {
            ThemedStatCard(
                title: "Héritage",
                value: String(format: "%.0f", totalHeritage),
                icon: "sparkles",
                subtitle: "grains cumulés"
            )

            ThemedStatCard(
                title: "Jours vécus",
                value: "\(daysLived)",
                icon: "calendar",
                subtitle: "dans cette saison"
            )

            ThemedStatCard(
                title: "Disponibles",
                value: String(format: "%.0f", availableGrains),
                icon: "circle.fill",
                subtitle: "grains à utiliser"
            )

            ThemedStatCard(
                title: "Aujourd'hui",
                value: String(format: "%.1f", todayProgress),
                icon: "arrow.up.right",
                subtitle: "sur \(String(format: "%.0f", potentialGrains))"
            )
        }
    }

    // MARK: - Profile Button
    private var profileButton: some View {
        Button {
            showProfile = true
        } label: {
            ThemedAvatar(
                imageURL: viewModel?.userProfile?.profileImageURL,
                size: 36,
                fallbackText: viewModel?.userProfile?.username
            )
        }
    }
}

// MARK: - Preview
#Preview {
    HourglassViewModern(viewModel: nil)
}
