//
//  NotificationsView.swift
//  Hourglass 4
//
//  Vue pour afficher les messages et transfusions de grains reçus
//

import SwiftUI
import FirebaseAuth
import FirebaseFirestore

struct NotificationsView: View {
    let viewModel: HourglassViewModel?

    @State private var messages: [FriendMessage] = []
    @State private var transfers: [GrainTransfer] = []
    @State private var isLoading = true
    @State private var hasLoadedOnce = false
    @State private var errorMessage: String?
    @State private var searchQuery = ""
    @State private var showNewConversation = false
    @State private var messagesListener: ListenerRegistration?
    @State private var transfersListener: ListenerRegistration?
    @State private var userCache: [String: UserData] = [:]
    @State private var hasLoadedMessages = false
    @State private var hasLoadedTransfers = false

    // Grouper les messages par utilisateur (conversation)
    var groupedMessages: [String: [FriendMessage]] {
        Dictionary(grouping: messages) { $0.fromUserId }
    }

    // Obtenir le dernier message de chaque conversation
    var conversations: [(user: UserData, lastMessage: FriendMessage, unreadCount: Int)] {
        groupedMessages.compactMap { userId, messagesFromUser in
            guard let lastMessage = messagesFromUser.max(by: { $0.createdAt < $1.createdAt }),
                  let user = lastMessage.fromUser else {
                return nil
            }
            let unreadCount = messagesFromUser.filter { !$0.isRead }.count
            return (user: user, lastMessage: lastMessage, unreadCount: unreadCount)
        }
        .sorted { $0.lastMessage.createdAt > $1.lastMessage.createdAt }
    }

    var filteredConversations: [(user: UserData, lastMessage: FriendMessage, unreadCount: Int)] {
        let trimmedQuery = searchQuery.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedQuery.isEmpty else { return conversations }

        let query = trimmedQuery.lowercased()
        return conversations.filter { conversation in
            let displayName = conversation.user.displayName?.lowercased() ?? ""
            let username = conversation.user.username.lowercased()
            let lastMessageText = conversation.lastMessage.text.lowercased()
            return displayName.contains(query)
                || username.contains(query)
                || lastMessageText.contains(query)
        }
    }

