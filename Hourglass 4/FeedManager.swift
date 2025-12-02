//
//  FeedManager.swift
//  Hourglass 4
//
//  Génère le fil d'actualité (posts des comptes suivis)
//

import Foundation
import FirebaseAuth
import FirebaseFirestore

final class FeedManager {
    static let shared = FeedManager()
    private let db = Firestore.firestore()
    private init() {}

    /// Récupère le feed pour l'utilisateur courant: posts des comptes suivis, triés du plus récent au plus ancien
    func getMyFeed(limit: Int = 50) async throws -> [PostData] {
        guard let currentUser = Auth.auth().currentUser else { return [] }

        // 1) Récupérer la liste des UID suivis
        let followingSnap = try await db.collection("users").document(currentUser.uid)
            .collection("following").getDocuments()
        let followedIds = followingSnap.documents.map { $0.documentID }
        if followedIds.isEmpty { return [] }

        // 2) Récupérer les posts de ces UID (Firestore ne gère pas nativement IN sur un grand set; on boucle)
        var allPosts: [PostData] = []
        for uid in followedIds {
            let snap = try await db.collection("posts")
                .whereField("uid_auteur", isEqualTo: uid)
                .order(by: "timestamp", descending: true)
                .limit(to: limit)
                .getDocuments()

            for doc in snap.documents {
                let data = doc.data()
                let author = data["uid_auteur"] as? String ?? ""
                let content = data["contenu_texte"] as? String ?? ""
                let ts = (data["timestamp"] as? Timestamp)?.dateValue() ?? Date()
                let likes = data["nombre_likes"] as? Int ?? 0
                let comments = data["nombre_commentaires"] as? Int ?? 0
                allPosts.append(PostData(id: doc.documentID, authorUID: author, content: content, timestamp: ts, likesCount: likes, commentsCount: comments))
            }
        }

        // 3) Trier globalement côté client (plus récent d'abord) et tronquer au besoin
        allPosts.sort { $0.timestamp > $1.timestamp }
        if allPosts.count > limit {
            return Array(allPosts.prefix(limit))
        } else {
            return allPosts
        }
    }
}
