//
//  ProfileImageView.swift
//  Hourglass 4
//
//  Composant réutilisable pour afficher les photos de profil
//

import SwiftUI
import UIKit
import Combine

/// Vue d'avatar de profil avec photo ou initiale
struct ProfileImageView: View {
    let imageURL: String?
    let username: String
    let size: CGFloat
    let gradientColors: [Color]
    @StateObject private var loader: ProfileImageLoader

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
        _loader = StateObject(wrappedValue: ProfileImageLoader(urlString: imageURL))
    }

    var body: some View {
        Group {
            if let uiImage = loader.image {
                Image(uiImage: uiImage)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: size, height: size)
                    .clipShape(Circle())
            } else if imageURL != nil {
                ProgressView()
                    .frame(width: size, height: size)
                    .task {
                        loader.loadIfNeeded()
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

    static func prefetch(urlStrings: [String]) {
        ProfileImageLoader.prefetch(urlStrings: urlStrings)
    }
}

@MainActor
private final class ProfileImageLoader: ObservableObject {
    @Published var image: UIImage?

    private let urlString: String?
    private var task: Task<Void, Never>?
    private static let cache = NSCache<NSString, UIImage>()

    init(urlString: String?) {
        self.urlString = urlString
        if let urlString,
           let cached = Self.cache.object(forKey: urlString as NSString) {
            self.image = cached
        }
    }

    deinit {
        task?.cancel()
    }

    func loadIfNeeded() {
        guard image == nil else { return }
        guard let urlString, let url = URL(string: urlString) else { return }

        if let cached = Self.cache.object(forKey: urlString as NSString) {
            image = cached
            return
        }

        task?.cancel()
        task = Task {
            do {
                let (data, _) = try await URLSession.shared.data(from: url)
                guard !Task.isCancelled, let image = UIImage(data: data) else { return }
                Self.cache.setObject(image, forKey: urlString as NSString)
                self.image = image
            } catch {
                return
            }
        }
    }

    static func prefetch(urlStrings: [String]) {
        let unique = Array(Set(urlStrings)).prefix(20)
        for urlString in unique {
            if cache.object(forKey: urlString as NSString) != nil { continue }
            guard let url = URL(string: urlString) else { continue }

            Task.detached(priority: .utility) {
                do {
                    let (data, _) = try await URLSession.shared.data(from: url)
                    guard let image = UIImage(data: data) else { return }
                    await MainActor.run {
                        cache.setObject(image, forKey: urlString as NSString)
                    }
                } catch {
                    return
                }
            }
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
