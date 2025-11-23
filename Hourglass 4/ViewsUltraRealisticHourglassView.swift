//
//  UltraRealisticHourglassView.swift
//  Hourglass 4
//
//  Created by Corentin Soula on 13/11/2025.
//

import SwiftUI

/// Sablier ultra-réaliste avec détails photographiques
struct UltraRealisticHourglassView: View {
    let topSandLevel: Double // 0.0 à 1.0
    let bottomSandLevel: Double // 0.0 à 1.0
    
    @State private var sandParticles: [SandParticle] = []
    @State private var isFlowing = true
    
    var body: some View {
        ZStack {
            // Ombre au sol (très diffuse et réaliste)
            GroundShadow()
            
            VStack(spacing: 0) {
                // Capuchon supérieur en bois sculpté
                TopWoodenCap()
                
                // Structure supérieure (colonne + verre)
                TopSection(sandLevel: topSandLevel, isFlowing: $isFlowing, particles: $sandParticles)
                
                // Goulot central avec écoulement
                CentralNeck(isFlowing: $isFlowing, particles: $sandParticles)
                
                // Structure inférieure (verre + colonne)
                BottomSection(sandLevel: bottomSandLevel, particles: $sandParticles)
                
                // Base en bois sculpté
                BottomWoodenCap()
            }
            .rotation3DEffect(
                .degrees(2),
                axis: (x: 0, y: 1, z: 0),
                perspective: 0.5
            )
        }
        .frame(width: 300, height: 500)
        .onAppear {
            initializeSandParticles()
            startSandFlow()
        }
    }
    
    private func initializeSandParticles() {
        // Générer des particules de sable réalistes
        sandParticles = (0..<200).map { _ in
            SandParticle(
                position: CGPoint(
                    x: CGFloat.random(in: -20...20),
                    y: CGFloat.random(in: 0...100)
                ),
                size: CGFloat.random(in: 0.5...2.5),
                color: sandColors.randomElement() ?? .sandBase,
                velocity: CGFloat.random(in: 0.5...2.0)
            )
        }
    }
    
    private func startSandFlow() {
        Timer.scheduledTimer(withTimeInterval: 0.05, repeats: true) { _ in
            if isFlowing && topSandLevel > 0 {
                animateSandParticles()
            }
        }
    }
    
    private func animateSandParticles() {
        for index in sandParticles.indices {
            sandParticles[index].position.y += sandParticles[index].velocity
            
            // Reset particle when it reaches bottom
            if sandParticles[index].position.y > 200 {
                sandParticles[index].position.y = 0
                sandParticles[index].position.x = CGFloat.random(in: -2...2)
            }
        }
    }
}

// MARK: - Ground Shadow

struct GroundShadow: View {
    var body: some View {
        Ellipse()
            .fill(
                RadialGradient(
                    colors: [
                        Color.black.opacity(0.4),
                        Color.black.opacity(0.2),
                        Color.black.opacity(0.05),
                        Color.clear
                    ],
                    center: .center,
                    startRadius: 40,
                    endRadius: 140
                )
            )
            .frame(width: 280, height: 50)
            .offset(y: 260)
            .blur(radius: 8)
    }
}

// MARK: - Wooden Caps

