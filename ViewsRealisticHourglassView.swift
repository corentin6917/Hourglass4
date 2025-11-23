//
//  RealisticHourglassView.swift
//  Hourglass 4
//
//  Created by Corentin Soula on 13/11/2025.
//

import SwiftUI

struct RealisticHourglassView: View {
    let topGrains: Double // 0 à 1
    let bottomGrains: Double // 0 à 1
    
    @State private var particlePositions: [SandParticle] = []
    @State private var flowAnimation: Double = 0
    @State private var glassShine: Double = 0
    
    var body: some View {
        ZStack {
            // Ombre portée réaliste
            ShadowView()
                .offset(y: 200)
            
            VStack(spacing: 0) {
                // Base supérieure en bois sculpté
                WoodenBaseTop()
                
                // Verre supérieur avec sable
                TopGlassSection(
                    fillLevel: topGrains,
                    particles: $particlePositions
                )
                
                // Centre : connexion et flux de sable
                CenterNeck(flowAnimation: $flowAnimation)
                
                // Verre inférieur avec sable accumulé
                BottomGlassSection(
                    fillLevel: bottomGrains,
                    particles: $particlePositions
                )
                
                // Base inférieure en bois sculpté
                WoodenBaseBottom()
            }
            
            // Brillance sur le verre (animation)
            GlassShineOverlay(glassShine: $glassShine)
        }
        .frame(width: 220, height: 450)
        .onAppear {
            startAnimations()
            generateParticles()
        }
    }
    
    private func startAnimations() {
        // Animation du flux de sable
        withAnimation(.linear(duration: 3).repeatForever(autoreverses: false)) {
            flowAnimation = 1
        }
        
        // Animation de la brillance du verre
        withAnimation(.easeInOut(duration: 4).repeatForever(autoreverses: true)) {
            glassShine = 1
        }
    }
    
    private func generateParticles() {
        particlePositions = (0..<100).map { _ in
            SandParticle(
                x: Double.random(in: -40...40),
                y: Double.random(in: -80...80),
                size: Double.random(in: 1...2.5),
                opacity: Double.random(in: 0.6...1.0)
            )
        }
    }
}

// MARK: - Shadow View

struct ShadowView: View {
    var body: some View {
        Canvas { context, size in
            // Ombre douce et réaliste
            let shadow = Ellipse().path(in: CGRect(x: 0, y: 0, width: size.width, height: 60))
            
            context.fill(
                shadow,
                with: .radialGradient(
                    Gradient(colors: [
                        Color.black.opacity(0.4),
                        Color.black.opacity(0.2),
                        Color.black.opacity(0.05),
                        Color.clear
                    ]),
                    center: CGPoint(x: size.width/2, y: 30),
                    startRadius: 20,
                    endRadius: size.width/2
                )
            )
        }
        .frame(width: 200, height: 60)
        .blur(radius: 8)
    }
}

// MARK: - Wooden Base Top

struct WoodenBaseTop: View {
    var body: some View {
        ZStack {
            // Base principale en bois
            Canvas { context, size in
                // Forme elliptique avec perspective
                let basePath = Ellipse().path(in: CGRect(x: 0, y: 5, width: size.width, height: 40))
                
                // Gradient bois réaliste
                let woodGradient = LinearGradient(
                    gradient: Gradient(colors: [
                        Color(red: 0.45, green: 0.3, blue: 0.2),
                        Color(red: 0.6, green: 0.4, blue: 0.25),
                        Color(red: 0.55, green: 0.35, blue: 0.22),
                        Color(red: 0.65, green: 0.45, blue: 0.3)
                    ]),
                    startPoint: .leading,
                    endPoint: .trailing
                )
                
                context.fill(basePath, with: .linearGradient(woodGradient, startPoint: .leading, endPoint: .trailing))
                
                // Veines du bois
                for i in 0..<12 {
                    let veinPath = Path { path in
                        let startX = CGFloat.random(in: 20...size.width-20)
                        let startY = CGFloat(20 + i * 3)
                        let endX = startX + CGFloat.random(in: -15...15)
                        let endY = startY + 2
                        
                        path.move(to: CGPoint(x: startX, y: startY))
                        path.addCurve(
                            to: CGPoint(x: endX, y: endY),
                            control1: CGPoint(x: startX + 5, y: startY),
                            control2: CGPoint(x: endX - 5, y: endY)
                        )
                    }
                    
                    context.stroke(veinPath, with: .color(Color(red: 0.4, green: 0.25, blue: 0.15).opacity(0.4)), lineWidth: 1.5)
                }
                
                // Reflet sur le dessus
                let highlightPath = Ellipse().path(in: CGRect(x: 20, y: 8, width: size.width-40, height: 12))
                context.fill(highlightPath, with: .color(Color.white.opacity(0.15)))
            }
            .frame(width: 150, height: 45)
            .shadow(color: .black.opacity(0.4), radius: 6, x: 0, y: 4)
            
            // Anneau métallique supérieur
            Circle()
                .trim(from: 0.0, to: 0.5)
                .stroke(
                    LinearGradient(
                        colors: [
                            Color(white: 0.6),
                            Color(white: 0.8),
                            Color(white: 0.7)
                        ],
                        startPoint: .leading,
                        endPoint: .trailing
                    ),
                    lineWidth: 3
                )
                .frame(width: 130, height: 130)
                .offset(y: -8)
        }
        .frame(height: 45)
    }
}

