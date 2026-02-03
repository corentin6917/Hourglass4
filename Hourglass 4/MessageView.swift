//
//  MessageView.swift
//  Hourglass 4
//
//  Vue pour envoyer un message à un ami
//

import SwiftUI

struct MessageView: View {
    let friend: UserData
    @Environment(\.dismiss) private var dismiss
    @State private var messageText = ""
    @State private var isSending = false
    @State private var showSuccess = false

    var displayName: String {
        friend.displayName ?? friend.username
    }

    var canSend: Bool {
        !messageText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Zone de destinataire
                recipientSection

                Rectangle()
                    .fill(Theme.Colors.divider)
                    .frame(height: 1)

                // Zone de message
                messageSection

                Spacer()
            }
            .navigationTitle("Nouveau message")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Annuler") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Envoyer") {
                        Task {
                            await sendMessage()
                        }
                    }
                    .disabled(!canSend || isSending)
                    .foregroundStyle((canSend && !isSending) ? Theme.Colors.accent : Theme.Colors.textTertiary)
                }
            }
            .alert("Message envoyé !", isPresented: $showSuccess) {
                Button("OK") {
                    dismiss()
                }
            } message: {
                Text("Votre message a été envoyé à \(displayName) avec succès !")
            }
            .background(Theme.Colors.background)
        }
    }

    private var recipientSection: some View {
        HStack(spacing: Theme.Spacing.small) {
            Text("À :")
                .font(Theme.Typography.bodySmall)
                .foregroundStyle(Theme.Colors.textSecondary)

            // Avatar miniature
            ProfileImageView(
                imageURL: friend.profileImageURL,
                username: friend.username,
                size: 32,
                gradientColors: [Theme.Colors.accent, Theme.Colors.accent.opacity(0.6)]
            )

            Text(displayName)
                .font(Theme.Typography.labelLarge)
                .foregroundStyle(Theme.Colors.textPrimary)

            Spacer()
        }
        .padding(Theme.Spacing.medium)
        .background(Theme.Colors.surface)
        .overlay(
            Rectangle()
                .frame(height: 1)
                .foregroundStyle(Theme.Colors.divider),
            alignment: .bottom
        )
    }

    private var messageSection: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.small) {
            Text("Message")
                .font(Theme.Typography.caption)
                .foregroundStyle(Theme.Colors.textTertiary)
                .padding(.horizontal, Theme.Spacing.large)
                .padding(.top, Theme.Spacing.medium)

            TextEditor(text: $messageText)
                .frame(minHeight: 150)
                .padding(.horizontal, Theme.Spacing.medium)
                .padding(.vertical, Theme.Spacing.small)
                .background(Theme.Colors.surface)
                .cornerRadius(Theme.CornerRadius.medium)
                .overlay(
                    RoundedRectangle(cornerRadius: Theme.CornerRadius.medium)
                        .stroke(Theme.Colors.border, lineWidth: Theme.BorderWidth.thin)
                )
                .padding(.horizontal, Theme.Spacing.large)

            // Suggestions de messages rapides
            quickMessagesSection
        }
        .padding(.vertical, Theme.Spacing.small)
    }

    private var quickMessagesSection: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.small) {
            Text("Messages rapides")
                .font(Theme.Typography.caption)
                .foregroundStyle(Theme.Colors.textTertiary)
                .padding(.horizontal, Theme.Spacing.large)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: Theme.Spacing.small) {
                    QuickMessageButton(text: "Bon courage ! 💪") {
                        messageText = "Bon courage ! 💪"
                    }

                    QuickMessageButton(text: "Continue comme ça ! 🌟") {
                        messageText = "Continue comme ça ! 🌟"
                    }

                    QuickMessageButton(text: "Tu gères ! 🔥") {
                        messageText = "Tu gères ! 🔥"
                    }

                    QuickMessageButton(text: "Je crois en toi ! ✨") {
                        messageText = "Je crois en toi ! ✨"
                    }
                }
                .padding(.horizontal, Theme.Spacing.large)
            }
        }
    }

    private func sendMessage() async {
        guard canSend else { return }

        isSending = true

        do {
            // Envoyer le message via Firestore
            try await FriendMessageManager.shared.sendMessage(
                to: friend.uid,
                text: messageText
            )
            isSending = false
            showSuccess = true
        } catch {
            print("Erreur lors de l'envoi du message: \(error)")
            isSending = false
            // TODO: Afficher une alerte d'erreur
        }
    }
}

// MARK: - Quick Message Button

struct QuickMessageButton: View {
    let text: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(text)
                .font(Theme.Typography.bodySmall)
                .padding(.horizontal, Theme.Spacing.medium)
                .padding(.vertical, Theme.Spacing.small)
                .background {
                    Capsule()
                        .fill(Theme.Colors.accentSubtle)
                }
                .foregroundStyle(Theme.Colors.accent)
        }
    }
}

#Preview {
    MessageView(
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
