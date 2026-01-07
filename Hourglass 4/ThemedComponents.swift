//
//  ThemedComponents.swift
//  Hourglass 4
//
//  Modern, minimalist UI components - BeReal inspired
//  Created on 2026-01-07
//

import SwiftUI

// MARK: - Themed Stat Card (Minimalist)
/// Replaces the colorful StatCardView with a clean, minimal design
struct ThemedStatCard: View {
    let title: String
    let value: String
    let icon: String
    let subtitle: String?

    init(title: String, value: String, icon: String, subtitle: String? = nil) {
        self.title = title
        self.value = value
        self.icon = icon
        self.subtitle = subtitle
    }

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.small) {
            // Icon
            Image(systemName: icon)
                .font(.system(size: Theme.IconSize.medium))
                .foregroundColor(Theme.Colors.textSecondary)

            Spacer()

            // Value - Large and bold
            Text(value)
                .font(Theme.Typography.displaySmall)
                .foregroundColor(Theme.Colors.textPrimary)
                .lineLimit(1)
                .minimumScaleFactor(0.7)

            // Title
            Text(title)
                .font(Theme.Typography.bodySmall)
                .foregroundColor(Theme.Colors.textSecondary)

            // Optional subtitle
            if let subtitle = subtitle {
                Text(subtitle)
                    .font(Theme.Typography.captionSmall)
                    .foregroundColor(Theme.Colors.textTertiary)
            }
        }
        .padding(Theme.Spacing.medium)
        .frame(maxWidth: .infinity, alignment: .leading)
        .frame(height: 140)
        .themedCard()
    }
}

// MARK: - Themed Victory Card (Clean & Authentic)
/// Minimalist victory card inspired by BeReal's photo-first approach
struct ThemedVictoryCard: View {
    let title: String
    let date: String
    let grains: Int
    let imageURL: String?
    let notes: String?

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Photo section (if available) - Full width like BeReal
            if let imageURL = imageURL {
                AsyncImage(url: URL(string: imageURL)) { phase in
                    switch phase {
                    case .success(let image):
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(height: 300)
                            .clipped()
                    case .failure, .empty:
                        Rectangle()
                            .fill(Theme.Colors.surface)
                            .frame(height: 300)
                            .overlay(
                                Image(systemName: "photo")
                                    .font(.system(size: 40))
                                    .foregroundColor(Theme.Colors.textTertiary)
                            )
                    @unknown default:
                        EmptyView()
                    }
                }
            }

            // Content section
            VStack(alignment: .leading, spacing: Theme.Spacing.small) {
                // Title
                Text(title)
                    .font(Theme.Typography.titleLarge)
                    .foregroundColor(Theme.Colors.textPrimary)

                // Date and grains in one line
                HStack(spacing: Theme.Spacing.xSmall) {
                    Text(date)
                        .font(Theme.Typography.bodySmall)
                        .foregroundColor(Theme.Colors.textSecondary)

                    Text("•")
                        .foregroundColor(Theme.Colors.textTertiary)

                    HStack(spacing: 4) {
                        Image(systemName: "circle.fill")
                            .font(.system(size: 6))
                            .foregroundColor(Theme.Colors.accent)

                        Text("\(grains)")
                            .font(Theme.Typography.labelSmall)
                            .foregroundColor(Theme.Colors.accent)
                    }
                }

                // Notes if available
                if let notes = notes, !notes.isEmpty {
                    Text(notes)
                        .font(Theme.Typography.bodyMedium)
                        .foregroundColor(Theme.Colors.textSecondary)
                        .lineLimit(2)
                        .padding(.top, Theme.Spacing.xxSmall)
                }
            }
            .padding(Theme.Spacing.medium)
        }
        .background(Theme.Colors.surface)
        .cornerRadius(Theme.CornerRadius.large)
        .overlay(
            RoundedRectangle(cornerRadius: Theme.CornerRadius.large)
                .stroke(Theme.Colors.border, lineWidth: Theme.BorderWidth.thin)
        )
    }
}

// MARK: - Themed Goal Card (Simple & Clear)
/// Clean goal card with minimal visual noise
struct ThemedGoalCard: View {
    let emoji: String
    let title: String
    let description: String
    let grains: Int
    let isCompleted: Bool

