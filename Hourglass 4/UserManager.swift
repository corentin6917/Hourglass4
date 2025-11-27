//
//  UserManager.swift
//  Hourglass 4
//
//  Gestionnaire pour les profils utilisateurs dans Firestore
//

import Foundation
import FirebaseAuth
import FirebaseFirestore

enum Gender: String, Codable, CaseIterable {
    case male = "Masculin"
    case female = "Féminin"
    case notSpecified = "Ne pas préciser"

    var displayName: String {
        return self.rawValue
    }
}

struct UserData: Identifiable, Codable {
    var id: String { uid } // Conformité à Identifiable
    let uid: String
    let email: String
    let username: String
    let displayName: String?
    let gender: Gender
    let birthDate: Date
    let createdAt: Date

    var dictionary: [String: Any] {
        return [
            "uid": uid,
            "email": email,
            "username": username,
            "displayName": displayName ?? "",
            "gender": gender.rawValue,
            "birthDate": Timestamp(date: birthDate),
            "createdAt": Timestamp(date: createdAt)
        ]
    }
}

class UserManager {
    static let shared = UserManager()
    private let db = Firestore.firestore()

    private init() {}

    // Vérifier si un nom d'utilisateur existe déjà
    func isUsernameAvailable(_ username: String) async throws -> Bool {
        let normalizedUsername = username.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)

        guard !normalizedUsername.isEmpty else {
            throw NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Le nom d'utilisateur ne peut pas être vide."])
        }

        let snapshot = try await db.collection("users")
            .whereField("username_lower", isEqualTo: normalizedUsername)
            .getDocuments()

        return snapshot.documents.isEmpty
    }

    // Créer un profil utilisateur dans Firestore
    func createUserProfile(uid: String, email: String, username: String, displayName: String?, gender: Gender, birthDate: Date) async throws {
        let normalizedUsername = username.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)

        let userData: [String: Any] = [
            "uid": uid,
            "email": email,
            "username": username.trimmingCharacters(in: .whitespacesAndNewlines),
            "username_lower": normalizedUsername, // Pour la recherche insensible à la casse
            "displayName": displayName ?? "",
            "gender": gender.rawValue,
            "birthDate": Timestamp(date: birthDate),
            "createdAt": Timestamp(date: Date())
        ]

        try await db.collection("users").document(uid).setData(userData)
    }

    // Récupérer un profil utilisateur
    func getUserProfile(uid: String) async throws -> UserData? {
        let document = try await db.collection("users").document(uid).getDocument()

        guard let data = document.data() else {
            return nil
        }

        let uid = data["uid"] as? String ?? uid
        let email = data["email"] as? String ?? ""
        let username = data["username"] as? String ?? ""
        let displayName = data["displayName"] as? String
        let genderString = data["gender"] as? String ?? Gender.notSpecified.rawValue
        let gender = Gender(rawValue: genderString) ?? .notSpecified
        let birthDateTimestamp = data["birthDate"] as? Timestamp ?? Timestamp(date: Date())
        let createdAtTimestamp = data["createdAt"] as? Timestamp ?? Timestamp(date: Date())

        return UserData(
            uid: uid,
            email: email,
            username: username,
            displayName: displayName,
            gender: gender,
            birthDate: birthDateTimestamp.dateValue(),
            createdAt: createdAtTimestamp.dateValue()
        )
    }
}
