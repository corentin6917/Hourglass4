//
//  FindFriendViewModel.swift
//  Hourglass 4
//
//  ViewModel pour rechercher et ajouter des amis via Data Connect
//

import Foundation
import FirebaseAuth
import Combine

@MainActor
class FindFriendViewModel: ObservableObject {
    @Published var searchQuery: String = ""
    @Published var searchResult: DCUser?
    @Published var pendingRequests: [DCFriendRequest] = []
    @Published var isSearching: Bool = false
    @Published var isSendingRequest: Bool = false
    @Published var errorMessage: String?
    @Published var successMessage: String?

    private var currentUserId: String? {
        Auth.auth().currentUser?.uid
    }

    /// Rechercher un utilisateur par username ou email
    func searchUser() async {
        guard !searchQuery.isEmpty else {
            searchResult = nil
            return
        }

        isSearching = true
        errorMessage = nil
        searchResult = nil

        do {
            let query = searchQuery.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()

            // Essayer d'abord par username
            if let user = try await DataConnectManager.shared.searchUserByUsername(query) {
                // Ne pas afficher l'utilisateur actuel
                if user.id != currentUserId {
                    searchResult = user
                }
            }
            // Sinon essayer par email
            else if query.contains("@"), let user = try await DataConnectManager.shared.searchUserByEmail(query) {
                // Ne pas afficher l'utilisateur actuel
                if user.id != currentUserId {
                    searchResult = user
                }
            }

            if searchResult == nil && searchQuery != "" {
                errorMessage = "Aucun utilisateur trouvé"
            }

            isSearching = false
        } catch {
            isSearching = false
            errorMessage = "Erreur: \(error.localizedDescription)"
        }
    }

    /// Envoyer une demande d'ami
    func sendFriendRequest(to userId: String) async {
        guard let currentUserId = currentUserId else {
            errorMessage = "Vous devez être connecté"
            return
        }

        isSendingRequest = true
        errorMessage = nil
        successMessage = nil

        do {
            try await DataConnectManager.shared.sendFriendRequest(
                from: currentUserId,
                to: userId
            )

            isSendingRequest = false
            successMessage = "Demande d'ami envoyée !"

            // Cacher le message après 2 secondes
            Task {
                try? await Task.sleep(nanoseconds: 2_000_000_000)
                successMessage = nil
            }
        } catch {
            isSendingRequest = false
            errorMessage = "Erreur: \(error.localizedDescription)"
        }
    }

    /// Charger les demandes d'amis en attente
    func loadPendingRequests() async {
        guard let currentUserId = currentUserId else { return }

        do {
            pendingRequests = try await DataConnectManager.shared.getPendingFriendRequests(for: currentUserId)
        } catch {
            errorMessage = "Erreur lors du chargement des demandes: \(error.localizedDescription)"
        }
    }

    /// Accepter une demande d'ami
    func acceptRequest(_ requestId: String) async {
        do {
            try await DataConnectManager.shared.acceptFriendRequest(requestId)
            await loadPendingRequests() // Recharger la liste
        } catch {
            errorMessage = "Erreur: \(error.localizedDescription)"
        }
    }

    /// Refuser une demande d'ami
    func rejectRequest(_ requestId: String) async {
        do {
            try await DataConnectManager.shared.rejectFriendRequest(requestId)
            await loadPendingRequests() // Recharger la liste
        } catch {
            errorMessage = "Erreur: \(error.localizedDescription)"
        }
    }

    /// Effacer la recherche
    func clearSearch() {
        searchQuery = ""
        searchResult = nil
        errorMessage = nil
        successMessage = nil
    }
}
