//
//  VictoryManager.swift
//  Hourglass 4
//
//  Manager pour le fil des victoires (Victory Feed)
//

import Foundation
import Combine
import FirebaseAuth
import FirebaseFirestore
import FirebaseStorage

class VictoryManager: ObservableObject {
    static let shared = VictoryManager()

    private let db = Firestore.firestore()
    private let storage = Storage.storage()

    @Published var victories: [Victory] = []
    @Published var isLoading = false

    private init() {}

    // MARK: - Créer une victoire

    func createVictory(goalTitle: String, goalEmoji: String, photoImage: UIImage) async throws -> Victory {
        guard let currentUser = Auth.auth().currentUser else {
            throw NSError(domain: "VictoryManager", code: 401, userInfo: [NSLocalizedDescriptionKey: "Utilisateur non connecté"])
        }

        // 1. Récupérer les infos utilisateur
        let userData = try await UserManager.shared.getUserProfile(uid: currentUser.uid)

        guard let userData = userData else {
            throw NSError(domain: "VictoryManager", code: 404, userInfo: [NSLocalizedDescriptionKey: "Profil utilisateur introuvable"])
        }

        // 2. Upload de la photo
        let photoURL = try await uploadVictoryPhoto(photoImage, userId: currentUser.uid)

        // 3. Créer la victoire
        let victory = Victory(
            userId: currentUser.uid,
            username: userData.username,
            displayName: userData.displayName,
            profileImageURL: userData.profileImageURL,
            goalTitle: goalTitle,
            goalEmoji: goalEmoji,
            photoURL: photoURL
        )

        // 4. Sauvegarder dans Firestore
        try await db.collection("victories").document(victory.victoryId).setData(victory.dictionary)

        return victory
    }

    // MARK: - Upload photo de victoire

    private func uploadVictoryPhoto(_ image: UIImage, userId: String) async throws -> String {
        // Compression
        guard let resizedImage = resizeImage(image, maxSize: 1200),
              let imageData = resizedImage.jpegData(compressionQuality: 0.8) else {
            throw NSError(domain: "VictoryManager", code: 400, userInfo: [NSLocalizedDescriptionKey: "Impossible de compresser l'image"])
        }

        // Vérifier la taille (max 10MB)
        let maxSize = 10 * 1024 * 1024
        guard imageData.count <= maxSize else {
            throw NSError(domain: "VictoryManager", code: 400, userInfo: [NSLocalizedDescriptionKey: "Image trop grande (max 10MB)"])
        }

        // Upload vers Storage: victories/{userId}/{timestamp}.jpg
        let timestamp = Int(Date().timeIntervalSince1970)
        let storageRef = storage.reference()
        let photoRef = storageRef.child("victories/\(userId)/\(timestamp).jpg")

        let metadata = StorageMetadata()
        metadata.contentType = "image/jpeg"

        _ = try await photoRef.putDataAsync(imageData, metadata: metadata)
        let downloadURL = try await photoRef.downloadURL()

        return downloadURL.absoluteString
    }

    private func resizeImage(_ image: UIImage, maxSize: CGFloat) -> UIImage? {
        let size = image.size
        let ratio = size.width / size.height

        var newSize: CGSize
        if size.width > size.height {
            newSize = CGSize(width: maxSize, height: maxSize / ratio)
        } else {
            newSize = CGSize(width: maxSize * ratio, height: maxSize)
        }

        UIGraphicsBeginImageContextWithOptions(newSize, false, 1.0)
        image.draw(in: CGRect(origin: .zero, size: newSize))
        let resizedImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()

        return resizedImage
    }

    // MARK: - Charger le fil des victoires

    func loadVictoryFeed(friendIds: [String]) async throws {
        await MainActor.run {
            isLoading = true
        }

        // Récupérer les victoires des amis (non expirées)
        let now = Date()
        let snapshot = try await db.collection("victories")
            .whereField("userId", in: friendIds.isEmpty ? ["dummy"] : friendIds)
            .whereField("expiresAt", isGreaterThan: Timestamp(date: now))
            .order(by: "expiresAt", descending: false)
            .order(by: "createdAt", descending: true)
            .limit(to: 50)
            .getDocuments()

        let loadedVictories = snapshot.documents.compactMap { Victory.from(document: $0) }

        await MainActor.run {
            self.victories = loadedVictories
            self.isLoading = false
        }
    }

