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
        }
    }

    private var emptyStateView: some View {
        VStack(spacing: 16) {
            Image(systemName: "message.fill")
                .font(.system(size: 60))
                .foregroundStyle(.orange.opacity(0.6))

            Text("Aucun message")
                .font(.headline)

            Text("Vous recevrez ici les messages et transfusions de grains de vos amis")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(
            LinearGradient(
                colors: [
                    Color(uiColor: .systemGroupedBackground),
                    Color(uiColor: .systemBackground)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
        )
    }

    private var contentList: some View {
        ScrollView {
            LazyVStack(spacing: 20) {
                let visibleConversations = filteredConversations

                // Section Transfusions
                if !transfers.isEmpty {
                    VStack(alignment: .leading, spacing: 12) {
                        SectionHeader(
                            title: "Transfusions",
                            subtitle: "\(transfers.count) reçue\(transfers.count > 1 ? "s" : "")"
                        )

                        ForEach(transfers) { transfer in
                            TransferCard(transfer: transfer)
                                .padding(.horizontal, 20)
                        }
                    }
                }

                // Section Messages (groupés par conversation)
                if !visibleConversations.isEmpty {
                    VStack(alignment: .leading, spacing: 12) {
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
                            .padding(.horizontal, 20)
                        }
                    }
                } else if !searchQuery.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    VStack(spacing: 12) {
                        Image(systemName: "magnifyingglass")
                            .font(.system(size: 48))
                            .foregroundStyle(.secondary.opacity(0.6))
                        Text("Aucune conversation trouvée")
                            .font(.headline)
                        Text("Essaie un autre nom ou un autre mot-clé")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.vertical, 24)
                }
            }
            .padding(.vertical, 16)
        }
        .background(
            LinearGradient(
                colors: [
                    Color(uiColor: .systemGroupedBackground),
                    Color(uiColor: .systemBackground)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
        )
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

// MARK: - Transfer Card Component

struct TransferCard: View {
    let transfer: GrainTransfer

    var senderName: String {
        transfer.fromUser?.displayName ?? transfer.fromUser?.username ?? "Utilisateur inconnu"
    }

    var body: some View {
        HStack(spacing: 14) {
            // Icône
            Circle()
                .fill(Color.orange.opacity(0.18))
                .frame(width: 46, height: 46)
                .overlay {
                    Image(systemName: "heart.fill")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(.orange)
                }

            // Contenu
            VStack(alignment: .leading, spacing: 4) {
                Text(senderName)
                    .font(.subheadline)
                    .fontWeight(.semibold)

                Text("Transfusion de \(Int(transfer.grainAmount)) grain\(transfer.grainAmount > 1 ? "s" : "")")
                    .font(.footnote)
                    .foregroundStyle(.secondary)

                if let message = transfer.message {
                    Text(message)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                }

                Text(transfer.createdAt.formatted(date: .abbreviated, time: .shortened))
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }

            Spacer()
        }
        .padding(14)
        .background {
            RoundedRectangle(cornerRadius: 18)
                .fill(
                    LinearGradient(
                        colors: [
                            Color(uiColor: .systemBackground),
                            Color.orange.opacity(0.04)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .shadow(color: .black.opacity(0.06), radius: 12, x: 0, y: 6)
        }
        .overlay {
            RoundedRectangle(cornerRadius: 18)
                .stroke(Color.black.opacity(0.04), lineWidth: 1)
        }
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
                                    HStack(spacing: 12) {
                                        ProfileImageView(
                                            imageURL: friend.profileImageURL,
                                            username: friend.username,
                                            size: 44,
                                            gradientColors: [.orange, .orange.opacity(0.6)]
                                        )

                                        VStack(alignment: .leading, spacing: 4) {
                                            Text(friend.displayName ?? friend.username)
                                                .font(.subheadline)
                                                .fontWeight(.semibold)
                                                .foregroundStyle(.primary)

                                            Text("@\(friend.username)")
                                                .font(.caption)
                                                .foregroundStyle(.secondary)
                                        }

                                        Spacer()

                                        Image(systemName: "chevron.right")
                                            .font(.footnote)
                                            .foregroundStyle(.secondary)
                                    }
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 12)
                                    .background {
                                        RoundedRectangle(cornerRadius: 16)
                                            .fill(Color(uiColor: .secondarySystemBackground))
                                    }
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
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
        VStack(spacing: 16) {
            Image(systemName: "person.2.fill")
                .font(.system(size: 60))
                .foregroundStyle(.orange.opacity(0.4))

            Text(searchQuery.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? "Aucun complice" : "Aucun complice trouvé")
                .font(.headline)

            Text(searchQuery.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? "Ajoute des amis pour démarrer une discussion." : "Essaie un autre nom.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(
            LinearGradient(
                colors: [
                    Color(uiColor: .systemGroupedBackground),
                    Color(uiColor: .systemBackground)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
        )
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
        HStack(spacing: 14) {
            // Avatar
            ProfileImageView(
                imageURL: user.profileImageURL,
                username: user.username,
                size: 52,
                gradientColors: [.orange, .orange.opacity(0.6)]
            )

            // Contenu
            VStack(alignment: .leading, spacing: 6) {
                HStack(alignment: .center) {
                    Text(displayName)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundStyle(.primary)

                    Text("@\(user.username)")
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    Spacer()

                    Text(lastMessage.createdAt.formatted(date: .omitted, time: .shortened))
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 3)
                        .background {
                            Capsule()
                                .fill(Color.orange.opacity(0.14))
                        }
                }

                HStack(alignment: .center, spacing: 8) {
                    Text(lastMessage.text)
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)

                    Spacer()

                    if unreadCount > 0 {
                        Text("\(unreadCount)")
                            .font(.caption2)
                            .fontWeight(.bold)
                            .foregroundStyle(.white)
                            .padding(.horizontal, 7)
                            .padding(.vertical, 4)
                            .background {
                                Capsule()
                                    .fill(Color.orange)
                            }
                    }
                }
            }
        }
        .padding(14)
        .background {
            RoundedRectangle(cornerRadius: 18)
                .fill(
                    LinearGradient(
                        colors: [
                            Color(uiColor: .systemBackground),
                            Color.orange.opacity(0.04)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .shadow(color: .black.opacity(0.06), radius: 12, x: 0, y: 6)
        }
        .overlay {
            RoundedRectangle(cornerRadius: 18)
                .stroke(Color.black.opacity(0.04), lineWidth: 1)
        }
    }
}

struct SectionHeader: View {
    let title: String
    let subtitle: String

    var body: some View {
        HStack(alignment: .firstTextBaseline) {
            Text(title)
                .font(.headline)
                .foregroundStyle(.primary)

            Spacer()

            Text(subtitle)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding(.horizontal, 20)
    }
}

struct InboxHeader: View {
    let totalConversations: Int
    let totalUnread: Int

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Boite de reception")
                .font(.title3)
                .fontWeight(.bold)
                .foregroundStyle(.primary)

            HStack(spacing: 8) {
                Text("\(totalConversations) conversation\(totalConversations > 1 ? "s" : "")")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                if totalUnread > 0 {
                    Text("\(totalUnread) non lu\(totalUnread > 1 ? "s" : "")")
                        .font(.caption2)
                        .fontWeight(.semibold)
                        .foregroundStyle(.white)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background {
                            Capsule()
                                .fill(Color.orange)
                        }
                }
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 8)
    }
}

#Preview {
    NotificationsView(viewModel: nil)
}
