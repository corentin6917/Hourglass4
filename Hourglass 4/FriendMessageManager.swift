//
//  FriendMessageManager.swift
//  Hourglass 4
//
//  Gère les messages entre amis via Firestore
//

import Foundation
import FirebaseFirestore
import FirebaseAuth

/// Représente un message entre amis dans Firestore
struct FriendMessage: Identifiable, Codable {
    let id: String
    let fromUserId: String
    let toUserId: String
    let text: String
    let createdAt: Date
    let isRead: Bool

    // Informations du sender (pour l'affichage)
    var fromUser: UserData?
}

class FriendMessageManager {
    static let shared = FriendMessageManager()
    private let db = Firestore.firestore()

    private init() {}

    // MARK: - Envoyer un message

    /// Envoie un message à un ami
    func sendMessage(to userId: String, text: String) async throws {
        guard let currentUserId = Auth.auth().currentUser?.uid else {
            throw NSError(domain: "FriendMessage", code: 401, userInfo: [NSLocalizedDescriptionKey: "Non authentifié"])
        }

        // Vérifier qu'on ne s'envoie pas à soi-même
        guard currentUserId != userId else {
            throw NSError(domain: "FriendMessage", code: 400, userInfo: [NSLocalizedDescriptionKey: "Vous ne pouvez pas vous envoyer un message à vous-même"])
        }

        // Vérifier que le texte n'est pas vide
        let trimmedText = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedText.isEmpty else {
            throw NSError(domain: "FriendMessage", code: 400, userInfo: [NSLocalizedDescriptionKey: "Le message ne peut pas être vide"])
        }

        // Créer le message dans Firestore
        let message: [String: Any] = [
            "fromUserId": currentUserId,
            "toUserId": userId,
            "text": trimmedText,
            "createdAt": Timestamp(date: Date()),
            "isRead": false
        ]

        try await db.collection("friendMessages").addDocument(data: message)

        // Nettoyage automatique : garder seulement les 100 derniers messages
        // On le fait en arrière-plan sans bloquer l'envoi
        Task {
            try? await cleanOldMessages(with: userId, keepLast: 100)
        }
    }

    // MARK: - Récupérer les messages reçus

    /// Récupère tous les messages reçus par l'utilisateur actuel
    func getReceivedMessages() async throws -> [FriendMessage] {
        guard let currentUserId = Auth.auth().currentUser?.uid else {
            throw NSError(domain: "FriendMessage", code: 401, userInfo: [NSLocalizedDescriptionKey: "Non authentifié"])
        }

        let snapshot = try await db.collection("friendMessages")
            .whereField("toUserId", isEqualTo: currentUserId)
            .order(by: "createdAt", descending: true)
            .getDocuments()

        var messages: [FriendMessage] = []

        for document in snapshot.documents {
            let data = document.data()

            guard let fromUserId = data["fromUserId"] as? String,
                  let toUserId = data["toUserId"] as? String,
                  let text = data["text"] as? String,
                  let timestamp = data["createdAt"] as? Timestamp else {
                continue
            }

            let isRead = data["isRead"] as? Bool ?? false

            // Récupérer les infos du sender
            var fromUser: UserData?
            do {
                fromUser = try await UserManager.shared.getUserProfile(uid: fromUserId)
            } catch {
                print("Erreur lors de la récupération de l'utilisateur: \(error)")
            }

            let message = FriendMessage(
                id: document.documentID,
                fromUserId: fromUserId,
                toUserId: toUserId,
                text: text,
                createdAt: timestamp.dateValue(),
                isRead: isRead,
                fromUser: fromUser
            )

            messages.append(message)
        }

        return messages
    }

    // MARK: - Récupérer les messages envoyés

    /// Récupère tous les messages envoyés par l'utilisateur actuel
    func getSentMessages() async throws -> [FriendMessage] {
        guard let currentUserId = Auth.auth().currentUser?.uid else {
            throw NSError(domain: "FriendMessage", code: 401, userInfo: [NSLocalizedDescriptionKey: "Non authentifié"])
        }

        let snapshot = try await db.collection("friendMessages")
            .whereField("fromUserId", isEqualTo: currentUserId)
            .order(by: "createdAt", descending: true)
            .getDocuments()

        var messages: [FriendMessage] = []

        for document in snapshot.documents {
            let data = document.data()

            guard let fromUserId = data["fromUserId"] as? String,
                  let toUserId = data["toUserId"] as? String,
                  let text = data["text"] as? String,
                  let timestamp = data["createdAt"] as? Timestamp else {
                continue
            }

            let isRead = data["isRead"] as? Bool ?? false

            let message = FriendMessage(
                id: document.documentID,
                fromUserId: fromUserId,
                toUserId: toUserId,
                text: text,
                createdAt: timestamp.dateValue(),
                isRead: isRead
            )

            messages.append(message)
        }

        return messages
    }

    // MARK: - Récupérer une conversation

