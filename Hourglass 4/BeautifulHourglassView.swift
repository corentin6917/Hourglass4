//
//  BeautifulHourglassView.swift
//  Hourglass 4
//
//  Sablier MAGNIFIQUE et réaliste
//

import SwiftUI

struct BeautifulHourglassView: View {
    let progress: Double // 0.0 à 1.0
    let totalGrains: Int
    let earnedGrains: Int

    @State private var fallingParticles: [FallingParticle] = []
    @State private var glowPulse: Double = 1.0
    @State private var rotationEffect: Double = 0
    @State private var particleTimer: Timer?

    var body: some View {
        GeometryReader { geometry in
            let size = min(geometry.size.width, geometry.size.height)

            ZStack {
                // Glow d'arrière-plan
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [
                                Color.orange.opacity(0.2 * glowPulse),
                                Color.clear
                            ],
                            center: .center,
                            startRadius: 0,
                            endRadius: size * 0.6
                        )
                    )
                    .frame(width: size, height: size)
                    .blur(radius: 30)

                // Sablier principal
                hourglassBody(size: size)
            }
            .frame(width: geometry.size.width, height: geometry.size.height)
            .rotationEffect(.degrees(rotationEffect))
        }
        .onAppear {
            startAnimations()
        }
        .onDisappear {
            particleTimer?.invalidate()
            particleTimer = nil
        }
    }

    // MARK: - Corps du sablier

    @ViewBuilder
    private func hourglassBody(size: CGFloat) -> some View {
        ZStack {
            // Contour du verre (forme élégante)
            glassOutline(size: size)

            // Sable partie haute
            topSandFill(size: size)

            // Sable partie basse
            bottomSandFill(size: size)

            // Particules qui tombent
            fallingParticlesView(size: size)

            // Reflets sur le verre
            glassReflections(size: size)

            // Chiffres centraux avec effet néon
            centralNumbers(size: size)
        }
    }

    // MARK: - Contour du verre

    private func glassOutline(size: CGFloat) -> some View {
        ZStack {
            // Forme du sablier
            HourglassGlassShape()
                .stroke(
                    LinearGradient(
                        colors: [
                            Color.white.opacity(0.8),
                            Color.orange.opacity(0.3),
                            Color.white.opacity(0.5)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 3
                )
                .frame(width: size * 0.7, height: size * 0.9)

            // Ombre portée
            HourglassGlassShape()
                .fill(Color.black.opacity(0.05))
                .frame(width: size * 0.7, height: size * 0.9)
                .blur(radius: 10)
                .offset(x: 5, y: 5)
        }
    }

    // MARK: - Sable partie haute

    private func topSandFill(size: CGFloat) -> some View {
        HourglassGlassShape()
            .fill(
                LinearGradient(
                    colors: [
                        Color(red: 1.0, green: 0.85, blue: 0.4),
                        Color(red: 1.0, green: 0.75, blue: 0.3)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
            .mask(
                Rectangle()
                    .frame(height: 1000)
                    .offset(y: -500 + (500 * progress))
            )
            .clipShape(TopHalfShape())
            .frame(width: size * 0.7, height: size * 0.9)
            .shadow(color: .orange.opacity(0.3), radius: 8, x: 0, y: 3)
    }

    // MARK: - Sable partie basse

    private func bottomSandFill(size: CGFloat) -> some View {
        HourglassGlassShape()
            .fill(
                LinearGradient(
                    colors: [
                        Color(red: 1.0, green: 0.8, blue: 0.3),
                        Color(red: 1.0, green: 0.65, blue: 0.2)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
            .mask(
                Rectangle()
                    .frame(height: 1000)
                    .offset(y: 500 - (500 * progress))
            )
            .clipShape(BottomHalfShape())
            .frame(width: size * 0.7, height: size * 0.9)
            .overlay(
                // Texture brillante
                BottomHalfShape()
                    .fill(
                        LinearGradient(
                            colors: [
                                Color.white.opacity(0.3),
                                Color.clear
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .mask(
                        Rectangle()
                            .frame(height: 1000)
                            .offset(y: 500 - (500 * progress))
                    )
            )
    }

    // MARK: - Particules qui tombent

    private func fallingParticlesView(size: CGFloat) -> some View {
        ZStack {
            ForEach(fallingParticles) { particle in
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [Color.yellow, Color.orange],
                            center: .center,
                            startRadius: 0,
                            endRadius: particle.size
                        )
                    )
                    .frame(width: particle.size, height: particle.size)
                    .offset(x: particle.x, y: particle.y)
                    .opacity(particle.opacity)
                    .blur(radius: 0.5)
            }
        }
        .frame(width: size * 0.7, height: size * 0.9)
    }

    // MARK: - Reflets sur le verre

    private func glassReflections(size: CGFloat) -> some View {
        ZStack {
            // Reflet gauche
            Ellipse()
                .fill(
                    LinearGradient(
                        colors: [
                            Color.white.opacity(0.5),
                            Color.white.opacity(0.2),
                            Color.clear
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: size * 0.1, height: size * 0.3)
                .rotationEffect(.degrees(-20))
                .offset(x: -size * 0.2, y: -size * 0.25)
                .blur(radius: 2)

            // Reflet droit
            Ellipse()
                .fill(
                    LinearGradient(
                        colors: [
                            Color.white.opacity(0.4),
                            Color.clear
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .frame(width: size * 0.08, height: size * 0.2)
                .rotationEffect(.degrees(15))
                .offset(x: size * 0.18, y: size * 0.15)
                .blur(radius: 1.5)
        }
    }

    // MARK: - Chiffres centraux

    private func centralNumbers(size: CGFloat) -> some View {
        VStack(spacing: 4) {
            // Chiffre principal avec néon
            Text("\(earnedGrains)")
                .font(.system(size: size * 0.25, weight: .black, design: .rounded))
                .foregroundStyle(
                    LinearGradient(
                        colors: [
                            Color(red: 1.0, green: 0.95, blue: 0.6),
                            Color.orange
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .shadow(color: .orange.opacity(0.8 * glowPulse), radius: 20, x: 0, y: 0)
                .shadow(color: .yellow.opacity(0.6 * glowPulse), radius: 35, x: 0, y: 0)

            // Sous-titre
            Text("/ \(totalGrains) grains")
                .font(.system(size: size * 0.06, weight: .semibold, design: .rounded))
                .foregroundColor(.secondary)
        }
    }

    // MARK: - Animations

    private func startAnimations() {
        // Glow pulsant
        withAnimation(
            Animation.easeInOut(duration: 2.5)
                .repeatForever(autoreverses: true)
        ) {
            glowPulse = earnedGrains > totalGrains / 2 ? 1.5 : 0.7
        }

        // Rotation subtile
        withAnimation(
            Animation.easeInOut(duration: 4)
                .repeatForever(autoreverses: true)
        ) {
            rotationEffect = 3
        }

        // Particules tombantes
        particleTimer?.invalidate()
        particleTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { _ in
            if progress < 1.0 {
                addFallingParticle()
            }
        }
    }

    private func addFallingParticle() {
        let particle = FallingParticle(
            x: CGFloat.random(in: -5...5),
            y: -200,
            size: CGFloat.random(in: 3...6),
            opacity: 1.0
        )

        fallingParticles.append(particle)

        // Animation de la chute
        withAnimation(.linear(duration: Double.random(in: 1.2...1.8))) {
            if let index = fallingParticles.firstIndex(where: { $0.id == particle.id }) {
                fallingParticles[index].y = 200
                fallingParticles[index].opacity = 0
            }
        }

        // Nettoyage
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            fallingParticles.removeAll { $0.id == particle.id }
        }
    }
}

// MARK: - Falling Particle Model

struct FallingParticle: Identifiable {
    let id = UUID()
    var x: CGFloat
    var y: CGFloat
    var size: CGFloat
    var opacity: Double
}

// MARK: - Glass Shape (forme élégante courbe)

struct HourglassGlassShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()

        let width = rect.width
        let height = rect.height
        let centerX = width / 2
        let centerY = height / 2

        // Partie haute (courbe élégante)
        path.move(to: CGPoint(x: centerX - width * 0.4, y: height * 0.05))
        path.addLine(to: CGPoint(x: centerX + width * 0.4, y: height * 0.05))
        path.addCurve(
            to: CGPoint(x: centerX, y: centerY),
            control1: CGPoint(x: centerX + width * 0.35, y: height * 0.25),
            control2: CGPoint(x: centerX + width * 0.1, y: centerY - height * 0.08)
        )
        path.addCurve(
            to: CGPoint(x: centerX - width * 0.4, y: height * 0.05),
            control1: CGPoint(x: centerX - width * 0.1, y: centerY - height * 0.08),
            control2: CGPoint(x: centerX - width * 0.35, y: height * 0.25)
        )

        // Partie basse (courbe élégante)
        path.move(to: CGPoint(x: centerX, y: centerY))
        path.addCurve(
            to: CGPoint(x: centerX - width * 0.4, y: height * 0.95),
            control1: CGPoint(x: centerX - width * 0.1, y: centerY + height * 0.08),
            control2: CGPoint(x: centerX - width * 0.35, y: height * 0.75)
        )
        path.addLine(to: CGPoint(x: centerX + width * 0.4, y: height * 0.95))
        path.addCurve(
            to: CGPoint(x: centerX, y: centerY),
            control1: CGPoint(x: centerX + width * 0.35, y: height * 0.75),
            control2: CGPoint(x: centerX + width * 0.1, y: centerY + height * 0.08)
        )

        return path
    }
}

// MARK: - Top Half Shape

struct TopHalfShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()

        let width = rect.width
        let height = rect.height
        let centerX = width / 2
        let centerY = height / 2

        path.move(to: CGPoint(x: centerX - width * 0.4, y: height * 0.05))
        path.addLine(to: CGPoint(x: centerX + width * 0.4, y: height * 0.05))
        path.addCurve(
            to: CGPoint(x: centerX, y: centerY),
            control1: CGPoint(x: centerX + width * 0.35, y: height * 0.25),
            control2: CGPoint(x: centerX + width * 0.1, y: centerY - height * 0.08)
        )
        path.addCurve(
            to: CGPoint(x: centerX - width * 0.4, y: height * 0.05),
            control1: CGPoint(x: centerX - width * 0.1, y: centerY - height * 0.08),
            control2: CGPoint(x: centerX - width * 0.35, y: height * 0.25)
        )

        return path
    }
}

// MARK: - Bottom Half Shape

struct BottomHalfShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()

        let width = rect.width
        let height = rect.height
        let centerX = width / 2
        let centerY = height / 2

        path.move(to: CGPoint(x: centerX, y: centerY))
        path.addCurve(
            to: CGPoint(x: centerX - width * 0.4, y: height * 0.95),
            control1: CGPoint(x: centerX - width * 0.1, y: centerY + height * 0.08),
            control2: CGPoint(x: centerX - width * 0.35, y: height * 0.75)
        )
        path.addLine(to: CGPoint(x: centerX + width * 0.4, y: height * 0.95))
        path.addCurve(
            to: CGPoint(x: centerX, y: centerY),
            control1: CGPoint(x: centerX + width * 0.35, y: height * 0.75),
            control2: CGPoint(x: centerX + width * 0.1, y: centerY + height * 0.08)
        )

        return path
    }
}

// MARK: - Preview

#Preview {
    VStack(spacing: 40) {
        BeautifulHourglassView(
            progress: 0.0,
            totalGrains: 10,
            earnedGrains: 0
        )
        .frame(width: 280, height: 350)

        BeautifulHourglassView(
            progress: 0.5,
            totalGrains: 10,
            earnedGrains: 5
        )
        .frame(width: 280, height: 350)

        BeautifulHourglassView(
            progress: 1.0,
            totalGrains: 10,
            earnedGrains: 10
        )
        .frame(width: 280, height: 350)
    }
    .padding()
    .background(Color(uiColor: .systemBackground))
}
