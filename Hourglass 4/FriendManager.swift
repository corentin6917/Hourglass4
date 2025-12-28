//
//  FriendManager.swift
//  Hourglass 4
//
//  Gestionnaire des relations d'amitié entre utilisateurs
//

import Foundation
import Combine
import FirebaseAuth
import FirebaseFirestore

enum FriendRequestStatus: String, Codable {
    case pending = "pending"
    case accepted = "accepted"
    case rejected = "rejected"
}

struct FriendRequest: Identifiable, Codable {
    let id: String
    let fromUserId: String
    let fromUsername: String
    let fromDisplayName: String?
    let toUserId: String
    let status: FriendRequestStatus
    let createdAt: Date

    var dictionary: [String: Any] {
        return [
            "id": id,
            "fromUserId": fromUserId,
            "fromUsername": fromUsername,
            "fromDisplayName": fromDisplayName ?? "",
            "toUserId": toUserId,
            "status": status.rawValue,
            "createdAt": Timestamp(date: createdAt)
        ]
    }
}

struct Friendship: Identifiable, Codable {
    let id: String
    let user1Id: String
    let user2Id: String
    let createdAt: Date
}

class FriendManager: ObservableObject {
    static let shared = FriendManager()
    private let db = Firestore.firestore()

    @Published var friends: [UserData] = []

    private init() {}

    // MARK: - Recherche d'utilisateurs

    /// Recherche des utilisateurs par nom d'utilisateur ou email (correspondance exacte, insensible à la casse)
    func searchUsers(query: String) async throws -> [UserData] {
        let normalizedQuery = query.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)

        guard !normalizedQuery.isEmpty else {
            return []
        }

        var users: [UserData] = []
        var userIds = Set<String>()

        // Recherche 1 : Par nom d'utilisateur (username_lower) en recherche préfixe
        let end = normalizedQuery + "\u{f8ff}"
        let usernameSnapshot = try await db.collection("users")
            .whereField("username_lower", isGreaterThanOrEqualTo: normalizedQuery)
            .whereField("username_lower", isLessThan: end)
            .limit(to: 10)
            .getDocuments()

        for document in usernameSnapshot.documents {
            let data = document.data()
            let uid = data["uid"] as? String ?? document.documentID

            // Ne pas inclure l'utilisateur actuel
            if uid == Auth.auth().currentUser?.uid { continue }
            if userIds.contains(uid) { continue }
            userIds.insert(uid)

            if let user = parseUserData(from: data, uid: uid) {
                users.append(user)
            }
        }

        // Recherche 2 : Par email (en minuscules)
        let emailLower = normalizedQuery
        let emailSnapshot = try await db.collection("users")
            .whereField("email", isEqualTo: emailLower)
            .limit(to: 5)
            .getDocuments()

        for document in emailSnapshot.documents {
            let data = document.data()
            let uid = data["uid"] as? String ?? document.documentID

            // Ne pas inclure l'utilisateur actuel
            if uid == Auth.auth().currentUser?.uid { continue }
            if userIds.contains(uid) { continue }
            userIds.insert(uid)

            if let user = parseUserData(from: data, uid: uid) {
                users.append(user)
            }
        }

