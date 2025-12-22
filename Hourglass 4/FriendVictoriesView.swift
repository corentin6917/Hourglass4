//
//  FriendVictoriesView.swift
//  Hourglass 4
//
//  Vue pour afficher les victoires d'un ami
//

import SwiftUI

struct FriendVictoriesView: View {
    let friend: UserData
    @Environment(\.dismiss) private var dismiss
    @State private var victories: [Victory] = []
    @State private var isLoading = true

    var displayName: String {
        friend.displayName ?? friend.username
    }

    var body: some View {
        NavigationStack {
            Group {
                if isLoading {
                    ProgressView("Chargement des victoires...")
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if victories.isEmpty {
                    emptyStateView
                } else {
                    victoriesList
                }
            }
            .navigationTitle("Victoires de \(displayName)")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Fermer") {
                        dismiss()
                    }
                }
            }
            .onAppear {
                Task {
                    await loadVictories()
                }
            }
        }
    }

    private var emptyStateView: some View {
        VStack(spacing: 16) {
            Image(systemName: "trophy.fill")
                .font(.system(size: 60))
                .foregroundStyle(.yellow)

            Text("Aucune victoire pour l'instant")
                .font(.headline)

            Text("\(displayName) n'a pas encore remporté de victoires. Encouragez-le !")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var victoriesList: some View {
        ScrollView {
            LazyVStack(spacing: 16) {
                ForEach(victories) { victory in
                    VictoryCard(victory: victory)
                }
            }
            .padding()
        }
        .background(Color(uiColor: .systemGroupedBackground))
    }

    private func loadVictories() async {
        isLoading = true
        // TODO: Charger les vraies victoires depuis Firestore
        // Pour l'instant, on simule des données
        try? await Task.sleep(nanoseconds: 500_000_000) // 0.5 secondes

        // Données de test
        victories = []

        isLoading = false
    }
}

// MARK: - Victory Model

struct Victory: Identifiable {
    let id: String
    let title: String
    let description: String
    let date: Date
    let icon: String
    let color: Color
}

// MARK: - Victory Card Component

struct VictoryCard: View {
    let victory: Victory

    var body: some View {
        HStack(spacing: 16) {
            // Icône
            Circle()
                .fill(victory.color.opacity(0.2))
                .frame(width: 60, height: 60)
                .overlay {
                    Image(systemName: victory.icon)
                        .font(.title2)
                        .foregroundStyle(victory.color)
                }

            // Contenu
            VStack(alignment: .leading, spacing: 4) {
                Text(victory.title)
                    .font(.headline)

                Text(victory.description)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                Text(victory.date.formatted(date: .abbreviated, time: .omitted))
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

#Preview {
    FriendVictoriesView(
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
