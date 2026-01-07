//
//  Theme.swift
//  Hourglass 4
//
//  Design System - BeReal-inspired minimalist aesthetic
//  Created on 2026-01-07
//

import SwiftUI

// MARK: - Theme
/// Centralized design system for the entire app
/// Inspired by BeReal's minimalist, authentic aesthetic
struct Theme {

    // MARK: - Colors
    struct Colors {

        // Primary colors - Monochrome base
        static let primary = Color("Primary") // Black in light mode, white in dark mode
        static let secondary = Color("Secondary") // Dark gray in light mode, light gray in dark mode
        static let background = Color("Background") // White in light mode, black in dark mode
        static let surface = Color("Surface") // Very light gray in light mode, dark gray in dark mode

        // Text hierarchy
        static let textPrimary = Color("TextPrimary") // High contrast
        static let textSecondary = Color("TextSecondary") // Medium contrast
        static let textTertiary = Color("TextTertiary") // Low contrast

        // Accent - Minimal usage, maximum impact
        static let accent = Color("Accent") // Subtle orange, used sparingly
        static let accentSubtle = Color("AccentSubtle") // Very faded accent

        // Semantic colors
        static let success = Color("Success") // Muted green
        static let error = Color("Error") // Muted red
        static let warning = Color("Warning") // Muted yellow

        // Borders and dividers
        static let border = Color("Border") // Subtle border color
        static let divider = Color("Divider") // Even more subtle divider

        // Overlays
        static let overlay = Color("Overlay") // For modals and sheets
        static let scrim = Color.black.opacity(0.4) // For dimming background

        // Legacy colors for gradual migration
        static let legacyOrange = Color.orange
        static let legacyPurple = Color.purple
        static let legacyBlue = Color.blue
    }

    // MARK: - Typography
    struct Typography {

        // Display - Extra large titles
        static let displayLarge = Font.system(size: 57, weight: .bold)
        static let displayMedium = Font.system(size: 45, weight: .bold)
        static let displaySmall = Font.system(size: 36, weight: .bold)

        // Headline - Page titles
        static let headlineLarge = Font.system(size: 32, weight: .semibold)
        static let headlineMedium = Font.system(size: 28, weight: .semibold)
        static let headlineSmall = Font.system(size: 24, weight: .semibold)

        // Title - Section titles
        static let titleLarge = Font.system(size: 22, weight: .medium)
        static let titleMedium = Font.system(size: 18, weight: .medium)
        static let titleSmall = Font.system(size: 16, weight: .medium)

        // Body - Main content
        static let bodyLarge = Font.system(size: 17, weight: .regular)
        static let bodyMedium = Font.system(size: 15, weight: .regular)
        static let bodySmall = Font.system(size: 13, weight: .regular)

        // Label - UI elements
        static let labelLarge = Font.system(size: 15, weight: .semibold)
        static let labelMedium = Font.system(size: 13, weight: .semibold)
        static let labelSmall = Font.system(size: 11, weight: .semibold)

        // Caption - Metadata
        static let caption = Font.system(size: 12, weight: .regular)
        static let captionSmall = Font.system(size: 11, weight: .regular)
    }

    // MARK: - Spacing
    struct Spacing {
        static let xxxSmall: CGFloat = 2
        static let xxSmall: CGFloat = 4
        static let xSmall: CGFloat = 8
        static let small: CGFloat = 12
        static let medium: CGFloat = 16
        static let large: CGFloat = 24
        static let xLarge: CGFloat = 32
        static let xxLarge: CGFloat = 48
        static let xxxLarge: CGFloat = 64
    }

    // MARK: - Corner Radius
    struct CornerRadius {
        static let small: CGFloat = 8
        static let medium: CGFloat = 12
        static let large: CGFloat = 16
        static let xLarge: CGFloat = 24
        static let full: CGFloat = 9999 // For circles
    }

    // MARK: - Border Width
    struct BorderWidth {
        static let thin: CGFloat = 0.5
        static let regular: CGFloat = 1
        static let thick: CGFloat = 2
        static let heavy: CGFloat = 3
    }