    /// Récupère les 100 derniers messages d'une conversation avec un utilisateur (dans les deux sens)
    func getConversation(with userId: String, limit: Int = 100) async throws -> [FriendMessage] {
        guard let currentUserId = Auth.auth().currentUser?.uid else {
            throw NSError(domain: "FriendMessage", code: 401, userInfo: [NSLocalizedDescriptionKey: "Non authentifié"])
        }

        // Récupérer les messages envoyés par l'utilisateur actuel (triés par date décroissante)
        let sentSnapshot = try await db.collection("friendMessages")
            .whereField("fromUserId", isEqualTo: currentUserId)
            .whereField("toUserId", isEqualTo: userId)
            .order(by: "createdAt", descending: true)
            .limit(to: limit)
            .getDocuments()

        // Récupérer les messages reçus de l'autre utilisateur (triés par date décroissante)
        let receivedSnapshot = try await db.collection("friendMessages")
            .whereField("fromUserId", isEqualTo: userId)
            .whereField("toUserId", isEqualTo: currentUserId)
            .order(by: "createdAt", descending: true)
            .limit(to: limit)
            .getDocuments()

        var messages: [FriendMessage] = []

        // Traiter les messages envoyés
        for document in sentSnapshot.documents {
            let data = document.data()

            guard let fromUserId = data["fromUserId"] as? String,
                  let toUserId = data["toUserId"] as? String,
                  let text = data["text"] as? String,
                  let timestamp = data["createdAt"] as? Timestamp else {
                continue
            }

            let isRead = data["isRead"] as? Bool ?? false

            let message = FriendMessage(
                id: document.documentID,
                fromUserId: fromUserId,
                toUserId: toUserId,
                text: text,
                createdAt: timestamp.dateValue(),
                isRead: isRead,
                fromUser: nil
            )

            messages.append(message)
        }

        // Traiter les messages reçus
        for document in receivedSnapshot.documents {
            let data = document.data()

            guard let fromUserId = data["fromUserId"] as? String,
                  let toUserId = data["toUserId"] as? String,
                  let text = data["text"] as? String,
                  let timestamp = data["createdAt"] as? Timestamp else {
                continue
            }

            let isRead = data["isRead"] as? Bool ?? false

            // Récupérer les infos du sender
            var fromUser: UserData?
            do {
                fromUser = try await UserManager.shared.getUserProfile(uid: fromUserId)
            } catch {
                print("Erreur lors de la récupération de l'utilisateur: \(error)")
            }

            let message = FriendMessage(
                id: document.documentID,
                fromUserId: fromUserId,
                toUserId: toUserId,
                text: text,
                createdAt: timestamp.dateValue(),
                isRead: isRead,
                fromUser: fromUser
            )

            messages.append(message)
        }

        return messages
    }

    // MARK: - Marquer comme lu

    /// Marque un message comme lu
    func markAsRead(messageId: String) async throws {
        try await db.collection("friendMessages")
            .document(messageId)
            .updateData(["isRead": true])
    }

    /// Marque tous les messages d'un expéditeur comme lus
    func markAllAsRead(from userId: String) async throws {
        guard let currentUserId = Auth.auth().currentUser?.uid else {
            throw NSError(domain: "FriendMessage", code: 401, userInfo: [NSLocalizedDescriptionKey: "Non authentifié"])
        }

        let snapshot = try await db.collection("friendMessages")
            .whereField("toUserId", isEqualTo: currentUserId)
            .whereField("fromUserId", isEqualTo: userId)
            .whereField("isRead", isEqualTo: false)
            .getDocuments()

        let batch = db.batch()

        for document in snapshot.documents {
            batch.updateData(["isRead": true], forDocument: document.reference)
        }

        try await batch.commit()
    }

    // MARK: - Compter les messages non lus

    /// Compte le nombre de messages non lus
    func getUnreadMessagesCount() async throws -> Int {
        guard let currentUserId = Auth.auth().currentUser?.uid else {
            return 0
        }

        let snapshot = try await db.collection("friendMessages")
            .whereField("toUserId", isEqualTo: currentUserId)
            .whereField("isRead", isEqualTo: false)
            .getDocuments()

        return snapshot.documents.count
    }

    // MARK: - Supprimer un message

    /// Supprime un message
    func deleteMessage(messageId: String) async throws {
        try await db.collection("friendMessages")
            .document(messageId)
            .delete()
    }

    // MARK: - Nettoyage automatique

    /// Nettoie les messages d'une conversation, ne garde que les 100 derniers
    func cleanOldMessages(with userId: String, keepLast: Int = 100) async throws {
        guard let currentUserId = Auth.auth().currentUser?.uid else {
            throw NSError(domain: "FriendMessage", code: 401, userInfo: [NSLocalizedDescriptionKey: "Non authentifié"])
        }

        // Récupérer tous les messages de la conversation (dans les deux sens)
        let allMessages = try await getConversation(with: userId, limit: 1000)

        // Si on a plus de keepLast messages, supprimer les plus anciens
        if allMessages.count > keepLast {
            // Trier par date (plus récents en premier)
            let sortedMessages = allMessages.sorted { $0.createdAt > $1.createdAt }

            // Garder les keepLast premiers, supprimer le reste
            let messagesToDelete = sortedMessages.dropFirst(keepLast)

            // Supprimer par batch (max 500 à la fois pour Firestore)
            let batch = db.batch()
            var batchCount = 0

            for message in messagesToDelete {
                let docRef = db.collection("friendMessages").document(message.id)
                batch.deleteDocument(docRef)
                batchCount += 1

                // Firestore limite à 500 opérations par batch
                if batchCount >= 500 {
                    try await batch.commit()
                    batchCount = 0
                }
            }

            // Commit le dernier batch s'il reste des opérations
            if batchCount > 0 {
                try await batch.commit()
            }

            print("🧹 Nettoyage : \(messagesToDelete.count) messages supprimés, \(keepLast) conservés")
        }
    }
}
