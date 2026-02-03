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

        // Keep everything on /users/{uid} to stay compatible with current Firestore rules.
        try await userRef.setData([
            "pinnedGoalKeys": FieldValue.arrayUnion([goalKey]),
            "pinnedGoalsMeta.\(goalKey)": goalData,
        ], merge: true)
    }

    func unpinGoal(_ goalKey: String, userId: String) async throws {
        let userRef = db.collection("users").document(userId)

        // Remove key + metadata from /users/{uid}
        try await userRef.setData([
            "pinnedGoalKeys": FieldValue.arrayRemove([goalKey]),
            "pinnedGoalsMeta.\(goalKey)": FieldValue.delete(),
        ], merge: true)
    }

    // MARK: - Load Pinned Goals

    func loadPinnedGoals(userId: String) async throws -> [[String: Any]] {
        let userDoc = try await db.collection("users").document(userId).getDocument()
        let metadata = userDoc.data()?["pinnedGoalsMeta"] as? [String: Any] ?? [:]
        return metadata.values.compactMap { $0 as? [String: Any] }
    }
}
