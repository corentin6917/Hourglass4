//
//  VictoryFeedView.swift
//  Hourglass 4
//
//  Fil d'actualité des victoires des amis
//

import SwiftUI
import FirebaseAuth
import FirebaseFirestore

enum VictoryFilter {
    case friends
    case thisWeek
    case mine
}

struct VictoryFeedView: View {
    @StateObject private var victoryManager = VictoryManager.shared
    @StateObject private var friendManager = FriendManager.shared
    @StateObject private var userManager = UserManager.shared
    @StateObject private var goalManager = GoalManager.shared

    @State private var selectedVictory: Victory?
    @State private var showComments = false
    @State private var selectedFilter: VictoryFilter = .friends
    @State private var showFeedInfo = false
    @State private var showGrainInfo = false
    @State private var dailyGrainSpent: Double = 0.0
    @State private var unreadNotificationsCount = 0
    @State private var notificationsListener: ListenerRegistration?
    @State private var showNotifications = false

    private var groupedVictories: [UserVictoryGroup] {
        let calendar = AppTimeZone.calendar
        let visibleVictories: [Victory]

        switch selectedFilter {
        case .friends, .mine:
            visibleVictories = victoryManager.victories
        case .thisWeek:
            let weekInterval = calendar.dateInterval(of: .weekOfYear, for: Date())
            let weekStart = weekInterval?.start ?? calendar.startOfDay(for: Date())
            visibleVictories = victoryManager.victories.filter { $0.createdAt >= weekStart }
        }

        let grouped = Dictionary(grouping: visibleVictories) { $0.userId }

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

    private var canViewCurrentFeed: Bool {
        selectedFilter == .mine ? true : canViewFeed
    }

    private var grainsEarnedToday: Double {
        goalManager.todayGoals
            .filter { $0.status == .completed }
            .reduce(0.0) { $0 + $1.grainValue }
    }

    private var availableGrainsToday: Double {
        max(grainsEarnedToday - dailyGrainSpent, 0)
    }

    var body: some View {
        NavigationStack {
            ZStack {
                // Background gradient élégant
                LinearGradient(
                    colors: [
                        Color.white,
                        Color.orange.opacity(0.05)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()

                VStack(spacing: 0) {
                    // Header minimaliste
                    VStack(spacing: 10) {
                    HStack {
                        Button {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                showFeedInfo.toggle()
                            }
                        } label: {
                            Text("Fil des Victoires")
                                .font(.system(size: 18, weight: .semibold))
                                .foregroundStyle(.orange)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(
                                    Capsule()
                                        .fill(Color.orange.opacity(0.12))
                                        .overlay {
                                            Capsule()
                                                .stroke(Color.orange.opacity(0.25), lineWidth: 1)
                                        }
                                )
                        }
                        .buttonStyle(.plain)

                        Spacer()

                        Button {
                            showNotifications = true
                        } label: {
                            ZStack(alignment: .topTrailing) {
                                Image(systemName: "bell")
                                    .font(.system(size: 18, weight: .semibold))
                                    .foregroundStyle(.orange)
                                    .padding(8)
                                    .background(
                                        Circle()
                                            .fill(Color.orange.opacity(0.12))
                                    )

                                if unreadNotificationsCount > 0 {
                                    Text("\(unreadNotificationsCount)")
                                        .font(.caption2)
                                        .fontWeight(.bold)
                                        .foregroundStyle(.white)
                                        .padding(4)
                                        .background {
                                            Circle()
                                                .fill(.red)
                                        }
                                        .offset(x: 6, y: -6)
                                }
                            }
                        }
                        .buttonStyle(.plain)
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 8)
                    .tutorialAnchor("feed.header")

                    if showFeedInfo {
                        VStack(spacing: 0) {
                            InfoBubbleTriangleUp()
                                .fill(Color(uiColor: .systemBackground))
                                .frame(width: 20, height: 10)
                                .shadow(color: .orange.opacity(0.15), radius: 4, x: 0, y: -2)

                            VStack(alignment: .leading, spacing: 8) {
                                Text("Photos éphémères")
                                    .font(.system(size: 14, weight: .semibold))

                                Text("Le feed se rafraîchit chaque soir à 21h avec les photos de la journée. Validation possible jusqu'à 20h59.")
                                    .font(.system(size: 12))
                                    .foregroundStyle(.secondary)
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                            .padding(14)
                            .background {
                                RoundedRectangle(cornerRadius: 16)
                                    .fill(Color(uiColor: .systemBackground))
                                    .shadow(color: .orange.opacity(0.25), radius: 16, x: 0, y: 8)
                            }
                        }
                        .frame(maxWidth: 300)
                        .transition(.scale.combined(with: .opacity))
                        .padding(.horizontal, 20)
                        .onTapGesture {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                showFeedInfo = false
                            }
                        }
                    }

                    HStack(spacing: 8) {
                        FilterButton(
                            icon: "person.2.fill",
                            title: "Complices",
                            isSelected: selectedFilter == .friends
                        ) {
                            selectedFilter = .friends
                        }

                        FilterButton(
                            icon: "calendar",
                            title: "Semaine",
                            isSelected: selectedFilter == .thisWeek
                        ) {
                            selectedFilter = .thisWeek
                        }

                        FilterButton(
                            icon: "person.crop.circle",
                            title: "Mes victoires",
                            isSelected: selectedFilter == .mine
                        ) {
                            selectedFilter = .mine
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.horizontal, 16)
                    .padding(.bottom, 8)
                    .tutorialAnchor("feed.filters")
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
                                        userManager: userManager,
                                        availableGrainsToday: availableGrainsToday,
                                        canViewFeed: canViewCurrentFeed,
                                        onTapComments: { victory in
                                            selectedVictory = victory
                                            showComments = true
                                        },
                                        onGrainSpent: { newSpent in
                                            dailyGrainSpent = newSpent
                                        }
                                    )
                                }
                            }
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                        }
                    }
                }
                }
                .safeAreaInset(edge: .bottom) {
                    grainBadge
                }
                .navigationBarTitleDisplayMode(.inline)
                .toolbar(.hidden, for: .navigationBar)
                .refreshable {
                    await goalManager.loadTodayGoals()
                    await loadDailyGrainSpent()
                    await loadSelectedFeed()
                }
                .task {
                    await goalManager.loadTodayGoals()
                    await loadDailyGrainSpent()
                    await loadSelectedFeed()
                }
                .onChange(of: selectedFilter) { _, _ in
                    Task {
                        await loadSelectedFeed()
                    }
                }
                .onAppear {
                    startNotificationsListener()
                }
                .onDisappear {
                    stopNotificationsListener()
                }
                .onReceive(NotificationCenter.default.publisher(for: .openVictoryFromNotification)) { notification in
                    guard let victoryId = notification.userInfo?["victoryId"] as? String else { return }
                    Task { await openVictory(victoryId: victoryId) }
                }
                .sheet(item: $selectedVictory) { victory in
                    VictoryDetailView(victory: victory)
                }
                .sheet(isPresented: $showNotifications) {
                    MentionsNotificationsView()
                }
            }
        }
    }

    private var emptyState: some View {
        VStack(spacing: 24) {
            ZStack {
                Circle()
                    .stroke(Color.orange.opacity(0.18), lineWidth: 1)
                    .frame(width: 84, height: 84)

                Image(systemName: "hourglass")
                    .font(.system(size: 46, weight: .regular))
                    .foregroundStyle(.orange)
            }
            .padding(.bottom, 6)

            Text(emptyStateTitle)
                .font(.headline)
                .fontWeight(.semibold)
                .multilineTextAlignment(.center)

            Text(emptyStateSubtitle)
                .font(.footnote)
                .foregroundStyle(.orange)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
        }
        .padding(.vertical, 60)
    }

    private var emptyStateTitle: String {
        switch selectedFilter {
        case .friends:
            return "Aucune victoire visible de tes complices"
        case .thisWeek:
            return "Aucune victoire marquante cette semaine"
        case .mine:
            return "Aucun post en cours"
        }
    }

    private var emptyStateSubtitle: String {
        switch selectedFilter {
        case .mine:
            return "Valide un objectif pour publier ton post du jour. Tes posts restent visibles pendant 24h."
        case .friends:
            return "Les photos apparaissent à 21h et restent visibles 24h."
        case .thisWeek:
            return "Les plus beaux objectifs de la communauté apparaîtront ici."
        }
    }

    private func loadSelectedFeed() async {
        switch selectedFilter {
        case .friends, .thisWeek:
            await loadFriendsFeed()
        case .mine:
            await loadMyPosts()
        }
    }

    private func loadFriendsFeed() async {
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

    private func loadMyPosts() async {
        do {
            try await victoryManager.loadMyActiveVictories()
        } catch {
            print("❌ Erreur de chargement de mes posts: \(error.localizedDescription)")
            await MainActor.run {
                victoryManager.isLoading = false
            }
        }
    }

    private func loadDailyGrainSpent() async {
        do {
            dailyGrainSpent = try await victoryManager.fetchDailyGrainSpent()
        } catch {
            dailyGrainSpent = 0.0
        }
    }

    private func startNotificationsListener() {
        stopNotificationsListener()
        guard let currentUserId = Auth.auth().currentUser?.uid else { return }

        let db = Firestore.firestore()
        notificationsListener = db.collection("notifications")
            .whereField("toUserId", isEqualTo: currentUserId)
            .whereField("isRead", isEqualTo: false)
            .addSnapshotListener { snapshot, _ in
                let count = snapshot?.documents.count ?? 0
                DispatchQueue.main.async {
                    unreadNotificationsCount = count
                }
            }
    }

    private func stopNotificationsListener() {
        notificationsListener?.remove()
        notificationsListener = nil
    }

    private func openVictory(victoryId: String) async {
        if let existing = victoryManager.victories.first(where: { $0.victoryId == victoryId }) {
            await MainActor.run {
                selectedVictory = existing
            }
            return
        }

        if let fetched = try? await victoryManager.fetchVictory(by: victoryId) {
            await MainActor.run {
                selectedVictory = fetched
            }
        }
    }

    private var grainBadge: some View {
        VStack(spacing: 6) {
            if showGrainInfo {
                    VStack(spacing: 0) {
                        VStack(alignment: .leading, spacing: 10) {
                        Text("Grains disponibles")
                            .font(.system(size: 13, weight: .semibold))

                        Text("Ce sont les grains gagnés aujourd’hui. Ils servent à récompenser tes amis (1 grain max par post). Le budget se remet à zéro à minuit.")
                            .font(.system(size: 12))
                            .foregroundStyle(.secondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .padding(12)
                    .background {
                        RoundedRectangle(cornerRadius: 16)
                            .fill(Color(uiColor: .systemBackground))
                            .shadow(color: .orange.opacity(0.18), radius: 12, x: 0, y: 6)
                    }

                    InfoBubbleTriangle()
                        .fill(Color(uiColor: .systemBackground))
                        .frame(width: 18, height: 9)
                        .shadow(color: .orange.opacity(0.12), radius: 4, x: 0, y: 2)
                }
                .frame(maxWidth: 260)
                .transition(.scale.combined(with: .opacity))
                .onTapGesture {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        showGrainInfo = false
                    }
                }
            }

            Button {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                    showGrainInfo.toggle()
                }
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: "circle.fill")
                        .font(.system(size: 7))
                        .foregroundStyle(.white)
                    Text("Grains dispo \(Int(availableGrainsToday))")
                        .font(.caption2)
                        .foregroundStyle(.white)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(
                    RoundedRectangle(cornerRadius: 14)
                        .fill(
                            LinearGradient(
                                colors: [.orange, Color(red: 1.0, green: 0.6, blue: 0.0)],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                )
            }
            .buttonStyle(.plain)
            .tutorialAnchor("feed.grains")
        }
        .frame(maxWidth: .infinity)
        .padding(.bottom, 8)
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
    let availableGrainsToday: Double
    let canViewFeed: Bool
    let onTapComments: (Victory) -> Void
    let onGrainSpent: (Double) -> Void
    @State private var selectedFriend: UserData?

    init(
        group: UserVictoryGroup,
        userManager: UserManager,
        availableGrainsToday: Double,
        canViewFeed: Bool = true,
        onTapComments: @escaping (Victory) -> Void,
        onGrainSpent: @escaping (Double) -> Void
    ) {
        self.group = group
        self._userManager = ObservedObject(wrappedValue: userManager)
        self.availableGrainsToday = availableGrainsToday
        self.canViewFeed = canViewFeed
        self.onTapComments = onTapComments
        self.onGrainSpent = onGrainSpent
    }

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
                        }, showHeader: false, availableGrainsToday: availableGrainsToday, canViewFeed: canViewFeed) { newSpent in
                            onGrainSpent(newSpent)
                        }
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
    let availableGrainsToday: Double
    let canViewFeed: Bool
    let onGrainSpent: (Double) -> Void

    @StateObject private var userManager = UserManager.shared
    @State private var isBoosting = false
    @State private var showBoostError: String?
    @State private var showPhoto = false

    init(
        victory: Victory,
        onTapComments: @escaping () -> Void,
        showHeader: Bool = true,
        availableGrainsToday: Double,
        canViewFeed: Bool = true,
        onGrainSpent: @escaping (Double) -> Void
    ) {
        self.victory = victory
        self.onTapComments = onTapComments
        self.showHeader = showHeader
        self.availableGrainsToday = availableGrainsToday
        self.canViewFeed = canViewFeed
        self.onGrainSpent = onGrainSpent
    }

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

            if let comment = victory.comment, !comment.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                Text(comment)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
            }

            // Photo de l'accomplissement
            Button {
                guard canViewFeed else { return }
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
                .blur(radius: canViewFeed ? 0 : 16)
                .overlay {
                    if !canViewFeed {
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.black.opacity(0.12))

                        FeedLockOverlay(compact: true) {
                            NotificationCenter.default.post(name: .switchToObjectivesTab, object: nil)
                        }
                    }
                }
            }
            .buttonStyle(.plain)
        
            // Actions
            HStack(spacing: 20) {
                // Don 1 grain
                Button {
                    Task {
                        await boostVictory()
                    }
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: victory.boostedBy.contains(Auth.auth().currentUser?.uid ?? "") ? "circle.fill" : "circle")
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
                let isNoGrains = error == "Plus de grains disponibles aujourd'hui"
                Text(error)
                    .font(isNoGrains ? .footnote.weight(.semibold) : .caption)
                    .foregroundStyle(isNoGrains ? Color.orange.opacity(0.85) : .red)
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
            let currentUserId = Auth.auth().currentUser?.uid ?? ""
            let alreadyBoosted = victory.boostedBy.contains(currentUserId)
            let newSpent: Double

            if alreadyBoosted {
                newSpent = try await VictoryManager.shared.removeGrain(victory)
            } else {
                newSpent = try await VictoryManager.shared.donateGrain(victory, availableBudget: availableGrainsToday)
            }
            onGrainSpent(newSpent)
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

    @StateObject private var friendManager = FriendManager.shared
    @State private var comments: [VictoryComment] = []
    @State private var newCommentText = ""
    @State private var isPostingComment = false
    @State private var editableComment = ""
    @State private var savedComment = ""
    @State private var isSavingComment = false
    @State private var commentError: String?
    @State private var isPinned = false
    @State private var pinError: String?
    @State private var isUpdatingPin = false
    @Environment(\.dismiss) private var dismiss
    @FocusState private var isCommentFocused: Bool

    private var isOwner: Bool {
        victory.userId == Auth.auth().currentUser?.uid
    }
    
    private var trimmedEditableComment: String {
        editableComment.trimmingCharacters(in: .whitespacesAndNewlines)
    }
    
    private var trimmedSavedComment: String {
        savedComment.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private var mentionSuggestions: [UserData] {
        guard let query = currentMentionQuery(in: newCommentText),
              !query.isEmpty else {
            return []
        }
        let lowered = query.lowercased()
        return friendManager.friends
            .filter { $0.username.lowercased().hasPrefix(lowered) }
            .sorted { $0.username.lowercased() < $1.username.lowercased() }
            .prefix(6)
            .map { $0 }
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
                        if isOwner {
                            VStack(alignment: .leading, spacing: 10) {
                                HStack(spacing: 8) {
                                    Image(systemName: "quote.bubble")
                                        .font(.system(size: 14, weight: .semibold))
                                        .foregroundStyle(.orange)
                                    Text("Ton commentaire")
                                        .font(.subheadline)
                                        .fontWeight(.semibold)
                                    Spacer()
                                    if isSavingComment {
                                        ProgressView()
                                    }
                                }

                                TextField("Ajoute un commentaire pour ta victoire", text: $editableComment, axis: .vertical)
                                    .lineLimit(2...4)
                                    .submitLabel(.done)
                                    .focused($isCommentFocused)
                                    .onSubmit { isCommentFocused = false }
                                    .padding(12)
                                    .background {
                                        RoundedRectangle(cornerRadius: 14)
                                            .fill(Color.orange.opacity(0.08))
                                            .overlay {
                                                RoundedRectangle(cornerRadius: 14)
                                                    .stroke(Color.orange.opacity(0.18), lineWidth: 1)
                                            }
                                    }

                                Button {
                                    Task {
                                        await saveVictoryComment()
                                    }
                                } label: {
                                    Text(trimmedSavedComment.isEmpty ? "Ajouter" : "Mettre à jour")
                                        .font(.subheadline)
                                        .fontWeight(.semibold)
                                        .foregroundStyle(.white)
                                        .padding(.horizontal, 16)
                                        .padding(.vertical, 10)
                                        .background {
                                            RoundedRectangle(cornerRadius: 12)
                                                .fill(Color.orange)
                                        }
                                }
                                .disabled(isSavingComment || trimmedEditableComment == trimmedSavedComment)

                                if let commentError {
                                    Text(commentError)
                                        .font(.caption)
                                        .foregroundStyle(.red)
                                }
                            }
                            .padding(12)
                            .background {
                                RoundedRectangle(cornerRadius: 16)
                                    .fill(Color(uiColor: .secondarySystemBackground))
                            }
                        }

                        ForEach(comments) { comment in
                            CommentRow(comment: comment)
                        }
                    }
                    .padding()
                }

                Divider()

                // Zone de commentaire
                VStack(spacing: 8) {
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

                    if !mentionSuggestions.isEmpty {
                        VStack(alignment: .leading, spacing: 6) {
                            ForEach(mentionSuggestions) { friend in
                                Button {
                                    insertMention(friend.username)
                                } label: {
                                    HStack(spacing: 10) {
                                        ProfileImageView(
                                            imageURL: friend.profileImageURL,
                                            username: friend.username,
                                            size: 28,
                                            gradientColors: [.orange, .orange.opacity(0.6)]
                                        )
                                        VStack(alignment: .leading, spacing: 2) {
                                            Text(friend.displayName?.isEmpty == false ? friend.displayName! : friend.username)
                                                .font(.caption)
                                                .foregroundStyle(.primary)
                                            Text("@\(friend.username)")
                                                .font(.caption2)
                                                .foregroundStyle(.secondary)
                                        }
                                        Spacer()
                                    }
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 6)
                                    .background(
                                        RoundedRectangle(cornerRadius: 10)
                                            .fill(Color(uiColor: .secondarySystemBackground))
                                    )
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }

                    if let commentError, !commentError.isEmpty {
                        Text(commentError)
                            .font(.caption)
                            .foregroundStyle(.red)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
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
                    ToolbarItem(placement: .keyboard) {
                        Button("Terminer") {
                            isCommentFocused = false
                        }
                    }
                }
            }
            .task {
                await friendManager.loadFriends()
                await loadComments()
                await loadPinnedState()
                savedComment = victory.comment ?? ""
                editableComment = savedComment
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
            let mentioned = mentionedFriends(in: newCommentText)
            try await VictoryManager.shared.commentVictory(victory, text: newCommentText, mentionedUsers: mentioned)
            newCommentText = ""
            await loadComments()
        } catch {
            print("Erreur de commentaire: \(error.localizedDescription)")
            commentError = error.localizedDescription
        }

        isPostingComment = false
    }
    
    private func saveVictoryComment() async {
        isSavingComment = true
        commentError = nil

        do {
            let updated = try await VictoryManager.shared.updateVictoryComment(victory, comment: editableComment)
            await MainActor.run {
                savedComment = updated.comment ?? ""
                editableComment = savedComment
                isCommentFocused = false
            }
        } catch {
            await MainActor.run {
                commentError = error.localizedDescription
            }
        }

        isSavingComment = false
    }

    private func currentMentionQuery(in text: String) -> String? {
        guard let atIndex = text.lastIndex(of: "@") else { return nil }
        if atIndex > text.startIndex {
            let prev = text.index(before: atIndex)
            if !text[prev].isWhitespace {
                return nil
            }
        }
        let start = text.index(after: atIndex)
        var end = text.endIndex
        if let spaceIndex = text[start...].firstIndex(where: { $0.isWhitespace }) {
            end = spaceIndex
        }
        return String(text[start..<end])
    }

    private func insertMention(_ username: String) {
        guard let atIndex = newCommentText.lastIndex(of: "@") else {
            newCommentText += "@\(username) "
            return
        }
        let start = newCommentText.index(after: atIndex)
        var end = newCommentText.endIndex
        if let spaceIndex = newCommentText[start...].firstIndex(where: { $0.isWhitespace }) {
            end = spaceIndex
        }
        newCommentText.replaceSubrange(start..<end, with: username + " ")
    }

    private func mentionedFriends(in text: String) -> [UserData] {
        let tokens = text.split { $0.isWhitespace || $0 == "\n" }
        let usernames = tokens.compactMap { token -> String? in
            guard token.hasPrefix("@") else { return nil }
            let raw = token.dropFirst()
            let trimmed = raw.trimmingCharacters(in: CharacterSet(charactersIn: ".,!?:;\"'()[]{}"))
            return trimmed.isEmpty ? nil : String(trimmed)
        }
        if usernames.isEmpty { return [] }

        let lookup = Dictionary(uniqueKeysWithValues: friendManager.friends.map { ($0.username.lowercased(), $0) })
        let unique = Set(usernames.map { $0.lowercased() })
        return unique.compactMap { lookup[$0] }
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
            .fixedSize()
            .background {
                RoundedRectangle(cornerRadius: 20)
                    .fill(isSelected ? Color.orange : Color.gray.opacity(0.15))
            }
        }
        .buttonStyle(.plain)
    }
}

