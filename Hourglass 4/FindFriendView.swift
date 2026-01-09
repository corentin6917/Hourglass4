//
//  FindFriendView.swift
//  Hourglass 4
//
//  Vue pour rechercher et ajouter des amis via Firestore
//

import SwiftUI

struct FindFriendView: View {
    @StateObject private var viewModel = FindFriendViewModelV2()
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    // Barre de recherche
                    searchBar

                    // Résultat de recherche
                    if viewModel.isSearching {
                        ProgressView()
                            .padding()
                    } else if let user = viewModel.searchResult {
                        userResultCard(user)
                    } else if viewModel.searchQuery.isEmpty {
                        emptyStateView
                    } else if viewModel.searchResult == nil && !viewModel.searchQuery.isEmpty {
                        noResultView
                    }

                    // Messages d'erreur/succès
                    if let errorMessage = viewModel.errorMessage {
                        Text(errorMessage)
                            .font(.caption)
                            .foregroundStyle(.red)
                            .padding(.horizontal)
                    }

                    if let successMessage = viewModel.successMessage {
                        Text(successMessage)
                            .font(.caption)
                            .foregroundStyle(.green)
                            .padding(.horizontal)
                    }
                }
                .padding(.vertical, 12)
            }
            .navigationTitle("Trouver des amis")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Fermer") { dismiss() }
                }
            }
        }
    }

    // MARK: - Search Bar

    private var searchBar: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(.secondary)

            TextField("Username ou email", text: $viewModel.searchQuery)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled(true)
                .onSubmit {
                    Task {
                        await viewModel.searchUser()
                    }
                }

            if !viewModel.searchQuery.isEmpty {
                Button {
                    viewModel.clearSearch()
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding()
        .background {
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.secondarySystemBackground))
        }
        .padding()
    }

    // MARK: - User Result Card

    private func userResultCard(_ user: UserData) -> some View {
        VStack(spacing: 12) {
            // Avatar
            Circle()
                .fill(LinearGradient(colors: [.purple, .pink], startPoint: .topLeading, endPoint: .bottomTrailing))
                .frame(width: 80, height: 80)
                .overlay {
                    Text(user.username.prefix(1).uppercased())
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundStyle(.white)
                }

            // Infos
            VStack(spacing: 4) {
                let displayName = user.displayName ?? ""
                if !displayName.isEmpty {
                    Text(displayName)
                        .font(.title3)
                        .fontWeight(.semibold)
                }

                Text("@\(user.username)")
                    .font(.subheadline)
                    .foregroundStyle(.purple)

                Text(user.email)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            // Bouton d'ajout
            Button {
                Task {
                    await viewModel.sendFriendRequest(to: user)
                }
            } label: {
                if viewModel.isSendingRequest {
                    ProgressView()
                        .progressViewStyle(.circular)
                } else {
                    Label("Ajouter comme ami", systemImage: "person.badge.plus.fill")
                        .font(.subheadline)
                        .fontWeight(.medium)
                }
            }
            .buttonStyle(.borderedProminent)
            .disabled(viewModel.isSendingRequest)
            .padding(.top, 8)
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background {
            RoundedRectangle(cornerRadius: 20)
                .fill(Color(.secondarySystemBackground))
                .shadow(color: .black.opacity(0.05), radius: 10)
        }
        .padding()
    }

    // MARK: - Empty States

    private var emptyStateView: some View {
        VStack(spacing: 16) {
            Image(systemName: "person.2.fill")
                .font(.system(size: 60))
                .foregroundStyle(.blue.opacity(0.5))
            Text("Trouve tes amis")
                .font(.title3)
                .fontWeight(.medium)
            Text("Recherche par username ou email")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .padding()
    }

    private var noResultView: some View {
        VStack(spacing: 16) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 60))
                .foregroundStyle(.secondary.opacity(0.5))
            Text("Aucun résultat")
                .font(.title3)
                .fontWeight(.medium)
            Text("Essaie une autre recherche")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .padding()
    }
}

// MARK: - Pending Request Card

struct PendingRequestCardView: View {
    let request: FriendRequest
    let onAction: (RequestAction) -> Void

    enum RequestAction {
        case accept, reject
    }

    var body: some View {
        VStack(spacing: 12) {
            // Avatar
            Circle()
                .fill(LinearGradient(colors: [.blue, .cyan], startPoint: .topLeading, endPoint: .bottomTrailing))
                .frame(width: 60, height: 60)
                .overlay {
                    Text(request.fromUsername.prefix(1).uppercased())
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundStyle(.white)
                }

            // Infos
            VStack(spacing: 4) {
                if let displayName = request.fromDisplayName, !displayName.isEmpty {
                    Text(displayName)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .lineLimit(1)
                }
                Text("@\(request.fromUsername)")
                    .font(.caption)
                    .foregroundStyle(.blue)
                    .lineLimit(1)
            }

            // Boutons
            HStack(spacing: 8) {
                Button {
                    onAction(.accept)
                } label: {
                    Image(systemName: "checkmark")
                        .font(.caption)
                        .foregroundStyle(.white)
                        .frame(width: 32, height: 32)
                        .background(Color.green)
                        .clipShape(Circle())
                }

                Button {
                    onAction(.reject)
                } label: {
                    Image(systemName: "xmark")
                        .font(.caption)
                        .foregroundStyle(.white)
                        .frame(width: 32, height: 32)
                        .background(Color.red)
                        .clipShape(Circle())
                }
            }
        }
        .frame(width: 150)
        .padding()
        .background {
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.secondarySystemBackground))
                .shadow(color: .black.opacity(0.05), radius: 5)
        }
    }
}

#Preview {
    FindFriendView()
}
