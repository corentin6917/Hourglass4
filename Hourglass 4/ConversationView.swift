//
//  ConversationView.swift
//  Hourglass 4
//
//  Vue de conversation complète entre deux utilisateurs
//

import SwiftUI
import FirebaseAuth

struct ConversationView: View {
    let friend: UserData
    @Environment(\.dismiss) private var dismiss

    @State private var messages: [FriendMessage] = []
    @State private var messageText = ""
    @State private var isLoading = true
    @State private var isSending = false
    @State private var errorMessage: String?

    var currentUserId: String {
        Auth.auth().currentUser?.uid ?? ""
    }

    var friendDisplayName: String {
        friend.displayName ?? friend.username
    }

    var canSend: Bool {
        !messageText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && !isSending
    }

    var body: some View {
        VStack(spacing: 0) {
            // Header avec nom et avatar
            conversationHeader

            themedDivider

            // Liste des messages
            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(spacing: 12) {
                        ForEach(messages) { message in
                            MessageBubble(
                                message: message,
                                isFromCurrentUser: message.fromUserId == currentUserId
                            )
                            .id(message.id)
                        }
                    }
                    .padding()
                }
                .onChange(of: messages.count) { _, _ in
                    // Scroll vers le dernier message quand un nouveau arrive
                    if let lastMessage = messages.last {
                        withAnimation {
                            proxy.scrollTo(lastMessage.id, anchor: .bottom)
                        }
                    }
                }
            }

            themedDivider

            // Barre de saisie
            messageInputBar
        }
        .navigationTitle(friendDisplayName)
        .navigationBarTitleDisplayMode(.inline)
        .background(Theme.Colors.background)
        .onAppear {
            Task {
                await loadMessages()
                // Marquer tous les messages de cet ami comme lus
                try? await FriendMessageManager.shared.markAllAsRead(from: friend.uid)
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

    private var conversationHeader: some View {
        HStack(spacing: 12) {
            // Avatar
            ProfileImageView(
                imageURL: friend.profileImageURL,
                username: friend.username,
                size: 40,
                gradientColors: [Theme.Colors.accent, Theme.Colors.accent.opacity(0.6)]
            )

            // Nom
            VStack(alignment: .leading, spacing: 2) {
                Text(friendDisplayName)
                    .font(Theme.Typography.titleSmall)
                    .foregroundStyle(Theme.Colors.textPrimary)

                Text("@\(friend.username)")
                    .font(Theme.Typography.caption)
                    .foregroundStyle(Theme.Colors.textTertiary)
            }

            Spacer()
        }
        .padding(Theme.Spacing.medium)
        .background(Theme.Colors.background)
    }

    private var messageInputBar: some View {
        HStack(spacing: Theme.Spacing.small) {
            // Champ de texte
            TextField("Message...", text: $messageText, axis: .vertical)
                .textFieldStyle(.plain)
                .padding(.horizontal, Theme.Spacing.medium)
                .padding(.vertical, Theme.Spacing.small)
                .background {
                    RoundedRectangle(cornerRadius: Theme.CornerRadius.large)
                        .fill(Theme.Colors.surface)
                }
                .overlay(
                    RoundedRectangle(cornerRadius: Theme.CornerRadius.large)
                        .stroke(Theme.Colors.border, lineWidth: Theme.BorderWidth.thin)
                )
                .lineLimit(1...4)

            // Bouton Envoyer
            Button {
                Task {
                    await sendMessage()
                }
            } label: {
                Image(systemName: isSending ? "hourglass" : "arrow.up.circle.fill")
                    .font(.title2)
                    .foregroundStyle(canSend ? Theme.Colors.accent : Theme.Colors.textTertiary)
            }
            .disabled(!canSend)
        }
        .padding(Theme.Spacing.medium)
        .background(Theme.Colors.background)
    }

    private var themedDivider: some View {
        Rectangle()
            .fill(Theme.Colors.divider)
            .frame(height: 1)
    }

    private func loadMessages() async {
        isLoading = true
        errorMessage = nil

        do {
            // Charger tous les messages entre les deux utilisateurs
            let receivedMessages = try await FriendMessageManager.shared.getConversation(with: friend.uid)

            // Trier par date (plus anciens en premier)
            messages = receivedMessages.sorted { $0.createdAt < $1.createdAt }
        } catch {
            errorMessage = "Erreur de chargement: \(error.localizedDescription)"
        }

        isLoading = false
    }

    private func sendMessage() async {
        guard canSend else { return }

        let textToSend = messageText
        messageText = "" // Vider le champ immédiatement
        isSending = true

        do {
            try await FriendMessageManager.shared.sendMessage(
                to: friend.uid,
                text: textToSend
            )

            // Recharger les messages pour afficher le nouveau
            await loadMessages()
        } catch {
            errorMessage = "Erreur lors de l'envoi: \(error.localizedDescription)"
            messageText = textToSend // Remettre le texte en cas d'erreur
        }

        isSending = false
    }
}

// MARK: - Message Bubble

struct MessageBubble: View {
    let message: FriendMessage
    let isFromCurrentUser: Bool

    var body: some View {
        HStack {
            if isFromCurrentUser {
                Spacer(minLength: 60)
            }

            VStack(alignment: isFromCurrentUser ? .trailing : .leading, spacing: 4) {
                Text(message.text)
                    .font(Theme.Typography.bodyMedium)
                    .padding(.horizontal, Theme.Spacing.medium)
                    .padding(.vertical, Theme.Spacing.small)
                    .background {
                        RoundedRectangle(cornerRadius: Theme.CornerRadius.large)
                            .fill(isFromCurrentUser ? Theme.Colors.accent : Theme.Colors.surface)
                    }
                    .foregroundStyle(isFromCurrentUser ? .white : Theme.Colors.textPrimary)
                    .overlay(
                        RoundedRectangle(cornerRadius: Theme.CornerRadius.large)
                            .stroke(isFromCurrentUser ? Color.clear : Theme.Colors.border, lineWidth: Theme.BorderWidth.thin)
                    )

                Text(message.createdAt.formatted(date: .omitted, time: .shortened))
                    .font(Theme.Typography.captionSmall)
                    .foregroundStyle(Theme.Colors.textTertiary)
                    .padding(.horizontal, Theme.Spacing.xxSmall)
            }

            if !isFromCurrentUser {
                Spacer(minLength: 60)
            }
        }
    }
}

#Preview {
    NavigationStack {
        ConversationView(
            friend: UserData(
                uid: "test123",
                email: "ami@test.com",
                username: "johndoe",
                displayName: "John Doe",
                gender: .male,
                birthDate: Date().addingTimeInterval(-25 * 365 * 24 * 60 * 60),
                createdAt: Date().addingTimeInterval(-30 * 24 * 60 * 60)
            )
        )
    }
}
