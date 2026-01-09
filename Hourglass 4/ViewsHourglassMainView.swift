//
//  HourglassMainView.swift
//  Hourglass 4
//
//  Created by Corentin Soula on 13/11/2025.
//

import SwiftUI

/// Vue principale du sablier avec animation
struct HourglassMainView: View {
    let viewModel: HourglassViewModel?
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    // Header compact
                    HStack(spacing: 10) {
                        Image(systemName: "trophy")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundStyle(.orange)
                        Text("HOURGLASS")
                            .font(.headline)
                            .foregroundStyle(.primary)
                        Spacer()
                        Circle()
                            .fill(LinearGradient(colors: [.pink, .purple], startPoint: .topLeading, endPoint: .bottomTrailing))
                            .frame(width: 28, height: 28)
                    }
                    .padding(.horizontal)
                    .padding(.top, 8)

                    // Title + subtitle
                    VStack(alignment: .leading, spacing: 4) {
                        HStack(spacing: 8) {
                            Image(systemName: "sparkles")
                                .foregroundStyle(.orange)
                            Text("Fil des Victoires")
                                .font(.system(size: 28, weight: .bold))
                        }
                        Text("Les accomplissements de la communauté")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal)

                    // Pills filters
                    HStack(spacing: 10) {
                        FilterPill(title: "Mes Complices", systemImage: "person.2.fill", selected: true, tint: .orange)
                        FilterPill(title: "Cette semaine", systemImage: "trophy.fill", selected: false, tint: .gray.opacity(0.3))
                        Spacer()
                    }
                    .padding(.horizontal)

                    // Info banner
                    InfoBannerView(
                        text: "Photos éphémères ! Les preuves photo deviennent visibles à partir de 20h et disparaissent après 24h.",
                        tint: .yellow
                    )
                    .padding(.horizontal)

                    // Empty state card
                    EmptyStateVictoryView()
                        .padding(.horizontal)

                    Spacer(minLength: 24)
                }
            }
            .background(
                LinearGradient(
                    colors: [Color.yellow.opacity(0.06), Color.orange.opacity(0.03)],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("HOURGLASS").font(.headline)
                }
            }
        }
    }
}

struct FilterPill: View {
    let title: String
    let systemImage: String
    let selected: Bool
    let tint: Color

    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: systemImage)
            Text(title)
                .fontWeight(.semibold)
        }
        .font(.subheadline)
        .foregroundStyle(selected ? .white : .primary)
        .padding(.vertical, 8)
        .padding(.horizontal, 12)
        .background(
            Capsule(style: .continuous)
                .fill(selected ? Color.orange : Color(.systemBackground))
                .shadow(color: selected ? Color.orange.opacity(0.25) : .clear, radius: 6, y: 2)
        )
        .overlay(
            Capsule(style: .continuous)
                .stroke(selected ? Color.orange.opacity(0.001) : Color.gray.opacity(0.15), lineWidth: 1)
        )
    }
}

struct InfoBannerView: View {
    let text: String
    let tint: Color

    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: "exclamationmark.bubble.fill")
                .foregroundStyle(.yellow)
            Text(text)
                .font(.subheadline)
                .foregroundStyle(.primary)
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(Color.yellow.opacity(0.12))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .stroke(Color.yellow.opacity(0.35), lineWidth: 1)
        )
    }
}

struct EmptyStateVictoryView: View {
    var body: some View {
        VStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(Color.orange.opacity(0.12))
                    .frame(width: 120, height: 120)
                Image(systemName: "sparkles")
                    .font(.system(size: 40, weight: .semibold))
                    .foregroundStyle(.orange)
            }
            Text("Aucune victoire visible")
                .font(.title3)
                .fontWeight(.bold)
            Text("Les photos de tes amis deviennent visibles à partir de 20h et restent 24h.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .center)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [Color.white, Color.yellow.opacity(0.05)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(Color.orange.opacity(0.12), lineWidth: 1)
        )
    }
}

// MARK: - Season Header

struct SeasonHeaderView: View {
    let season: LifeSeason
    
