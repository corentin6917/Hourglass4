//
//  AnimationHelpers.swift
//  Hourglass 4
//
//  Animations subtiles et fluides pour le design moderne
//  Created on 2026-01-07
//

import SwiftUI

// MARK: - Animation Presets
extension Animation {
    /// Animation rapide pour les interactions instantanées (boutons, toggles)
    static let themeFast = Animation.easeInOut(duration: 0.15)

    /// Animation standard pour la plupart des transitions
    static let themeStandard = Animation.easeInOut(duration: 0.3)

    /// Animation lente pour les grands changements d'état
    static let themeSlow = Animation.easeInOut(duration: 0.5)

    /// Spring naturel pour les mouvements organiques
    static let themeSpring = Animation.spring(response: 0.4, dampingFraction: 0.8)

    /// Spring bouncy pour les éléments ludiques (FAB, badges)
    static let themeBouncy = Animation.spring(response: 0.3, dampingFraction: 0.6)

    /// Animation douce pour les fades
    static let themeFade = Animation.easeOut(duration: 0.2)
}

// MARK: - View Modifiers avec animations

/// Fade in subtil à l'apparition
struct FadeInModifier: ViewModifier {
    @State private var opacity: Double = 0

    func body(content: Content) -> some View {
        content
            .opacity(opacity)
            .onAppear {
                withAnimation(.themeFade) {
                    opacity = 1
                }
            }
    }
}

/// Slide in depuis le bas
struct SlideInModifier: ViewModifier {
    @State private var offset: CGFloat = 20
    @State private var opacity: Double = 0

    func body(content: Content) -> some View {
        content
            .offset(y: offset)
            .opacity(opacity)
            .onAppear {
                withAnimation(.themeSpring) {
                    offset = 0
                    opacity = 1
                }
            }
    }
}

/// Scale in avec bounce
struct ScaleInModifier: ViewModifier {
    @State private var scale: CGFloat = 0.8
    @State private var opacity: Double = 0

    func body(content: Content) -> some View {
        content
            .scaleEffect(scale)
            .opacity(opacity)
            .onAppear {
                withAnimation(.themeBouncy) {
                    scale = 1
                    opacity = 1
                }
            }
    }
}

/// Effet de pression sur les boutons
struct PressEffectModifier: ViewModifier {
    @State private var isPressed = false

    func body(content: Content) -> some View {
        content
            .scaleEffect(isPressed ? 0.95 : 1.0)
            .brightness(isPressed ? -0.05 : 0)
            .simultaneousGesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { _ in
                        if !isPressed {
                            withAnimation(.themeFast) {
                                isPressed = true
                            }
                        }
                    }
                    .onEnded { _ in
                        withAnimation(.themeFast) {
                            isPressed = false
                        }
                    }
            )
    }
}

/// Shimmer effect pour les loadings
struct ShimmerModifier: ViewModifier {
    @State private var phase: CGFloat = 0

    func body(content: Content) -> some View {
        content
            .overlay(
                LinearGradient(
                    colors: [
                        .clear,
                        Theme.Colors.surface.opacity(0.5),
                        .clear
                    ],
                    startPoint: .leading,
                    endPoint: .trailing
                )
                .offset(x: phase)
                .mask(content)
            )
            .onAppear {
                withAnimation(
                    .linear(duration: 1.5)
                    .repeatForever(autoreverses: false)
                ) {
                    phase = 300
                }
            }
    }
}

/// Pulse animation pour les badges de notification
struct PulseModifier: ViewModifier {
    @State private var isPulsing = false

    func body(content: Content) -> some View {
        content
            .scaleEffect(isPulsing ? 1.1 : 1.0)
            .animation(
                .easeInOut(duration: 0.8)
                .repeatForever(autoreverses: true),
                value: isPulsing
            )
            .onAppear {
                isPulsing = true
            }
    }
}

/// Rotation continue (pour les loaders)
struct RotatingModifier: ViewModifier {
    @State private var rotation: Double = 0

    func body(content: Content) -> some View {
        content
            .rotationEffect(.degrees(rotation))
            .onAppear {
                withAnimation(
                    .linear(duration: 1)
                    .repeatForever(autoreverses: false)
                ) {
                    rotation = 360
                }
            }
    }
}

// MARK: - View Extensions

extension View {
    /// Applique une animation de fade in à l'apparition
    func fadeIn() -> some View {
        self.modifier(FadeInModifier())
    }

    /// Applique une animation de slide in depuis le bas
    func slideIn() -> some View {
        self.modifier(SlideInModifier())
    }

    /// Applique une animation de scale in avec bounce
    func scaleIn() -> some View {
        self.modifier(ScaleInModifier())
    }

    /// Applique un effet de pression tactile
    func pressEffect() -> some View {
        self.modifier(PressEffectModifier())
    }

    /// Applique un effet shimmer (loading)
    func shimmer() -> some View {
        self.modifier(ShimmerModifier())
    }

    /// Applique une animation de pulse
    func pulse() -> some View {
        self.modifier(PulseModifier())
    }

    /// Applique une rotation continue
    func rotating() -> some View {
        self.modifier(RotatingModifier())
    }

    /// Transition conditionnelle avec animation
    func animatedIf<T: Equatable>(_ condition: T, animation: Animation = .themeStandard) -> some View {
        self.animation(animation, value: condition)
    }
}

// MARK: - Transition Presets

