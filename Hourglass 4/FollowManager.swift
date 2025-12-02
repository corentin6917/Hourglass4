//
//  FollowManager.swift
//  Hourglass 4
//
//  Gestion des relations de suivi (follow/unfollow) avec Firestore
//

import Foundation
import FirebaseAuth
import FirebaseFirestore

final class FollowManager {
    static let shared = FollowManager()
    private let db = Firestore.firestore()
    private init() {}

    // MARK: - Follow / Unfollow

    /// Suit l'utilisateur cible via un batch (following + followers)
    func follow(userId targetUserUID: String) async throws {
        guard let currentUser = Auth.auth().currentUser else {
            throw NSError(domain: "Follow", code: -1, userInfo: [NSLocalizedDescriptionKey: "Utilisateur non connecté"])
        }
        guard currentUser.uid != targetUserUID else {
            throw NSError(domain: "Follow", code: -2, userInfo: [NSLocalizedDescriptionKey: "Impossible de se suivre soi-même"])
        }

        let batch = db.batch()

        // Ajoute la cible dans la sous-collection `following` du current user
        let followingRef = db.collection("users").document(currentUser.uid)
            .collection("following").document(targetUserUID)
        batch.setData(["timestamp": FieldValue.serverTimestamp()], forDocument: followingRef)

        // Ajoute le current user dans la sous-collection `followers` de la cible
        let followersRef = db.collection("users").document(targetUserUID)
            .collection("followers").document(currentUser.uid)
        batch.setData(["timestamp": FieldValue.serverTimestamp()], forDocument: followersRef)

        try await batch.commit()
    }

    /// Ne suit plus l'utilisateur cible via un batch (suppression croisée)
    func unfollow(userId targetUserUID: String) async throws {
        guard let currentUser = Auth.auth().currentUser else {
            throw NSError(domain: "Follow", code: -1, userInfo: [NSLocalizedDescriptionKey: "Utilisateur non connecté"])
        }
        guard currentUser.uid != targetUserUID else { return }

        let batch = db.batch()

        let followingRef = db.collection("users").document(currentUser.uid)
            .collection("following").document(targetUserUID)
        batch.deleteDocument(followingRef)

        let followersRef = db.collection("users").document(targetUserUID)
            .collection("followers").document(currentUser.uid)
        batch.deleteDocument(followersRef)

        try await batch.commit()
    }

    /// Vérifie si le current user suit déjà `userId`
    func isFollowing(userId: String) async throws -> Bool {
        guard let currentUser = Auth.auth().currentUser else { return false }
        let doc = try await db.collection("users").document(currentUser.uid)
            .collection("following").document(userId).getDocument()
        return doc.exists
    }

    // MARK: - Lists

    /// Récupère la liste des followers d'un utilisateur (UserData)
    func getFollowers(for uid: String? = nil) async throws -> [UserData] {
        let ownerId: String
        if let uid = uid {
            ownerId = uid
        } else {
            guard let currentUser = Auth.auth().currentUser else { return [] }
            ownerId = currentUser.uid
        }

        let snap = try await db.collection("users").document(ownerId)
            .collection("followers").getDocuments()

        var users: [UserData] = []
        for doc in snap.documents {
            let followerId = doc.documentID
            if let data = try await UserManager.shared.getUserProfile(uid: followerId) {
                users.append(data)
            }
        }
        return users
    }

    /// Récupère la liste des comptes suivis (following) d'un utilisateur (UserData)
    func getFollowing(for uid: String? = nil) async throws -> [UserData] {
        let ownerId: String
        if let uid = uid {
            ownerId = uid
        } else {
            guard let currentUser = Auth.auth().currentUser else { return [] }
            ownerId = currentUser.uid
        }

        let snap = try await db.collection("users").document(ownerId)
            .collection("following").getDocuments()

        var users: [UserData] = []
        for doc in snap.documents {
            let followingId = doc.documentID
            if let data = try await UserManager.shared.getUserProfile(uid: followingId) {
                users.append(data)
            }
        }
        return users
    }

    // MARK: - Counts

    func followersCount(for uid: String? = nil) async throws -> Int {
        let ownerId: String
        if let uid = uid {
            ownerId = uid
        } else {
            guard let currentUser = Auth.auth().currentUser else { return 0 }
            ownerId = currentUser.uid
        }
        let snap = try await db.collection("users").document(ownerId)
            .collection("followers").getDocuments()
        return snap.documents.count
    }

    func followingCount(for uid: String? = nil) async throws -> Int {
        let ownerId: String
        if let uid = uid {
            ownerId = uid
        } else {
            guard let currentUser = Auth.auth().currentUser else { return 0 }
            ownerId = currentUser.uid
        }
        let snap = try await db.collection("users").document(ownerId)
            .collection("following").getDocuments()
        return snap.documents.count
    }
}