    var body: some View {
        VStack(spacing: 8) {
            Text(season.emoji)
                .font(.system(size: 60))
            
            Text(season.displayName)
                .font(.title2)
                .fontWeight(.bold)
            
            Text(season.message)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
        }
        .padding()
        .background {
            RoundedRectangle(cornerRadius: 20)
                .fill(seasonGradient(for: season))
                .opacity(0.2)
        }
        .padding(.horizontal)
    }
    
    private func seasonGradient(for season: LifeSeason) -> LinearGradient {
        switch season {
        case .winter:
            return LinearGradient(
                colors: [.blue, .cyan],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        case .spring:
            return LinearGradient(
                colors: [.green, .mint],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        case .summer:
            return LinearGradient(
                colors: [.yellow, .orange],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        case .autumn:
            return LinearGradient(
                colors: [.orange, .red],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }
    }
}

// MARK: - Hourglass Visual

struct HourglassVisualView: View {
    let viewModel: HourglassViewModel?
    
    @State private var grainsFalling = false
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Contour du sablier
                HourglassShapeView()
                    .stroke(Color.primary, lineWidth: 3)
                
                // Partie haute (potentiel blanc)
                VStack {
                    PotentialGrainsView(
                        count: Int(viewModel?.potentialGrainsToday() ?? 0),
                        falling: grainsFalling
                    )
                    .frame(height: geometry.size.height * 0.45)
                    
                    Spacer()
                }
                
                // Partie basse (héritage doré)
                VStack {
                    Spacer()
                    
                    EarnedGrainsView(
                        totalGrains: viewModel?.userProfile?.totalGrainsEarned ?? 0
                    )
                    .frame(height: geometry.size.height * 0.45)
                }
                
                // Goulot central
                HourglassNeckView()
                    .frame(height: 60)
            }
        }
        .onAppear {
            // Animation automatique toutes les 3 secondes
            withAnimation(.easeInOut(duration: 2.0).repeatForever()) {
                grainsFalling = true
            }
        }
    }
}

// MARK: - Hourglass Shape

struct HourglassShapeView: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        
        let width = rect.width
        let height = rect.height
        let neckWidth = width * 0.2
        
        // Partie haute (triangle inversé)
        path.move(to: CGPoint(x: rect.minX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.midX + neckWidth / 2, y: rect.midY))
        path.addLine(to: CGPoint(x: rect.midX - neckWidth / 2, y: rect.midY))
        path.closeSubpath()
        
        // Partie basse (triangle)
        path.move(to: CGPoint(x: rect.midX - neckWidth / 2, y: rect.midY))
        path.addLine(to: CGPoint(x: rect.midX + neckWidth / 2, y: rect.midY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
        path.closeSubpath()
        
        return path
    }
}

struct HourglassNeckView: View {
    var body: some View {
        Rectangle()
            .fill(Color.gray.opacity(0.3))
            .frame(width: 30)
    }
}

// MARK: - Potential Grains (Blanc)

struct PotentialGrainsView: View {
    let count: Int
    let falling: Bool
    
    var body: some View {
        ZStack {
            ForEach(0..<min(count, 10), id: \.self) { index in
                Circle()
                    .fill(Color.white)
                    .frame(width: 20, height: 20)
                    .shadow(color: .gray.opacity(0.3), radius: 2)
                    .offset(
                        x: CGFloat.random(in: -50...50),
                        y: falling ? CGFloat.random(in: 50...100) : CGFloat.random(in: -50...0)
                    )
                    .animation(
                        .easeInOut(duration: 2.0)
                            .delay(Double(index) * 0.1)
                            .repeatForever(autoreverses: false),
                        value: falling
                    )
            }
        }
    }
}

// MARK: - Earned Grains (Doré)

struct EarnedGrainsView: View {
    let totalGrains: Double
    
    var body: some View {
        VStack {
            ZStack {
                // Représentation visuelle des grains accumulés
                ForEach(0..<min(Int(totalGrains / 10), 50), id: \.self) { _ in
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [.yellow, .orange],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 15, height: 15)
                        .offset(
                            x: CGFloat.random(in: -80...80),
                            y: CGFloat.random(in: -80...0)
                        )
                }
            }
            
            Text("\(Int(totalGrains)) grains")
                .font(.headline)
                .foregroundStyle(.yellow)
        }
    }
}

