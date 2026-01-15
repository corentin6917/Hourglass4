// DebugMaintenance.swift
// Utilitaires de maintenance pour le développement (DEBUG seulement)

import Foundation
#if DEBUG
import FirebaseFirestore

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

    /// Tente de libérer le username partout (Firestore + Data Connect)
    public static func freeUsernameEverywhere(_ username: String) async {
        do {
            try await freeUsernameInFirestore(username)
        } catch {
            print("[DebugMaintenance] Firestore cleanup error: \(error)")
        }
    }
}
#endif