    var body: some View {
        NavigationStack {
            Group {
                if isLoading && !hasLoadedOnce {
                    ProgressView("Chargement...")
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if conversations.isEmpty && transfers.isEmpty {
                    emptyStateView
                } else {
                    contentList
                }
            }
            .navigationTitle("Messages")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showNewConversation = true
                    } label: {
                        Image(systemName: "plus")
                            .foregroundStyle(Theme.Colors.accent)
                    }
                }
            }
            .searchable(text: $searchQuery, placement: .navigationBarDrawer(displayMode: .always), prompt: "Rechercher une conversation")
            .onAppear {
                startListeners()
            }
            .onDisappear {
                stopListeners()
            }
            .sheet(isPresented: $showNewConversation) {
                NewConversationView()
            }
            .alert("Erreur", isPresented: .constant(errorMessage != nil)) {
                Button("OK") {
                    errorMessage = nil
                }
            } message: {
                if let error = errorMessage {
                    Text(error)
                }
            }
            .background(Theme.Colors.background)
        }
    }

    private var emptyStateView: some View {
        VStack(spacing: Theme.Spacing.medium) {
            Image(systemName: "message.fill")
                .font(.system(size: 52, weight: .semibold))
                .foregroundStyle(Theme.Colors.accent)

            Text("Aucun message")
                .font(Theme.Typography.titleMedium)
                .foregroundColor(Theme.Colors.textPrimary)

            Text("Vous recevrez ici les messages et transfusions de grains de vos amis")
                .font(Theme.Typography.bodyMedium)
                .foregroundStyle(Theme.Colors.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Theme.Colors.background)
    }

    private var contentList: some View {
        ScrollView {
            LazyVStack(spacing: Theme.Spacing.large) {
                let visibleConversations = filteredConversations
                let totalUnread = conversations.reduce(0) { $0 + $1.unreadCount }

                InboxHeader(
                    totalConversations: conversations.count,
                    totalUnread: totalUnread
                )

                // Section Transfusions
                if !transfers.isEmpty {
                    VStack(alignment: .leading, spacing: Theme.Spacing.small) {
                        SectionHeader(
                            title: "Transfusions",
                            subtitle: "\(transfers.count) reçue\(transfers.count > 1 ? "s" : "")"
                        )

                        ForEach(transfers) { transfer in
                            TransferCard(transfer: transfer)
                                .padding(.horizontal, Theme.Spacing.large)
                        }
                    }
                }

                // Section Messages (groupés par conversation)
                if !visibleConversations.isEmpty {
                    VStack(alignment: .leading, spacing: Theme.Spacing.small) {
                        SectionHeader(
                            title: "Messages",
                            subtitle: ""
                        )

                        ForEach(visibleConversations, id: \.user.uid) { conversation in
                            NavigationLink {
                                ConversationView(friend: conversation.user)
                            } label: {
                                ConversationCard(
                                    user: conversation.user,
                                    lastMessage: conversation.lastMessage,
                                    unreadCount: conversation.unreadCount
                                )
                            }
                            .buttonStyle(.plain)
                            .padding(.horizontal, Theme.Spacing.large)
                        }
                    }
                } else if !searchQuery.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    VStack(spacing: Theme.Spacing.small) {
                        Image(systemName: "magnifyingglass")
                            .font(.system(size: 44, weight: .semibold))
                            .foregroundStyle(Theme.Colors.textTertiary)
                        Text("Aucune conversation trouvée")
                            .font(Theme.Typography.titleSmall)
                            .foregroundColor(Theme.Colors.textPrimary)
                        Text("Essaie un autre nom ou un autre mot-clé")
                            .font(Theme.Typography.bodySmall)
                            .foregroundStyle(Theme.Colors.textSecondary)
                    }
                    .padding(.vertical, Theme.Spacing.large)
                }
            }
            .padding(.vertical, Theme.Spacing.medium)
        }
        .background(Theme.Colors.background)
    }

    private func startListeners() {
        stopListeners()
        errorMessage = nil

        guard let currentUserId = Auth.auth().currentUser?.uid else {
            errorMessage = "Utilisateur non connecté"
            return
        }

        if !hasLoadedOnce {
            isLoading = true
        }

        let db = Firestore.firestore()

        messagesListener = db.collection("friendMessages")
            .whereField("toUserId", isEqualTo: currentUserId)
            .order(by: "createdAt", descending: true)
            .addSnapshotListener { snapshot, error in
                if let error {
                    Task { @MainActor in
                        errorMessage = "Erreur de chargement: \(error.localizedDescription)"
                        hasLoadedMessages = true
                        updateLoadingState()
                    }
                    return
                }

                guard let snapshot else { return }
                Task { @MainActor in
                    await handleMessagesSnapshot(snapshot)
                }
            }

        transfersListener = db.collection("grainTransfers")
            .whereField("toUserId", isEqualTo: currentUserId)
            .order(by: "createdAt", descending: true)
            .addSnapshotListener { snapshot, error in
                if let error {
                    Task { @MainActor in
                        errorMessage = "Erreur de chargement: \(error.localizedDescription)"
                        hasLoadedTransfers = true
                        updateLoadingState()
                    }
                    return
                }

                guard let snapshot else { return }
                Task { @MainActor in
                    await handleTransfersSnapshot(snapshot)
                }
            }

    }

    private func stopListeners() {
        messagesListener?.remove()
        messagesListener = nil
        transfersListener?.remove()
        transfersListener = nil
    }

    @MainActor
    private func handleMessagesSnapshot(_ snapshot: QuerySnapshot) async {
        let documents = snapshot.documents
        let senderIds = Set(documents.compactMap { $0.data()["fromUserId"] as? String })
        await updateUserCache(for: senderIds)

        let currentCache = userCache
        let newMessages = documents.compactMap { doc -> FriendMessage? in
            let data = doc.data()
            guard let fromUserId = data["fromUserId"] as? String,
                  let toUserId = data["toUserId"] as? String,
                  let text = data["text"] as? String,
                  let timestamp = data["createdAt"] as? Timestamp else {
                return nil
            }

            let isRead = data["isRead"] as? Bool ?? false
            return FriendMessage(
                id: doc.documentID,
                fromUserId: fromUserId,
                toUserId: toUserId,
                text: text,
                createdAt: timestamp.dateValue(),
                isRead: isRead,
                fromUser: currentCache[fromUserId]
            )
        }

        messages = newMessages
        hasLoadedMessages = true
        updateLoadingState()
    }

    @MainActor
    private func handleTransfersSnapshot(_ snapshot: QuerySnapshot) async {
        let documents = snapshot.documents
        let senderIds = Set(documents.compactMap { $0.data()["fromUserId"] as? String })
        await updateUserCache(for: senderIds)

        let currentCache = userCache
        let newTransfers = documents.compactMap { doc -> GrainTransfer? in
            let data = doc.data()
            guard let fromUserId = data["fromUserId"] as? String,
                  let toUserId = data["toUserId"] as? String,
                  let grainAmount = data["grainAmount"] as? Double,
                  let timestamp = data["createdAt"] as? Timestamp else {
                return nil
            }

            let message = data["message"] as? String
            return GrainTransfer(
                id: doc.documentID,
                fromUserId: fromUserId,
                toUserId: toUserId,
                grainAmount: grainAmount,
                createdAt: timestamp.dateValue(),
                message: message,
                fromUser: currentCache[fromUserId]
            )
        }

        transfers = newTransfers
        hasLoadedTransfers = true
        updateLoadingState()
    }


    @MainActor
    private func updateUserCache(for ids: Set<String>) async {
        let missingIds = ids.filter { userCache[$0] == nil }
        guard !missingIds.isEmpty else { return }

        var fetched: [String: UserData] = [:]
        await withTaskGroup(of: (String, UserData?).self) { group in
            for id in missingIds {
                group.addTask {
                    let user = try? await UserManager.shared.getUserProfile(uid: id)
                    return (id, user)
                }
            }

            for await (id, user) in group {
                if let user {
                    fetched[id] = user
                }
            }
        }

        if !fetched.isEmpty {
            userCache.merge(fetched) { current, _ in current }
        }
    }

    @MainActor
    private func updateLoadingState() {
        if hasLoadedMessages && hasLoadedTransfers {
            isLoading = false
            hasLoadedOnce = true
        }
    }
}