extension AnyTransition {
    /// Fade simple
    static let themeFade = AnyTransition.opacity
        .animation(.themeFade)

    /// Slide depuis le bas
    static let themeSlideUp = AnyTransition.move(edge: .bottom)
        .combined(with: .opacity)
        .animation(.themeSpring)

    /// Scale avec fade
    static let themeScale = AnyTransition.scale(scale: 0.8)
        .combined(with: .opacity)
        .animation(.themeBouncy)

    /// Push depuis la droite
    static let themePush = AnyTransition.asymmetric(
        insertion: .move(edge: .trailing).combined(with: .opacity),
        removal: .move(edge: .leading).combined(with: .opacity)
    )
    .animation(.themeStandard)
}

// MARK: - Loading States

/// Vue de chargement minimaliste
struct LoadingView: View {
    var body: some View {
        Circle()
            .trim(from: 0, to: 0.7)
            .stroke(Theme.Colors.accent, style: StrokeStyle(lineWidth: 3, lineCap: .round))
            .frame(width: 30, height: 30)
            .rotating()
    }
}

/// Skeleton loader pour les cartes
struct SkeletonCard: View {
    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.small) {
            RoundedRectangle(cornerRadius: 8)
                .fill(Theme.Colors.surface)
                .frame(width: 80, height: 20)
                .shimmer()

            RoundedRectangle(cornerRadius: 8)
                .fill(Theme.Colors.surface)
                .frame(height: 60)
                .shimmer()

            RoundedRectangle(cornerRadius: 8)
                .fill(Theme.Colors.surface)
                .frame(width: 120, height: 16)
                .shimmer()
        }
        .padding(Theme.Spacing.medium)
        .themedCard()
    }
}

// MARK: - Interactive Animations

/// Bouton avec animation de succès
struct AnimatedSuccessButton: View {
    let title: String
    let action: () async -> Void

    @State private var isLoading = false
    @State private var isSuccess = false

    var body: some View {
        Button {
            Task {
                isLoading = true
                await action()
                isLoading = false

                withAnimation(.themeBouncy) {
                    isSuccess = true
                }

                try? await Task.sleep(nanoseconds: 1_500_000_000)

                withAnimation(.themeFast) {
                    isSuccess = false
                }
            }
        } label: {
            HStack(spacing: Theme.Spacing.xSmall) {
                if isLoading {
                    LoadingView()
                        .scaleEffect(0.7)
                } else if isSuccess {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: Theme.IconSize.medium))
                        .foregroundColor(Theme.Colors.success)
                        .transition(.themeScale)
                } else {
                    Text(title)
                        .font(Theme.Typography.labelLarge)
                }
            }
            .frame(maxWidth: .infinity)
            .frame(height: 50)
        }
        .disabled(isLoading || isSuccess)
        .themedButton(style: .primary)
        .animation(.themeSpring, value: isLoading)
        .animation(.themeSpring, value: isSuccess)
    }
}

// MARK: - Staggered Animations

/// Helper pour animer une liste avec un délai progressif
struct StaggeredView<Content: View>: View {
    let items: Int
    let delay: Double
    let content: (Int) -> Content

    init(items: Int, delay: Double = 0.05, @ViewBuilder content: @escaping (Int) -> Content) {
        self.items = items
        self.delay = delay
        self.content = content
    }

    var body: some View {
        ForEach(0..<items, id: \.self) { index in
            content(index)
                .opacity(0)
                .offset(y: 10)
                .animation(
                    .themeSpring.delay(Double(index) * delay),
                    value: true
                )
                .onAppear {
                    // Trigger animation
                }
        }
    }
}

// MARK: - Preview
#Preview("Animations") {
    ScrollView {
        VStack(spacing: Theme.Spacing.large) {
            Text("Exemples d'animations")
                .font(Theme.Typography.headlineLarge)
                .fadeIn()

            VStack(spacing: Theme.Spacing.medium) {
                // Fade In
                RoundedRectangle(cornerRadius: 12)
                    .fill(Theme.Colors.accent)
                    .frame(height: 60)
                    .overlay(Text("Fade In").foregroundColor(.white))
                    .fadeIn()

                // Slide In
                RoundedRectangle(cornerRadius: 12)
                    .fill(Theme.Colors.success)
                    .frame(height: 60)
                    .overlay(Text("Slide In").foregroundColor(.white))
                    .slideIn()

                // Scale In
                RoundedRectangle(cornerRadius: 12)
                    .fill(Theme.Colors.error)
                    .frame(height: 60)
                    .overlay(Text("Scale In").foregroundColor(.white))
                    .scaleIn()

                // Press Effect
                RoundedRectangle(cornerRadius: 12)
                    .fill(Theme.Colors.textPrimary)
                    .frame(height: 60)
                    .overlay(Text("Press Me").foregroundColor(.white))
                    .pressEffect()

                // Shimmer
                SkeletonCard()

                // Loading
                LoadingView()

                // Animated Button
                AnimatedSuccessButton(title: "Sauvegarder") {
                    try? await Task.sleep(nanoseconds: 2_000_000_000)
                }

                // Pulse Badge
                Circle()
                    .fill(Theme.Colors.error)
                    .frame(width: 20, height: 20)
                    .overlay(
                        Text("3")
                            .font(Theme.Typography.captionSmall)
                            .foregroundColor(.white)
                    )
                    .pulse()
            }
            .padding(Theme.Spacing.medium)
        }
    }
    .background(Theme.Colors.background)
}
