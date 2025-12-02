//
//  DataConnectManager.swift
//  Hourglass 4
//
//  Manager pour Firebase Data Connect
//

import Foundation
import FirebaseCore
import FirebaseDataConnect
import FirebaseAuth

// MARK: - Models

enum DataConnectGender: String, Codable {
    case male = "MALE"
    case female = "FEMALE"
    case notSpecified = "NOT_SPECIFIED"

    init(from gender: Gender) {
        switch gender {
        case .male:
            self = .male
        case .female:
            self = .female
        case .notSpecified:
            self = .notSpecified
        }
    }
}

enum FriendshipStatus: String, Codable {
    case pending = "PENDING"
    case accepted = "ACCEPTED"
    case rejected = "REJECTED"
}

struct DCUser: Codable, Identifiable {
    let id: String
    let email: String
    let username: String
    let displayName: String?
    let gender: String
    let birthDate: String
    let createdAt: String
}

struct DCFriendship: Codable, Identifiable {
    let id: String
    let requesterId: String
    let addresseeId: String
    let status: String
    let createdAt: String
}

struct DCFriendRequest: Identifiable {
    let id: String
    let requester: DCUser
    let status: String
    let createdAt: String
}

// MARK: - DataConnectManager

class DataConnectManager {
    static let shared = DataConnectManager()

    private init() {}

    // MARK: - User Operations

    /// Créer un utilisateur dans Data Connect après création Firebase Auth
    func createUser(
        uid: String,
        email: String,
        username: String,
        displayName: String?,
        gender: Gender,
        birthDate: Date
    ) async throws {
        // Convertir la date en format ISO8601
        let dateFormatter = ISO8601DateFormatter()
        dateFormatter.formatOptions = [.withFullDate]
        let birthDateString = dateFormatter.string(from: birthDate)

        let genderString = DataConnectGender(from: gender).rawValue
        let usernameLower = username.lowercased()

        // Appel GraphQL
        let mutation = """
        mutation CreateUser(
          $uid: String!
          $email: String!
          $username: String!
          $usernameLower: String!
          $displayName: String
          $gender: String!
          $birthDate: String!
        ) {
          user_insert(data: {
            id: $uid
            email: $email
            username: $username
            username_lower: $usernameLower
            displayName: $displayName
            gender: $gender
            birthDate: $birthDate
          })
        }
        """

        let variables: [String: Any] = [
            "uid": uid,
            "email": email.lowercased(),
            "username": username,
            "usernameLower": usernameLower,
            "displayName": displayName ?? "",
            "gender": genderString,
            "birthDate": birthDateString
        ]

        try await executeGraphQL(query: mutation, variables: variables)
    }

    /// Rechercher un utilisateur par username
    func searchUserByUsername(_ username: String) async throws -> DCUser? {
        let query = """
        query GetUserByUsername($username: String!) {
          users(where: { username_lower: { eq: $username } }) {
            id
            email
            username
            displayName
            gender
            birthDate
            createdAt
          }
        }
        """

        let variables: [String: Any] = [
            "username": username.lowercased()
        ]

        let response = try await executeGraphQL(query: query, variables: variables)

        if let data = response["data"] as? [String: Any],
           let users = data["users"] as? [[String: Any]],
           let firstUser = users.first {
            return try JSONDecoder().decode(DCUser.self, from: JSONSerialization.data(withJSONObject: firstUser))
        }

        return nil
    }

    /// Rechercher un utilisateur par email
    func searchUserByEmail(_ email: String) async throws -> DCUser? {
        let query = """
        query GetUserByEmail($email: String!) {
          users(where: { email: { eq: $email } }) {
            id
            email
            username
            displayName
            gender
            birthDate
            createdAt
          }
        }
        """

        let variables: [String: Any] = [
            "email": email.lowercased()
        ]

        let response = try await executeGraphQL(query: query, variables: variables)

        if let data = response["data"] as? [String: Any],
           let users = data["users"] as? [[String: Any]],
           let firstUser = users.first {
            return try JSONDecoder().decode(DCUser.self, from: JSONSerialization.data(withJSONObject: firstUser))
        }

        return nil
    }

