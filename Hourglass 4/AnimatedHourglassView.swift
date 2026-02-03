//
//  AnimatedHourglassView.swift
//  Hourglass 4
//
//  Sablier animé avec grains qui tombent
//

import SwiftUI

struct AnimatedHourglassView: View {
    let progress: Double // 0.0 à 1.0 (0% = vide, 100% = plein)
    let totalGrains: Int // Nombre total de grains (ex: 10)
    let earnedGrains: Int // Grains gagnés aujourd'hui

    @State private var isAnimating = false
    @State private var particleOffset: CGFloat = 0
    @State private var rotationAngle: Double = 0

    private let hourglassColor = Color.orange
    private let sandColor = Color(red: 1.0, green: 0.85, blue: 0.4)
    private let glassColor = Color.gray.opacity(0.2)

    var body: some View {
        GeometryReader { geometry in
            let size = min(geometry.size.width, geometry.size.height)

            ZStack {
                // Contour du sablier (verre)
                hourglassShape
                    .stroke(hourglassColor.opacity(0.3), lineWidth: 3)
                    .frame(width: size * 0.8, height: size)

                // Sable dans la partie haute (se vide)
                topSand
                    .frame(width: size * 0.8, height: size)

                // Sable dans la partie basse (se remplit)
                bottomSand
                    .frame(width: size * 0.8, height: size)

                // Particules qui tombent au centre
                fallingParticles
                    .frame(width: size * 0.8, height: size)

                // Stats overlay
                VStack(spacing: 8) {
                    Spacer()

                    Text("\(earnedGrains)")
                        .font(.system(size: size * 0.25, weight: .black))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [hourglassColor, sandColor],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )

                    Text("/ \(totalGrains) grains")
                        .font(.system(size: size * 0.08, weight: .semibold))
                        .foregroundColor(.secondary)

                    Spacer()
                }
                .frame(width: size * 0.8, height: size)
            }
            .frame(width: geometry.size.width, height: geometry.size.height)
        }
        .onAppear {
            startAnimations()
        }
    }

    // MARK: - Hourglass Shape

    private var hourglassShape: some Shape {
        HourglassShape()
    }

    // MARK: - Top Sand (partie haute qui se vide)

    private var topSand: some View {
        HourglassShape()
            .fill(sandColor.opacity(0.8))
            .mask(
                Rectangle()
                    .frame(height: 1000)
                    .offset(y: -500 + (500 * progress))
            )
            .clipShape(HourglassTopHalf())
    }

    // MARK: - Bottom Sand (partie basse qui se remplit)

    private var bottomSand: some View {
        HourglassShape()
            .fill(sandColor)
            .mask(
                Rectangle()
                    .frame(height: 1000)
                    .offset(y: 500 - (500 * progress))
            )
            .clipShape(HourglassBottomHalf())
    }

    // MARK: - Falling Particles (grains qui tombent)

    private var fallingParticles: some View {
        ZStack {
            ForEach(0..<5, id: \.self) { index in
                Circle()
                    .fill(sandColor)
                    .frame(width: 3, height: 3)
                    .offset(y: particleOffset + CGFloat(index * 20))
                    .opacity(isAnimating ? 0.8 : 0)
            }
        }
        .offset(y: -50)
    }

    // MARK: - Animations

    private func startAnimations() {
        // Animation des particules qui tombent
        withAnimation(
            Animation.linear(duration: 1.5)
                .repeatForever(autoreverses: false)
        ) {
            particleOffset = 100
            isAnimating = true
        }

        // Rotation subtile du sablier (effet vivant)
        withAnimation(
            Animation.easeInOut(duration: 3)
                .repeatForever(autoreverses: true)
        ) {
            rotationAngle = 2
        }
    }
}

// MARK: - Hourglass Shape (forme complète)

struct HourglassShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()

        let width = rect.width
        let height = rect.height
        let centerX = width / 2
        let centerY = height / 2

        // Partie haute (triangle inversé)
        path.move(to: CGPoint(x: centerX - width * 0.35, y: height * 0.1))
        path.addLine(to: CGPoint(x: centerX + width * 0.35, y: height * 0.1))
        path.addLine(to: CGPoint(x: centerX, y: centerY))
        path.closeSubpath()

        // Partie basse (triangle normal)
        path.move(to: CGPoint(x: centerX, y: centerY))
        path.addLine(to: CGPoint(x: centerX - width * 0.35, y: height * 0.9))
        path.addLine(to: CGPoint(x: centerX + width * 0.35, y: height * 0.9))
        path.closeSubpath()

        return path
    }
}

// MARK: - Top Half (moitié haute pour masking)

struct HourglassTopHalf: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()

        let width = rect.width
        let height = rect.height
        let centerX = width / 2
        let centerY = height / 2

        path.move(to: CGPoint(x: centerX - width * 0.35, y: height * 0.1))
        path.addLine(to: CGPoint(x: centerX + width * 0.35, y: height * 0.1))
        path.addLine(to: CGPoint(x: centerX, y: centerY))
        path.closeSubpath()

        return path
    }
}

// MARK: - Bottom Half (moitié basse pour masking)

struct HourglassBottomHalf: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()

        let width = rect.width
        let height = rect.height
        let centerX = width / 2
        let centerY = height / 2

        path.move(to: CGPoint(x: centerX, y: centerY))
        path.addLine(to: CGPoint(x: centerX - width * 0.35, y: height * 0.9))
        path.addLine(to: CGPoint(x: centerX + width * 0.35, y: height * 0.9))
        path.closeSubpath()

        return path
    }
}

// MARK: - Preview

#Preview {
    VStack(spacing: 40) {
        // Sablier vide
        AnimatedHourglassView(progress: 0.0, totalGrains: 10, earnedGrains: 0)
            .frame(width: 200, height: 300)

        // Sablier à moitié
        AnimatedHourglassView(progress: 0.5, totalGrains: 10, earnedGrains: 5)
            .frame(width: 200, height: 300)

        // Sablier plein
        AnimatedHourglassView(progress: 1.0, totalGrains: 10, earnedGrains: 10)
            .frame(width: 200, height: 300)
    }
    .padding()
}
