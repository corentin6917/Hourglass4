//
//  RealisticHourglassView.swift
//  Hourglass 4
//
//  Created by Corentin Soula on 13/11/2025.
//

import SwiftUI

struct RealisticHourglassView: View {
    let topGrains: Double // Grains dans la partie haute (0 à 1)
    let bottomGrains: Double // Grains dans la partie basse (0 à 1)
    
    @State private var isAnimating = false
    @State private var sandFlowOffset: CGFloat = 0
    
    var body: some View {
        ZStack {
            // Ombre portée du sablier
            Ellipse()
                .fill(
                    RadialGradient(
                        colors: [
                            Color.black.opacity(0.3),
                            Color.black.opacity(0.1),
                            Color.clear
                        ],
                        center: .center,
                        startRadius: 50,
                        endRadius: 120
                    )
                )
                .frame(width: 240, height: 40)
                .offset(y: 180)
            
            VStack(spacing: 0) {
                // Base supérieure en bois
                WoodenBase(isTop: true)
                
                // Partie haute du sablier (verre + sable)
                TopGlassSection(fillPercentage: topGrains, isAnimating: $isAnimating)
                
                // Connexion centrale (goulot)
                NeckSection(sandFlowOffset: $sandFlowOffset, isAnimating: $isAnimating)
                
                // Partie basse du sablier (verre + sable)
                BottomGlassSection(fillPercentage: bottomGrains)
                
                // Base inférieure en bois
                WoodenBase(isTop: false)
            }
        }
        .frame(width: 200, height: 400)
        .onAppear {
            startAnimation()
        }
    }
    
    private func startAnimation() {
        withAnimation(.linear(duration: 2).repeatForever(autoreverses: false)) {
            sandFlowOffset = 100
        }
        
        withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true)) {
            isAnimating = true
        }
    }
}

// MARK: - Wooden Base

struct WoodenBase: View {
    let isTop: Bool
    
