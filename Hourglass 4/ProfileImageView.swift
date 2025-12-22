//
//  ProfileImageView.swift
//  Hourglass 4
//
//  Composant réutilisable pour afficher les photos de profil
//

import SwiftUI

/// Vue d'avatar de profil avec photo ou initiale
struct ProfileImageView: View {
    let imageURL: String?
    let username: String
    let size: CGFloat
    let gradientColors: [Color]

    init(
        imageURL: String?,
        username: String,
        size: CGFloat = 50,
        gradientColors: [Color] = [.purple, .purple.opacity(0.6)]
    ) {
        self.imageURL = imageURL
        self.username = username
        self.size = size
        self.gradientColors = gradientColors
    }

    var body: some View {
        Group {
            if let urlString = imageURL, let url = URL(string: urlString) {
                // Photo de profil
                AsyncImage(url: url) { phase in
                    switch phase {
                    case .empty:
                        // Chargement
                        ProgressView()
                            .frame(width: size, height: size)
                    case .success(let image):
                        // Image chargée
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: size, height: size)
                            .clipShape(Circle())
                    case .failure:
                        // Erreur de chargement -> fallback sur initiale
                        initialAvatar
                    @unknown default:
                        initialAvatar
                    }
                }
            } else {
                // Pas d'image -> avatar avec initiale
                initialAvatar
            }
        }
    }

    private var initialAvatar: some View {
        Circle()
            .fill(
                LinearGradient(
                    colors: gradientColors,
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .frame(width: size, height: size)
            .overlay {
                Text(username.prefix(1).uppercased())
                    .font(.system(size: size * 0.4, weight: .bold))
                    .foregroundStyle(.white)
            }
    }
}

#Preview {
    VStack(spacing: 20) {
        // Avatar sans photo
        ProfileImageView(
            imageURL: nil,
            username: "johndoe",
            size: 100
        )

        // Avatar avec photo (exemple)
        ProfileImageView(
            imageURL: "https://picsum.photos/200",
            username: "janedoe",
            size: 100,
            gradientColors: [.green, .green.opacity(0.6)]
        )
    }
    .padding()
}
