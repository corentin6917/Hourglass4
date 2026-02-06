//
//  FindFriendViewModelV2.swift
//  Hourglass 4
//
//  ViewModel pour rechercher et ajouter des amis via Firebase Data Connect SDK
//

import Foundation
import FirebaseAuth
import FirebaseFirestore
import Combine

@MainActor
class FindFriendViewModelV2: ObservableObject {
    @Published var searchQuery: String = ""
    @Published var searchResult: UserData?
    @Published var pendingRequests: [FriendRequest] = []
    @Published var friends: [UserData] = []
    @Published var isSearching: Bool = false
    @Published var isSendingRequest: Bool = false
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    @Published var successMessage: String?
    @Published var pendingRelationUserIds: Set<String> = []

    private var currentUserId: String? {
        Auth.auth().currentUser?.uid
    }

    /// Rechercher un utilisateur par username
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
            let users = try await FriendManager.shared.searchUsers(query: query)

            // Ne pas afficher l'utilisateur actuel
            if let user = users.first(where: { $0.uid != currentUserId }) {
                searchResult = user
            } else {
                errorMessage = "Aucun utilisateur trouvé"
            }

            isSearching = false
        } catch {
            isSearching = false
            errorMessage = "Erreur: \(error.localizedDescription)"
        }
    }

    /// Envoyer une demande d'ami
    func sendFriendRequest(to user: UserData) async {
        guard currentUserId != nil else {
            errorMessage = "Vous devez être connecté"
            return
        }

        isSendingRequest = true
        errorMessage = nil
        successMessage = nil

        do {
            try await FriendManager.shared.sendFriendRequest(to: user.uid)
            pendingRelationUserIds.insert(user.uid)

            isSendingRequest = false
            successMessage = "Demande d'ami envoyée à @\(user.username) !"

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

    /// Annuler une demande d'ami envoyée
    func cancelFriendRequest(to user: UserData) async {
        guard currentUserId != nil else {
            errorMessage = "Vous devez être connecté"
            return
        }

        isSendingRequest = true
        errorMessage = nil
        successMessage = nil

        do {
            try await FriendManager.shared.cancelFriendRequest(to: user.uid)
            pendingRelationUserIds.remove(user.uid)
            isSendingRequest = false
            successMessage = "Demande annulée."
            Task {
                try? await Task.sleep(nanoseconds: 1_500_000_000)
                successMessage = nil
            }
        } catch {
            isSendingRequest = false
            errorMessage = "Erreur: \(error.localizedDescription)"
        }
    }

    func isRequestPending(for userId: String) -> Bool {
        pendingRelationUserIds.contains(userId)
    }

    func refreshPendingRelationUserIds() async {
        guard let currentUserId = currentUserId else {
            pendingRelationUserIds = []
            return
        }

        do {
            var ids = Set<String>()
            let db = Firestore.firestore()

            let outgoing = try await db.collection("friendRequests")
                .whereField("fromUserId", isEqualTo: currentUserId)
                .whereField("status", isEqualTo: FriendRequestStatus.pending.rawValue)
                .getDocuments()
            for doc in outgoing.documents {
                if let id = doc.data()["toUserId"] as? String {
                    ids.insert(id)
                }
            }

            let incoming = try await db.collection("friendRequests")
                .whereField("toUserId", isEqualTo: currentUserId)
                .whereField("status", isEqualTo: FriendRequestStatus.pending.rawValue)
                .getDocuments()
            for doc in incoming.documents {
                if let id = doc.data()["fromUserId"] as? String {
                    ids.insert(id)
                }
            }

            pendingRelationUserIds = ids
        } catch {
            pendingRelationUserIds = []
        }
    }

    /// Charger les demandes d'amis en attente
    func loadPendingRequests() async {
        isLoading = true
        do {
            guard let uid = Auth.auth().currentUser?.uid else {
                isLoading = false
                return
            }

            let snap = try await Firestore.firestore()
                .collection("friendRequests")
                .whereField("toUserId", isEqualTo: uid)
                .whereField("status", isEqualTo: FriendRequestStatus.pending.rawValue)
                .getDocuments()

            let items = snap.documents.map { doc in
                let data = doc.data()
                return FriendRequest(
                    id: doc.documentID,
                    fromUserId: data["fromUserId"] as? String ?? "",
                    fromUsername: data["fromUsername"] as? String ?? "",
                    fromDisplayName: data["fromDisplayName"] as? String ?? "",
                    toUserId: data["toUserId"] as? String ?? "",
                    status: FriendRequestStatus(rawValue: data["status"] as? String ?? "pending") ?? .pending,
                    createdAt: (data["createdAt"] as? Timestamp)?.dateValue() ?? Date()
                )
            }
            // Trier côté client par date décroissante si dispo
            pendingRequests = items.sorted { (a, b) in
                let da = a.createdAt ?? .distantPast
                let db = b.createdAt ?? .distantPast
                return da > db
            }
            isLoading = false
        } catch {
            isLoading = false
            errorMessage = "Erreur lors du chargement des demandes: \(error.localizedDescription)"
        }
    }

    /// Charger la liste des amis
    func loadFriends() async {
        isLoading = true
        do {
            friends = try await FriendManager.shared.getFriends()
            isLoading = false
        } catch {
            isLoading = false
            errorMessage = "Erreur lors du chargement des amis: \(error.localizedDescription)"
        }
    }

    /// Accepter une demande d'ami
    func acceptRequest(_ request: FriendRequest) async {
        do {
            try await FriendManager.shared.acceptFriendRequest(request.id)
            await loadPendingRequests() // Recharger la liste
            successMessage = "Demande acceptée !"
        } catch {
            errorMessage = "Erreur: \(error.localizedDescription)"
        }
    }

    /// Refuser une demande d'ami
    func rejectRequest(_ request: FriendRequest) async {
        do {
            try await FriendManager.shared.rejectFriendRequest(request.id)
            await loadPendingRequests() // Recharger la liste
            successMessage = "Demande refusée"
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

    /// Sauvegarder le username de l'utilisateur connecté (à appeler après login/signup)
    static func saveCurrentUsername(_ username: String) {
        UserDefaults.standard.set(username, forKey: "current_username")
    }

    /// Supprimer le username sauvegardé (à appeler à la déconnexion)
    static func clearCurrentUsername() {
        UserDefaults.standard.removeObject(forKey: "current_username")
    }
}
