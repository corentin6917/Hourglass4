//
//  PostManager.swift
//  Hourglass 4
//
//  Gestion des publications (posts) avec Firestore
//

import Foundation
import FirebaseAuth
import FirebaseFirestore

struct PostData: Identifiable, Codable {
    let id: String
    let authorUID: String
    let content: String
    let timestamp: Date
    let likesCount: Int
    let commentsCount: Int
}

final class PostManager {
    static let shared = PostManager()
    private let db = Firestore.firestore()

    private init() {}

    // MARK: - Create Post

    /// Crée une nouvelle publication pour l'utilisateur courant
    func createPost(content: String) async throws {
        guard let user = Auth.auth().currentUser else {
            throw NSError(domain: "PostManager", code: -1, userInfo: [NSLocalizedDescriptionKey: "Utilisateur non connecté"])
        }

        let data: [String: Any] = [
            "uid_auteur": user.uid,
            "contenu_texte": content.trimmingCharacters(in: .whitespacesAndNewlines),
            "timestamp": FieldValue.serverTimestamp(),
            "nombre_likes": 0,
            "nombre_commentaires": 0
        ]

        _ = try await db.collection("posts").addDocument(data: data)
    }

    // MARK: - Fetch Posts

    /// Récupère les publications d'un utilisateur donné (ordre: plus récent d'abord)
    func getPosts(for uid: String) async throws -> [PostData] {
        let snap = try await db.collection("posts")
            .whereField("uid_auteur", isEqualTo: uid)
            .order(by: "timestamp", descending: true)
            .getDocuments()

        var results: [PostData] = []
        for doc in snap.documents {
            let data = doc.data()

            let author = data["uid_auteur"] as? String ?? ""
            let content = data["contenu_texte"] as? String ?? ""
            let ts = (data["timestamp"] as? Timestamp)?.dateValue() ?? Date()
            let likes = data["nombre_likes"] as? Int ?? 0
            let comments = data["nombre_commentaires"] as? Int ?? 0

            results.append(
                PostData(
                    id: doc.documentID,
                    authorUID: author,
                    content: content,
                    timestamp: ts,
                    likesCount: likes,
                    commentsCount: comments
                )
            )
        }
        return results
    }
}
