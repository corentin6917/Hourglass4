// DebugMaintenance.swift
// Utilitaires de maintenance pour le développement (DEBUG seulement)

import Foundation
#if DEBUG
import FirebaseFirestore
import FirebaseDataConnect
import Default

/// Utilitaires pour nettoyer des usernames orphelins en DEV
public enum DebugMaintenance {
    /// Supprime tous les documents Firestore dans `users` qui matchent `username_lower == username.lowercased()`
    public static func freeUsernameInFirestore(_ username: String) async throws {
        let normalized = username.lowercased()
        let db = Firestore.firestore()
        let snap = try await db.collection("users")
            .whereField("username_lower", isEqualTo: normalized)
            .getDocuments()
        for doc in snap.documents {
            try await doc.reference.delete()
        }
    }

    /// Supprime l'utilisateur côté Firebase Data Connect via l'opération générée
    public static func freeUsernameInDataConnect(_ username: String) async throws {
        let _ = try await DataConnect.defaultConnector
            .deleteUserByUsernameMutation
            .execute(username: username)
    }

    /// Tente de libérer le username partout (Firestore + Data Connect)
    public static func freeUsernameEverywhere(_ username: String) async {
        do {
            try await freeUsernameInFirestore(username)
        } catch {
            print("[DebugMaintenance] Firestore cleanup error: \(error)")
        }
        do {
            try await freeUsernameInDataConnect(username)
        } catch {
            print("[DebugMaintenance] Data Connect cleanup error: \(error)")
        }
    }
}
#endif