    var body: some View {
        HStack(spacing: Theme.Spacing.medium) {
            // Emoji icon
            Text(emoji)
                .font(.system(size: 32))

            // Content
            VStack(alignment: .leading, spacing: Theme.Spacing.xxSmall) {
                Text(title)
                    .font(Theme.Typography.titleMedium)
                    .foregroundColor(Theme.Colors.textPrimary)

                Text(description)
                    .font(Theme.Typography.bodySmall)
                    .foregroundColor(Theme.Colors.textSecondary)
                    .lineLimit(2)
            }

            Spacer()

            // Status and grain value
            VStack(alignment: .trailing, spacing: Theme.Spacing.xxSmall) {
                // Status badge
                if isCompleted {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: Theme.IconSize.medium))
                        .foregroundColor(Theme.Colors.success)
                } else {
                    Image(systemName: "circle")
                        .font(.system(size: Theme.IconSize.medium))
                        .foregroundColor(Theme.Colors.textTertiary)
                }

                // Grain value
                HStack(spacing: 4) {
                    Image(systemName: "circle.fill")
                        .font(.system(size: 6))
                        .foregroundColor(Theme.Colors.accent)

                    Text("\(grains)")
                        .font(Theme.Typography.labelSmall)
                        .foregroundColor(Theme.Colors.accent)
                }
            }
        }
        .padding(Theme.Spacing.medium)
        .themedCard()
    }
}

// MARK: - Themed Button
/// Primary action button with BeReal minimalist style
struct ThemedButton: View {
    let title: String
    let icon: String?
    let style: ThemeButtonStyle
    let action: () -> Void

    init(
        _ title: String,
        icon: String? = nil,
        style: ThemeButtonStyle = .primary,
        action: @escaping () -> Void
    ) {
        self.title = title
        self.icon = icon
        self.style = style
        self.action = action
    }

    var body: some View {
        Button(action: action) {
            HStack(spacing: Theme.Spacing.xSmall) {
                if let icon = icon {
                    Image(systemName: icon)
                        .font(.system(size: Theme.IconSize.medium))
                }
                Text(title)
            }
            .frame(maxWidth: .infinity)
        }
        .themedButton(style: style)
    }
}

// MARK: - Themed Section Header
/// Minimal section header
struct ThemedSectionHeader: View {
    let title: String
    let action: (() -> Void)?
    let actionTitle: String?

    init(_ title: String, action: (() -> Void)? = nil, actionTitle: String? = nil) {
        self.title = title
        self.action = action
        self.actionTitle = actionTitle
    }

    var body: some View {
        HStack {
            Text(title)
                .font(Theme.Typography.headlineSmall)
                .foregroundColor(Theme.Colors.textPrimary)

            Spacer()

            if let action = action, let actionTitle = actionTitle {
                Button(action: action) {
                    Text(actionTitle)
                        .font(Theme.Typography.labelMedium)
                        .foregroundColor(Theme.Colors.accent)
                }
            }
        }
        .padding(.horizontal, Theme.Spacing.medium)
        .padding(.vertical, Theme.Spacing.small)
    }
}

// MARK: - Themed Info Banner (Subtle)
/// Minimal info banner without heavy backgrounds
struct ThemedInfoBanner: View {
    let icon: String
    let title: String
    let message: String

    var body: some View {
        HStack(alignment: .top, spacing: Theme.Spacing.small) {
            Image(systemName: icon)
                .font(.system(size: Theme.IconSize.medium))
                .foregroundColor(Theme.Colors.accent)

            VStack(alignment: .leading, spacing: Theme.Spacing.xxSmall) {
                Text(title)
                    .font(Theme.Typography.labelLarge)
                    .foregroundColor(Theme.Colors.textPrimary)

                Text(message)
                    .font(Theme.Typography.bodySmall)
                    .foregroundColor(Theme.Colors.textSecondary)
            }

            Spacer()
        }
        .padding(Theme.Spacing.medium)
        .background(Theme.Colors.accentSubtle)
        .cornerRadius(Theme.CornerRadius.medium)
        .overlay(
            RoundedRectangle(cornerRadius: Theme.CornerRadius.medium)
                .stroke(Theme.Colors.accent.opacity(0.2), lineWidth: Theme.BorderWidth.thin)
        )
    }
}

