//
//  SharedComponents.swift
//  Hourglass 4
//
//  Created by Corentin Soula on 13/11/2025.
//

import SwiftUI
import FirebaseAuth
import UIKit

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
                    
                    Text("\(Int(ceil(allocated))) / \(Int(ceil(total))) grains")
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
                    
                    Text("Il te reste \(Int(ceil(remaining))) grains à allouer")
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
    @State private var pendingFriendRequestsCount = 0

    var body: some View {
        Button {
            action()
        } label: {
            ZStack(alignment: .topTrailing) {
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
                if pendingFriendRequestsCount > 0 {
                    Circle()
                        .fill(Color.red)
                        .frame(width: max(8, size * 0.18), height: max(8, size * 0.18))
                        .overlay(
                            Circle()
                                .stroke(Color.white, lineWidth: 2)
                        )
                        .offset(x: 2, y: -2)
                        .accessibilityLabel("Nouvelle demande d'ami")
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
            await loadPendingFriendRequestsCount()
        }
        .onReceive(NotificationCenter.default.publisher(for: .profileDidUpdate)) { _ in
            Task {
                await loadCurrentUser(forceRefresh: true)
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: UIApplication.willEnterForegroundNotification)) { _ in
            Task {
                await loadPendingFriendRequestsCount()
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

    private func loadPendingFriendRequestsCount() async {
        do {
            let requests = try await FriendManager.shared.getPendingFriendRequests()
            await MainActor.run {
                pendingFriendRequestsCount = requests.count
            }
        } catch {
            await MainActor.run {
                pendingFriendRequestsCount = 0
            }
        }
    }
}

// MARK: - Page Header

enum PageHeaderDateStyle {
    case standard
    case capsule
}

struct PageHeader: View {
    let title: String
    let dateText: String
    var dateStyle: PageHeaderDateStyle = .standard
    var onTitleTap: (() -> Void)? = nil
    let onAvatarTap: () -> Void

    @ViewBuilder
    private func titleCapsule() -> some View {
        Text(title)
            .font(.system(size: 18, weight: .semibold))
            .foregroundStyle(.orange)
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(
                Capsule()
                    .fill(Color.orange.opacity(0.12))
                    .overlay {
                        Capsule()
                            .stroke(Color.orange.opacity(0.25), lineWidth: 1)
                    }
            )
    }

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 6) {
                if let onTitleTap {
                    Button(action: onTitleTap) {
                        titleCapsule()
                    }
                    .buttonStyle(.plain)
                } else {
                    titleCapsule()
                }

                if !dateText.isEmpty {
                    switch dateStyle {
                    case .standard:
                        Text(dateText)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    case .capsule:
                        Text(dateText)
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundStyle(.orange)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 4)
                            .background(
                                Capsule()
                                    .fill(Color.orange.opacity(0.12))
                            )
                    }
                }
            }

            Spacer()

            CurrentUserAvatarButton(size: 44) {
                onAvatarTap()
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 24)
        .padding(.top, 16)
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
