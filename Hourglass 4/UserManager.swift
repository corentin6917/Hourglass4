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
import FirebaseFunctions

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
    var phoneE164: String?
    let username: String
    var displayName: String?
    var gender: Gender
    var birthDate: Date
    let createdAt: Date
    var profileImageURL: String?
    var isPublic: Bool
    var heritageTotal: Double?
    var usernameLastChangedAt: Date?
    var tutorialCompleted: Bool

    init(
        uid: String,
        email: String,
        phoneE164: String? = nil,
        username: String,
        displayName: String?,
        gender: Gender,
        birthDate: Date,
        createdAt: Date,
        profileImageURL: String? = nil,
        isPublic: Bool = true,
        heritageTotal: Double? = nil,
        usernameLastChangedAt: Date? = nil,
        tutorialCompleted: Bool = false
    ) {
        self.uid = uid
        self.email = email
        self.phoneE164 = phoneE164
        self.username = username
        self.displayName = displayName
        self.gender = gender
        self.birthDate = birthDate
        self.createdAt = createdAt
        self.profileImageURL = profileImageURL
        self.isPublic = isPublic
        self.heritageTotal = heritageTotal
        self.usernameLastChangedAt = usernameLastChangedAt
        self.tutorialCompleted = tutorialCompleted
    }

    var dictionary: [String: Any] {
        var dict: [String: Any] = [
            "uid": uid,
            "email": email,
            "phone_e164": phoneE164 ?? "",
            "username": username,
            "displayName": displayName ?? "",
            "gender": gender.rawValue,
            "birthDate": Timestamp(date: birthDate),
            "createdAt": Timestamp(date: createdAt),
            "isPublic": isPublic,
            "heritageTotal": heritageTotal ?? 0,
            "tutorialCompleted": tutorialCompleted
        ]

        if let imageURL = profileImageURL {
            dict["profileImageURL"] = imageURL
        }

        if let usernameLastChangedAt {
            dict["usernameLastChangedAt"] = Timestamp(date: usernameLastChangedAt)
        }

        return dict
    }
}

class UserManager: ObservableObject {
    static let shared = UserManager()
    private let db = Firestore.firestore()
    private let functions = Functions.functions(region: "europe-west1")

    @Published var cachedUsers: [String: UserData] = [:]
    var currentUserId: String? { Auth.auth().currentUser?.uid }

    private init() {}

    func updateFcmToken(_ token: String) async throws {
        guard let currentUserId = Auth.auth().currentUser?.uid else { return }
        try await db.collection("users").document(currentUserId).updateData([
            "fcmTokens": FieldValue.arrayUnion([token])
        ])
    }

    // Vérifier si un nom d'utilisateur existe déjà
    func isUsernameAvailable(_ username: String) async throws -> Bool {
        let normalizedUsername = username.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)

        guard !normalizedUsername.isEmpty else {
            throw NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Le nom d'utilisateur ne peut pas être vide."])
        }