// MARK: - Wooden Base Bottom

struct WoodenBaseBottom: View {
    var body: some View {
        ZStack {
            Canvas { context, size in
                let basePath = Ellipse().path(in: CGRect(x: 0, y: 0, width: size.width, height: 35))
                
                let woodGradient = LinearGradient(
                    gradient: Gradient(colors: [
                        Color(red: 0.5, green: 0.32, blue: 0.22),
                        Color(red: 0.65, green: 0.45, blue: 0.3),
                        Color(red: 0.6, green: 0.4, blue: 0.25)
                    ]),
                    startPoint: .leading,
                    endPoint: .trailing
                )
                
                context.fill(basePath, with: .linearGradient(woodGradient, startPoint: .leading, endPoint: .trailing))
                
                // Veines du bois
                for i in 0..<10 {
                    let veinPath = Path { path in
                        let y = CGFloat(i * 3)
                        path.move(to: CGPoint(x: 20, y: y))
                        path.addQuadCurve(
                            to: CGPoint(x: size.width - 20, y: y + 1),
                            control: CGPoint(x: size.width/2, y: y - 2)
                        )
                    }
                    context.stroke(veinPath, with: .color(Color(red: 0.35, green: 0.2, blue: 0.12).opacity(0.3)), lineWidth: 1)
                }
            }
            .frame(width: 150, height: 35)
            .shadow(color: .black.opacity(0.3), radius: 5, x: 0, y: 3)
        }
        .frame(height: 40)
    }
}

// MARK: - Top Glass Section

struct TopGlassSection: View {
    let fillLevel: Double
    @Binding var particles: [SandParticle]
    
    var body: some View {
        ZStack {
            // Structure de verre avec profondeur
            Canvas { context, size in
                // Verre externe (contour)
                let outerGlass = ConePath(isInverted: true).path(in: CGRect(origin: .zero, size: size))
                
                // Fond du verre (légèrement plus petit pour créer l'épaisseur)
                let innerGlass = ConePath(isInverted: true, inset: 4).path(in: CGRect(origin: .zero, size: size))
                
                // Remplir le verre avec transparence
                context.fill(innerGlass, with: .color(Color.white.opacity(0.05)))
                
                // Contour brillant
                context.stroke(outerGlass, with: .linearGradient(
                    Gradient(colors: [
                        Color.white.opacity(0.6),
                        Color.cyan.opacity(0.3),
                        Color.white.opacity(0.4)
                    ]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ), lineWidth: 2.5)
                
                // Reflets internes
                let highlight1 = Path { path in
                    path.move(to: CGPoint(x: size.width * 0.25, y: 10))
                    path.addLine(to: CGPoint(x: size.width * 0.3, y: size.height - 20))
                }
                context.stroke(highlight1, with: .color(Color.white.opacity(0.4)), lineWidth: 2)
                
                let highlight2 = Path { path in
                    path.move(to: CGPoint(x: size.width * 0.75, y: 10))
                    path.addLine(to: CGPoint(x: size.width * 0.7, y: size.height - 20))
                }
                context.stroke(highlight2, with: .color(Color.white.opacity(0.3)), lineWidth: 1.5)
            }
            .frame(width: 180, height: 140)
            
            // Sable dans la partie haute
            SandInTopGlass(fillLevel: fillLevel, particles: particles)
        }
        .frame(height: 140)
    }
}

// MARK: - Bottom Glass Section

struct BottomGlassSection: View {
    let fillLevel: Double
    @Binding var particles: [SandParticle]
    
