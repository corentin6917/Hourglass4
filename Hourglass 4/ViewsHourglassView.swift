//
//  HourglassView.swift
//  Hourglass 4
//
//  Created by Corentin Soula on 13/11/2025.
//

import SwiftUI

/// Vue principale du sablier
struct HourglassView: View {
    let viewModel: HourglassViewModel?
    @State private var showProfile = false
    @State private var showRatioInfo = false
    @State private var showHeritageInfo = false
    @State private var showDaysInfo = false
    @State private var showDispoInfo = false
    @State private var showTodayInfo = false
    
    var lifeRatio: Double {
        // Calcul du ratio de vie (exemple : earned / potential)
        let earned = viewModel?.earnedGrainsToday() ?? 0.0
        let potential = viewModel?.potentialGrainsToday() ?? 10.0
        return potential > 0 ? (earned / potential) : 0.0
    }
    
    var totalHeritage: Double {
        // Total des grains gagnés dans la saison
        viewModel?.userProfile?.totalGrainsEarned ?? 0.0
    }
    
    var daysLived: Int {
        // Jours vécus dans la saison
        guard let profile = viewModel?.userProfile else { return 29 }
        let calendar = AppTimeZone.calendar
        let days = calendar.dateComponents([.day], from: profile.seasonStartDate, to: Date()).day ?? 0
        return days
    }
    
    var availableGrains: Double {
        // Grains disponibles actuellement (grains gagnés non évaporés)
        guard let profile = viewModel?.userProfile else { return 0.0 }
        let earnedGrains = profile.grains.filter { $0.type == .earned }.reduce(0) { $0 + $1.value }
        let evaporatedGrains = profile.grains.filter { $0.type == .evaporated }.reduce(0) { $0 + $1.value }
        return earnedGrains - evaporatedGrains
    }
    
    var todayProgress: Double {
        // Grains gagnés aujourd'hui
        viewModel?.earnedGrainsToday() ?? 0.0
    }
    
    var ratioMessage: String {
        if lifeRatio < 0.3 {
            return "Tu survis plus que tu ne vis."
        } else if lifeRatio < 0.7 {
            return "Tu vis modérément."
        } else {
            return "Tu vis pleinement !"
        }
    }
    
    var ratioColor: Color {
        if lifeRatio < 0.3 {
            return .red
        } else if lifeRatio < 0.7 {
            return .orange
        } else {
            return .green
        }
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    headerSection
                    ratioCardSection
                    statsGridSection
                    Spacer(minLength: 40)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    CurrentUserAvatarButton(
                        size: 36,
                        action: { showProfile = true },
                        showShadow: false
                    )
                }
            }
            .sheet(isPresented: $showProfile) {
                ProfileView(viewModel: viewModel)
            }
            .alert("Ratio de Vie", isPresented: $showRatioInfo) {
                Button("OK") { }
            } message: {
                Text("Le ratio de vie mesure la qualité de ta journée en comparant les grains gagnés au potentiel disponible.")
            }
            .alert("Héritage", isPresented: $showHeritageInfo) {
                Button("OK") { }
            } message: {
                Text("Total des grains que tu as accumulés dans ta saison actuelle.")
            }
            .alert("Jours", isPresented: $showDaysInfo) {
                Button("OK") { }
            } message: {
                Text("Nombre de jours vécus dans la saison actuelle.")
            }
            .alert("Dispo", isPresented: $showDispoInfo) {
                Button("OK") { }
            } message: {
                Text("Grains disponibles que tu peux utiliser pour soutenir tes amis.")
            }
            .alert("Aujourd'hui", isPresented: $showTodayInfo) {
                Button("OK") { }
            } message: {
                Text("Nombre de grains gagnés aujourd'hui sur un maximum de 10.")
            }
        }
    }
}

private extension HourglassView {
    var headerSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 12) {
                Image(systemName: "hourglass")
                    .font(.system(size: 32))
                    .foregroundStyle(.orange)

                Text("TON SABLIER")
                    .font(.system(size: 34, weight: .bold))
            }

            Text("Ton héritage et ton ratio de vie")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal)
        .padding(.top, 20)
        .padding(.bottom, 24)
    }

    var ratioCardSection: some View {
        VStack(alignment: .leading, spacing: 20) {
            HStack {
                HStack(spacing: 8) {
                    Image(systemName: "arrow.up.right")
                        .font(.title3)

                    Text("RATIO DE VIE")
                        .font(.headline)
                        .fontWeight(.bold)
                }
                .foregroundStyle(ratioColor)

                Spacer()

                Button {
                    showRatioInfo = true
                } label: {
                    Image(systemName: "info.circle")
                        .font(.title3)
                        .foregroundStyle(.gray)
                }
            }

            Text(String(format: "%.0f%%", lifeRatio * 100))
                .font(.system(size: 80, weight: .bold))
                .foregroundStyle(ratioColor)
                .frame(maxWidth: .infinity)

            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 10)
                        .fill(Color.gray.opacity(0.3))

                    RoundedRectangle(cornerRadius: 10)
                        .fill(ratioColor)
                        .frame(width: geometry.size.width * lifeRatio)
                }
            }
            .frame(height: 20)

            Text(ratioMessage)
                .font(.headline)
                .foregroundStyle(ratioColor)
                .frame(maxWidth: .infinity, alignment: .center)
        }
        .padding(24)
        .background {
            RoundedRectangle(cornerRadius: 20)
                .fill(ratioColor.opacity(0.1))
        }
        .padding(.horizontal)
        .padding(.bottom, 24)
    }

    var statsGridSection: some View {
        LazyVGrid(columns: [
            GridItem(.flexible(), spacing: 16),
            GridItem(.flexible(), spacing: 16)
        ], spacing: 16) {
            StatCardView(
                icon: "sparkles",
                title: "Héritage",
                value: "\(Int(ceil(totalHeritage)))",
                subtitle: "grains",
                backgroundColor: Color(red: 1.0, green: 0.95, blue: 0.85),
                foregroundColor: Color(red: 0.8, green: 0.5, blue: 0.2),
                onInfoTapped: { showHeritageInfo = true }
            )

            StatCardView(
                icon: "calendar",
                title: "Jours",
                value: "\(daysLived)",
                subtitle: "vécus",
                backgroundColor: Color(red: 0.9, green: 0.95, blue: 1.0),
                foregroundColor: Color.blue,
                onInfoTapped: { showDaysInfo = true }
            )

            StatCardView(
                icon: "sparkle",
                title: "Dispo",
                value: "\(Int(ceil(availableGrains)))",
                subtitle: "grains",
                backgroundColor: Color(red: 0.95, green: 0.9, blue: 1.0),
                foregroundColor: Color.purple,
                onInfoTapped: { showDispoInfo = true }
            )

            StatCardView(
                icon: "arrow.up.right",
                title: "Aujour.",
                value: "\(Int(ceil(todayProgress)))",
                subtitle: "/10",
                backgroundColor: Color(red: 0.9, green: 1.0, blue: 0.95),
                foregroundColor: Color.green,
                onInfoTapped: { showTodayInfo = true }
            )
        }
        .padding(.horizontal)
        .padding(.bottom, 32)
    }
}

#Preview {
    HourglassView(viewModel: nil)
}