// MARK: - Mention Notification Model

struct MentionNotification: Identifiable {
    let id: String
    let type: String
    let fromUserId: String
    let fromUsername: String
    let fromDisplayName: String?
    let fromProfileImageURL: String?
    let toUserId: String
    let victoryId: String
    let victoryTitle: String?
    let victoryEmoji: String?
    let commentId: String
    let text: String
    let grainAmount: Double?
    let createdAt: Date
    let isRead: Bool
}

// MARK: - Mentions Notifications Center

struct MentionsNotificationsView: View {
    @State private var mentions: [MentionNotification] = []
    @State private var isLoading = true
    @State private var errorMessage: String?
    @State private var mentionsListener: ListenerRegistration?
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            Group {
                if isLoading {
                    ProgressView("Chargement...")
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if mentions.isEmpty {
                    emptyStateView
                } else {
                    ScrollView {
                        VStack(alignment: .leading, spacing: 12) {
                            ForEach(mentions) { mention in
                                MentionCard(mention: mention)
                                    .padding(.horizontal, 20)
                            }
                        }
                        .padding(.vertical, 16)
                    }
                }
            }
            .navigationTitle("Notifications")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Fermer") { dismiss() }
                }
            }
            .onAppear {
                startListener()
                markAllAsRead()
            }
            .onDisappear {
                stopListener()
            }
            .alert("Erreur", isPresented: .constant(errorMessage != nil)) {
                Button("OK") {
                    errorMessage = nil
                }
            } message: {
                if let errorMessage {
                    Text(errorMessage)
                }
            }
        }
    }

    private var emptyStateView: some View {
        VStack(spacing: Theme.Spacing.medium) {
            Image(systemName: "bell.fill")
                .font(.system(size: 52, weight: .semibold))
                .foregroundStyle(Theme.Colors.accent)

            Text("Aucune notification")
                .font(Theme.Typography.titleMedium)
                .foregroundStyle(Theme.Colors.textPrimary)

        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Theme.Colors.background)
    }

    private func startListener() {
        stopListener()
        errorMessage = nil
        guard let currentUserId = Auth.auth().currentUser?.uid else {
            errorMessage = "Utilisateur non connecté"
            isLoading = false
            return
        }

        let db = Firestore.firestore()
        mentionsListener = db.collection("notifications")
            .whereField("toUserId", isEqualTo: currentUserId)
            .order(by: "createdAt", descending: true)
            .addSnapshotListener { snapshot, error in
                if let error {
                    Task { @MainActor in
                        errorMessage = "Erreur de chargement: \(error.localizedDescription)"
                        isLoading = false
                    }
                    return
                }

                guard let snapshot else { return }
                Task { @MainActor in
                    let documents = snapshot.documents
                    let newMentions = documents.compactMap { doc -> MentionNotification? in
                        let data = doc.data()
                        guard let fromUserId = data["fromUserId"] as? String,
                              let toUserId = data["toUserId"] as? String,
                              let text = data["text"] as? String,
                              let timestamp = data["createdAt"] as? Timestamp else {
                            return nil
                        }

                        return MentionNotification(
                            id: doc.documentID,
                            type: data["type"] as? String ?? "mention",
                            fromUserId: fromUserId,
                            fromUsername: data["fromUsername"] as? String ?? "",
                            fromDisplayName: data["fromDisplayName"] as? String,
                            fromProfileImageURL: data["fromProfileImageURL"] as? String,
                            toUserId: toUserId,
                            victoryId: data["victoryId"] as? String ?? "",
                            victoryTitle: data["victoryTitle"] as? String,
                            victoryEmoji: data["victoryEmoji"] as? String,
                            commentId: data["commentId"] as? String ?? "",
                            text: text,
                            grainAmount: data["grainAmount"] as? Double,
                            createdAt: timestamp.dateValue(),
                            isRead: data["isRead"] as? Bool ?? false
                        )
                    }

                    mentions = newMentions
                    isLoading = false
                }
            }
    }

    private func markAllAsRead() {
        guard let currentUserId = Auth.auth().currentUser?.uid else { return }
        let db = Firestore.firestore()
        db.collection("notifications")
            .whereField("toUserId", isEqualTo: currentUserId)
            .whereField("isRead", isEqualTo: false)
            .getDocuments { snapshot, _ in
                guard let snapshot else { return }
                let batch = db.batch()
                snapshot.documents.forEach { doc in
                    batch.updateData(["isRead": true], forDocument: doc.reference)
                }
                batch.commit(completion: nil)
            }
    }

    private func stopListener() {
        mentionsListener?.remove()
        mentionsListener = nil
    }
}

