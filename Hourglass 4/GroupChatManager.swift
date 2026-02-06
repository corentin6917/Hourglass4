//
//  GroupChatManager.swift
//  Hourglass 4
//
//  Gestion des conversations de groupe
//

import Foundation
import FirebaseAuth
import FirebaseFirestore
import FirebaseStorage
import UIKit

struct GroupChat: Identifiable, Codable {
    let id: String
    let name: String
    let imageURL: String?
    let createdBy: String
    let adminIds: [String]
    let memberIds: [String]
    let createdAt: Date
    let lastMessageText: String?
    let lastMessageAt: Date?

    init(
        id: String = UUID().uuidString,
        name: String,
        imageURL: String? = nil,
        createdBy: String,
        adminIds: [String],
        memberIds: [String],
        createdAt: Date = Date(),
        lastMessageText: String? = nil,
        lastMessageAt: Date? = nil
    ) {
        self.id = id
        self.name = name
        self.imageURL = imageURL
        self.createdBy = createdBy
        self.adminIds = adminIds
        self.memberIds = memberIds
        self.createdAt = createdAt
        self.lastMessageText = lastMessageText
        self.lastMessageAt = lastMessageAt
    }

    var dictionary: [String: Any] {
        var dict: [String: Any] = [
            "id": id,
            "name": name,
            "createdBy": createdBy,
            "adminIds": adminIds,
            "memberIds": memberIds,
            "createdAt": Timestamp(date: createdAt),
        ]

        if let imageURL {
            dict["imageURL"] = imageURL
        }
        if let lastMessageText {
            dict["lastMessageText"] = lastMessageText
        }
        if let lastMessageAt {
            dict["lastMessageAt"] = Timestamp(date: lastMessageAt)
        }
        return dict
    }

    static func from(document: DocumentSnapshot) -> GroupChat? {
        let data = document.data() ?? [:]
        guard let name = data["name"] as? String,
              let createdBy = data["createdBy"] as? String,
              let adminIds = data["adminIds"] as? [String],
              let memberIds = data["memberIds"] as? [String],
              let createdAt = data["createdAt"] as? Timestamp else {
            return nil
        }

        return GroupChat(
            id: data["id"] as? String ?? document.documentID,
            name: name,
            imageURL: data["imageURL"] as? String,
            createdBy: createdBy,
            adminIds: adminIds,
            memberIds: memberIds,
            createdAt: createdAt.dateValue(),
            lastMessageText: data["lastMessageText"] as? String,
            lastMessageAt: (data["lastMessageAt"] as? Timestamp)?.dateValue()
        )
    }
}

struct GroupMessage: Identifiable, Codable {
    let id: String
    let groupId: String
    let fromUserId: String
    let text: String
    let createdAt: Date

    var dictionary: [String: Any] {
        [
            "groupId": groupId,
            "fromUserId": fromUserId,
            "text": text,
            "createdAt": Timestamp(date: createdAt)
        ]
    }
}

class GroupChatManager {
    static let shared = GroupChatManager()
    private let db = Firestore.firestore()
    private let storage = Storage.storage()

    private init() {}

    func createGroup(name: String, image: UIImage?, memberIds: [String]) async throws -> GroupChat {
        guard let currentUserId = Auth.auth().currentUser?.uid else {
            throw NSError(domain: "GroupChat", code: 401, userInfo: [NSLocalizedDescriptionKey: "Non authentifié"])
        }

        let uniqueMembers = Array(Set(memberIds + [currentUserId]))
        if uniqueMembers.count > 20 {
            throw NSError(domain: "GroupChat", code: 400, userInfo: [NSLocalizedDescriptionKey: "Maximum 20 personnes par groupe."])
        }

        let groupId = UUID().uuidString
        var imageURL: String?

        if let image {
            imageURL = try await uploadGroupImage(image, groupId: groupId, userId: currentUserId)
        }

        let group = GroupChat(
            id: groupId,
            name: name.trimmingCharacters(in: .whitespacesAndNewlines),
            imageURL: imageURL,
            createdBy: currentUserId,
            adminIds: [currentUserId],
            memberIds: uniqueMembers
        )

        try await db.collection("groupChats").document(groupId).setData(group.dictionary)
        return group
    }

    func fetchGroupsForCurrentUser() async throws -> [GroupChat] {
        guard let currentUserId = Auth.auth().currentUser?.uid else { return [] }
        let snapshot = try await db.collection("groupChats")
            .whereField("memberIds", arrayContains: currentUserId)
            .order(by: "createdAt", descending: true)
            .getDocuments()

        return snapshot.documents.compactMap { GroupChat.from(document: $0) }
    }

