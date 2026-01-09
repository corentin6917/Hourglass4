//
//  SharedComponents.swift
//  Hourglass 4
//
//  Created by Corentin Soula on 13/11/2025.
//

import SwiftUI
import FirebaseAuth

// MARK: - Stat Card View

struct StatCardView: View {
    let icon: String
    let title: String
    let value: String
    let subtitle: String
    let backgroundColor: Color
    let foregroundColor: Color
    let onInfoTapped: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                HStack(spacing: 8) {
                    Image(systemName: icon)
                        .font(.subheadline)
                    
                    Text(title)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                }
                .foregroundStyle(foregroundColor)
                
                Spacer()
                
                Button {
                    onInfoTapped()
                } label: {
                    Image(systemName: "info.circle")
                        .font(.subheadline)
                        .foregroundStyle(.gray)
                }
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(value)
                    .font(.system(size: 48, weight: .bold))
                    .foregroundStyle(foregroundColor)
                
                Text(subtitle)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background {
            RoundedRectangle(cornerRadius: 20)
                .fill(backgroundColor)
        }
    }
}

// MARK: - Potential Card

struct PotentialCardView: View {
    let allocated: Double
    let remaining: Double
    var totalBudget: Double = 10.0

    var total: Double {
        totalBudget
    }

    var progress: Double {
        allocated / total
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("POTENTIEL DU JOUR")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    
                    HStack(alignment: .firstTextBaseline, spacing: 4) {
                        Text("\(Int(total))")
                            .font(.system(size: 48, weight: .bold))
                            .foregroundStyle(.orange)
                        
                        Text("grains")
                            .font(.title3)
                            .foregroundStyle(.orange)
                    }
                    
                    Text("Valeur fixe quotidienne")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                
                Spacer()
                
                Image(systemName: "sparkles")
                    .font(.system(size: 40))
                    .foregroundStyle(.orange)
            }
            
            Divider()
            
            // Potentiel alloué
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("Potentiel alloué")
                        .font(.subheadline)
                    
                    Spacer()
                    
                    Text(String(format: "%.1f / %.0f grains", allocated, total))
                        .font(.subheadline)
                        .foregroundStyle(.orange)
                }
                
                // Barre de progression
                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color.gray.opacity(0.2))
                        
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color.orange)
                            .frame(width: geometry.size.width * progress)
                    }
                }
                .frame(height: 12)
                
                HStack {
                    Image(systemName: "hourglass")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    
                    Text("Il te reste \(String(format: "%.1f", remaining)) grains à allouer")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding()
        .background {
            RoundedRectangle(cornerRadius: 15)
                .fill(Color.orange.opacity(0.1))
                .overlay {
                    RoundedRectangle(cornerRadius: 15)
                        .stroke(Color.orange.opacity(0.3), lineWidth: 2)
                }
        }
    }
}

// MARK: - Inline Info Banner

struct InlineInfoBannerView: View {
    let text: String
    let tint: Color
    
    init(text: String, tint: Color = .blue) {
        self.text = text
        self.tint = tint
    }
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "info.circle")
                .foregroundStyle(tint)
            
            Text(text)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background {
            RoundedRectangle(cornerRadius: 12)
                .fill(tint.opacity(0.1))
        }
    }
}

// MARK: - Backward compatibility wrapper

/// Renamed to avoid redeclaration conflicts with another InfoBannerView in the project.
/// Use InlineInfoBannerCompatView if you specifically need this wrapper.
struct InlineInfoBannerCompatView: View {
    private let inner: InlineInfoBannerView

    init(message: String, tint: Color = .blue) {
        self.inner = InlineInfoBannerView(text: message, tint: tint)
    }

    init(text: String, tint: Color = .blue) {
        self.inner = InlineInfoBannerView(text: text, tint: tint)
    }

    init() {
        self.inner = InlineInfoBannerView(text: "")
    }

    var body: some View {
        inner
    }
}

// MARK: - Current User Avatar Button

struct CurrentUserAvatarButton: View {
    let size: CGFloat
    let action: () -> Void
    var gradientColors: [Color] = [.orange, Color(red: 1.0, green: 0.6, blue: 0.0)]
    var showShadow: Bool = true

    @StateObject private var userManager = UserManager.shared
    @State private var userData: UserData?
    @State private var isLoading = true

    var body: some View {
        Button {
            action()
        } label: {
            Group {
                if let userData = userData {
                    ProfileImageView(
                        imageURL: userData.profileImageURL,
                        username: userData.username,
                        size: size,
                        gradientColors: gradientColors
                    )
                } else if isLoading {
                    Circle()
                        .fill(Color.orange.opacity(0.12))
                        .frame(width: size, height: size)
                        .overlay {
                            ProgressView()
                                .tint(.orange)
                        }
                } else {
                    ProfileImageView(
                        imageURL: nil,
                        username: "U",
                        size: size,
                        gradientColors: gradientColors
                    )
                }
            }
            .frame(width: size, height: size)
            .shadow(
                color: showShadow ? Color.orange.opacity(0.3) : .clear,
                radius: showShadow ? 8 : 0,
                x: 0,
                y: showShadow ? 4 : 0
            )
        }
        .buttonStyle(.plain)
        .task {
            await loadCurrentUser()
        }
        .onReceive(NotificationCenter.default.publisher(for: .profileDidUpdate)) { _ in
            Task {
                await loadCurrentUser(forceRefresh: true)
            }
        }
    }

    private func loadCurrentUser(forceRefresh: Bool = false) async {
        guard let currentUserId = Auth.auth().currentUser?.uid else {
            await MainActor.run {
                isLoading = false
                userData = nil
            }
            return
        }

        if !forceRefresh, let cached = userManager.cachedUsers[currentUserId] {
            await MainActor.run {
                isLoading = false
                userData = cached
            }
            return
        }

        do {
            if let data = try await UserManager.shared.getUserProfile(uid: currentUserId) {
                await MainActor.run {
                    userManager.cachedUsers[currentUserId] = data
                    userData = data
                    isLoading = false
                }
            } else {
                await MainActor.run {
                    isLoading = false
                }
            }
        } catch {
            await MainActor.run {
                isLoading = false
            }
        }
    }
}

// MARK: - Objective Stat Card

struct ObjectiveStatCard: View {
    let icon: String
    let value: String
    let label: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(color)
            
            Text(value)
                .font(.title)
                .fontWeight(.bold)
                .foregroundStyle(color)
            
            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background {
            RoundedRectangle(cornerRadius: 12)
                .fill(color.opacity(0.1))
        }
    }
}