// MARK: - Mention Card Component

struct MentionCard: View {
    let mention: MentionNotification

    private var senderName: String {
        if let displayName = mention.fromDisplayName, !displayName.isEmpty {
            return displayName
        }
        return mention.fromUsername.isEmpty ? "Utilisateur" : mention.fromUsername
    }

    private var titleText: String {
        let emoji = mention.victoryEmoji ?? "✨"
        let title = mention.victoryTitle ?? "victoire"
        return "\(emoji) \(title)"
    }

    private var actionText: String {
        switch mention.type {
        case "comment":
            return "\(senderName) a commenté ta victoire"
        case "boost":
            return "\(senderName) t'a donné un grain"
        default:
            return "\(senderName) t'a mentionné"
        }
    }

    private var detailText: String? {
        if mention.type == "comment" || mention.type == "mention" {
            return mention.text.isEmpty ? nil : mention.text
        }
        if mention.type == "boost" {
            return "⭐️ +\(Int(mention.grainAmount ?? 1)) grain"
        }
        return nil
    }

    var body: some View {
        HStack(spacing: Theme.Spacing.medium) {
            ProfileImageView(
                imageURL: mention.fromProfileImageURL,
                username: mention.fromUsername.isEmpty ? "U" : mention.fromUsername,
                size: 46,
                gradientColors: [Theme.Colors.accent, Theme.Colors.accent.opacity(0.6)]
            )

            VStack(alignment: .leading, spacing: Theme.Spacing.xxSmall) {
                Text(actionText)
                    .font(Theme.Typography.labelLarge)
                    .foregroundStyle(Theme.Colors.textPrimary)

                Text(titleText)
                    .font(Theme.Typography.caption)
                    .foregroundStyle(Theme.Colors.textSecondary)

                if let detailText {
                    Text(detailText)
                        .font(Theme.Typography.captionSmall)
                        .foregroundStyle(Theme.Colors.textTertiary)
                        .lineLimit(2)
                }
            }

            Spacer()

            Text(mention.createdAt, style: .time)
                .font(Theme.Typography.captionSmall)
                .foregroundStyle(Theme.Colors.textTertiary)
        }
        .padding(Theme.Spacing.medium)
        .background(Theme.Colors.surface)
        .cornerRadius(Theme.CornerRadius.large)
        .overlay(
            RoundedRectangle(cornerRadius: Theme.CornerRadius.large)
                .stroke(Theme.Colors.border, lineWidth: Theme.BorderWidth.thin)
        )
    }
}

