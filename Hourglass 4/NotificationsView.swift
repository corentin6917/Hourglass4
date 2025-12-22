//
//  NotificationsView.swift
//  Hourglass 4
//
//  Vue pour afficher les messages et transfusions de grains reçus
//

import SwiftUI

struct NotificationsView: View {
    let viewModel: HourglassViewModel?

    @State private var messages: [FriendMessage] = []
    @State private var transfers: [GrainTransfer] = []
    @State private var isLoading = true
    @State private var errorMessage: String?

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

    var body: some View {
        NavigationStack {
            Group {
                if isLoading {
                    ProgressView("Chargement...")
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if conversations.isEmpty && transfers.isEmpty {
                    emptyStateView
                } else {
                    contentList
                }
            }
            .navigationTitle("Notifications")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        Task {
                            await loadData()
                        }
                    } label: {
                        Image(systemName: "arrow.clockwise")
                    }
                }
            }
            .onAppear {
                Task {
                    await loadData()
                }
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
            Image(systemName: "bell.slash.fill")
                .font(.system(size: 60))
                .foregroundStyle(.secondary)

            Text("Aucune notification")
                .font(.headline)

            Text("Vous recevrez ici les messages et transfusions de grains de vos amis")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var contentList: some View {
        ScrollView {
            LazyVStack(spacing: 16) {
                // Section Transfusions
                if !transfers.isEmpty {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Transfusions de Grains")
                            .font(.headline)
                            .padding(.horizontal)

                        ForEach(transfers) { transfer in
                            TransferCard(transfer: transfer)
                                .padding(.horizontal)
                        }
                    }
                }

                // Section Messages (groupés par conversation)
                if !conversations.isEmpty {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Messages")
                            .font(.headline)
                            .padding(.horizontal)

                        ForEach(conversations, id: \.user.uid) { conversation in
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
                            .padding(.horizontal)
                        }
                    }
                }
            }
            .padding(.vertical)
        }
        .background(Color(uiColor: .systemGroupedBackground))
    }

    private func loadData() async {
        isLoading = true
        errorMessage = nil

        do {
            // Charger les messages et transfusions en parallèle
            async let messagesTask = FriendMessageManager.shared.getReceivedMessages()
            async let transfersTask = GrainTransferManager.shared.getReceivedTransfers()

            messages = try await messagesTask
            transfers = try await transfersTask
        } catch {
            errorMessage = "Erreur de chargement: \(error.localizedDescription)"
        }

        isLoading = false
    }
}

// MARK: - Transfer Card Component

struct TransferCard: View {
    let transfer: GrainTransfer

    var senderName: String {
        transfer.fromUser?.displayName ?? transfer.fromUser?.username ?? "Utilisateur inconnu"
    }

    var body: some View {
        HStack(spacing: 16) {
            // Icône
            Circle()
                .fill(Color.red.opacity(0.2))
                .frame(width: 50, height: 50)
                .overlay {
                    Image(systemName: "heart.fill")
                        .font(.title3)
                        .foregroundStyle(.red)
                }

            // Contenu
            VStack(alignment: .leading, spacing: 4) {
                Text("\(senderName) vous a transfusé \(Int(transfer.grainAmount)) Grain")
                    .font(.subheadline)
                    .fontWeight(.medium)

                if let message = transfer.message {
                    Text(message)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Text(transfer.createdAt.formatted(date: .abbreviated, time: .shortened))
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }

            Spacer()
        }
        .padding()
        .background {
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(uiColor: .systemBackground))
                .shadow(color: .black.opacity(0.05), radius: 10)
        }
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
        HStack(spacing: 16) {
            // Avatar
            ProfileImageView(
                imageURL: user.profileImageURL,
                username: user.username,
                size: 50,
                gradientColors: [.green, .green.opacity(0.6)]
            )

            // Contenu
            VStack(alignment: .leading, spacing: 6) {
                HStack(alignment: .center) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(displayName)
                            .font(.headline)
                            .fontWeight(.semibold)
                            .foregroundStyle(.primary)

                        Text("@\(user.username)")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }

                    Spacer()

                    Text(lastMessage.createdAt.formatted(date: .omitted, time: .shortened))
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                }

                HStack {
                    Text(lastMessage.text)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)

                    Spacer()

                    // Badge nombre de messages non lus
                    if unreadCount > 0 {
                        Text("\(unreadCount)")
                            .font(.caption2)
                            .fontWeight(.bold)
                            .foregroundStyle(.white)
                            .padding(6)
                            .background {
                                Circle()
                                    .fill(.purple)
                            }
                    }
                }
            }
        }
        .padding()
        .background {
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(uiColor: .systemBackground))
                .shadow(color: .black.opacity(0.05), radius: 10)
        }
    }
}

#Preview {
    NotificationsView(viewModel: nil)
}
