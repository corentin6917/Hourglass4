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

    func createVictory(goalTitle: String, goalEmoji: String, photoImage: UIImage, comment: String? = nil) async throws -> Victory {
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
        let trimmedComment = comment?.trimmingCharacters(in: .whitespacesAndNewlines)
        let victory = Victory(
            userId: currentUser.uid,
            username: userData.username,
            displayName: userData.displayName,
            profileImageURL: userData.profileImageURL,
            comment: (trimmedComment?.isEmpty == false) ? trimmedComment : nil,
            goalTitle: goalTitle,
            goalEmoji: goalEmoji,
            photoURL: photoURL
        )

        // 4. Sauvegarder dans Firestore
        try await db.collection("victories").document(victory.victoryId).setData(victory.dictionary)

        return victory
    }

    // MARK: - Mettre à jour le commentaire d'une victoire

    func updateVictoryComment(_ victory: Victory, comment: String?) async throws -> Victory {
        guard let currentUserId = Auth.auth().currentUser?.uid else {
            throw NSError(domain: "VictoryManager", code: 401, userInfo: [NSLocalizedDescriptionKey: "Utilisateur non connecté"])
        }

        guard currentUserId == victory.userId else {
            throw NSError(domain: "VictoryManager", code: 403, userInfo: [NSLocalizedDescriptionKey: "Action non autorisée"])
        }

        let trimmedComment = comment?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        let savedComment: String? = trimmedComment.isEmpty ? nil : trimmedComment

        try await db.collection("victories")
            .document(victory.victoryId)
            .updateData(["comment": trimmedComment])

        let updatedVictory = Victory(
            victoryId: victory.victoryId,
            userId: victory.userId,
            username: victory.username,
            displayName: victory.displayName,
            profileImageURL: victory.profileImageURL,
            comment: savedComment,
            goalTitle: victory.goalTitle,
            goalEmoji: victory.goalEmoji,
            photoURL: victory.photoURL,
            createdAt: victory.createdAt,
            boostCount: victory.boostCount,
            commentCount: victory.commentCount,
            boostedBy: victory.boostedBy
        )

        await MainActor.run {
            if let index = victories.firstIndex(where: { $0.victoryId == victory.victoryId }) {
                victories[index] = updatedVictory
            }
        }

        return updatedVictory
    }

    // MARK: - Commentaire d'une victoire (par id)

    func fetchVictoryComment(victoryId: String) async throws -> String? {
        let snapshot = try await db.collection("victories").document(victoryId).getDocument()
        let comment = snapshot.data()?["comment"] as? String
        let trimmed = comment?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        return trimmed.isEmpty ? nil : trimmed
    }

    func fetchVictoryIdByPhotoURL(_ photoURL: String, userId: String) async throws -> String? {
        let snapshot = try await db.collection("victories")
            .whereField("userId", isEqualTo: userId)
            .whereField("photoURL", isEqualTo: photoURL)
            .limit(to: 1)
            .getDocuments()

        guard let document = snapshot.documents.first else { return nil }
        let victoryId = document.data()["victoryId"] as? String
        return victoryId ?? document.documentID
    }

    func updateVictoryComment(victoryId: String, comment: String?) async throws {
        let trimmed = comment?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""

        try await db.collection("victories")
            .document(victoryId)
            .updateData(["comment": trimmed])

        await MainActor.run {
            if let index = victories.firstIndex(where: { $0.victoryId == victoryId }) {
                let victory = victories[index]
                let updated = Victory(
                    victoryId: victory.victoryId,
                    userId: victory.userId,
                    username: victory.username,
                    displayName: victory.displayName,
                    profileImageURL: victory.profileImageURL,
                    comment: trimmed.isEmpty ? nil : trimmed,
                    goalTitle: victory.goalTitle,
                    goalEmoji: victory.goalEmoji,
                    photoURL: victory.photoURL,
                    createdAt: victory.createdAt,
                    boostCount: victory.boostCount,
                    commentCount: victory.commentCount,
                    boostedBy: victory.boostedBy
                )
                victories[index] = updated
            }
        }
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

        print("=" + String(repeating: "=", count: 60))
        print("🔍 VictoryManager - CHARGEMENT DU FIL DES VICTOIRES")
        print("🔍 VictoryManager - friendIds: \(friendIds)")
        print("🔍 VictoryManager - friendIds.count: \(friendIds.count)")
        print("=" + String(repeating: "=", count: 60))

        // Récupérer les victoires des amis (fil quotidien 21h-21h)
        let now = Date()
        print("🔍 VictoryManager - Date actuelle: \(now)")
        print("✅ MODE PRODUCTION: Seules les victoires visibles (21h-21h) sont affichées")

        // Si pas d'amis, on ne peut pas utiliser la query "in" avec un tableau vide
        if friendIds.isEmpty {
            print("⚠️ VictoryManager - Aucun ami trouvé, impossible de charger les victoires")
            await MainActor.run {
                self.victories = []
                self.isLoading = false
            }
            return
        }

        // Récupérer toutes les victoires récentes des amis (dernières 48h pour couvrir 2 cycles de 24h)
        let twoDaysAgo = AppTimeZone.calendar.date(byAdding: .day, value: -2, to: now) ?? now

        let snapshot = try await db.collection("victories")
            .whereField("userId", in: friendIds)
            .whereField("createdAt", isGreaterThan: Timestamp(date: twoDaysAgo))
            .order(by: "createdAt", descending: true)
            .limit(to: 100)
            .getDocuments()

        print("🔍 VictoryManager - Documents trouvés dans Firestore: \(snapshot.documents.count)")

        // Parser et filtrer les victoires visibles (entre visibleAt et expiresAt)
        let allVictories = snapshot.documents.compactMap { Victory.from(document: $0) }

        // Filtrer uniquement les victoires actuellement visibles
        let loadedVictories = allVictories.filter { victory in
            let isCurrentlyVisible = now >= victory.visibleAt && now <= victory.expiresAt
            if !isCurrentlyVisible {
                print("   ⏭️ Victoire non visible: \(victory.goalEmoji) \(victory.goalTitle)")
                print("      Visible à: \(victory.visibleAt), Expire: \(victory.expiresAt), Maintenant: \(now)")
            }
            return isCurrentlyVisible
        }

        print("🔍 VictoryManager - Victoires parsées avec succès: \(loadedVictories.count)")

        await MainActor.run {
            self.victories = loadedVictories
            self.isLoading = false
        }
    }

    // MARK: - Charger mes victoires actives

    func loadMyActiveVictories() async throws {
        guard let currentUserId = Auth.auth().currentUser?.uid else {
            await MainActor.run {
                self.victories = []
                self.isLoading = false
            }
            return
        }

        await MainActor.run {
            isLoading = true
        }

        let now = Date()
        let twoDaysAgo = AppTimeZone.calendar.date(byAdding: .day, value: -2, to: now) ?? now

        let snapshot = try await db.collection("victories")
            .whereField("userId", isEqualTo: currentUserId)
            .whereField("createdAt", isGreaterThan: Timestamp(date: twoDaysAgo))
            .order(by: "createdAt", descending: true)
            .limit(to: 100)
            .getDocuments()

        let allVictories = snapshot.documents.compactMap { Victory.from(document: $0) }
        let activeVictories = allVictories.filter { victory in
            now >= victory.visibleAt && now <= victory.expiresAt
        }

        await MainActor.run {
            self.victories = activeVictories
            self.isLoading = false
        }
    }

    // MARK: - Booster une victoire (Éclat de Grain)

    func fetchDailyGrainSpent() async throws -> Double {
        guard let currentUserId = Auth.auth().currentUser?.uid else {
            throw NSError(domain: "VictoryManager", code: 401)
        }

        let snapshot = try await db.collection("users").document(currentUserId).getDocument()
        let data = snapshot.data() ?? [:]
        let todayKey = Self.dayKey(for: Date())
        let storedKey = data["dailyGrainSpentDate"] as? String ?? ""
        let spent = data["dailyGrainSpent"] as? Double ?? 0.0

        if storedKey != todayKey {
            return 0.0
        }

        return spent
    }

    // MARK: - Donner 1 grain à une victoire

    func donateGrain(_ victory: Victory, availableBudget: Double) async throws -> Double {
        guard let currentUserId = Auth.auth().currentUser?.uid else {
            throw NSError(domain: "VictoryManager", code: 401)
        }
        let fromUser = try? await UserManager.shared.getUserProfile(uid: currentUserId)

        // Vérifier que l'utilisateur n'a pas déjà donné
        if victory.boostedBy.contains(currentUserId) {
            throw NSError(domain: "VictoryManager", code: 409, userInfo: [NSLocalizedDescriptionKey: "Tu as déjà donné 1 grain à cette victoire"])
        }

        if availableBudget < 1 {
            throw NSError(domain: "VictoryManager", code: 402, userInfo: [NSLocalizedDescriptionKey: "Plus de grains disponibles aujourd'hui"])
        }

        let userRef = db.collection("users").document(currentUserId)
        let userSnapshot = try await userRef.getDocument()
        let userData = userSnapshot.data() ?? [:]
        let todayKey = Self.dayKey(for: Date())
        let storedKey = userData["dailyGrainSpentDate"] as? String ?? ""
        let storedSpent = userData["dailyGrainSpent"] as? Double ?? 0.0
        let currentSpent = (storedKey == todayKey) ? storedSpent : 0.0

        if currentSpent + 1 > availableBudget {
            throw NSError(domain: "VictoryManager", code: 402, userInfo: [NSLocalizedDescriptionKey: "Plus de grains disponibles aujourd'hui"])
        }

        // Mettre à jour la victoire
        try await db.collection("victories").document(victory.victoryId).updateData([
            "boostCount": FieldValue.increment(Int64(1)),
            "boostedBy": FieldValue.arrayUnion([currentUserId])
        ])

        // Mettre à jour le budget consommé du jour
        let newSpent = currentSpent + 1
        try await userRef.updateData([
            "dailyGrainSpent": newSpent,
            "dailyGrainSpentDate": todayKey
        ])

        await MainActor.run {
            if let index = self.victories.firstIndex(where: { $0.victoryId == victory.victoryId }) {
                self.victories[index].boostCount += 1
                self.victories[index].boostedBy.append(currentUserId)
            }
        }

        if let fromUser {
            try? await createBoostNotification(victory: victory, fromUser: fromUser)
        }

        return newSpent
    }

    // MARK: - Retirer 1 grain d'une victoire

    func removeGrain(_ victory: Victory) async throws -> Double {
        guard let currentUserId = Auth.auth().currentUser?.uid else {
            throw NSError(domain: "VictoryManager", code: 401)
        }

        guard victory.boostedBy.contains(currentUserId) else {
            throw NSError(domain: "VictoryManager", code: 409, userInfo: [NSLocalizedDescriptionKey: "Tu n'as pas donné de grain à cette victoire"])
        }

        let userRef = db.collection("users").document(currentUserId)
        let userSnapshot = try await userRef.getDocument()
        let userData = userSnapshot.data() ?? [:]
        let todayKey = Self.dayKey(for: Date())
        let storedKey = userData["dailyGrainSpentDate"] as? String ?? ""
        let storedSpent = userData["dailyGrainSpent"] as? Double ?? 0.0
        let currentSpent = (storedKey == todayKey) ? storedSpent : 0.0

        // Mettre à jour la victoire
        try await db.collection("victories").document(victory.victoryId).updateData([
            "boostCount": FieldValue.increment(Int64(-1)),
            "boostedBy": FieldValue.arrayRemove([currentUserId])
        ])

        // Mettre à jour le budget consommé du jour
        let newSpent = max(currentSpent - 1, 0.0)
        try await userRef.updateData([
            "dailyGrainSpent": newSpent,
            "dailyGrainSpentDate": todayKey
        ])

        await MainActor.run {
            if let index = self.victories.firstIndex(where: { $0.victoryId == victory.victoryId }) {
                self.victories[index].boostCount = max(self.victories[index].boostCount - 1, 0)
                self.victories[index].boostedBy.removeAll { $0 == currentUserId }
            }
        }

        return newSpent
    }

    private static func dayKey(for date: Date) -> String {
        let formatter = DateFormatter()
        formatter.calendar = AppTimeZone.calendar
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = AppTimeZone.current
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: date)
    }

    // MARK: - Commenter une victoire

    func commentVictory(_ victory: Victory, text: String, mentionedUsers: [UserData] = []) async throws {
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
        try await createMentionNotifications(
            victory: victory,
            comment: comment,
            fromUser: userData,
            mentionedUsers: mentionedUsers
        )
        try? await createCommentNotification(victory: victory, comment: comment, fromUser: userData)
    }

    private func createMentionNotifications(
        victory: Victory,
        comment: VictoryComment,
        fromUser: UserData,
        mentionedUsers: [UserData]
    ) async throws {
        guard !mentionedUsers.isEmpty else { return }

        let uniqueUsers = Dictionary(grouping: mentionedUsers, by: { $0.uid }).compactMap { $0.value.first }
        let notificationsRef = db.collection("notifications")

        for user in uniqueUsers {
            if user.uid == fromUser.uid { continue }
            let data: [String: Any] = [
                "type": "mention",
                "fromUserId": fromUser.uid,
                "fromUsername": fromUser.username,
                "fromDisplayName": fromUser.displayName ?? "",
                "fromProfileImageURL": fromUser.profileImageURL ?? "",
                "toUserId": user.uid,
                "victoryId": victory.victoryId,
                "victoryTitle": victory.goalTitle,
                "victoryEmoji": victory.goalEmoji,
                "commentId": comment.commentId,
                "text": comment.text,
                "createdAt": Timestamp(date: Date()),
                "isRead": false
            ]
            try await notificationsRef.addDocument(data: data)
        }
    }

    private func createCommentNotification(
        victory: Victory,
        comment: VictoryComment,
        fromUser: UserData
    ) async throws {
        guard victory.userId != fromUser.uid else { return }

        let data: [String: Any] = [
            "type": "comment",
            "fromUserId": fromUser.uid,
            "fromUsername": fromUser.username,
            "fromDisplayName": fromUser.displayName ?? "",
            "fromProfileImageURL": fromUser.profileImageURL ?? "",
            "toUserId": victory.userId,
            "victoryId": victory.victoryId,
            "victoryTitle": victory.goalTitle,
            "victoryEmoji": victory.goalEmoji,
            "commentId": comment.commentId,
            "text": comment.text,
            "createdAt": Timestamp(date: Date()),
            "isRead": false
        ]
        try await db.collection("notifications").addDocument(data: data)
    }

    private func createBoostNotification(
        victory: Victory,
        fromUser: UserData
    ) async throws {
        guard victory.userId != fromUser.uid else { return }

        let data: [String: Any] = [
            "type": "boost",
            "fromUserId": fromUser.uid,
            "fromUsername": fromUser.username,
            "fromDisplayName": fromUser.displayName ?? "",
            "fromProfileImageURL": fromUser.profileImageURL ?? "",
            "toUserId": victory.userId,
            "victoryId": victory.victoryId,
            "victoryTitle": victory.goalTitle,
            "victoryEmoji": victory.goalEmoji,
            "grainAmount": 1,
            "text": "",
            "createdAt": Timestamp(date: Date()),
            "isRead": false
        ]
        try await db.collection("notifications").addDocument(data: data)
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

    func fetchVictory(by victoryId: String) async throws -> Victory? {
        let snapshot = try await db.collection("victories")
            .whereField("victoryId", isEqualTo: victoryId)
            .limit(to: 1)
            .getDocuments()

        guard let doc = snapshot.documents.first else { return nil }
        return Victory.from(document: doc)
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

    // MARK: - Victoires épinglées

    func loadPinnedVictories(userId: String) async throws -> [Victory] {
        let userDoc = try await db.collection("users").document(userId).getDocument()
        let ids = userDoc.data()?["pinnedVictoryIds"] as? [String] ?? []

        if ids.isEmpty {
            return []
        }

        let snapshot = try await db.collection("victories")
            .whereField("victoryId", in: ids)
            .getDocuments()

        let victories = snapshot.documents.compactMap { Victory.from(document: $0) }
        return victories.sorted { $0.createdAt > $1.createdAt }
    }

    func isVictoryPinned(_ victoryId: String, userId: String) async throws -> Bool {
        let userDoc = try await db.collection("users").document(userId).getDocument()
        let ids = userDoc.data()?["pinnedVictoryIds"] as? [String] ?? []
        return ids.contains(victoryId)
    }

    func pinVictory(_ victoryId: String, userId: String) async throws {
        let userRef = db.collection("users").document(userId)
        let snapshot = try await userRef.getDocument()
        let ids = snapshot.data()?["pinnedVictoryIds"] as? [String] ?? []

        if ids.contains(victoryId) {
            return
        }

        if ids.count >= 10 {
            throw NSError(domain: "VictoryManager", code: 400, userInfo: [
                NSLocalizedDescriptionKey: "Tu as déjà 10 victoires épinglées."
            ])
        }

        try await userRef.setData([
            "pinnedVictoryIds": FieldValue.arrayUnion([victoryId])
        ], merge: true)
    }

    func unpinVictory(_ victoryId: String, userId: String) async throws {
        let userRef = db.collection("users").document(userId)
        try await userRef.setData([
            "pinnedVictoryIds": FieldValue.arrayRemove([victoryId])
        ], merge: true)
    }
}