    var body: some View {
        ZStack {
            // Base principale
            Ellipse()
                .fill(
                    LinearGradient(
                        colors: [
                            Color(red: 0.7, green: 0.5, blue: 0.3),
                            Color(red: 0.6, green: 0.4, blue: 0.25),
                            Color(red: 0.7, green: 0.5, blue: 0.3)
                        ],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .frame(width: 140, height: 30)
                .shadow(color: .black.opacity(0.3), radius: 5, y: 3)
            
            // Texture bois (lignes)
            ForEach(0..<8, id: \.self) { index in
                Capsule()
                    .fill(Color(red: 0.5, green: 0.35, blue: 0.2).opacity(0.3))
                    .frame(width: CGFloat.random(in: 60...100), height: 2)
                    .offset(x: CGFloat.random(in: -20...20), y: CGFloat(index - 4) * 3)
            }
            
            // Reflet supérieur
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
                .frame(width: 120, height: 8)
                .offset(y: isTop ? -8 : -10)
        }
        .frame(height: 35)
    }
}

// MARK: - Top Glass Section

struct TopGlassSection: View {
    let fillPercentage: Double
    @Binding var isAnimating: Bool
    
    var body: some View {
        ZStack {
            // Contour du verre
            GlassShape(isTop: true)
                .stroke(
                    LinearGradient(
                        colors: [
                            Color.white.opacity(0.6),
                            Color.blue.opacity(0.2),
                            Color.white.opacity(0.4)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 2
                )
            
            // Verre transparent avec reflets
            GlassShape(isTop: true)
                .fill(
                    LinearGradient(
                        colors: [
                            Color.white.opacity(0.1),
                            Color.blue.opacity(0.05),
                            Color.white.opacity(0.15)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
            
            // Sable dans la partie haute
            SandFill(percentage: fillPercentage, isTop: true, isAnimating: $isAnimating)
        }
        .frame(height: 120)
    }
}

// MARK: - Bottom Glass Section

struct BottomGlassSection: View {
    let fillPercentage: Double
    
    var body: some View {
        ZStack {
            // Contour du verre
            GlassShape(isTop: false)
                .stroke(
                    LinearGradient(
                        colors: [
                            Color.white.opacity(0.4),
                            Color.blue.opacity(0.2),
                            Color.white.opacity(0.6)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 2
                )
            
            // Verre transparent
            GlassShape(isTop: false)
                .fill(
                    LinearGradient(
                        colors: [
                            Color.white.opacity(0.15),
                            Color.blue.opacity(0.05),
                            Color.white.opacity(0.1)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
            
            // Sable accumulé en bas
            SandFill(percentage: fillPercentage, isTop: false, isAnimating: .constant(false))
        }
        .frame(height: 120)
    }
}

// MARK: - Neck Section (Goulot)

struct NeckSection: View {
    @Binding var sandFlowOffset: CGFloat
    @Binding var isAnimating: Bool
    
    var body: some View {
        ZStack {
            // Structure du goulot en verre
            Path { path in
                path.move(to: CGPoint(x: 70, y: 0))
                path.addLine(to: CGPoint(x: 100, y: 15))
                path.addLine(to: CGPoint(x: 100, y: 25))
                path.addLine(to: CGPoint(x: 70, y: 40))
                path.addLine(to: CGPoint(x: 130, y: 40))
                path.addLine(to: CGPoint(x: 100, y: 25))
                path.addLine(to: CGPoint(x: 100, y: 15))
                path.addLine(to: CGPoint(x: 130, y: 0))
            }
            .fill(
                LinearGradient(
                    colors: [
                        Color.white.opacity(0.2),
                        Color.blue.opacity(0.1)
                    ],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            
            // Filet de sable qui coule
            if isAnimating {
                Rectangle()
                    .fill(
                        LinearGradient(
                            colors: [
                                Color(red: 0.9, green: 0.8, blue: 0.6),
                                Color(red: 0.85, green: 0.7, blue: 0.5)
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .frame(width: 3, height: 40)
                    .offset(x: 0, y: sandFlowOffset.truncatingRemainder(dividingBy: 40))
                    .opacity(0.8)
            }
        }
        .frame(height: 40)
    }
}

// MARK: - Glass Shape

struct GlassShape: Shape {
    let isTop: Bool
    
    func path(in rect: CGRect) -> Path {
        var path = Path()
        
        if isTop {
            // Forme conique inversée (partie haute)
            path.move(to: CGPoint(x: rect.midX - 60, y: rect.minY))
            path.addLine(to: CGPoint(x: rect.midX - 20, y: rect.maxY))
            path.addLine(to: CGPoint(x: rect.midX + 20, y: rect.maxY))
            path.addLine(to: CGPoint(x: rect.midX + 60, y: rect.minY))
            path.closeSubpath()
        } else {
            // Forme conique normale (partie basse)
            path.move(to: CGPoint(x: rect.midX - 20, y: rect.minY))
            path.addLine(to: CGPoint(x: rect.midX - 60, y: rect.maxY))
            path.addLine(to: CGPoint(x: rect.midX + 60, y: rect.maxY))
            path.addLine(to: CGPoint(x: rect.midX + 20, y: rect.minY))
            path.closeSubpath()
        }
        
        return path
    }
}

// MARK: - Sand Fill

struct SandFill: View {
    let percentage: Double
    let isTop: Bool
    @Binding var isAnimating: Bool
    
    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: isTop ? .bottom : .bottom) {
                // Forme du sable
                if isTop {
                    TopSandShape(percentage: percentage)
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color(red: 0.95, green: 0.85, blue: 0.65),
                                    Color(red: 0.9, green: 0.75, blue: 0.5),
                                    Color(red: 0.85, green: 0.7, blue: 0.45)
                                ],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .overlay(
                            // Texture granuleuse
                            TopSandShape(percentage: percentage)
                                .fill(
                                    RadialGradient(
                                        colors: [
                                            Color.white.opacity(0.3),
                                            Color.clear
                                        ],
                                        center: .center,
                                        startRadius: 0,
                                        endRadius: 60
                                    )
                                )
                        )
                } else {
                    BottomSandShape(percentage: percentage)
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color(red: 0.85, green: 0.7, blue: 0.45),
                                    Color(red: 0.9, green: 0.75, blue: 0.5),
                                    Color(red: 0.95, green: 0.85, blue: 0.65)
                                ],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .overlay(
                            // Reflet sur le sable du bas
                            BottomSandShape(percentage: percentage)
                                .fill(
                                    LinearGradient(
                                        colors: [
                                            Color.white.opacity(0.2),
                                            Color.clear
                                        ],
                                        startPoint: .top,
                                        endPoint: .bottom
                                    )
                                )
                                .frame(height: 20)
                                .offset(y: -CGFloat(percentage * 100))
                        )
                }
                
                // Particules de sable (effet réaliste)
                ForEach(0..<20, id: \.self) { index in
                    Circle()
                        .fill(Color(red: 0.9, green: 0.8, blue: 0.6).opacity(0.6))
                        .frame(width: CGFloat.random(in: 1...3))
                        .offset(
                            x: CGFloat.random(in: -30...30),
                            y: isTop ? -CGFloat(percentage * 100) : CGFloat.random(in: 0...20)
                        )
                }
            }
        }
    }
}

// MARK: - Sand Shapes

struct TopSandShape: Shape {
    let percentage: Double
    
    func path(in rect: CGRect) -> Path {
        var path = Path()
        
        let sandHeight = rect.height * CGFloat(percentage)
        let startY = rect.maxY - sandHeight
        
        // Forme trapézoïdale pour le haut
        let topWidth: CGFloat = 120
        let bottomWidth: CGFloat = 40
        
        let widthAtHeight = topWidth - ((topWidth - bottomWidth) * CGFloat(percentage))
        
        path.move(to: CGPoint(x: rect.midX - widthAtHeight/2, y: startY))
        path.addLine(to: CGPoint(x: rect.midX - 20, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.midX + 20, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.midX + widthAtHeight/2, y: startY))
        path.closeSubpath()
        
        return path
    }
}

struct BottomSandShape: Shape {
    let percentage: Double
    
    func path(in rect: CGRect) -> Path {
        var path = Path()
        
        let sandHeight = rect.height * CGFloat(percentage)
        let startY = rect.maxY - sandHeight
        
        // Forme pyramidale pour le bas
        path.move(to: CGPoint(x: rect.midX, y: rect.minY + 10))
        path.addLine(to: CGPoint(x: rect.midX - 60, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.midX + 60, y: rect.maxY))
        path.closeSubpath()
        
        // Clipper selon le pourcentage
        let clipPath = Path { clip in
            clip.addRect(CGRect(x: 0, y: startY, width: rect.width, height: sandHeight))
        }
        
        return path.intersection(clipPath)
    }
}

// MARK: - Preview

#Preview {
    ZStack {
        LinearGradient(
            colors: [Color(red: 0.95, green: 0.95, blue: 0.97), .white],
            startPoint: .top,
            endPoint: .bottom
        )
        .ignoresSafeArea()
        
        VStack(spacing: 40) {
            Text("Sablier Réaliste")
                .font(.largeTitle)
                .fontWeight(.bold)
            
            // Sablier mi-rempli
            RealisticHourglassView(topGrains: 0.5, bottomGrains: 0.5)
            
            HStack(spacing: 40) {
                VStack {
                    Text("Début")
                        .font(.caption)
                    RealisticHourglassView(topGrains: 0.9, bottomGrains: 0.1)
                        .scaleEffect(0.6)
                }
                
                VStack {
                    Text("Fin")
                        .font(.caption)
                    RealisticHourglassView(topGrains: 0.1, bottomGrains: 0.9)
                        .scaleEffect(0.6)
                }
            }
        }
    }
}