        let result = try await callFunction(
            name: "checkUsernameAvailability",
            data: ["username": normalizedUsername]
        )
        return result["available"] as? Bool ?? false
    }

    // Réserver un nom d'utilisateur unique (Cloud Function)
    func claimUsername(_ username: String, previousUsername: String?) async throws {
        var data: [String: Any] = ["username": username]
        if let previousUsername, !previousUsername.isEmpty {
            data["previousUsername"] = previousUsername
        }
        _ = try await callFunction(name: "claimUsername", data: data)
    }

    func backfillUsernames() async throws -> [String: Any] {
        try await callFunction(name: "backfillUsernames", data: [:])
    }

    private func callFunction(name: String, data: [String: Any]) async throws -> [String: Any] {
        try await withCheckedThrowingContinuation { continuation in
            functions.httpsCallable(name).call(data) { result, error in
                if let error {
                    continuation.resume(throwing: error)
                    return
                }
                let payload = result?.data as? [String: Any] ?? [:]
                continuation.resume(returning: payload)
            }
        }
    }

    // Créer un profil utilisateur dans Firestore
    func createUserProfile(uid: String, email: String, username: String, displayName: String?, gender: Gender, birthDate: Date) async throws {
        let normalizedUsername = username.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
        let normalizedEmail = email.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
        let normalizedPhone = Self.normalizeToE164(Auth.auth().currentUser?.phoneNumber)

        let userData: [String: Any] = [
            "uid": uid,
            "email": normalizedEmail, // Email en minuscules pour la recherche
            "phone_e164": normalizedPhone ?? "",
            "username": username.trimmingCharacters(in: .whitespacesAndNewlines),
            "username_lower": normalizedUsername, // Pour la recherche insensible à la casse
            "displayName": displayName ?? "",
            "gender": gender.rawValue,
            "birthDate": Timestamp(date: birthDate),
            "createdAt": Timestamp(date: Date()),
            "usernameLastChangedAt": Timestamp(date: Date()),
            "isPublic": true,
            "heritageTotal": 0,
            "heritageBackfilled": true,
            "tutorialCompleted": false
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
        let phoneE164Raw = data["phone_e164"] as? String
        let username = data["username"] as? String ?? ""
        let displayName = data["displayName"] as? String
        let genderString = data["gender"] as? String ?? Gender.notSpecified.rawValue
        let gender = Gender(rawValue: genderString) ?? .notSpecified
        let birthDateTimestamp = data["birthDate"] as? Timestamp ?? Timestamp(date: Date())
        let createdAtTimestamp = data["createdAt"] as? Timestamp ?? Timestamp(date: Date())
        let usernameLastChangedAt = (data["usernameLastChangedAt"] as? Timestamp)?.dateValue()
        let profileImageURL = data["profileImageURL"] as? String
        let isPublic = data["isPublic"] as? Bool ?? true
        let heritageTotal = data["heritageTotal"] as? Double
        let tutorialCompleted = data["tutorialCompleted"] as? Bool ?? false

        return UserData(
            uid: uid,
            email: email,
            phoneE164: (phoneE164Raw?.isEmpty == false) ? phoneE164Raw : nil,
            username: username,
            displayName: displayName,
            gender: gender,
            birthDate: birthDateTimestamp.dateValue(),
            createdAt: createdAtTimestamp.dateValue(),
            profileImageURL: profileImageURL,
            isPublic: isPublic,
            heritageTotal: heritageTotal,
            usernameLastChangedAt: usernameLastChangedAt,
            tutorialCompleted: tutorialCompleted
        )
    }

    func getTutorialCompleted(uid: String) async throws -> Bool {
        let document = try await db.collection("users").document(uid).getDocument()
        return document.data()?["tutorialCompleted"] as? Bool ?? true
    }

    func setTutorialCompleted(uid: String, completed: Bool) async throws {
        try await db.collection("users").document(uid).setData(
            ["tutorialCompleted": completed],
            merge: true
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

                let currentPhone = Self.normalizeToE164(user.phoneNumber)
                let storedPhone = Self.normalizeToE164(data["phone_e164"] as? String)
                if currentPhone != storedPhone {
                    updates["phone_e164"] = currentPhone ?? ""
                }

                if !updates.isEmpty {
                    try await docRef.updateData(updates)
                }

                if (data["heritageBackfilled"] as? Bool) != true {
                    let total = try await calculateHeritageTotal(for: user.uid)
                    try await docRef.setData(
                        [
                            "heritageTotal": total,
                            "heritageBackfilled": true
                        ],
                        merge: true
                    )
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

    private func calculateHeritageTotal(for userId: String) async throws -> Double {
        let snapshot = try await db.collection("goals")
            .whereField("userId", isEqualTo: userId)
            .whereField("status", isEqualTo: GoalStatus.completed.rawValue)
            .getDocuments()

        return snapshot.documents.reduce(0.0) { partial, doc in
            let value = doc.data()["grainValue"] as? Double ?? 0.0
            return partial + value
        }
    }

    static func normalizeToE164(_ raw: String?) -> String? {
        guard var value = raw?.trimmingCharacters(in: .whitespacesAndNewlines), !value.isEmpty else {
            return nil
        }

        value = value.replacingOccurrences(of: "[^0-9+]", with: "", options: .regularExpression)
        if value.hasPrefix("00") {
            value = "+" + value.dropFirst(2)
        }
        if value.hasPrefix("+") {
            let digits = value.dropFirst().filter(\.isNumber)
            guard digits.count >= 8 else { return nil }
            return "+" + digits
        }

        return nil
    }
}