struct FeedLockOverlay: View {
    var compact: Bool = false
    let onTapAction: () -> Void

    var body: some View {
        VStack(spacing: compact ? 8 : 16) {
            ZStack {
                Circle()
                    .fill(Color.orange.opacity(0.15))
                    .frame(width: compact ? 44 : 72, height: compact ? 44 : 72)
                Image(systemName: "lock.fill")
                    .font(.system(size: compact ? 18 : 28, weight: .semibold))
                    .foregroundStyle(.orange)
            }

            VStack(spacing: 6) {
                Text("Accomplis tes objectifs")
                    .font(compact ? .footnote : .headline)
                    .fontWeight(.semibold)
                    .foregroundStyle(.primary)

                Text("Valide au moins un objectif aujourd’hui pour voir les victoires de tes amis.")
                    .font(compact ? .caption2 : .subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }

            Button {
                onTapAction()
            } label: {
                Text("Aller aux objectifs")
                    .font(compact ? .caption2 : .subheadline)
                    .fontWeight(.semibold)
                    .foregroundStyle(.white)
                    .padding(.horizontal, compact ? 10 : 18)
                    .padding(.vertical, compact ? 6 : 10)
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
        .padding(compact ? 12 : 24)
        .frame(maxWidth: compact ? 200 : 320)
        .background(
            RoundedRectangle(cornerRadius: 22)
                .fill(Color(uiColor: .systemBackground).opacity(0.95))
                .shadow(color: .black.opacity(0.12), radius: 18, x: 0, y: 10)
        )
        .padding(.horizontal, 24)
    }
}
