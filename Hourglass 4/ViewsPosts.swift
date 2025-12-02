//
//  ViewsPosts.swift
//  Hourglass 4
//
//  Vues SwiftUI pour créer et afficher des publications Firestore
//

import SwiftUI
import FirebaseAuth

struct NewPostView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var content: String = ""
    @State private var isPosting = false
    @State private var errorMessage: String?

    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 12) {
                Text("Nouveau post")
                    .font(.headline)
                TextEditor(text: $content)
                    .frame(minHeight: 160)
                    .overlay(RoundedRectangle(cornerRadius: 8).stroke(.secondary.opacity(0.3)))

                if let errorMessage { Text(errorMessage).foregroundStyle(.red).font(.caption) }

                Spacer()
            }
            .padding()
            .navigationTitle("Publier")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Annuler") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button {
                        Task { await publish() }
                    } label: {
                        if isPosting { ProgressView() } else { Text("Publier") }
                    }
                    .disabled(isPosting || content.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
        }
    }

    private func publish() async {
        guard Auth.auth().currentUser != nil else {
            errorMessage = "Connectez-vous pour publier."
            return
        }
        isPosting = true
        errorMessage = nil
        do {
            try await PostManager.shared.createPost(content: content)
            await MainActor.run { dismiss() }
        } catch {
            await MainActor.run {
                errorMessage = error.localizedDescription
                isPosting = false
            }
        }
    }
}

struct PostsListView: View {
    let userId: String
    @State private var posts: [PostData] = []
    @State private var isLoading = true

    var body: some View {
        List {
            if isLoading {
                ProgressView().frame(maxWidth: .infinity, alignment: .center)
            } else if posts.isEmpty {
                Text("Aucune publication")
                    .foregroundStyle(.secondary)
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
        .navigationTitle("Publications")
        .onAppear { load() }
    }

    private func load() {
        isLoading = true
        Task {
            do {
                let data = try await PostManager.shared.getPosts(for: userId)
                await MainActor.run {
                    posts = data
                    isLoading = false
                }
            } catch {
                await MainActor.run { isLoading = false }
                print("Erreur chargement posts: \(error)")
            }
        }
    }
}

#Preview("NewPostView") {
    NewPostView()
}

#Preview("PostsListView") {
    PostsListView(userId: "demo")
}