// MARK: - Themed Avatar
/// Clean circular avatar with fallback
struct ThemedAvatar: View {
    let imageURL: String?
    let size: CGFloat
    let fallbackText: String?

    init(imageURL: String?, size: CGFloat = 40, fallbackText: String? = nil) {
        self.imageURL = imageURL
        self.size = size
        self.fallbackText = fallbackText
    }

    var body: some View {
        Group {
            if let imageURL = imageURL, let url = URL(string: imageURL) {
                AsyncImage(url: url) { phase in
                    switch phase {
                    case .success(let image):
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                    case .failure, .empty:
                        fallbackView
                    @unknown default:
                        fallbackView
                    }
                }
            } else {
                fallbackView
            }
        }
        .frame(width: size, height: size)
        .clipShape(Circle())
        .overlay(
            Circle()
                .stroke(Theme.Colors.border, lineWidth: Theme.BorderWidth.thin)
        )
    }

    private var fallbackView: some View {
        ZStack {
            Theme.Colors.surface

            if let text = fallbackText {
                Text(text.prefix(1).uppercased())
                    .font(.system(size: size * 0.4, weight: .semibold))
                    .foregroundColor(Theme.Colors.textSecondary)
            } else {
                Image(systemName: "person.fill")
                    .font(.system(size: size * 0.4))
                    .foregroundColor(Theme.Colors.textTertiary)
            }
        }
    }
}

// MARK: - Themed Divider
/// Subtle divider
struct ThemedDivider: View {
    var body: some View {
        Rectangle()
            .fill(Theme.Colors.divider)
            .frame(height: Theme.BorderWidth.thin)
    }
}

// MARK: - Themed Badge
/// Small badge for notifications/counts
struct ThemedBadge: View {
    let count: Int

    var body: some View {
        if count > 0 {
            Text("\(count)")
                .font(Theme.Typography.captionSmall)
                .foregroundColor(.white)
                .padding(.horizontal, 6)
                .padding(.vertical, 2)
                .background(Theme.Colors.error)
                .clipShape(Capsule())
        }
    }
}

// MARK: - Preview Provider
#Preview("Themed Components") {
    ScrollView {
        VStack(spacing: Theme.Spacing.large) {
            // Stat Cards
            HStack(spacing: Theme.Spacing.medium) {
                ThemedStatCard(
                    title: "Héritage",
                    value: "100",
                    icon: "star.fill",
                    subtitle: "grains"
                )

                ThemedStatCard(
                    title: "Jours vécus",
                    value: "8,234",
                    icon: "calendar"
                )
            }

            // Victory Card
            ThemedVictoryCard(
                title: "Séance de sport matinale",
                date: "Aujourd'hui à 8:30",
                grains: 5,
                imageURL: nil,
                notes: "Course de 5km au parc. Beau temps et bonne motivation !"
            )

            // Goal Card
            ThemedGoalCard(
                emoji: "💪",
                title: "Sport du matin",
                description: "Faire au moins 30 minutes d'exercice",
                grains: 5,
                isCompleted: false
            )

            // Buttons
            VStack(spacing: Theme.Spacing.small) {
                ThemedButton("Créer une victoire", icon: "plus", style: .primary) {}
                ThemedButton("Voir mon profil", style: .secondary) {}
                ThemedButton("Annuler", style: .ghost) {}
            }

            // Info Banner
            ThemedInfoBanner(
                icon: "info.circle",
                title: "Règle des photos",
                message: "Les photos disparaissent après 24h comme sur BeReal"
            )

            // Avatar
            HStack(spacing: Theme.Spacing.medium) {
                ThemedAvatar(imageURL: nil, size: 40, fallbackText: "C")
                ThemedAvatar(imageURL: nil, size: 60, fallbackText: "JS")
                ThemedAvatar(imageURL: nil, size: 80)
            }
        }
        .padding(Theme.Spacing.medium)
    }
    .background(Theme.Colors.background)
}