    var body: some View {
        ZStack {
            Canvas { context, size in
                let outerGlass = ConePath(isInverted: false).path(in: CGRect(origin: .zero, size: size))
                let innerGlass = ConePath(isInverted: false, inset: 4).path(in: CGRect(origin: .zero, size: size))
                
                context.fill(innerGlass, with: .color(Color.white.opacity(0.05)))
                
                context.stroke(outerGlass, with: .linearGradient(
                    Gradient(colors: [
                        Color.white.opacity(0.4),
                        Color.cyan.opacity(0.3),
                        Color.white.opacity(0.6)
                    ]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ), lineWidth: 2.5)
                
                // Reflets
                let highlight = Path { path in
                    path.move(to: CGPoint(x: size.width * 0.7, y: 20))
                    path.addLine(to: CGPoint(x: size.width * 0.75, y: size.height - 10))
                }
                context.stroke(highlight, with: .color(Color.white.opacity(0.5)), lineWidth: 2)
            }
            .frame(width: 180, height: 140)
            
            // Sable accumulé en bas
            SandInBottomGlass(fillLevel: fillLevel, particles: particles)
        }
        .frame(height: 140)
    }
}

// MARK: - Center Neck

struct CenterNeck: View {
    @Binding var flowAnimation: Double
    
    var body: some View {
        ZStack {
            // Structure du goulot
            Canvas { context, size in
                let neckPath = Path { path in
                    // Forme de sablier au centre
                    path.move(to: CGPoint(x: size.width * 0.35, y: 0))
                    path.addCurve(
                        to: CGPoint(x: size.width * 0.5, y: size.height * 0.5),
                        control1: CGPoint(x: size.width * 0.4, y: size.height * 0.2),
                        control2: CGPoint(x: size.width * 0.45, y: size.height * 0.4)
                    )
                    path.addCurve(
                        to: CGPoint(x: size.width * 0.35, y: size.height),
                        control1: CGPoint(x: size.width * 0.45, y: size.height * 0.6),
                        control2: CGPoint(x: size.width * 0.4, y: size.height * 0.8)
                    )
                    
                    path.addLine(to: CGPoint(x: size.width * 0.65, y: size.height))
                    
                    path.addCurve(
                        to: CGPoint(x: size.width * 0.5, y: size.height * 0.5),
                        control1: CGPoint(x: size.width * 0.6, y: size.height * 0.8),
                        control2: CGPoint(x: size.width * 0.55, y: size.height * 0.6)
                    )
                    path.addCurve(
                        to: CGPoint(x: size.width * 0.65, y: 0),
                        control1: CGPoint(x: size.width * 0.55, y: size.height * 0.4),
                        control2: CGPoint(x: size.width * 0.6, y: size.height * 0.2)
                    )
                    path.closeSubpath()
                }
                
                context.fill(neckPath, with: .color(Color.white.opacity(0.08)))
                context.stroke(neckPath, with: .color(Color.white.opacity(0.5)), lineWidth: 1.5)
            }
            .frame(width: 180, height: 50)
            
            // Flux de sable animé
            SandFlowAnimation(flowAnimation: flowAnimation)
        }
        .frame(height: 50)
    }
}

// MARK: - Sand Flow Animation

struct SandFlowAnimation: View {
    let flowAnimation: Double
    