// MARK: - Transfer Card Component

struct TransferCard: View {
    let transfer: GrainTransfer

    var senderName: String {
        transfer.fromUser?.displayName ?? transfer.fromUser?.username ?? "Utilisateur inconnu"
    }

    var body: some View {
        HStack(spacing: Theme.Spacing.medium) {
            // Icône
            Circle()
                .fill(Theme.Colors.accentSubtle)
                .frame(width: 46, height: 46)
                .overlay {
                    Image(systemName: "heart.fill")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(Theme.Colors.accent)
                }

            // Contenu
            VStack(alignment: .leading, spacing: Theme.Spacing.xxSmall) {
                Text(senderName)
                    .font(Theme.Typography.labelLarge)
                    .foregroundStyle(Theme.Colors.textPrimary)

                Text("Transfusion de \(Int(transfer.grainAmount)) grain\(transfer.grainAmount > 1 ? "s" : "")")
                    .font(Theme.Typography.bodySmall)
                    .foregroundStyle(Theme.Colors.textSecondary)

                if let message = transfer.message {
                    Text(message)
                        .font(Theme.Typography.caption)
                        .foregroundStyle(Theme.Colors.textSecondary)
                        .lineLimit(2)
                }

                Text(transfer.createdAt.formatted(date: .abbreviated, time: .shortened))
                    .font(Theme.Typography.captionSmall)
                    .foregroundStyle(Theme.Colors.textTertiary)
            }

            Spacer()
        }
        .padding(Theme.Spacing.medium)
        .background(Theme.Colors.surface)
        .cornerRadius(Theme.CornerRadius.large)
        .overlay(
            RoundedRectangle(cornerRadius: Theme.CornerRadius.large)
                .stroke(Theme.Colors.border, lineWidth: Theme.BorderWidth.thin)
        )
    }
}

// MARK: - New Conversation

