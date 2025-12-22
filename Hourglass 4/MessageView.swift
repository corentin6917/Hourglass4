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

                Divider()

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
                }
            }
            .alert("Message envoyé !", isPresented: $showSuccess) {
                Button("OK") {
                    dismiss()
                }
            } message: {
                Text("Votre message a été envoyé à \(displayName) avec succès !")
            }
        }
    }

    private var recipientSection: some View {
        HStack(spacing: 12) {
            Text("À :")
                .font(.subheadline)
                .foregroundStyle(.secondary)

            // Avatar miniature
            Circle()
                .fill(
                    LinearGradient(
                        colors: [.purple, .purple.opacity(0.6)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: 32, height: 32)
                .overlay {
                    Text(friend.username.prefix(1).uppercased())
                        .font(.caption)
                        .fontWeight(.bold)
                        .foregroundStyle(.white)
                }

            Text(displayName)
                .font(.subheadline)
                .fontWeight(.medium)

            Spacer()
        }
        .padding()
        .background(Color(uiColor: .systemGroupedBackground))
    }

    private var messageSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Message")
                .font(.caption)
                .foregroundStyle(.secondary)
                .padding(.horizontal)
                .padding(.top)

            TextEditor(text: $messageText)
                .frame(minHeight: 150)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(Color(uiColor: .systemBackground))
                .cornerRadius(12)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.secondary.opacity(0.2), lineWidth: 1)
                )
                .padding(.horizontal)

            // Suggestions de messages rapides
            quickMessagesSection
        }
        .padding(.vertical)
    }

    private var quickMessagesSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Messages rapides")
                .font(.caption)
                .foregroundStyle(.secondary)
                .padding(.horizontal)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
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
                .padding(.horizontal)
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
                .font(.subheadline)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background {
                    Capsule()
                        .fill(Color.purple.opacity(0.1))
                }
                .foregroundStyle(.purple)
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