    var body: some View {
        Canvas { context, size in
            // Filet de sable principal
            for i in 0..<5 {
                let offset = (flowAnimation + Double(i) * 0.2).truncatingRemainder(dividingBy: 1.0)
                let y = size.height * CGFloat(offset)
                
                let sandStream = Path { path in
                    path.move(to: CGPoint(x: size.width/2 - 1, y: y))
                    path.addLine(to: CGPoint(x: size.width/2 + 1, y: y + 10))
                }
                
                let sandColor = Color(
                    red: 0.9 - Double(i) * 0.05,
                    green: 0.75 - Double(i) * 0.05,
                    blue: 0.5 - Double(i) * 0.05
                )
                
                context.stroke(sandStream, with: .color(sandColor.opacity(0.8)), lineWidth: 2)
            }
            
            // Particules qui tombent
            for i in 0..<15 {
                let offset = (flowAnimation * 1.5 + Double(i) * 0.07).truncatingRemainder(dividingBy: 1.0)
                let y = size.height * CGFloat(offset)
                let x = size.width/2 + CGFloat.random(in: -2...2)
                
                let particle = Circle().path(in: CGRect(x: x, y: y, width: 1.5, height: 1.5))
                context.fill(particle, with: .color(Color(red: 0.95, green: 0.8, blue: 0.6).opacity(0.7)))
            }
        }
        .frame(width: 10, height: 50)
    }
}

// MARK: - Sand in Top Glass

struct SandInTopGlass: View {
    let fillLevel: Double
    let particles: [SandParticle]
    
    var body: some View {
        Canvas { context, size in
            guard fillLevel > 0 else { return }
            
            // Forme du sable (pyramide inversée)
            let sandHeight = size.height * CGFloat(fillLevel)
            let topWidth: CGFloat = 120
            let bottomWidth: CGFloat = 20
            
            let sandPath = Path { path in
                let startY = size.height - sandHeight
                path.move(to: CGPoint(x: size.width/2 - topWidth/2, y: startY))
                path.addLine(to: CGPoint(x: size.width/2 - bottomWidth/2, y: size.height))
                path.addLine(to: CGPoint(x: size.width/2 + bottomWidth/2, y: size.height))
                path.addLine(to: CGPoint(x: size.width/2 + topWidth/2, y: startY))
                path.closeSubpath()
            }
            
            // Gradient du sable
            let sandGradient = LinearGradient(
                gradient: Gradient(colors: [
                    Color(red: 0.98, green: 0.88, blue: 0.7),
                    Color(red: 0.92, green: 0.78, blue: 0.55),
                    Color(red: 0.88, green: 0.72, blue: 0.48)
                ]),
                startPoint: .top,
                endPoint: .bottom
            )
            
            context.fill(sandPath, with: .linearGradient(sandGradient, startPoint: .top, endPoint: .bottom))
            
            // Particules individuelles
            for particle in particles.prefix(Int(fillLevel * 60)) {
                let adjustedY = size.height - sandHeight + CGFloat(particle.y)
                if adjustedY > size.height - sandHeight && adjustedY < size.height {
                    let particlePath = Circle().path(in: CGRect(
                        x: size.width/2 + CGFloat(particle.x),
                        y: adjustedY,
                        width: CGFloat(particle.size),
                        height: CGFloat(particle.size)
                    ))
                    
                    context.fill(particlePath, with: .color(
                        Color(red: 0.95, green: 0.82, blue: 0.62).opacity(particle.opacity)
                    ))
                }
            }
            
            // Surface du sable (ligne plus claire)
            let surfaceLine = Path { path in
                path.move(to: CGPoint(x: size.width/2 - topWidth/2 * CGFloat(fillLevel), y: size.height - sandHeight))
                path.addLine(to: CGPoint(x: size.width/2 + topWidth/2 * CGFloat(fillLevel), y: size.height - sandHeight))
            }
            context.stroke(surfaceLine, with: .color(Color.white.opacity(0.3)), lineWidth: 1)
        }
        .frame(width: 180, height: 140)
    }
}

// MARK: - Sand in Bottom Glass

struct SandInBottomGlass: View {
    let fillLevel: Double
    let particles: [SandParticle]
    
