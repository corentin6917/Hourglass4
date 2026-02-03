//
//  DeepLinkFriendRequestView.swift
//  Hourglass 4
//
//  View displayed when user taps a friend request deep link
//

import SwiftUI
import FirebaseAuth

struct DeepLinkFriendRequestView: View {
    let username: String
    @Environment(\.dismiss) private var dismiss

    @State private var user: UserData? = nil
    @State private var isLoading = true
    @State private var errorMessage: String? = nil
    @State private var isAlreadyFriend = false
    @State private var isSendingRequest = false
    @State private var requestSent = false

    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                if isLoading {
                    ProgressView()
                        .padding()
                } else if let error = errorMessage {
                    // Error state
                    VStack(spacing: 16) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .font(.system(size: 50))
                            .foregroundStyle(.orange.opacity(0.7))

                        Text("Utilisateur introuvable")
                            .font(.headline)

                        Text(error)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                    }
                    .padding()
                } else if let user = user {
                    // User found
                    VStack(spacing: 20) {
                        // Profile Image
                        ProfileImageView(
                            imageURL: user.profileImageURL,
                            username: user.username,
                            size: 100,
                            gradientColors: [.orange, Color(red: 1.0, green: 0.6, blue: 0.0)]
                        )
                        .shadow(color: .orange.opacity(0.3), radius: 12, x: 0, y: 6)

                        // User Info
                        VStack(spacing: 8) {
                            if let displayName = user.displayName {
                                Text(displayName)
                                    .font(.title2)
                                    .fontWeight(.bold)
                            }

                            Text("@\(user.username)")
                                .font(.headline)
                                .foregroundStyle(.secondary)
                        }

                        Spacer()

                        // Action Button
                        if requestSent {
                            HStack {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundStyle(.green)
                                Text("Demande envoyée")
                                    .fontWeight(.semibold)
                            }
                            .font(.headline)
                            .foregroundStyle(.green)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background {
                                RoundedRectangle(cornerRadius: 15)
                                    .fill(Color.green.opacity(0.1))
                            }
                            .padding(.horizontal)
                        } else if isAlreadyFriend {
                            HStack {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundStyle(.green)
                                Text("Déjà ami")
                                    .fontWeight(.semibold)
                            }
                            .font(.headline)
                            .foregroundStyle(.secondary)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background {
                                RoundedRectangle(cornerRadius: 15)
                                    .fill(Color.gray.opacity(0.1))
                            }
                            .padding(.horizontal)
                        } else {
                            Button {
                                sendFriendRequest()
                            } label: {
                                if isSendingRequest {
                                    ProgressView()
                                        .tint(.white)
                                } else {
                                    HStack {
                                        Image(systemName: "person.badge.plus")
                                        Text("Envoyer une demande d'ami")
                                    }
                                    .fontWeight(.semibold)
                                }
                            }
                            .font(.headline)
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background {
                                RoundedRectangle(cornerRadius: 15)
                                    .fill(Color.orange)
                            }
                            .padding(.horizontal)
                            .disabled(isSendingRequest)
                        }
                    }
                    .padding(.top, 40)
                }
            }
            .navigationTitle("Ajouter un ami")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Fermer") {
                        DeepLinkHandler.shared.clearPendingRequest()
                        dismiss()
                    }
                }
            }
        }
        .task {
            await loadUser()
        }
    }

    private func loadUser() async {
        do {
            // Search for user by username
            let results = try await FriendManager.shared.searchUsers(query: username)

            // Find exact match (case-insensitive)
            if let foundUser = results.first(where: { $0.username.lowercased() == username.lowercased() }) {
                // Check if already friends
                let areFriends = try await FriendManager.shared.checkFriendship(with: foundUser.uid)

                await MainActor.run {
                    self.user = foundUser
                    self.isAlreadyFriend = areFriends
                    self.isLoading = false
                }
            } else {
                await MainActor.run {
                    self.errorMessage = "Aucun utilisateur trouvé avec ce nom d'utilisateur"
                    self.isLoading = false
                }
            }
        } catch {
            await MainActor.run {
                self.errorMessage = "Erreur lors de la recherche: \(error.localizedDescription)"
                self.isLoading = false
            }
        }
    }

    private func sendFriendRequest() {
        guard let user = user else { return }

        isSendingRequest = true

        Task {
            do {
                try await FriendManager.shared.sendFriendRequest(to: user.uid)
                await MainActor.run {
                    requestSent = true
                    isSendingRequest = false
                }

                // Auto-dismiss after 2 seconds
                try? await Task.sleep(nanoseconds: 2_000_000_000)
                await MainActor.run {
                    DeepLinkHandler.shared.clearPendingRequest()
                    dismiss()
                }
            } catch {
                await MainActor.run {
                    errorMessage = error.localizedDescription
                    isSendingRequest = false
                }
            }
        }
    }
}
