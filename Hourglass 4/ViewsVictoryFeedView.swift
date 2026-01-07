//
//  VictoryFeedView.swift
//  Hourglass 4
//
//  Fil d'actualité des victoires des amis
//

import SwiftUI
import FirebaseAuth

enum VictoryFilter {
    case friends
    case thisWeek
}

struct VictoryFeedView: View {
    @StateObject private var victoryManager = VictoryManager.shared
    @StateObject private var friendManager = FriendManager.shared

    @State private var selectedVictory: Victory?
    @State private var showComments = false
    @State private var selectedFilter: VictoryFilter = .friends
    @State private var showInfo = false

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Header minimaliste
                VStack(spacing: 12) {
                    // Titre avec bouton info
                    HStack(spacing: 8) {
                        Image(systemName: "sparkles")
                            .font(.title3)
                            .foregroundStyle(.orange)

                        Text("Fil des Victoires")
                            .font(.title2)
                            .fontWeight(.semibold)

                        Spacer()

                        Button {
                            showInfo = true
                        } label: {
                            Image(systemName: "info.circle")
                                .font(.title3)
                                .foregroundStyle(.orange)
                        }
                    }
                    .padding(.horizontal)
                    .padding(.top, 12)

                    // Filtres compacts
                    HStack(spacing: 12) {
                        FilterButton(
                            icon: "person.2.fill",
                            title: "Mes Complices",
                            isSelected: selectedFilter == .friends
                        ) {
                            selectedFilter = .friends
                        }

                        FilterButton(
                            icon: "calendar",
                            title: "Cette semaine",
                            isSelected: selectedFilter == .thisWeek
                        ) {
                            selectedFilter = .thisWeek
                        }
                    }
                    .padding(.horizontal)
                    .padding(.bottom, 8)
                }

                Divider()
                    .padding(.top)

                // Contenu
                ScrollView {
                    if victoryManager.isLoading {
                        ProgressView("Chargement...")
                            .padding()
                    } else if victoryManager.victories.isEmpty {
                        emptyState
                    } else {
                        LazyVStack(spacing: 16) {
                            ForEach(victoryManager.victories) { victory in
                                HStack {
                                    Spacer(minLength: 0)
                                    VictoryCard(victory: victory) {
                                        selectedVictory = victory
                                        showComments = true
                                    }
                                    .frame(maxWidth: 500)
                                    Spacer(minLength: 0)
                                }
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                    }
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar(.hidden, for: .navigationBar)
            .refreshable {
                await loadFeed()
            }
            .task {
                await loadFeed()
            }
            .sheet(item: $selectedVictory) { victory in
                VictoryDetailView(victory: victory)
            }
            .alert("Photos éphémères", isPresented: $showInfo) {
                Button("OK", role: .cancel) { }
            } message: {
                Text("Le feed se rafraîchit chaque soir à 21h avec les photos de la journée. Validation possible jusqu'à 20h59.")
            }
        }
    }

    private var emptyState: some View {
        VStack(spacing: 24) {
            Image(systemName: "sparkles")
                .font(.system(size: 80))
                .foregroundStyle(.orange.opacity(0.3))

            Text("Aucune victoire visible")
                .font(.title2)
                .fontWeight(.bold)

            Text("Les photos apparaissent à 21h et restent visibles 24h.")
                .font(.body)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
        }
        .padding(.vertical, 60)
    }

    private func loadFeed() async {
        do {
            guard let currentUserId = Auth.auth().currentUser?.uid else {
                print("❌ DEBUG - Aucun utilisateur connecté")
                return
            }

            print("🔍 DEBUG - Utilisateur actuel: \(currentUserId)")

            // Charger la liste des amis
            await friendManager.loadFriends()

            // Récupérer les IDs des amis
            let friendIds = friendManager.friends.map { $0.id }

            print("🔍 DEBUG - Nombre d'amis: \(friendIds.count)")
            print("🔍 DEBUG - IDs des amis: \(friendIds)")

            // Afficher les usernames des amis aussi
            friendManager.friends.forEach { friend in
                print("   - Ami: @\(friend.username) (ID: \(friend.id))")
            }

            // Charger le fil des victoires (même si pas d'amis, on charge quand même pour mettre à jour isLoading)
            try await victoryManager.loadVictoryFeed(friendIds: friendIds)

            print("🔍 DEBUG - Victoires chargées: \(victoryManager.victories.count)")
            victoryManager.victories.forEach { victory in
                print("   - \(victory.goalEmoji) \(victory.goalTitle) par @\(victory.username)")
                print("     UserId: \(victory.userId)")
                print("     Visible: \(victory.isVisible), Créé: \(victory.createdAt)")
            }
        } catch {
            print("❌ Erreur de chargement du fil: \(error.localizedDescription)")
            // Assurer que isLoading est désactivé même en cas d'erreur
            await MainActor.run {
                victoryManager.isLoading = false
            }
        }
    }
}

// MARK: - Carte de victoire

struct VictoryCard: View {
    let victory: Victory
    let onTapComments: () -> Void