    var body: some View {
        Canvas { context, size in
            guard fillLevel > 0 else { return }
            
            // Pile de sable conique
            let sandHeight = size.height * CGFloat(fillLevel) * 0.8
            let baseWidth: CGFloat = 120
            
            let sandPath = Path { path in
                path.move(to: CGPoint(x: size.width/2, y: size.height - sandHeight - 20))
                path.addLine(to: CGPoint(x: size.width/2 - baseWidth/2, y: size.height))
                path.addLine(to: CGPoint(x: size.width/2 + baseWidth/2, y: size.height))
                path.closeSubpath()
            }
            
            // Gradient du sable accumulé
            let sandGradient = LinearGradient(
                gradient: Gradient(colors: [
                    Color(red: 0.88, green: 0.72, blue: 0.48),
                    Color(red: 0.92, green: 0.78, blue: 0.55),
                    Color(red: 0.96, green: 0.85, blue: 0.65)
                ]),
                startPoint: .top,
                endPoint: .bottom
            )
            
            context.fill(sandPath, with: .linearGradient(sandGradient, startPoint: .top, endPoint: .bottom))
            
            // Particules
            for particle in particles.prefix(Int(fillLevel * 60)) {
                let adjustedY = size.height - sandHeight + CGFloat(particle.y) * 0.5
                if adjustedY < size.height && adjustedY > size.height - sandHeight {
                    let particlePath = Circle().path(in: CGRect(
                        x: size.width/2 + CGFloat(particle.x) * 0.8,
                        y: adjustedY,
                        width: CGFloat(particle.size),
                        height: CGFloat(particle.size)
                    ))
                    
                    context.fill(particlePath, with: .color(
                        Color(red: 0.9, green: 0.75, blue: 0.55).opacity(particle.opacity)
                    ))
                }
            }
            
            // Reflet sur le sommet du tas
            let highlight = Ellipse().path(in: CGRect(
                x: size.width/2 - 30,
                y: size.height - sandHeight - 25,
                width: 60,
                height: 8
            ))
            context.fill(highlight, with: .color(Color.white.opacity(0.2)))
        }
        .frame(width: 180, height: 140)
    }
}

// MARK: - Glass Shine Overlay

struct GlassShineOverlay: View {
    @Binding var glassShine: Double
    
    var body: some View {
        Canvas { context, size in
            // Brillance qui se déplace sur le verre
            let shineX = size.width * CGFloat(glassShine) - 50
            
            let shinePath = Path { path in
                path.move(to: CGPoint(x: shineX, y: 50))
                path.addLine(to: CGPoint(x: shineX + 30, y: 50))
                path.addLine(to: CGPoint(x: shineX + 40, y: size.height - 50))
                path.addLine(to: CGPoint(x: shineX + 10, y: size.height - 50))
                path.closeSubpath()
            }
            
            context.fill(shinePath, with: .linearGradient(
                Gradient(colors: [
                    Color.white.opacity(0),
                    Color.white.opacity(0.4),
                    Color.white.opacity(0)
                ]),
                startPoint: .leading,
                endPoint: .trailing
            ))
        }
        .frame(width: 220, height: 450)
        .allowsHitTesting(false)
        .blur(radius: 3)
    }
}

// MARK: - Cone Path

struct ConePath: Shape {
    let isInverted: Bool
    var inset: CGFloat = 0
    
    func path(in rect: CGRect) -> Path {
        var path = Path()
        
        let adjustedRect = rect.insetBy(dx: inset, dy: inset)
        
        if isInverted {
            // Cone pointant vers le bas
            path.move(to: CGPoint(x: adjustedRect.minX, y: adjustedRect.minY))
            path.addLine(to: CGPoint(x: adjustedRect.midX, y: adjustedRect.maxY))
            path.addLine(to: CGPoint(x: adjustedRect.maxX, y: adjustedRect.minY))
            path.closeSubpath()
        } else {
            // Cone pointant vers le haut
            path.move(to: CGPoint(x: adjustedRect.midX, y: adjustedRect.minY))
            path.addLine(to: CGPoint(x: adjustedRect.minX, y: adjustedRect.maxY))
            path.addLine(to: CGPoint(x: adjustedRect.maxX, y: adjustedRect.maxY))
            path.closeSubpath()
        }
        
        return path
    }
}

// MARK: - Sand Particle

struct SandParticle: Identifiable {
    let id = UUID()
    let x: Double
    let y: Double
    let size: Double
    let opacity: Double
}

// MARK: - Preview

#Preview {
    ZStack {
        LinearGradient(
            colors: [
                Color(red: 0.95, green: 0.95, blue: 0.98),
                Color(red: 0.92, green: 0.92, blue: 0.95)
            ],
            startPoint: .top,
            endPoint: .bottom
        )
        .ignoresSafeArea()
        
        VStack(spacing: 40) {
            Text("⏳ Sablier Ultra-Réaliste")
                .font(.system(size: 32, weight: .bold, design: .rounded))
                .foregroundStyle(.primary)
            
            RealisticHourglassView(topGrains: 0.6, bottomGrains: 0.4)
                .shadow(color: .black.opacity(0.15), radius: 20, x: 0, y: 10)
        }
    }
}
