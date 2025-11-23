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
    
    @State private var animateGrains = false
    @State private var showSeasonMessage = false
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 30) {
                    // En-tête avec saison
                    if let profile = viewModel?.userProfile {
                        SeasonHeaderView(season: profile.currentSeason)
                            .padding(.top)
                    }
                    
                    // Le Sablier Visual
                    HourglassVisualView(viewModel: viewModel)
                        .frame(height: 400)
                        .padding()
                    
                    // Statistiques du jour
                    TodayStatsView(viewModel: viewModel)
                        .padding(.horizontal)
                    
                    // Ratio de vie
                    if let profile = viewModel?.userProfile {
                        LifeRatioCard(profile: profile)
                            .padding(.horizontal)
                    }
                    
                    // Actions rapides
                    QuickActionsView(viewModel: viewModel)
                        .padding(.horizontal)
                    
                    Spacer(minLength: 40)
                }
            }
            .navigationTitle("⏳ HOURGLASS")
            .navigationBarTitleDisplayMode(.large)
        }
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
        Calendar.current.dateComponents([.day], from: joinDate, to: Date()).day ?? 0
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