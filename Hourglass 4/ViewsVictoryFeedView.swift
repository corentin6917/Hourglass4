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
    @StateObject private var userManager = UserManager.shared
    @StateObject private var goalManager = GoalManager.shared

    @State private var selectedVictory: Victory?
    @State private var showComments = false
    @State private var selectedFilter: VictoryFilter = .friends
    @State private var showInfo = false

    private var groupedVictories: [UserVictoryGroup] {
        let grouped = Dictionary(grouping: victoryManager.victories) { $0.userId }

        let groups = grouped.map { userId, victories in
            let sorted = victories.sorted { $0.createdAt < $1.createdAt }
            let sample = sorted.first
            return UserVictoryGroup(
                userId: userId,
                username: sample?.username ?? "",
                displayName: sample?.displayName,
                profileImageURL: sample?.profileImageURL,
                victories: sorted
            )
        }

        return groups.sorted { lhs, rhs in
            let leftDate = lhs.victories.first?.createdAt ?? .distantPast
            let rightDate = rhs.victories.first?.createdAt ?? .distantPast
            return leftDate > rightDate
        }
    }

    private var canViewFeed: Bool {
        goalManager.todayGoals.contains { $0.status == .completed }
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Header minimaliste
                VStack(spacing: 10) {
                    HStack {
                        Text("Fil des Victoires")
                            .font(.system(size: 22, weight: .bold))
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [.orange, Color(red: 1.0, green: 0.6, blue: 0.0)],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )

                        Spacer()

                        Button {
                            showInfo = true
                        } label: {
                            Image(systemName: "info.circle")
                                .font(.system(size: 18, weight: .medium))
                                .foregroundStyle(.orange)
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 8)

                    HStack(spacing: 10) {
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
                    .padding(.horizontal, 16)
                    .padding(.bottom, 8)
                }

                Divider()

                // Contenu
                ZStack {
                    ScrollView {
                        if victoryManager.isLoading {
                            ProgressView("Chargement...")
                                .padding()
                        } else if victoryManager.victories.isEmpty {
                            emptyState
                        } else {
                            LazyVStack(spacing: 16) {
                                ForEach(groupedVictories) { group in
                                    UserVictoryGroupView(
                                        group: group,
                                        userManager: userManager
                                    ) { victory in
                                        selectedVictory = victory
                                        showComments = true
                                    }
                                }
                            }
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                        }
                    }
                    .blur(radius: canViewFeed ? 0 : 12)
                    .animation(.easeInOut(duration: 0.2), value: canViewFeed)
                    .allowsHitTesting(canViewFeed)

                    if !canViewFeed {
                        FeedLockOverlay {
                            NotificationCenter.default.post(name: .switchToObjectivesTab, object: nil)
                        }
                    }
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar(.hidden, for: .navigationBar)
            .refreshable {
                await goalManager.loadTodayGoals()
                await loadFeed()
            }
            .task {
                await goalManager.loadTodayGoals()
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

// MARK: - Grouped Feed

struct UserVictoryGroup: Identifiable {
    var id: String { userId }
    let userId: String
    let username: String
    let displayName: String?
    let profileImageURL: String?
    let victories: [Victory]
}

struct UserVictoryGroupView: View {
    let group: UserVictoryGroup
    @ObservedObject var userManager: UserManager
    let onTapComments: (Victory) -> Void
    @State private var selectedFriend: UserData?

    private var resolvedProfileImageURL: String? {
        let cached = userManager.cachedUsers[group.userId]?.profileImageURL
        if let cached, !cached.isEmpty {
            return cached
        }
        if let url = group.profileImageURL, !url.isEmpty {
            return url
        }
        return nil
    }

    private var resolvedDisplayName: String {
        if let cached = userManager.cachedUsers[group.userId]?.displayName?.trimmingCharacters(in: .whitespacesAndNewlines),
           !cached.isEmpty {
            return cached
        }
        if let name = group.displayName?.trimmingCharacters(in: .whitespacesAndNewlines),
           !name.isEmpty {
            return name
        }
        return group.username
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 12) {
                Button {
                    showFriendProfile()
                } label: {
                    HStack(spacing: 12) {
                        ProfileImageView(
                            imageURL: resolvedProfileImageURL,
                            username: group.username,
                            size: 44,
                            gradientColors: [.orange, .orange.opacity(0.6)]
                        )

                        VStack(alignment: .leading, spacing: 4) {
                            Text(resolvedDisplayName)
                                .font(.headline)
                                .fontWeight(.semibold)

                            Text("@\(group.username)")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
                .buttonStyle(.plain)

                Spacer()

                Text("\(group.victories.count) objectif\(group.victories.count > 1 ? "s" : "")")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(group.victories) { victory in
                        VictoryCard(victory: victory, onTapComments: {
                            onTapComments(victory)
                        }, showHeader: false)
                        .frame(width: 320)
                        .scrollTargetLayout()
                    }
                }
                .padding(.horizontal, 2)
            }
            .scrollTargetBehavior(.viewAligned)
        }
        .padding(.vertical, 4)
        .task {
            if userManager.cachedUsers[group.userId] == nil {
                await userManager.fetchUserProfile(userId: group.userId)
            }
        }
        .sheet(item: $selectedFriend) { friend in
            FriendProfileView(friend: friend)
        }
    }

    private func showFriendProfile() {
        if let cached = userManager.cachedUsers[group.userId] {
            selectedFriend = cached
            return
        }

        Task {
            if let data = try? await UserManager.shared.getUserProfile(uid: group.userId) {
                await MainActor.run {
                    userManager.cachedUsers[group.userId] = data
                    selectedFriend = data
                }
            }
        }
    }
}

// MARK: - Carte de victoire

struct VictoryCard: View {
    let victory: Victory
    let onTapComments: () -> Void
    var showHeader: Bool = true

    @StateObject private var userManager = UserManager.shared
    @State private var isBoosting = false
    @State private var showBoostError: String?
    @State private var showPhoto = false

    private var resolvedProfileImageURL: String? {
        let cached = userManager.cachedUsers[victory.userId]?.profileImageURL
        if let cached, !cached.isEmpty {
            return cached
        }
        if let url = victory.profileImageURL, !url.isEmpty {
            return url
        }
        return nil
    }

    private var resolvedDisplayName: String {
        if let cached = userManager.cachedUsers[victory.userId]?.displayName?.trimmingCharacters(in: .whitespacesAndNewlines),
           !cached.isEmpty {
            return cached
        }

        if let name = victory.displayName?.trimmingCharacters(in: .whitespacesAndNewlines),
           !name.isEmpty {
            return name
        }

        return victory.username
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            if showHeader {
                // Header avec profil
                HStack(spacing: 12) {
                    ProfileImageView(
                        imageURL: resolvedProfileImageURL,
                        username: victory.username,
                        size: 40,
                        gradientColors: [.orange, .orange.opacity(0.6)]
                    )

                    VStack(alignment: .leading, spacing: 2) {
                        Text(resolvedDisplayName)
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
            }

            if !showHeader {
                Text(victory.timeAgoString)
                    .font(.caption2)
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
            Button {
                showPhoto = true
            } label: {
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
            }
            .buttonStyle(.plain)

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
        .sheet(isPresented: $showPhoto) {
            VictoryPhotoView(photoURL: victory.photoURL, title: victory.goalTitle)
        }
        .task {
            if userManager.cachedUsers[victory.userId] == nil {
                await userManager.fetchUserProfile(userId: victory.userId)
            }
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

struct VictoryPhotoView: View {
    let photoURL: String
    let title: String
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ZStack {
                Color.black.opacity(0.95)
                    .ignoresSafeArea()

                AsyncImage(url: URL(string: photoURL)) { phase in
                    switch phase {
                    case .empty:
                        ProgressView()
                            .tint(.white)
                    case .success(let image):
                        image
                            .resizable()
                            .scaledToFit()
                            .padding()
                    case .failure:
                        VStack(spacing: 12) {
                            Image(systemName: "photo")
                                .font(.system(size: 48))
                                .foregroundStyle(.white)
                            Text("Impossible de charger la photo")
                                .foregroundStyle(.white)
                        }
                    @unknown default:
                        EmptyView()
                    }
                }
            }
            .navigationTitle(title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Fermer") { dismiss() }
                        .foregroundStyle(.white)
                }
            }
        }
    }
}

// MARK: - Détail de la victoire avec commentaires

struct VictoryDetailView: View {
    let victory: Victory

    @State private var comments: [VictoryComment] = []
    @State private var newCommentText = ""
    @State private var isPostingComment = false
    @State private var isPinned = false
    @State private var pinError: String?
    @State private var isUpdatingPin = false
    @Environment(\.dismiss) private var dismiss

    private var isOwner: Bool {
        victory.userId == Auth.auth().currentUser?.uid
    }

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

                if isOwner {
                    ToolbarItem(placement: .primaryAction) {
                        Button {
                            Task {
                                await togglePin()
                            }
                        } label: {
                            Image(systemName: isPinned ? "pin.fill" : "pin")
                                .foregroundStyle(.orange)
                        }
                        .disabled(isUpdatingPin)
                    }
                }
            }
            .task {
                await loadComments()
                await loadPinnedState()
            }
            .alert("Épingler", isPresented: .constant(pinError != nil)) {
                Button("OK") { pinError = nil }
            } message: {
                if let pinError {
                    Text(pinError)
                }
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

    private func loadPinnedState() async {
        guard let currentUserId = Auth.auth().currentUser?.uid, isOwner else { return }
        do {
            let pinned = try await VictoryManager.shared.isVictoryPinned(victory.victoryId, userId: currentUserId)
            await MainActor.run {
                isPinned = pinned
            }
        } catch {
            // Ignore
        }
    }

    private func togglePin() async {
        guard let currentUserId = Auth.auth().currentUser?.uid else { return }
        isUpdatingPin = true
        pinError = nil

        do {
            if isPinned {
                try await VictoryManager.shared.unpinVictory(victory.victoryId, userId: currentUserId)
                await MainActor.run { isPinned = false }
            } else {
                try await VictoryManager.shared.pinVictory(victory.victoryId, userId: currentUserId)
                await MainActor.run { isPinned = true }
            }
        } catch {
            await MainActor.run {
                pinError = error.localizedDescription
            }
        }

        isUpdatingPin = false
    }
}

struct CommentRow: View {
    let comment: VictoryComment
    @State private var currentUserImageURL: String?
    @State private var isLoadingUser = false

    private var resolvedImageURL: String? {
        if let url = comment.profileImageURL, !url.isEmpty {
            return url
        }

        if comment.userId == Auth.auth().currentUser?.uid {
            return currentUserImageURL
        }

        return nil
    }

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            ProfileImageView(
                imageURL: resolvedImageURL,
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
        .task {
            await loadCurrentUserIfNeeded()
        }
        .onReceive(NotificationCenter.default.publisher(for: .profileDidUpdate)) { _ in
            Task {
                await loadCurrentUserIfNeeded(forceRefresh: true)
            }
        }
    }

    private func loadCurrentUserIfNeeded(forceRefresh: Bool = false) async {
        guard let currentUserId = Auth.auth().currentUser?.uid,
              comment.userId == currentUserId
        else { return }

        if !forceRefresh, let cached = UserManager.shared.cachedUsers[currentUserId] {
            await MainActor.run {
                currentUserImageURL = cached.profileImageURL
            }
            return
        }

        if isLoadingUser { return }
        await MainActor.run { isLoadingUser = true }

        do {
            if let data = try await UserManager.shared.getUserProfile(uid: currentUserId) {
                await MainActor.run {
                    UserManager.shared.cachedUsers[currentUserId] = data
                    currentUserImageURL = data.profileImageURL
                }
            }
        } catch {
            // Pas bloquant : on garde le fallback sur l'initiale
        }

        await MainActor.run { isLoadingUser = false }
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

struct FeedLockOverlay: View {
    let onTapAction: () -> Void

    var body: some View {
        VStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(Color.orange.opacity(0.15))
                    .frame(width: 72, height: 72)
                Image(systemName: "lock.fill")
                    .font(.system(size: 28, weight: .semibold))
                    .foregroundStyle(.orange)
            }

            VStack(spacing: 6) {
                Text("Accomplis tes objectifs")
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundStyle(.primary)

                Text("Valide au moins un objectif aujourd’hui pour voir les victoires de tes amis.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }

            Button {
                onTapAction()
            } label: {
                Text("Aller aux objectifs")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundStyle(.white)
                    .padding(.horizontal, 18)
                    .padding(.vertical, 10)
                    .background(
                        LinearGradient(
                            colors: [.orange, Color(red: 1.0, green: 0.6, blue: 0.0)],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .clipShape(Capsule())
                    .shadow(color: .orange.opacity(0.25), radius: 10, x: 0, y: 6)
            }
        }
        .padding(24)
        .frame(maxWidth: 320)
        .background(
            RoundedRectangle(cornerRadius: 22)
                .fill(Color(uiColor: .systemBackground).opacity(0.95))
                .shadow(color: .black.opacity(0.12), radius: 18, x: 0, y: 10)
        )
        .padding(.horizontal, 24)
    }
}