    @State private var isBoosting = false
    @State private var showBoostError: String?

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header avec profil
            HStack(spacing: 12) {
                ProfileImageView(
                    imageURL: victory.profileImageURL,
                    username: victory.username,
                    size: 40,
                    gradientColors: [.orange, .orange.opacity(0.6)]
                )

                VStack(alignment: .leading, spacing: 2) {
                    Text(victory.displayName ?? victory.username)
                        .font(.headline)
                        .fontWeight(.semibold)

                    Text("@\(victory.username)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                Text(victory.timeAgoString)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            // Titre de l'objectif
            HStack(spacing: 6) {
                Text(victory.goalEmoji)
                    .font(.title2)

                Text(victory.goalTitle)
                    .font(.headline)
                    .foregroundStyle(.primary)
            }

            // Photo de l'accomplissement
            AsyncImage(url: URL(string: victory.photoURL)) { phase in
                switch phase {
                case .empty:
                    Rectangle()
                        .fill(Color.gray.opacity(0.2))
                        .frame(height: 300)
                        .overlay {
                            ProgressView()
                        }

                case .success(let image):
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(maxHeight: 400)
                        .cornerRadius(12)

                case .failure:
                    Rectangle()
                        .fill(Color.gray.opacity(0.2))
                        .frame(height: 300)
                        .overlay {
                            Image(systemName: "photo")
                                .font(.system(size: 40))
                                .foregroundStyle(.secondary)
                        }

                @unknown default:
                    EmptyView()
                }
            }

            // Actions
            HStack(spacing: 20) {
                // Bouton Boost
                Button {
                    Task {
                        await boostVictory()
                    }
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: victory.boostedBy.contains(Auth.auth().currentUser?.uid ?? "") ? "star.fill" : "star")
                            .foregroundStyle(.orange)

                        Text("\(victory.boostCount)")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                .disabled(isBoosting)

                // Bouton Commentaires
                Button {
                    onTapComments()
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "bubble.right")
                            .foregroundStyle(.blue)

                        Text("\(victory.commentCount)")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }

            if let error = showBoostError {
                Text(error)
                    .font(.caption)
                    .foregroundStyle(.red)
            }
        }
        .padding()
        .background {
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(uiColor: .systemBackground))
                .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)
        }
    }

    private func boostVictory() async {
        isBoosting = true
        showBoostError = nil

        do {
            try await VictoryManager.shared.boostVictory(victory)
        } catch {
            showBoostError = error.localizedDescription
        }

        isBoosting = false
    }
}

// MARK: - Détail de la victoire avec commentaires

struct VictoryDetailView: View {
    let victory: Victory

    @State private var comments: [VictoryComment] = []
    @State private var newCommentText = ""
    @State private var isPostingComment = false
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Photo
                AsyncImage(url: URL(string: victory.photoURL)) { phase in
                    switch phase {
                    case .success(let image):
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(maxHeight: 400)

                    default:
                        Rectangle()
                            .fill(Color.gray.opacity(0.2))
                            .frame(height: 300)
                    }
                }

                Divider()

                // Liste des commentaires
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 16) {
                        ForEach(comments) { comment in
                            CommentRow(comment: comment)
                        }
                    }
                    .padding()
                }

                Divider()

                // Zone de commentaire
                HStack(spacing: 12) {
                    TextField("Ajouter un commentaire...", text: $newCommentText)
                        .textFieldStyle(.roundedBorder)

                    Button {
                        Task {
                            await postComment()
                        }
                    } label: {
                        Image(systemName: "paperplane.fill")
                            .foregroundStyle(.blue)
                    }
                    .disabled(newCommentText.isEmpty || isPostingComment)
                }
                .padding()
            }
            .navigationTitle(victory.goalEmoji + " " + victory.goalTitle)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Fermer") {
                        dismiss()
                    }
                }
            }
            .task {
                await loadComments()
            }
        }
    }

    private func loadComments() async {
        do {
            comments = try await VictoryManager.shared.loadComments(for: victory.victoryId)
        } catch {
            print("Erreur de chargement des commentaires: \(error.localizedDescription)")
        }
    }

    private func postComment() async {
        isPostingComment = true

        do {
            try await VictoryManager.shared.commentVictory(victory, text: newCommentText)
            newCommentText = ""
            await loadComments()
        } catch {
            print("Erreur de commentaire: \(error.localizedDescription)")
        }

        isPostingComment = false
    }
}

struct CommentRow: View {
    let comment: VictoryComment

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            ProfileImageView(
                imageURL: comment.profileImageURL,
                username: comment.username,
                size: 32,
                gradientColors: [.blue, .blue.opacity(0.6)]
            )

            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text("@\(comment.username)")
                        .font(.caption)
                        .fontWeight(.semibold)

                    Text("•")
                        .foregroundStyle(.secondary)

                    Text(comment.timeAgoString)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Text(comment.text)
                    .font(.body)
            }
        }
    }
}

// MARK: - Bouton de filtre

struct FilterButton: View {
    let icon: String
    let title: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.caption)

                Text(title)
                    .font(.caption)
                    .fontWeight(.medium)
            }
            .foregroundStyle(isSelected ? .white : .primary)
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .frame(maxWidth: .infinity)
            .background {
                RoundedRectangle(cornerRadius: 20)
                    .fill(isSelected ? Color.orange : Color.gray.opacity(0.15))
            }
        }
    }
}