struct TopWoodenCap: View {
    var body: some View {
        ZStack {
            // Base circulaire avec perspective
            WoodenCapShape()
                .fill(
                    LinearGradient(
                        colors: [
                            Color.woodDark,
                            Color.woodMedium,
                            Color.woodLight,
                            Color.woodMedium,
                            Color.woodDark
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: 160, height: 40)
                .shadow(color: .black.opacity(0.6), radius: 8, x: 0, y: 4)
            
            // Anneaux décoratifs
            ForEach(0..<3) { index in
                Circle()
                    .stroke(Color.woodDark.opacity(0.5), lineWidth: 1.5)
                    .frame(width: CGFloat(140 - index * 20), height: CGFloat(12 - index * 2))
                    .offset(y: CGFloat(index * 3 - 3))
            }
            
            // Grain du bois (lignes organiques)
            WoodGrainTexture(density: 15)
                .frame(width: 150, height: 35)
                .clipShape(Ellipse())
                .opacity(0.4)
            
            // Reflet brillant
            Ellipse()
                .fill(
                    RadialGradient(
                        colors: [
                            Color.white.opacity(0.3),
                            Color.clear
                        ],
                        center: .top,
                        startRadius: 10,
                        endRadius: 60
                    )
                )
                .frame(width: 120, height: 15)
                .offset(y: -10)
        }
        .frame(height: 45)
    }
}

struct BottomWoodenCap: View {
    var body: some View {
        ZStack {
            // Base circulaire
            WoodenCapShape()
                .fill(
                    LinearGradient(
                        colors: [
                            Color.woodMedium,
                            Color.woodLight,
                            Color.woodMedium,
                            Color.woodDark
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .frame(width: 160, height: 40)
                .shadow(color: .black.opacity(0.5), radius: 6, x: 0, y: 2)
            
            // Anneaux décoratifs
            ForEach(0..<3) { index in
                Circle()
                    .stroke(Color.woodDark.opacity(0.6), lineWidth: 1.5)
                    .frame(width: CGFloat(140 - index * 20), height: CGFloat(12 - index * 2))
                    .offset(y: CGFloat(index * 3 - 3))
            }
            
            // Texture bois
            WoodGrainTexture(density: 12)
                .frame(width: 150, height: 35)
                .clipShape(Ellipse())
                .opacity(0.5)
        }
        .frame(height: 45)
    }
}

struct WoodenCapShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.addEllipse(in: rect)
        return path
    }
}

// MARK: - Wood Grain Texture

struct WoodGrainTexture: View {
    let density: Int
    
    var body: some View {
        Canvas { context, size in
            for i in 0..<density {
                let y = CGFloat(i) * (size.height / CGFloat(density))
                let startX = CGFloat.random(in: 0...size.width * 0.2)
                let endX = size.width - CGFloat.random(in: 0...size.width * 0.2)
                let controlY = y + CGFloat.random(in: -3...3)
                
                var path = Path()
                path.move(to: CGPoint(x: startX, y: y))
                path.addQuadCurve(
                    to: CGPoint(x: endX, y: y),
                    control: CGPoint(x: size.width / 2, y: controlY)
                )
                
                context.stroke(
                    path,
                    with: .color(Color.woodDark.opacity(0.3)),
                    lineWidth: CGFloat.random(in: 0.5...1.5)
                )
            }
        }
    }
}

// MARK: - Top Section (Bulbe supérieur)

struct TopSection: View {
    let sandLevel: Double
    @Binding var isFlowing: Bool
    @Binding var particles: [SandParticle]
    
    var body: some View {
        ZStack {
            // Structure du verre (forme bulbe)
            TopGlassBulb()
                .stroke(
                    LinearGradient(
                        colors: [
                            Color.white.opacity(0.8),
                            Color.blue.opacity(0.15),
                            Color.white.opacity(0.6),
                            Color.blue.opacity(0.1)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 3
                )
                .shadow(color: .white.opacity(0.5), radius: 2, x: -2, y: -2)
                .shadow(color: .black.opacity(0.3), radius: 4, x: 2, y: 2)
            
            // Remplissage verre transparent
            TopGlassBulb()
                .fill(
                    LinearGradient(
                        colors: [
                            Color.white.opacity(0.08),
                            Color.blue.opacity(0.03),
                            Color.clear
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
            
            // Reflets intenses sur le verre
            TopGlassBulb()
                .stroke(
                    LinearGradient(
                        colors: [
                            Color.white.opacity(0.9),
                            Color.clear
                        ],
                        startPoint: .topLeading,
                        endPoint: .center
                    ),
                    lineWidth: 4
                )
                .blur(radius: 1)
                .offset(x: -10, y: -5)
            
            // Le sable accumulé
            TopSandFill(level: sandLevel)
                .fill(
                    LinearGradient(
                        colors: sandGradient,
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .overlay(
                    // Texture granuleuse du sable
                    Canvas { context, size in
                        for _ in 0..<500 {
                            let x = CGFloat.random(in: 0...size.width)
                            let y = CGFloat.random(in: 0...size.height)
                            let radius = CGFloat.random(in: 0.3...1.2)
                            context.fill(
                                Circle()
                                    .path(in: CGRect(x: x, y: y, width: radius * 2, height: radius * 2)),
                                with: .color(sandColors.randomElement()!.opacity(0.6))
                            )
                        }
                    }
                    .clipShape(TopSandFill(level: sandLevel))
                )
                .shadow(color: Color.sandDark.opacity(0.6), radius: 3, x: 0, y: 2)
            
            // Reflet sur le sable (partie brillante)
            TopSandFill(level: sandLevel)
                .fill(
                    LinearGradient(
                        colors: [
                            Color.white.opacity(0.4),
                            Color.clear
                        ],
                        startPoint: .top,
                        endPoint: .center
                    )
                )
                .frame(height: 30)
                .offset(y: -CGFloat(sandLevel * 80))
        }
        .frame(height: 150)
    }
}

// MARK: - Bottom Section (Bulbe inférieur)

struct BottomSection: View {
    let sandLevel: Double
    @Binding var particles: [SandParticle]
    
    var body: some View {
        ZStack {
            // Structure du verre
            BottomGlassBulb()
                .stroke(
                    LinearGradient(
                        colors: [
                            Color.white.opacity(0.6),
                            Color.blue.opacity(0.1),
                            Color.white.opacity(0.8)
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    ),
                    lineWidth: 3
                )
                .shadow(color: .white.opacity(0.4), radius: 2, x: -2, y: -2)
                .shadow(color: .black.opacity(0.4), radius: 5, x: 2, y: 2)
            
            // Remplissage transparent
            BottomGlassBulb()
                .fill(
                    LinearGradient(
                        colors: [
                            Color.clear,
                            Color.blue.opacity(0.03),
                            Color.white.opacity(0.08)
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
            
            // Reflet sur le verre
            BottomGlassBulb()
                .stroke(
                    LinearGradient(
                        colors: [
                            Color.clear,
                            Color.white.opacity(0.8)
                        ],
                        startPoint: .top,
                        endPoint: .bottomLeading
                    ),
                    lineWidth: 5
                )
                .blur(radius: 1)
                .offset(x: -8, y: 10)
            
            // Le sable accumulé (forme conique)
            BottomSandPile(level: sandLevel)
                .fill(
                    LinearGradient(
                        colors: sandGradient.reversed(),
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .overlay(
                    // Texture du sable
                    Canvas { context, size in
                        for _ in 0..<600 {
                            let x = CGFloat.random(in: 0...size.width)
                            let y = CGFloat.random(in: 0...size.height)
                            let radius = CGFloat.random(in: 0.3...1.5)
                            context.fill(
                                Circle()
                                    .path(in: CGRect(x: x, y: y, width: radius * 2, height: radius * 2)),
                                with: .color(sandColors.randomElement()!.opacity(0.7))
                            )
                        }
                    }
                    .clipShape(BottomSandPile(level: sandLevel))
                )
                .shadow(color: Color.sandDark.opacity(0.7), radius: 4, x: 0, y: -2)
            
            // Reflet brillant sur la surface du sable
            BottomSandPile(level: sandLevel)
                .fill(
                    RadialGradient(
                        colors: [
                            Color.white.opacity(0.5),
                            Color.white.opacity(0.2),
                            Color.clear
                        ],
                        center: .top,
                        startRadius: 0,
                        endRadius: 40
                    )
                )
                .frame(height: 40)
                .offset(y: -CGFloat(sandLevel * 120) + 10)
        }
        .frame(height: 150)
    }
}

// MARK: - Central Neck (Goulot d'étranglement)

struct CentralNeck: View {
    @Binding var isFlowing: Bool
    @Binding var particles: [SandParticle]
    
    var body: some View {
        ZStack {
            // Structure du goulot en verre
            NeckGlassStructure()
                .stroke(
                    LinearGradient(
                        colors: [
                            Color.white.opacity(0.7),
                            Color.blue.opacity(0.2),
                            Color.white.opacity(0.7)
                        ],
                        startPoint: .leading,
                        endPoint: .trailing
                    ),
                    lineWidth: 2.5
                )
                .shadow(color: .white.opacity(0.6), radius: 1, x: -1, y: 0)
            
            NeckGlassStructure()
                .fill(
                    LinearGradient(
                        colors: [
                            Color.white.opacity(0.06),
                            Color.blue.opacity(0.02)
                        ],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
            
            // Filet de sable qui coule (ultra-réaliste)
            if isFlowing {
                ZStack {
                    // Filet principal
                    Rectangle()
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color.sandLight,
                                    Color.sandMedium,
                                    Color.sandBase
                                ],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .frame(width: 4, height: 50)
                        .blur(radius: 0.5)
                    
                    // Particules individuelles qui tombent
                    ForEach(particles.prefix(15).indices, id: \.self) { index in
                        Circle()
                            .fill(particles[index].color)
                            .frame(width: particles[index].size, height: particles[index].size)
                            .offset(
                                x: particles[index].position.x,
                                y: particles[index].position.y
                            )
                            .blur(radius: 0.3)
                    }
                }
            }
        }
        .frame(height: 60)
    }
}

// MARK: - Glass Shapes

struct TopGlassBulb: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        
        let width = rect.width
        let height = rect.height
        
        // Forme bulbeuse pour le haut
        path.move(to: CGPoint(x: width * 0.3, y: 0))
        
        // Courbe gauche
        path.addCurve(
            to: CGPoint(x: width * 0.45, y: height),
            control1: CGPoint(x: width * 0.15, y: height * 0.3),
            control2: CGPoint(x: width * 0.35, y: height * 0.7)
        )
        
        // Ligne du bas (goulot)
        path.addLine(to: CGPoint(x: width * 0.55, y: height))
        
        // Courbe droite
        path.addCurve(
            to: CGPoint(x: width * 0.7, y: 0),
            control1: CGPoint(x: width * 0.65, y: height * 0.7),
            control2: CGPoint(x: width * 0.85, y: height * 0.3)
        )
        
        path.closeSubpath()
        return path
    }
}

struct BottomGlassBulb: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        
        let width = rect.width
        let height = rect.height
        
        // Forme bulbeuse pour le bas (inversée)
        path.move(to: CGPoint(x: width * 0.45, y: 0))
        
        // Courbe gauche
        path.addCurve(
            to: CGPoint(x: width * 0.3, y: height),
            control1: CGPoint(x: width * 0.35, y: height * 0.3),
            control2: CGPoint(x: width * 0.15, y: height * 0.7)
        )
        
        // Ligne du bas
        path.addLine(to: CGPoint(x: width * 0.7, y: height))
        
        // Courbe droite
        path.addCurve(
            to: CGPoint(x: width * 0.55, y: 0),
            control1: CGPoint(x: width * 0.85, y: height * 0.7),
            control2: CGPoint(x: width * 0.65, y: height * 0.3)
        )
        
        path.closeSubpath()
        return path
    }
}

struct NeckGlassStructure: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        
        let width = rect.width
        let height = rect.height
        
        // Forme en sablier pour le goulot
        path.move(to: CGPoint(x: width * 0.42, y: 0))
        path.addLine(to: CGPoint(x: width * 0.48, y: height * 0.4))
        path.addLine(to: CGPoint(x: width * 0.48, y: height * 0.6))
        path.addLine(to: CGPoint(x: width * 0.42, y: height))
        path.addLine(to: CGPoint(x: width * 0.58, y: height))
        path.addLine(to: CGPoint(x: width * 0.52, y: height * 0.6))
        path.addLine(to: CGPoint(x: width * 0.52, y: height * 0.4))
        path.addLine(to: CGPoint(x: width * 0.58, y: 0))
        path.closeSubpath()
        
        return path
    }
}

// MARK: - Sand Shapes

struct TopSandFill: Shape {
    let level: Double
    
    func path(in rect: CGRect) -> Path {
        var path = Path()
        
        let width = rect.width
        let height = rect.height * CGFloat(level)
        let startY = rect.maxY - height
        
        // Forme qui suit le contour du bulbe
        path.move(to: CGPoint(x: width * 0.3, y: rect.maxY))
        path.addLine(to: CGPoint(x: width * 0.45, y: rect.maxY))
        path.addLine(to: CGPoint(x: width * 0.55, y: rect.maxY))
        path.addLine(to: CGPoint(x: width * 0.7, y: rect.maxY))
        
        // Surface ondulée du sable (naturelle)
        let wavePoints = 20
        for i in 0...wavePoints {
            let x = width * 0.7 - (width * 0.4 * CGFloat(i) / CGFloat(wavePoints))
            let waveOffset = sin(CGFloat(i) * 0.5) * 3
            let y = startY + waveOffset
            
            if i == 0 {
                path.move(to: CGPoint(x: x, y: y))
            } else {
                path.addLine(to: CGPoint(x: x, y: y))
            }
        }
        
        path.closeSubpath()
        return path
    }
}

struct BottomSandPile: Shape {
    let level: Double
    
    func path(in rect: CGRect) -> Path {
        var path = Path()
        
        let width = rect.width
        let height = rect.height * CGFloat(level)
        let startY = rect.maxY - height
        
        // Forme conique pour l'accumulation du sable
        path.move(to: CGPoint(x: width * 0.5, y: rect.maxY - height))
        
        // Pente gauche
        path.addCurve(
            to: CGPoint(x: width * 0.3, y: rect.maxY),
            control1: CGPoint(x: width * 0.35, y: rect.maxY - height * 0.6),
            control2: CGPoint(x: width * 0.25, y: rect.maxY - height * 0.2)
        )
        
        // Base
        path.addLine(to: CGPoint(x: width * 0.7, y: rect.maxY))
        
        // Pente droite
        path.addCurve(
            to: CGPoint(x: width * 0.5, y: rect.maxY - height),
            control1: CGPoint(x: width * 0.75, y: rect.maxY - height * 0.2),
            control2: CGPoint(x: width * 0.65, y: rect.maxY - height * 0.6)
        )
        
        path.closeSubpath()
        return path
    }
}

// MARK: - Sand Particle Model

struct SandParticle: Identifiable {
    let id = UUID()
    var position: CGPoint
    let size: CGFloat
    let color: Color
    let velocity: CGFloat
}

// MARK: - Colors

extension Color {
    // Bois
    static let woodDark = Color(red: 0.45, green: 0.3, blue: 0.2)
    static let woodMedium = Color(red: 0.65, green: 0.45, blue: 0.3)
    static let woodLight = Color(red: 0.8, green: 0.6, blue: 0.4)
    
    // Sable (palette photographique)
    static let sandLight = Color(red: 0.98, green: 0.92, blue: 0.78)
    static let sandMedium = Color(red: 0.94, green: 0.86, blue: 0.68)
    static let sandBase = Color(red: 0.89, green: 0.78, blue: 0.58)
    static let sandDark = Color(red: 0.82, green: 0.68, blue: 0.48)
}

let sandColors: [Color] = [
    .sandLight,
    .sandMedium,
    .sandBase,
    .sandDark,
    Color(red: 0.96, green: 0.88, blue: 0.72),
    Color(red: 0.91, green: 0.82, blue: 0.62)
]

let sandGradient: [Color] = [
    .sandLight,
    .sandMedium,
    .sandBase,
    .sandMedium,
    .sandDark
]

// MARK: - Preview

#Preview("Sablier Ultra-Réaliste") {
    ZStack {
        // Fond dégradé doux
        LinearGradient(
            colors: [
                Color(red: 0.96, green: 0.96, blue: 0.98),
                Color(red: 0.92, green: 0.92, blue: 0.95)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .ignoresSafeArea()
        
        VStack(spacing: 50) {
            Text("HOURGLASS")
                .font(.system(size: 36, weight: .thin, design: .serif))
                .foregroundColor(.gray)
                .tracking(8)
            
            UltraRealisticHourglassView(
                topSandLevel: 0.6,
                bottomSandLevel: 0.4
            )
            
            Text("Le temps s'écoule...")
                .font(.system(size: 14, design: .serif))
                .foregroundColor(.gray.opacity(0.6))
                .italic()
        }
    }
}

