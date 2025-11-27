//
//  SharedComponents.swift
//  Hourglass 4
//
//  Created by Corentin Soula on 13/11/2025.
//

import SwiftUI

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
    
    var total: Double {
        10.0
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
                    
                    Text(String(format: "%.1f / %.0f grains", allocated, total))
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
                    
                    Text("Il te reste \(String(format: "%.1f", remaining)) grains à allouer")
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