struct NewConversationView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var friends: [UserData] = []
    @State private var isLoading = true
    @State private var errorMessage: String?
    @State private var searchQuery = ""

    private var filteredFriends: [UserData] {
        let trimmedQuery = searchQuery.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedQuery.isEmpty else { return friends }
        let query = trimmedQuery.lowercased()
        return friends.filter { friend in
            let displayName = friend.displayName?.lowercased() ?? ""
            let username = friend.username.lowercased()
            return displayName.contains(query) || username.contains(query)
        }
    }

    var body: some View {
        NavigationStack {
            Group {
                if isLoading {
                    ProgressView("Chargement...")
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if filteredFriends.isEmpty {
                    emptyStateView
                } else {
                    ScrollView {
                        VStack(spacing: 12) {
                            ForEach(filteredFriends) { friend in
                                NavigationLink {
                                    ConversationView(friend: friend)
                                } label: {
                                    HStack(spacing: Theme.Spacing.small) {
                                        ProfileImageView(
                                            imageURL: friend.profileImageURL,
                                            username: friend.username,
                                            size: 44,
                                            gradientColors: [Theme.Colors.accent, Theme.Colors.accent.opacity(0.6)]
                                        )

                                        VStack(alignment: .leading, spacing: Theme.Spacing.xxxSmall) {
                                            Text(friend.displayName ?? friend.username)
                                                .font(Theme.Typography.labelLarge)
                                                .foregroundStyle(Theme.Colors.textPrimary)

                                            Text("@\(friend.username)")
                                                .font(Theme.Typography.captionSmall)
                                                .foregroundStyle(Theme.Colors.textTertiary)
                                        }

                                        Spacer()

                                        Image(systemName: "chevron.right")
                                            .font(.footnote)
                                            .foregroundStyle(Theme.Colors.textTertiary)
                                    }
                                    .padding(.horizontal, Theme.Spacing.medium)
                                    .padding(.vertical, Theme.Spacing.small)
                                    .background(Theme.Colors.surface)
                                    .cornerRadius(Theme.CornerRadius.large)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: Theme.CornerRadius.large)
                                            .stroke(Theme.Colors.border, lineWidth: Theme.BorderWidth.thin)
                                    )
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .padding(.horizontal, Theme.Spacing.medium)
                        .padding(.vertical, Theme.Spacing.small)
                    }
                }
            }
            .navigationTitle("Nouvelle discussion")
            .navigationBarTitleDisplayMode(.inline)
            .searchable(text: $searchQuery, placement: .navigationBarDrawer(displayMode: .always), prompt: "Rechercher un complice")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Fermer") { dismiss() }
                }
            }
            .task {
                await loadFriends()
            }
            .alert("Erreur", isPresented: .constant(errorMessage != nil)) {
                Button("OK") {
                    errorMessage = nil
                }
            } message: {
                if let error = errorMessage {
                    Text(error)
                }
            }
        }
    }

    private var emptyStateView: some View {
        VStack(spacing: Theme.Spacing.medium) {
            Image(systemName: "person.2.fill")
                .font(.system(size: 52, weight: .semibold))
                .foregroundStyle(Theme.Colors.accent)

            Text(searchQuery.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? "Aucun complice" : "Aucun complice trouvé")
                .font(Theme.Typography.titleMedium)
                .foregroundStyle(Theme.Colors.textPrimary)

            Text(searchQuery.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? "Ajoute des amis pour démarrer une discussion." : "Essaie un autre nom.")
                .font(Theme.Typography.bodyMedium)
                .foregroundStyle(Theme.Colors.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, Theme.Spacing.large)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Theme.Colors.background)
    }

    private func loadFriends() async {
        isLoading = true
        errorMessage = nil

        do {
            friends = try await FriendManager.shared.getFriends()
        } catch {
            errorMessage = "Erreur de chargement: \(error.localizedDescription)"
        }

        isLoading = false
    }
}

// MARK: - Conversation Card Component

struct ConversationCard: View {
    let user: UserData
    let lastMessage: FriendMessage
    let unreadCount: Int

    var displayName: String {
        user.displayName ?? user.username
    }

