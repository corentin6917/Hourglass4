//
//  UserManager.swift
//  Hourglass 4
//
//  Gestionnaire pour les profils utilisateurs dans Firestore
//

import Foundation
import Combine
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
    let profileImageURL: String?
    let isPublic: Bool

    init(
        uid: String,
        email: String,
        username: String,
        displayName: String?,
        gender: Gender,
        birthDate: Date,
        createdAt: Date,
        profileImageURL: String? = nil,
        isPublic: Bool = true
    ) {
        self.uid = uid
        self.email = email
        self.username = username
        self.displayName = displayName
        self.gender = gender
        self.birthDate = birthDate
        self.createdAt = createdAt
        self.profileImageURL = profileImageURL
        self.isPublic = isPublic
    }

    var dictionary: [String: Any] {
        var dict: [String: Any] = [
            "uid": uid,
            "email": email,
            "username": username,
            "displayName": displayName ?? "",
            "gender": gender.rawValue,
            "birthDate": Timestamp(date: birthDate),
            "createdAt": Timestamp(date: createdAt),
            "isPublic": isPublic
        ]

        if let imageURL = profileImageURL {
            dict["profileImageURL"] = imageURL
        }

        return dict
    }
}

class UserManager: ObservableObject {
    static let shared = UserManager()
    private let db = Firestore.firestore()

    @Published var cachedUsers: [String: UserData] = [:]

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
        let normalizedEmail = email.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)

        let userData: [String: Any] = [
            "uid": uid,
            "email": normalizedEmail, // Email en minuscules pour la recherche
            "username": username.trimmingCharacters(in: .whitespacesAndNewlines),
            "username_lower": normalizedUsername, // Pour la recherche insensible à la casse
            "displayName": displayName ?? "",
            "gender": gender.rawValue,
            "birthDate": Timestamp(date: birthDate),
            "createdAt": Timestamp(date: Date()),
            "isPublic": true
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
        let profileImageURL = data["profileImageURL"] as? String
        let isPublic = data["isPublic"] as? Bool ?? true

        return UserData(
            uid: uid,
            email: email,
            username: username,
            displayName: displayName,
            gender: gender,
            birthDate: birthDateTimestamp.dateValue(),
            createdAt: createdAtTimestamp.dateValue(),
            profileImageURL: profileImageURL,
            isPublic: isPublic
        )
    }

    // Fetch user profile and cache it
    func fetchUserProfile(userId: String) async {
        // Check if already cached
        if cachedUsers[userId] != nil {
            return
        }

        do {
            if let userData = try await getUserProfile(uid: userId) {
                await MainActor.run {
                    cachedUsers[userId] = userData
                }
            }
        } catch {
            print("Error fetching user profile: \(error)")
        }
    }
}

import FirebaseAuth
import FirebaseFirestore

extension UserManager {
    /// Ensure the current authenticated user has a Firestore profile document
    /// and normalize important fields (username_lower, email in lowercase).
    func ensureCurrentUserProfile() async throws {
        guard let user = Auth.auth().currentUser else { return }

        let docRef = db.collection("users").document(user.uid)
        let snapshot = try await docRef.getDocument()

        // If the document already exists, ensure normalization and return
        if snapshot.exists {
            if let data = snapshot.data() {
                var updates: [String: Any] = [:]

                if let username = data["username"] as? String {
                    let lowered = username.lowercased()
                    if (data["username_lower"] as? String) != lowered {
                        updates["username_lower"] = lowered
                    }
                }

                if let email = data["email"] as? String {
                    let loweredEmail = email.lowercased()
                    if email != loweredEmail {
                        updates["email"] = loweredEmail
                    }
                }

                if !updates.isEmpty {
                    try await docRef.updateData(updates)
                }
            }
            return
        }

        // Generate a base username from email/displayName or a random fallback
        let baseUsername: String = {
            if let email = user.email, let name = email.split(separator: "@").first {
                return String(name).replacingOccurrences(of: ".", with: "_").lowercased()
            } else if let display = user.displayName, !display.isEmpty {
                return display.replacingOccurrences(of: " ", with: "_").lowercased()
            } else {
                return "user_" + UUID().uuidString.prefix(6).lowercased()
            }
        }()

        // Ensure the username is unique by appending a numeric suffix if necessary
        var candidate = baseUsername
        var suffix = 0
        while true {
            let available = try await isUsernameAvailable(candidate)
            if available { break }
            suffix += 1
            candidate = baseUsername + String(suffix)
        }

        try await createUserProfile(
            uid: user.uid,
            email: user.email ?? "",
            username: candidate,
            displayName: user.displayName,
            gender: .notSpecified,
            birthDate: Date()
        )
    }
}
