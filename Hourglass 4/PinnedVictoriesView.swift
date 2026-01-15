//
//  PinnedVictoriesView.swift
//  Hourglass 4
//
//  Affiche les victoires épinglées d'un utilisateur
//

import SwiftUI

struct PinnedVictoriesView: View {
    let userId: String
    let displayName: String

    @State private var victories: [Victory] = []
    @State private var isLoading = true
    @State private var errorMessage: String?
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                if isLoading {
                    ProgressView()
                        .padding()
                } else if victories.isEmpty {
                    VStack(spacing: 14) {
                        Image(systemName: "pin")
                            .font(.system(size: 40))
                            .foregroundStyle(.orange.opacity(0.5))
                        Text("Aucune victoire épinglée")
                            .font(.headline)
                        Text("Épingle tes plus belles victoires pour les retrouver ici.")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding(.vertical, 40)
                    .padding(.horizontal, 24)
                } else {
                    VStack(spacing: 16) {
                        ForEach(victories) { victory in
                            VictoryCard(
                                victory: victory,
                                onTapComments: { },
                                showHeader: false,
                                availableGrainsToday: 0,
                                canViewFeed: true
                            ) { _ in }
                                .frame(maxWidth: 520)
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                }
            }
            .navigationTitle("Victoires épinglées")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Fermer") { dismiss() }
                }
            }
            .task {
                await loadPinnedVictories()
            }
        }
    }

    private func loadPinnedVictories() async {
        isLoading = true
        errorMessage = nil

        do {
            let pinned = try await VictoryManager.shared.loadPinnedVictories(userId: userId)
            await MainActor.run {
                victories = pinned
                isLoading = false
            }
        } catch {
            await MainActor.run {
                errorMessage = error.localizedDescription
                isLoading = false
            }
        }
    }
}
