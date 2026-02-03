//
//  SimpleRealisticHourglass.swift
//  Hourglass 4
//
//  Created by Corentin Soula on 14/11/2025.
//

import SwiftUI

/// Sablier 3D ultra-réaliste
struct SimpleRealisticHourglass: View {
    let topFill: Double // 0 à 1
    let bottomFill: Double // 0 à 1
    
    @State private var sandFlow: CGFloat = 0
    @State private var shine: CGFloat = 0
    
    var body: some View {
        ZStack {
            // Ombre
            Ellipse()
                .fill(
                    RadialGradient(
                        colors: [.black.opacity(0.3), .clear],
                        center: .center,
                        startRadius: 30,
                        endRadius: 100
                    )
                )
                .frame(width: 180, height: 40)
                .offset(y: 210)
                .blur(radius: 10)
            
            VStack(spacing: 0) {
                // Base bois supérieure
                WoodBase()
                
                // Verre supérieur
                GlassTop(fill: topFill)
                
                // Goulot central
                Neck(flow: $sandFlow)
                
                // Verre inférieur
                GlassBottom(fill: bottomFill)
                
                // Base bois inférieure
                WoodBase()
            }
            
            // Brillance animée
            SimpleHourglassShineEffect(offset: $shine)
        }
        .frame(width: 200, height: 420)
        .onAppear {
            withAnimation(.linear(duration: 2).repeatForever(autoreverses: false)) {
                sandFlow = 50
            }
            withAnimation(.easeInOut(duration: 3).repeatForever(autoreverses: true)) {
                shine = 200
            }
        }
    }
}

// MARK: - Wood Base