        return users
    }

    /// Parse les données Firestore en UserData
    private func parseUserData(from data: [String: Any], uid: String) -> UserData? {
        let email = data["email"] as? String ?? ""
        let username = data["username"] as? String ?? ""
        let displayName = data["displayName"] as? String
        let genderString = data["gender"] as? String ?? Gender.notSpecified.rawValue
        let gender = Gender(rawValue: genderString) ?? .notSpecified
        let birthDateTimestamp = data["birthDate"] as? Timestamp ?? Timestamp(date: Date())
        let createdAtTimestamp = data["createdAt"] as? Timestamp ?? Timestamp(date: Date())
        let profileImageURL = data["profileImageURL"] as? String

        return UserData(
            uid: uid,
            email: email,
            username: username,
            displayName: displayName,
            gender: gender,
            birthDate: birthDateTimestamp.dateValue(),
            createdAt: createdAtTimestamp.dateValue(),
            profileImageURL: profileImageURL
        )
    }

    // MARK: - Demandes d'amis

    /// Envoyer une demande d'ami
    func sendFriendRequest(to userId: String) async throws {
        guard let currentUser = Auth.auth().currentUser else {
            throw NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Utilisateur non connecté"])
        }

        // S'assurer que le profil Firestore de l'utilisateur courant existe/est normalisé
        try? await UserManager.shared.ensureCurrentUserProfile()

        // Récupérer les infos de l'utilisateur actuel
        guard let currentUserData = try await UserManager.shared.getUserProfile(uid: currentUser.uid) else {
            throw NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Profil utilisateur introuvable"])
        }

        // Vérifier qu'il n'y a pas déjà une demande en attente
        let existingRequest = try await db.collection("friendRequests")
            .whereField("fromUserId", isEqualTo: currentUser.uid)
            .whereField("toUserId", isEqualTo: userId)
            .whereField("status", isEqualTo: FriendRequestStatus.pending.rawValue)
            .getDocuments()

        if !existingRequest.documents.isEmpty {
            throw NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Une demande d'ami est déjà en attente"])
        }

        // Vérifier qu'ils ne sont pas déjà amis
        let areFriends = try await checkFriendship(with: userId)
        if areFriends {
            throw NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Vous êtes déjà amis"])
        }

        // Créer la demande
        let requestId = UUID().uuidString
        let request = FriendRequest(
            id: requestId,
            fromUserId: currentUser.uid,
            fromUsername: currentUserData.username,
            fromDisplayName: currentUserData.displayName,
            toUserId: userId,
            status: .pending,
            createdAt: Date()
        )

        try await db.collection("friendRequests").document(requestId).setData(request.dictionary)
    }

    /// Récupérer les demandes d'amis reçues
    func getPendingFriendRequests() async throws -> [FriendRequest] {
        guard let currentUser = Auth.auth().currentUser else {
            return []
        }

        let snapshot = try await db.collection("friendRequests")
            .whereField("toUserId", isEqualTo: currentUser.uid)
            .whereField("status", isEqualTo: FriendRequestStatus.pending.rawValue)
            .order(by: "createdAt", descending: true)
            .getDocuments()

        var requests: [FriendRequest] = []
        for document in snapshot.documents {
            let data = document.data()
            let request = FriendRequest(
                id: data["id"] as? String ?? document.documentID,
                fromUserId: data["fromUserId"] as? String ?? "",
                fromUsername: data["fromUsername"] as? String ?? "",
                fromDisplayName: data["fromDisplayName"] as? String,
                toUserId: data["toUserId"] as? String ?? "",
                status: FriendRequestStatus(rawValue: data["status"] as? String ?? "pending") ?? .pending,
                createdAt: (data["createdAt"] as? Timestamp)?.dateValue() ?? Date()
            )
            requests.append(request)
        }

        return requests
    }

    /// Accepter une demande d'ami
    func acceptFriendRequest(_ requestId: String) async throws {
        guard let currentUser = Auth.auth().currentUser else {
            throw NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Utilisateur non connecté"])
        }

        // Récupérer la demande
        let requestDoc = try await db.collection("friendRequests").document(requestId).getDocument()
        guard let data = requestDoc.data() else {
            throw NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Demande introuvable"])
        }

        let fromUserId = data["fromUserId"] as? String ?? ""
        let toUserId = data["toUserId"] as? String ?? ""

        // Vérifier que c'est bien notre demande
        guard toUserId == currentUser.uid else {
            throw NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Cette demande ne vous est pas destinée"])
        }

        // Mettre à jour le statut de la demande
        try await db.collection("friendRequests").document(requestId).updateData([
            "status": FriendRequestStatus.accepted.rawValue
        ])

        // Créer la relation d'amitié
        let friendshipId = UUID().uuidString
        let friendship = [
            "id": friendshipId,
            "user1Id": fromUserId,
            "user2Id": toUserId,
            "createdAt": Timestamp(date: Date())
        ] as [String: Any]

        try await db.collection("friendships").document(friendshipId).setData(friendship)
    }

    /// Refuser une demande d'ami
    func rejectFriendRequest(_ requestId: String) async throws {
        try await db.collection("friendRequests").document(requestId).updateData([
            "status": FriendRequestStatus.rejected.rawValue
        ])
    }

    // MARK: - Amis

    /// Vérifier si deux utilisateurs sont amis
    func checkFriendship(with userId: String) async throws -> Bool {
        guard let currentUser = Auth.auth().currentUser else {
            return false
        }

        let snapshot1 = try await db.collection("friendships")
            .whereField("user1Id", isEqualTo: currentUser.uid)
            .whereField("user2Id", isEqualTo: userId)
            .getDocuments()

        if !snapshot1.documents.isEmpty {
            return true
        }

        let snapshot2 = try await db.collection("friendships")
            .whereField("user1Id", isEqualTo: userId)
            .whereField("user2Id", isEqualTo: currentUser.uid)
            .getDocuments()

        return !snapshot2.documents.isEmpty
    }

    /// Récupérer la liste des amis
    func getFriends() async throws -> [UserData] {
        guard let currentUser = Auth.auth().currentUser else {
            return []
        }

        // Récupérer les friendships où on est user1
        let snapshot1 = try await db.collection("friendships")
            .whereField("user1Id", isEqualTo: currentUser.uid)
            .getDocuments()

        // Récupérer les friendships où on est user2
        let snapshot2 = try await db.collection("friendships")
            .whereField("user2Id", isEqualTo: currentUser.uid)
            .getDocuments()

        var friendIds: [String] = []

        for document in snapshot1.documents {
            if let friendId = document.data()["user2Id"] as? String {
                friendIds.append(friendId)
            }
        }

        for document in snapshot2.documents {
            if let friendId = document.data()["user1Id"] as? String {
                friendIds.append(friendId)
            }
        }

        // Récupérer les profils des amis
        var friends: [UserData] = []
        for friendId in friendIds {
            if let friendData = try await UserManager.shared.getUserProfile(uid: friendId) {
                friends.append(friendData)
            }
        }

        return friends
    }

    /// Supprimer un ami
    func removeFriend(_ userId: String) async throws {
        guard let currentUser = Auth.auth().currentUser else {
            throw NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Utilisateur non connecté"])
        }

        // Trouver la friendship
        let snapshot1 = try await db.collection("friendships")
            .whereField("user1Id", isEqualTo: currentUser.uid)
            .whereField("user2Id", isEqualTo: userId)
            .getDocuments()

        for document in snapshot1.documents {
            try await document.reference.delete()
        }

        let snapshot2 = try await db.collection("friendships")
            .whereField("user1Id", isEqualTo: userId)
            .whereField("user2Id", isEqualTo: currentUser.uid)
            .getDocuments()

        for document in snapshot2.documents {
            try await document.reference.delete()
        }
    }

    // MARK: - Charger la liste des amis

    func loadFriends() async {
        guard let currentUser = Auth.auth().currentUser else { return }

        do {
            // Récupérer les friendships où l'utilisateur est user1
            let snapshot1 = try await db.collection("friendships")
                .whereField("user1Id", isEqualTo: currentUser.uid)
                .getDocuments()

            // Récupérer les friendships où l'utilisateur est user2
            let snapshot2 = try await db.collection("friendships")
                .whereField("user2Id", isEqualTo: currentUser.uid)
                .getDocuments()

            // Collecter tous les IDs d'amis
            var friendIds = Set<String>()
            for doc in snapshot1.documents {
                if let user2Id = doc.data()["user2Id"] as? String {
                    friendIds.insert(user2Id)
                }
            }
            for doc in snapshot2.documents {
                if let user1Id = doc.data()["user1Id"] as? String {
                    friendIds.insert(user1Id)
                }
            }

            // Charger les données des amis
            var loadedFriends: [UserData] = []
            for friendId in friendIds {
                if let friendData = try await UserManager.shared.getUserProfile(uid: friendId) {
                    loadedFriends.append(friendData)
                }
            }

            await MainActor.run {
                self.friends = loadedFriends
            }
        } catch {
            print("Erreur de chargement des amis: \(error.localizedDescription)")
        }
    }
}