    // MARK: - Booster une victoire (Éclat de Grain)

    func boostVictory(_ victory: Victory) async throws {
        guard let currentUserId = Auth.auth().currentUser?.uid else {
            throw NSError(domain: "VictoryManager", code: 401)
        }

        // Vérifier que l'utilisateur n'a pas déjà boosté
        if victory.boostedBy.contains(currentUserId) {
            throw NSError(domain: "VictoryManager", code: 409, userInfo: [NSLocalizedDescriptionKey: "Vous avez déjà boosté cette victoire"])
        }

        // Mettre à jour la victoire
        try await db.collection("victories").document(victory.victoryId).updateData([
            "boostCount": FieldValue.increment(Int64(1)),
            "boostedBy": FieldValue.arrayUnion([currentUserId])
        ])

        // TODO: Déduire 0.2 grain du booster et ajouter 0.2 grain au créateur
        // TODO: Créer une notification pour le créateur
    }

    // MARK: - Commenter une victoire

    func commentVictory(_ victory: Victory, text: String) async throws {
        guard let currentUser = Auth.auth().currentUser else {
            throw NSError(domain: "VictoryManager", code: 401)
        }

        let userData = try await UserManager.shared.getUserProfile(uid: currentUser.uid)
        guard let userData = userData else {
            throw NSError(domain: "VictoryManager", code: 404)
        }

        let comment = VictoryComment(
            commentId: UUID().uuidString,
            victoryId: victory.victoryId,
            userId: currentUser.uid,
            username: userData.username,
            displayName: userData.displayName,
            profileImageURL: userData.profileImageURL,
            text: text,
            createdAt: Date()
        )

        // Sauvegarder le commentaire
        try await db.collection("victories").document(victory.victoryId)
            .collection("comments").document(comment.commentId)
            .setData(comment.dictionary)

        // Incrémenter le compteur
        try await db.collection("victories").document(victory.victoryId).updateData([
            "commentCount": FieldValue.increment(Int64(1))
        ])

        // TODO: Déduire 0.1 grain du commentateur
        // TODO: Créer une notification pour le créateur
    }

    // MARK: - Charger les commentaires

    func loadComments(for victoryId: String) async throws -> [VictoryComment] {
        let snapshot = try await db.collection("victories").document(victoryId)
            .collection("comments")
            .order(by: "createdAt", descending: false)
            .getDocuments()

        return snapshot.documents.compactMap { doc in
            let data = doc.data()
            guard let commentId = data["commentId"] as? String,
                  let victoryId = data["victoryId"] as? String,
                  let userId = data["userId"] as? String,
                  let username = data["username"] as? String,
                  let text = data["text"] as? String,
                  let createdAtTimestamp = data["createdAt"] as? Timestamp else {
                return nil
            }

            return VictoryComment(
                commentId: commentId,
                victoryId: victoryId,
                userId: userId,
                username: username,
                displayName: data["displayName"] as? String,
                profileImageURL: data["profileImageURL"] as? String,
                text: text,
                createdAt: createdAtTimestamp.dateValue()
            )
        }
    }

    // MARK: - Nettoyer les victoires expirées (à appeler périodiquement)

    func cleanupExpiredVictories() async throws {
        let now = Date()
        let snapshot = try await db.collection("victories")
            .whereField("expiresAt", isLessThan: Timestamp(date: now))
            .getDocuments()

        for document in snapshot.documents {
            // Supprimer les photos de Storage
            if let photoURL = document.data()["photoURL"] as? String {
                try? await deleteVictoryPhoto(photoURL)
            }

            // Supprimer le document
            try await document.reference.delete()
        }
    }

    private func deleteVictoryPhoto(_ urlString: String) async throws {
        guard let url = URL(string: urlString) else { return }
        let photoRef = storage.reference(forURL: urlString)
        try await photoRef.delete()
    }
}