private struct WoodBase: View {
    var body: some View {
        Ellipse()
            .fill(
                LinearGradient(
                    colors: [
                        Color(red: 0.6, green: 0.4, blue: 0.25),
                        Color(red: 0.7, green: 0.5, blue: 0.3),
                        Color(red: 0.55, green: 0.35, blue: 0.22)
                    ],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .frame(width: 140, height: 35)
            .overlay {
                Ellipse()
                    .fill(
                        LinearGradient(
                            colors: [.white.opacity(0.2), .clear],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .frame(width: 120, height: 10)
                    .offset(y: -10)
            }
            .shadow(color: .black.opacity(0.3), radius: 5, y: 3)
    }
}

// MARK: - Glass Top

private struct GlassTop: View {
    let fill: Double
    
    var body: some View {
        ZStack {
            // Contour verre
            Triangle(inverted: true)
                .stroke(
                    LinearGradient(
                        colors: [.white.opacity(0.6), .cyan.opacity(0.3)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 2
                )
            
            // Verre transparent
            Triangle(inverted: true)
                .fill(.white.opacity(0.08))
            
            // Sable
            if fill > 0 {
                SandShape(fill: fill, isTop: true)
                    .fill(
                        LinearGradient(
                            colors: [
                                Color(red: 0.95, green: 0.85, blue: 0.65),
                                Color(red: 0.88, green: 0.72, blue: 0.48)
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
            }
            
            // Reflets
            Path { path in
                path.move(to: CGPoint(x: 50, y: 10))
                path.addLine(to: CGPoint(x: 60, y: 110))
            }
            .stroke(.white.opacity(0.3), lineWidth: 2)
        }
        .frame(width: 160, height: 120)
    }
}

// MARK: - Glass Bottom

private struct GlassBottom: View {
    let fill: Double
    
    var body: some View {
        ZStack {
            // Contour verre
            Triangle(inverted: false)
                .stroke(
                    LinearGradient(
                        colors: [.cyan.opacity(0.3), .white.opacity(0.6)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 2
                )
            
            // Verre transparent
            Triangle(inverted: false)
                .fill(.white.opacity(0.08))
            
            // Sable accumulé
            if fill > 0 {
                SandShape(fill: fill, isTop: false)
                    .fill(
                        LinearGradient(
                            colors: [
                                Color(red: 0.88, green: 0.72, blue: 0.48),
                                Color(red: 0.95, green: 0.85, blue: 0.65)
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
            }
            
            // Reflets
            Path { path in
                path.move(to: CGPoint(x: 110, y: 20))
                path.addLine(to: CGPoint(x: 115, y: 110))
            }
            .stroke(.white.opacity(0.4), lineWidth: 2)
        }
        .frame(width: 160, height: 120)
    }
}

// MARK: - Neck

private struct Neck: View {
    @Binding var flow: CGFloat
    
    var body: some View {
        ZStack {
            // Goulot
            Path { path in
                path.move(to: CGPoint(x: 60, y: 0))
                path.addLine(to: CGPoint(x: 80, y: 20))
                path.addLine(to: CGPoint(x: 80, y: 25))
                path.addLine(to: CGPoint(x: 60, y: 45))
                path.addLine(to: CGPoint(x: 100, y: 45))
                path.addLine(to: CGPoint(x: 80, y: 25))
                path.addLine(to: CGPoint(x: 80, y: 20))
                path.addLine(to: CGPoint(x: 100, y: 0))
            }
            .fill(.white.opacity(0.1))
            .frame(width: 160, height: 45)
            
            // Flux de sable
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
                .frame(width: 2, height: 45)
                .offset(y: flow.truncatingRemainder(dividingBy: 45))
        }
        .frame(height: 45)
    }
}

// MARK: - Shine Effect

private struct SimpleHourglassShineEffect: View {
    @Binding var offset: CGFloat
    
    var body: some View {
        Rectangle()
            .fill(
                LinearGradient(
                    colors: [.clear, .white.opacity(0.3), .clear],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .frame(width: 40, height: 400)
            .rotationEffect(.degrees(15))
            .offset(x: offset - 100)
            .blur(radius: 5)
            .allowsHitTesting(false)
    }
}

// MARK: - Triangle Shape

private struct Triangle: Shape {
    let inverted: Bool
    
    func path(in rect: CGRect) -> Path {
        var path = Path()
        
        if inverted {
            path.move(to: CGPoint(x: rect.minX, y: rect.minY))
            path.addLine(to: CGPoint(x: rect.midX, y: rect.maxY))
            path.addLine(to: CGPoint(x: rect.maxX, y: rect.minY))
        } else {
            path.move(to: CGPoint(x: rect.midX, y: rect.minY))
            path.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
            path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
        }
        path.closeSubpath()
        
        return path
    }
}

// MARK: - Sand Shape

private struct SandShape: Shape {
    let fill: Double
    let isTop: Bool
    
    func path(in rect: CGRect) -> Path {
        var path = Path()
        
        let height = rect.height * CGFloat(fill)
        
        if isTop {
            let startY = rect.maxY - height
            path.move(to: CGPoint(x: rect.minX, y: startY))
            path.addLine(to: CGPoint(x: rect.midX, y: rect.maxY))
            path.addLine(to: CGPoint(x: rect.maxX, y: startY))
        } else {
            let sandHeight = height * 0.7
            path.move(to: CGPoint(x: rect.midX, y: rect.maxY - sandHeight))
            path.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
            path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
        }
        path.closeSubpath()
        
        return path
    }
}

// MARK: - Preview

#Preview {
    ZStack {
        LinearGradient(
            colors: [Color(red: 0.95, green: 0.95, blue: 0.98), .white],
            startPoint: .top,
            endPoint: .bottom
        )
        .ignoresSafeArea()
        
        VStack(spacing: 30) {
            Text("⏳ Sablier Réaliste")
                .font(.largeTitle)
                .fontWeight(.bold)
            
            SimpleRealisticHourglass(topFill: 0.6, bottomFill: 0.4)
                .shadow(color: .black.opacity(0.2), radius: 20, y: 10)
        }
    }
}
