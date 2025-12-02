//
//  ViewsFeed.swift
//  Hourglass 4
//
//  Vue SwiftUI pour afficher le fil d'actualité personnalisé
//

import SwiftUI

struct FeedView: View {
    @State private var posts: [PostData] = []
    @State private var isLoading = true

    var body: some View {
        NavigationStack {
            List {
                if isLoading {
                    ProgressView().frame(maxWidth: .infinity, alignment: .center)
                } else if posts.isEmpty {
                    VStack(alignment: .center, spacing: 8) {
                        Image(systemName: "text.bubble")
                            .font(.largeTitle)
                            .foregroundStyle(.secondary)
                        Text("Aucune publication dans votre fil")
                            .foregroundStyle(.secondary)
                        Text("Suivez des utilisateurs pour voir leurs posts ici.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity)
                } else {
                    ForEach(posts) { post in
                        VStack(alignment: .leading, spacing: 6) {
                            Text(post.content)
                                .font(.body)
                            HStack(spacing: 12) {
                                Text(post.timestamp, style: .date)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                Text("❤️ \(post.likesCount)")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                Text("💬 \(post.commentsCount)")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                        .padding(.vertical, 6)
                    }
                }
            }
            .navigationTitle("Fil d'actualité")
            .onAppear { loadFeed() }
            .refreshable { loadFeed() }
        }
    }

    private func loadFeed() {
        isLoading = true
        Task {
            do {
                let data = try await FeedManager.shared.getMyFeed()
                await MainActor.run {
                    posts = data
                    isLoading = false
                }
            } catch {
                await MainActor.run { isLoading = false }
                print("Erreur chargement feed: \(error)")
            }
        }
    }
}

#Preview {
    FeedView()
}