    func sendMessage(groupId: String, text: String) async throws {
        guard let currentUserId = Auth.auth().currentUser?.uid else {
            throw NSError(domain: "GroupChat", code: 401, userInfo: [NSLocalizedDescriptionKey: "Non authentifié"])
        }

        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            throw NSError(domain: "GroupChat", code: 400, userInfo: [NSLocalizedDescriptionKey: "Le message ne peut pas être vide"])
        }

        let message = GroupMessage(
            id: UUID().uuidString,
            groupId: groupId,
            fromUserId: currentUserId,
            text: trimmed,
            createdAt: Date()
        )

        try await db.collection("groupChats").document(groupId)
            .collection("messages")
            .document(message.id)
            .setData(message.dictionary)

        try await db.collection("groupChats").document(groupId).setData([
            "lastMessageText": trimmed,
            "lastMessageAt": Timestamp(date: message.createdAt)
        ], merge: true)
    }

    func fetchMessages(groupId: String, limit: Int = 200) async throws -> [GroupMessage] {
        let snapshot = try await db.collection("groupChats").document(groupId)
            .collection("messages")
            .order(by: "createdAt", descending: true)
            .limit(to: limit)
            .getDocuments()

        return snapshot.documents.compactMap { doc in
            let data = doc.data()
            guard let fromUserId = data["fromUserId"] as? String,
                  let text = data["text"] as? String,
                  let createdAt = data["createdAt"] as? Timestamp else { return nil }
            return GroupMessage(
                id: doc.documentID,
                groupId: groupId,
                fromUserId: fromUserId,
                text: text,
                createdAt: createdAt.dateValue()
            )
        }
    }

    func removeMember(groupId: String, memberId: String) async throws {
        guard let currentUserId = Auth.auth().currentUser?.uid else {
            throw NSError(domain: "GroupChat", code: 401, userInfo: [NSLocalizedDescriptionKey: "Non authentifié"])
        }
        let groupDoc = try await db.collection("groupChats").document(groupId).getDocument()
        guard let group = GroupChat.from(document: groupDoc) else {
            throw NSError(domain: "GroupChat", code: 404, userInfo: [NSLocalizedDescriptionKey: "Groupe introuvable"])
        }
        guard group.adminIds.contains(currentUserId) else {
            throw NSError(domain: "GroupChat", code: 403, userInfo: [NSLocalizedDescriptionKey: "Action non autorisée"])
        }

        try await db.collection("groupChats").document(groupId).setData([
            "memberIds": FieldValue.arrayRemove([memberId])
        ], merge: true)
    }

    func deleteGroup(groupId: String) async throws {
        guard let currentUserId = Auth.auth().currentUser?.uid else {
            throw NSError(domain: "GroupChat", code: 401, userInfo: [NSLocalizedDescriptionKey: "Non authentifié"])
        }
        let groupDoc = try await db.collection("groupChats").document(groupId).getDocument()
        guard let group = GroupChat.from(document: groupDoc) else {
            throw NSError(domain: "GroupChat", code: 404, userInfo: [NSLocalizedDescriptionKey: "Groupe introuvable"])
        }
        guard group.createdBy == currentUserId else {
            throw NSError(domain: "GroupChat", code: 403, userInfo: [NSLocalizedDescriptionKey: "Seul le créateur peut supprimer le groupe"])
        }

        try await db.collection("groupChats").document(groupId).delete()
    }

    private func uploadGroupImage(_ image: UIImage, groupId: String, userId: String) async throws -> String {
        let resized = resizeImage(image, maxSize: 800) ?? image
        guard let data = resized.jpegData(compressionQuality: 0.8) else {
            throw NSError(domain: "GroupChat", code: 400, userInfo: [NSLocalizedDescriptionKey: "Image invalide"])
        }

        let ref = storage.reference().child("groupChats/\(userId)/\(groupId).jpg")
        let metadata = StorageMetadata()
        metadata.contentType = "image/jpeg"
        _ = try await ref.putDataAsync(data, metadata: metadata)
        let url = try await ref.downloadURL()
        return url.absoluteString
    }

    private func resizeImage(_ image: UIImage, maxSize: CGFloat) -> UIImage? {
        let size = image.size
        let ratio = size.width / size.height
        let newSize: CGSize
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
}