    // MARK: - Friendship Operations

    /// Envoyer une demande d'ami
    func sendFriendRequest(from requesterId: String, to addresseeId: String) async throws {
        let mutation = """
        mutation CreateFriendship($requesterId: String!, $addresseeId: String!) {
          friendship_insert(data: {
            requesterId: $requesterId
            addresseeId: $addresseeId
            status: PENDING
          })
        }
        """

        let variables: [String: Any] = [
            "requesterId": requesterId,
            "addresseeId": addresseeId
        ]

        try await executeGraphQL(query: mutation, variables: variables)
    }

    /// Récupérer les demandes d'amis en attente
    func getPendingFriendRequests(for userId: String) async throws -> [DCFriendRequest] {
        let query = """
        query GetPendingFriendRequests($userId: String!) {
          friendships(
            where: {
              addresseeId: { eq: $userId }
              status: { eq: PENDING }
            }
            orderBy: [{ createdAt: DESC }]
          ) {
            id
            requesterId
            requester {
              id
              username
              displayName
              email
              gender
              birthDate
              createdAt
            }
            status
            createdAt
          }
        }
        """

        let variables: [String: Any] = ["userId": userId]

        let response = try await executeGraphQL(query: query, variables: variables)

        // Parse response
        var requests: [DCFriendRequest] = []

        if let data = response["data"] as? [String: Any],
           let friendships = data["friendships"] as? [[String: Any]] {
            for friendship in friendships {
                if let id = friendship["id"] as? String,
                   let status = friendship["status"] as? String,
                   let createdAt = friendship["createdAt"] as? String,
                   let requesterData = friendship["requester"] as? [String: Any],
                   let requester = try? JSONDecoder().decode(DCUser.self, from: JSONSerialization.data(withJSONObject: requesterData)) {
                    requests.append(DCFriendRequest(id: id, requester: requester, status: status, createdAt: createdAt))
                }
            }
        }

        return requests
    }

    /// Accepter une demande d'ami
    func acceptFriendRequest(_ friendshipId: String) async throws {
        try await updateFriendshipStatus(friendshipId, status: .accepted)
    }

    /// Refuser une demande d'ami
    func rejectFriendRequest(_ friendshipId: String) async throws {
        try await updateFriendshipStatus(friendshipId, status: .rejected)
    }

    private func updateFriendshipStatus(_ friendshipId: String, status: FriendshipStatus) async throws {
        let mutation = """
        mutation UpdateFriendshipStatus($friendshipId: String!, $status: String!) {
          friendship_update(id: $friendshipId, data: { status: $status })
        }
        """

        let variables: [String: Any] = [
            "friendshipId": friendshipId,
            "status": status.rawValue
        ]

        try await executeGraphQL(query: mutation, variables: variables)
    }

    // MARK: - Helper Methods

    private func executeGraphQL(query: String, variables: [String: Any]) async throws -> [String: Any] {
        // URL de votre endpoint Data Connect
        let urlString = "https://firebasedataconnect.googleapis.com/v1beta/projects/hourglass4/locations/europe-west9/services/hourglass4-service/connectors/default:executeGraphql"

        guard let url = URL(string: urlString) else {
            throw NSError(domain: "DataConnect", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid URL"])
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        // Ajouter le token d'authentification Firebase
        if let user = Auth.auth().currentUser {
            let token = try await user.getIDToken()
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }

        let body: [String: Any] = [
            "query": query,
            "variables": variables
        ]

        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            throw NSError(domain: "DataConnect", code: -1, userInfo: [NSLocalizedDescriptionKey: "HTTP Error"])
        }

        guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            throw NSError(domain: "DataConnect", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid JSON"])
        }

        // Vérifier les erreurs GraphQL
        if let errors = json["errors"] as? [[String: Any]] {
            let errorMessage = errors.first?["message"] as? String ?? "Unknown GraphQL error"
            throw NSError(domain: "DataConnect", code: -1, userInfo: [NSLocalizedDescriptionKey: errorMessage])
        }

        return json
    }
}