// MARK: - Today Stats

struct TodayStatsView: View {
    let viewModel: HourglassViewModel?
    
    var body: some View {
        HStack(spacing: 20) {
            StatCard(
                title: "Potentiel",
                value: "\(Int(viewModel?.potentialGrainsToday() ?? 0))",
                color: .gray
            )
            
            StatCard(
                title: "Gagnés",
                value: "\(Int(viewModel?.earnedGrainsToday() ?? 0))",
                color: .yellow
            )
            
            StatCard(
                title: "Objectifs",
                value: "\(viewModel?.todayGoals.count ?? 0)",
                color: .blue
            )
        }
    }
}

struct StatCard: View {
    let title: String
    let value: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 8) {
            Text(value)
                .font(.system(size: 32, weight: .bold))
                .foregroundStyle(color)
            
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background {
            RoundedRectangle(cornerRadius: 15)
                .fill(color.opacity(0.1))
        }
    }
}

// MARK: - Life Ratio Card

struct LifeRatioCard: View {
    let profile: UserProfile
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Ratio de Vie")
                .font(.headline)
            
            // Barre de progression
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 10)
                        .fill(Color.gray.opacity(0.2))
                    
                    RoundedRectangle(cornerRadius: 10)
                        .fill(ratioColor(for: profile.lifeRatio()))
                        .frame(width: geometry.size.width * (profile.lifeRatio() / 100))
                }
            }
            .frame(height: 20)
            
            HStack {
                Text("\(Int(profile.lifeRatio()))%")
                    .font(.system(size: 48, weight: .bold))
                    .foregroundStyle(ratioColor(for: profile.lifeRatio()))
                
                Spacer()
                
                VStack(alignment: .trailing) {
                    Text("\(Int(profile.totalGrainsEarned)) grains")
                        .font(.subheadline)
                    Text("\(daysOnApp(from: profile.joinDate)) jours vécus")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            
            Text(profile.ratioInterpretation())
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .padding()
        .background {
            RoundedRectangle(cornerRadius: 20)
                .fill(Color(uiColor: .systemBackground))
                .shadow(color: .black.opacity(0.1), radius: 10)
        }
    }
    
    private func ratioColor(for ratio: Double) -> Color {
        switch ratio {
        case ..<30: return .red
        case 30..<50: return .orange
        case 50..<70: return .green
        default: return .cyan
        }
    }
    
    private func daysOnApp(from joinDate: Date) -> Int {
        AppTimeZone.calendar.dateComponents([.day], from: joinDate, to: Date()).day ?? 0
    }
}

// MARK: - Quick Actions

struct QuickActionsView: View {
    let viewModel: HourglassViewModel?
    
    var body: some View {
        VStack(spacing: 12) {
            Text("Actions Rapides")
                .font(.headline)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            HStack(spacing: 12) {
                NavigationLink {
                    CreateGoalView(viewModel: viewModel)
                } label: {
                    QuickActionButton(
                        icon: "plus.circle.fill",
                        title: "Objectif",
                        color: .blue
                    )
                }
                
                Button {
                    viewModel?.performEveningValidation()
                } label: {
                    QuickActionButton(
                        icon: "checkmark.circle.fill",
                        title: "Valider",
                        color: .green
                    )
                }
                
                NavigationLink {
                    // TODO: Vue des capsules
                    Text("Capsules")
                } label: {
                    QuickActionButton(
                        icon: "cube.fill",
                        title: "Capsules",
                        color: .purple
                    )
                }
            }
        }
    }
}

struct QuickActionButton: View {
    let icon: String
    let title: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 32))
                .foregroundStyle(color)
            
            Text(title)
                .font(.caption)
                .foregroundStyle(.primary)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background {
            RoundedRectangle(cornerRadius: 15)
                .fill(color.opacity(0.1))
        }
    }
}

#Preview {
    HourglassMainView(viewModel: nil)
}
