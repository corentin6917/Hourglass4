//
//  GoalPinManager.swift
//  Hourglass 4
//
//  Manager for pinning completed goals to user profile
//

import Foundation
import FirebaseAuth
import FirebaseFirestore

class GoalPinManager {
    static let shared = GoalPinManager()

    private let db = Firestore.firestore()

    private init() {}

    // MARK: - Pin/Unpin Goals

    func isGoalPinned(_ goalKey: String, userId: String) async throws -> Bool {
        let userDoc = try await db.collection("users").document(userId).getDocument()
        let ids = userDoc.data()?["pinnedGoalKeys"] as? [String] ?? []
        return ids.contains(goalKey)
    }

    func pinGoal(_ goalKey: String, userId: String, goalData: [String: Any]) async throws {
        let userRef = db.collection("users").document(userId)
        let snapshot = try await userRef.getDocument()
        let ids = snapshot.data()?["pinnedGoalKeys"] as? [String] ?? []

        if ids.contains(goalKey) {
            return
        }

        if ids.count >= 10 {
            throw NSError(domain: "GoalPinManager", code: 400, userInfo: [
                NSLocalizedDescriptionKey: "Tu as déjà 10 objectifs épinglés."
            ])
        }

        // Store goal data in a subcollection for easy retrieval
        try await db.collection("users").document(userId)
            .collection("pinnedGoals").document(goalKey)
            .setData(goalData)

        // Add to pinnedGoalKeys array
        try await userRef.updateData([
            "pinnedGoalKeys": FieldValue.arrayUnion([goalKey])
        ])
    }

    func unpinGoal(_ goalKey: String, userId: String) async throws {
        let userRef = db.collection("users").document(userId)

        // Remove from pinnedGoalKeys array
        try await userRef.updateData([
            "pinnedGoalKeys": FieldValue.arrayRemove([goalKey])
        ])

        // Delete goal data from subcollection
        try await db.collection("users").document(userId)
            .collection("pinnedGoals").document(goalKey)
            .delete()
    }

    // MARK: - Load Pinned Goals

    func loadPinnedGoals(userId: String) async throws -> [[String: Any]] {
        let snapshot = try await db.collection("users").document(userId)
            .collection("pinnedGoals")
            .getDocuments()

        return snapshot.documents.map { $0.data() }
    }
}