    var body: some View {
        HStack(spacing: Theme.Spacing.medium) {
            // Avatar
            ProfileImageView(
                imageURL: user.profileImageURL,
                username: user.username,
                size: 52,
                gradientColors: [Theme.Colors.accent, Theme.Colors.accent.opacity(0.6)]
            )

            // Contenu
            VStack(alignment: .leading, spacing: Theme.Spacing.xxSmall) {
                HStack(alignment: .center) {
                    Text(displayName)
                        .font(Theme.Typography.labelLarge)
                        .foregroundStyle(Theme.Colors.textPrimary)

                    Text("@\(user.username)")
                        .font(Theme.Typography.captionSmall)
                        .foregroundStyle(Theme.Colors.textTertiary)

                    Spacer()

                    Text(lastMessage.createdAt.formatted(date: .omitted, time: .shortened))
                        .font(Theme.Typography.captionSmall)
                        .foregroundStyle(Theme.Colors.textSecondary)
                        .padding(.horizontal, Theme.Spacing.xSmall)
                        .padding(.vertical, Theme.Spacing.xxxSmall)
                        .background {
                            Capsule()
                                .fill(Theme.Colors.accentSubtle)
                        }
                }

                HStack(alignment: .center, spacing: Theme.Spacing.small) {
                    Text(lastMessage.text)
                        .font(Theme.Typography.bodySmall)
                        .foregroundStyle(Theme.Colors.textSecondary)
                        .lineLimit(2)

                    Spacer()

                    if unreadCount > 0 {
                        Text("\(unreadCount)")
                            .font(Theme.Typography.labelSmall)
                            .foregroundStyle(.white)
                            .padding(.horizontal, Theme.Spacing.xSmall)
                            .padding(.vertical, Theme.Spacing.xxxSmall)
                            .background {
                                Capsule()
                                    .fill(Theme.Colors.accent)
                            }
                    }
                }
            }
        }
        .padding(Theme.Spacing.medium)
        .background(Theme.Colors.surface)
        .cornerRadius(Theme.CornerRadius.large)
        .overlay(
            RoundedRectangle(cornerRadius: Theme.CornerRadius.large)
                .stroke(Theme.Colors.border, lineWidth: Theme.BorderWidth.thin)
        )
    }
}

struct SectionHeader: View {
    let title: String
    let subtitle: String

    var body: some View {
        HStack(alignment: .firstTextBaseline) {
            Text(title)
                .font(Theme.Typography.titleSmall)
                .foregroundStyle(Theme.Colors.textPrimary)

            Spacer()

            Text(subtitle)
                .font(Theme.Typography.captionSmall)
                .foregroundStyle(Theme.Colors.textTertiary)
        }
        .padding(.horizontal, Theme.Spacing.large)
    }
}

struct InboxHeader: View {
    let totalConversations: Int
    let totalUnread: Int

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.xxSmall) {
            Text("Boite de reception")
                .font(Theme.Typography.headlineSmall)
                .foregroundStyle(Theme.Colors.textPrimary)

            HStack(spacing: Theme.Spacing.small) {
                Text("\(totalConversations) conversation\(totalConversations > 1 ? "s" : "")")
                    .font(Theme.Typography.caption)
                    .foregroundStyle(Theme.Colors.textSecondary)

                if totalUnread > 0 {
                    Text("\(totalUnread) non lu\(totalUnread > 1 ? "s" : "")")
                        .font(Theme.Typography.labelSmall)
                        .foregroundStyle(.white)
                        .padding(.horizontal, Theme.Spacing.small)
                        .padding(.vertical, Theme.Spacing.xxSmall)
                        .background {
                            Capsule()
                                .fill(Theme.Colors.accent)
                        }
                }
            }
        }
        .padding(.horizontal, Theme.Spacing.large)
        .padding(.top, Theme.Spacing.xSmall)
    }
}

#Preview {
    NotificationsView(viewModel: nil)
}
