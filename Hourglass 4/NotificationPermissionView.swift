//
//  NotificationPermissionView.swift
//  Hourglass 4
//
//  Affiche une demande de permission pour les notifications
//  Réplique le design BeReal pour demander l'activation des notifications
//

import SwiftUI

struct NotificationPermissionView: View {
    var onDismiss: () -> Void
    var onAllow: () -> Void

    @State private var isRequestingPermission = false

    var body: some View {
        Color.black.opacity(0.90)
            .ignoresSafeArea()
            .overlay(
                VStack(spacing: 0) {
                    Spacer()

                    // Icône de sablier stylisé
                    ZStack {
                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: [Color.orange.opacity(0.3), Color.orange.opacity(0.1)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 100, height: 100)

                        Text("⏳")
                            .font(.system(size: 50))
                    }
                    .padding(.bottom, 24)

                    VStack(spacing: 16) {
                        Text("Quand ajouter du sable ?")
                            .font(.system(size: 28, weight: .bold))
                            .foregroundColor(.white)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 32)

                        Text("La seule façon de savoir quand ajouter du sable dans ton sablier est d'activer les notifications !")
                            .font(.system(size: 16))
                            .foregroundColor(.white.opacity(0.85))
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 40)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .padding(.bottom, 40)

                    VStack(spacing: 0) {
                        VStack(spacing: 8) {
                            Text("Merci d'activer les Notifications")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(.white)

                            Text("Toutes les notifications sur Hourglass sont silencieuses sauf celle qui t'indique quand ajouter du sable dans ton sablier.")
                                .font(.system(size: 13))
                                .foregroundColor(.white.opacity(0.75))
                                .multilineTextAlignment(.center)
                                .fixedSize(horizontal: false, vertical: true)
                                .padding(.horizontal, 24)
                        }
                        .padding(.vertical, 20)
                        .padding(.horizontal, 16)
                        .frame(maxWidth: .infinity)
                        .background(
                            LinearGradient(
                                colors: [Color.orange.opacity(0.15), Color.orange.opacity(0.08)],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .cornerRadius(16, corners: [.topLeft, .topRight])

                        Button(action: {
                            isRequestingPermission = true
                            onAllow()
                            isRequestingPermission = false
                        }) {
                            Text("Autoriser")
                                .font(.system(size: 17, weight: .semibold))
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .frame(height: 54)
                                .background(
                                    LinearGradient(
                                        colors: [Color.orange, Color.orange.opacity(0.8)],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                        }
                        .disabled(isRequestingPermission)

                        Button(action: {
                            onDismiss()
                        }) {
                            Text("Plus tard")
                                .font(.system(size: 15, weight: .medium))
                                .foregroundColor(.white.opacity(0.7))
                                .frame(maxWidth: .infinity)
                                .frame(height: 50)
                                .background(Color.white.opacity(0.05))
                        }
                    }
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(Color.white.opacity(0.08))
                            .overlay(
                                RoundedRectangle(cornerRadius: 16)
                                    .stroke(Color.orange.opacity(0.2), lineWidth: 1)
                            )
                    )
                    .cornerRadius(16)
                    .padding(.horizontal, 32)
                    .padding(.bottom, 60)

                    Spacer()
                }
            )
    }
}

extension View {
    func cornerRadius(_ radius: CGFloat, corners: UIRectCorner) -> some View {
        clipShape(RoundedCorner(radius: radius, corners: corners))
    }
}

struct RoundedCorner: Shape {
    var radius: CGFloat = .infinity
    var corners: UIRectCorner = .allCorners

    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(
            roundedRect: rect,
            byRoundingCorners: corners,
            cornerRadii: CGSize(width: radius, height: radius)
        )
        return Path(path.cgPath)
    }
}

#Preview {
    NotificationPermissionView(onDismiss: {}, onAllow: {})
}
