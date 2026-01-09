//
//  GrainTransferManager.swift
//  Hourglass 4
//
//  Gère les transfusions de grains entre amis via Firestore
//

import Foundation
import FirebaseFirestore
import FirebaseAuth

/// Représente une transfusion de grain dans Firestore
struct GrainTransfer: Identifiable, Codable {
    let id: String
    let fromUserId: String
    let toUserId: String
    let grainAmount: Double
    let createdAt: Date
    let message: String?

    // Informations du sender (pour l'affichage)
    var fromUser: UserData?
}

class GrainTransferManager {
    static let shared = GrainTransferManager()
    private let db = Firestore.firestore()

    private init() {}

    // MARK: - Envoyer une transfusion

    /// Transfuse un grain à un ami
    func transferGrain(to userId: String, amount: Double = 1.0, message: String? = nil) async throws {
        guard let currentUserId = Auth.auth().currentUser?.uid else {
            throw NSError(domain: "GrainTransfer", code: 401, userInfo: [NSLocalizedDescriptionKey: "Non authentifié"])
        }

        // Vérifier qu'on ne s'envoie pas à soi-même
        guard currentUserId != userId else {
            throw NSError(domain: "GrainTransfer", code: 400, userInfo: [NSLocalizedDescriptionKey: "Vous ne pouvez pas vous transfuser des grains à vous-même"])
        }

        // Créer la transfusion dans Firestore
        let transfer: [String: Any] = [
            "fromUserId": currentUserId,
            "toUserId": userId,
            "grainAmount": amount,
            "createdAt": Timestamp(date: Date()),
            "message": message as Any
        ]

        try await db.collection("grainTransfers").addDocument(data: transfer)
    }

    // MARK: - Récupérer les transfusions reçues

    /// Récupère toutes les transfusions reçues par l'utilisateur actuel
    func getReceivedTransfers() async throws -> [GrainTransfer] {
        guard let currentUserId = Auth.auth().currentUser?.uid else {
            throw NSError(domain: "GrainTransfer", code: 401, userInfo: [NSLocalizedDescriptionKey: "Non authentifié"])
        }

        let snapshot = try await db.collection("grainTransfers")
            .whereField("toUserId", isEqualTo: currentUserId)
            .order(by: "createdAt", descending: true)
            .getDocuments()

        var transfers: [GrainTransfer] = []

        for document in snapshot.documents {
            let data = document.data()

            guard let fromUserId = data["fromUserId"] as? String,
                  let toUserId = data["toUserId"] as? String,
                  let grainAmount = data["grainAmount"] as? Double,
                  let timestamp = data["createdAt"] as? Timestamp else {
                continue
            }

            let message = data["message"] as? String

            // Récupérer les infos du sender
            var fromUser: UserData?
            do {
                fromUser = try await UserManager.shared.getUserProfile(uid: fromUserId)
            } catch {
                print("Erreur lors de la récupération de l'utilisateur: \(error)")
            }

            let transfer = GrainTransfer(
                id: document.documentID,
                fromUserId: fromUserId,
                toUserId: toUserId,
                grainAmount: grainAmount,
                createdAt: timestamp.dateValue(),
                message: message,
                fromUser: fromUser
            )

            transfers.append(transfer)
        }

        return transfers
    }

    // MARK: - Récupérer les transfusions envoyées

    /// Récupère toutes les transfusions envoyées par l'utilisateur actuel
    func getSentTransfers() async throws -> [GrainTransfer] {
        guard let currentUserId = Auth.auth().currentUser?.uid else {
            throw NSError(domain: "GrainTransfer", code: 401, userInfo: [NSLocalizedDescriptionKey: "Non authentifié"])
        }

        let snapshot = try await db.collection("grainTransfers")
            .whereField("fromUserId", isEqualTo: currentUserId)
            .order(by: "createdAt", descending: true)
            .getDocuments()

        var transfers: [GrainTransfer] = []

        for document in snapshot.documents {
            let data = document.data()

            guard let fromUserId = data["fromUserId"] as? String,
                  let toUserId = data["toUserId"] as? String,
                  let grainAmount = data["grainAmount"] as? Double,
                  let timestamp = data["createdAt"] as? Timestamp else {
                continue
            }

            let message = data["message"] as? String

            let transfer = GrainTransfer(
                id: document.documentID,
                fromUserId: fromUserId,
                toUserId: toUserId,
                grainAmount: grainAmount,
                createdAt: timestamp.dateValue(),
                message: message
            )

            transfers.append(transfer)
        }

        return transfers
    }

    // MARK: - Compter les transfusions non lues

    /// Compte le nombre de transfusions non lues (reçues dans les dernières 24h)
    func getUnreadTransfersCount() async throws -> Int {
        guard let currentUserId = Auth.auth().currentUser?.uid else {
            return 0
        }

        let yesterday = AppTimeZone.calendar.date(byAdding: .day, value: -1, to: Date()) ?? Date()

        let snapshot = try await db.collection("grainTransfers")
            .whereField("toUserId", isEqualTo: currentUserId)
            .whereField("createdAt", isGreaterThan: Timestamp(date: yesterday))
            .getDocuments()

        return snapshot.documents.count
    }
}