    // MARK: - Shadows
    struct Shadow {
        static let subtle = ShadowStyle(
            color: .black.opacity(0.04),
            radius: 8,
            x: 0,
            y: 2
        )

        static let medium = ShadowStyle(
            color: .black.opacity(0.08),
            radius: 16,
            x: 0,
            y: 4
        )

        static let strong = ShadowStyle(
            color: .black.opacity(0.12),
            radius: 24,
            x: 0,
            y: 8
        )

        static let none = ShadowStyle(
            color: .clear,
            radius: 0,
            x: 0,
            y: 0
        )
    }

    // MARK: - Animation
    struct Animation {
        static let fast = SwiftUI.Animation.easeInOut(duration: 0.15)
        static let standard = SwiftUI.Animation.easeInOut(duration: 0.3)
        static let slow = SwiftUI.Animation.easeInOut(duration: 0.5)
        static let spring = SwiftUI.Animation.spring(response: 0.4, dampingFraction: 0.8)
    }

    // MARK: - Icon Size
    struct IconSize {
        static let small: CGFloat = 16
        static let medium: CGFloat = 20
        static let large: CGFloat = 24
        static let xLarge: CGFloat = 32
        static let xxLarge: CGFloat = 48
    }
}

// MARK: - Shadow Style Helper
struct ShadowStyle {
    let color: Color
    let radius: CGFloat
    let x: CGFloat
    let y: CGFloat
}

// MARK: - View Extensions for Theme
extension View {

    /// Apply a themed shadow
    func themedShadow(_ style: ShadowStyle) -> some View {
        self.shadow(color: style.color, radius: style.radius, x: style.x, y: style.y)
    }

    /// Apply themed card style (minimalist BeReal-inspired)
    func themedCard() -> some View {
        self
            .background(Theme.Colors.surface)
            .cornerRadius(Theme.CornerRadius.large)
            .overlay(
                RoundedRectangle(cornerRadius: Theme.CornerRadius.large)
                    .stroke(Theme.Colors.border, lineWidth: Theme.BorderWidth.thin)
            )
    }

    /// Apply themed button style
    func themedButton(style: ThemeButtonStyle = .primary) -> some View {
        self.buttonStyle(ThemedButtonStyle(style: style))
    }
}

// MARK: - Themed Button Styles
enum ThemeButtonStyle {
    case primary   // Filled accent color
    case secondary // Outlined
    case ghost     // Text only
}

struct ThemedButtonStyle: ButtonStyle {
    let style: ThemeButtonStyle

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(Theme.Typography.labelLarge)
            .padding(.horizontal, Theme.Spacing.large)
            .padding(.vertical, Theme.Spacing.medium)
            .background(backgroundColor(isPressed: configuration.isPressed))
            .foregroundColor(foregroundColor(isPressed: configuration.isPressed))
            .cornerRadius(Theme.CornerRadius.large)
            .overlay(
                RoundedRectangle(cornerRadius: Theme.CornerRadius.large)
                    .stroke(borderColor, lineWidth: style == .secondary ? Theme.BorderWidth.regular : 0)
            )
            .scaleEffect(configuration.isPressed ? 0.97 : 1.0)
            .animation(Theme.Animation.fast, value: configuration.isPressed)
    }

    private func backgroundColor(isPressed: Bool) -> Color {
        switch style {
        case .primary:
            return isPressed ? Theme.Colors.accent.opacity(0.8) : Theme.Colors.accent
        case .secondary:
            return isPressed ? Theme.Colors.surface : Color.clear
        case .ghost:
            return Color.clear
        }
    }

    private func foregroundColor(isPressed: Bool) -> Color {
        switch style {
        case .primary:
            return .white
        case .secondary:
            return Theme.Colors.textPrimary
        case .ghost:
            return isPressed ? Theme.Colors.textSecondary : Theme.Colors.textPrimary
        }
    }

    private var borderColor: Color {
        style == .secondary ? Theme.Colors.border : .clear
    }
}
