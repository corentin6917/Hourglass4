import Foundation
import FirebaseDataConnect
import Default
import FirebaseCore

/// Helper pour utiliser Firebase Data Connect facilement
class FirebaseDataConnectHelper {
    static let shared = FirebaseDataConnectHelper()

    private init() {}

    /// Connecteur Data Connect par défaut
    var connector: DefaultConnector {
        return DataConnect.defaultConnector
    }

    // MARK: - User Operations

    /// Créer un utilisateur dans Data Connect
    func createUser(
        username: String,
        email: String,
        displayName: String?,
        gender: String,
        birthDate: Date
    ) async throws {
        // Convertir Date en LocalDate pour Firebase Data Connect
        let calendar = Calendar.current
        let components = calendar.dateComponents([.year, .month, .day], from: birthDate)
        let localDate = try LocalDate(
            year: components.year!,
            month: components.month!,
            day: components.day!
        )

        let _ = try await connector.createUserMutation.execute(
            username: username,
            email: email,
            gender: gender,
            birthDate: localDate,
            usernameLower: username.lowercased()
        ) { vars in
            vars.displayName = displayName
        }
    }

    /// Chercher un utilisateur par nom d'utilisateur (insensible à la casse)
    func searchUser(username: String) async throws -> [SearchUserByUsernameQuery.Data.User] {
        let result = try await connector.searchUserByUsernameQuery.execute(
            usernameLower: username.lowercased()
        )
        return result.data.users
    }

    /// Obtenir un utilisateur par email
    func getUserByEmail(email: String) async throws -> [GetUserByEmailQuery.Data.User] {
        let result = try await connector.getUserByEmailQuery.execute(
            email: email
        )
        return result.data.users
    }

    // MARK: - Friendship Operations

    /// Envoyer une demande d'ami
    func sendFriendRequest(from requester: String, to addressee: String) async throws {
        let _ = try await connector.sendFriendRequestMutation.execute(
            requesterUsername: requester,
            addresseeUsername: addressee
        )
    }

    /// Accepter une demande d'ami
    func acceptFriendRequest(from requester: String, to addressee: String) async throws {
        let _ = try await connector.acceptFriendRequestMutation.execute(
            requesterUsername: requester,
            addresseeUsername: addressee
        )
    }

    /// Rejeter une demande d'ami
    func rejectFriendRequest(from requester: String, to addressee: String) async throws {
        let _ = try await connector.rejectFriendRequestMutation.execute(
            requesterUsername: requester,
            addresseeUsername: addressee
        )
    }

    /// Obtenir les demandes d'ami en attente pour un utilisateur
    func getPendingFriendRequests(for username: String) async throws -> [GetPendingFriendRequestsQuery.Data.Friendship] {
        let result = try await connector.getPendingFriendRequestsQuery.execute(
            addresseeUsername: username
        )
        return result.data.friendships
    }

    /// Obtenir tous les amis acceptés d'un utilisateur
    func getFriends(for username: String) async throws -> [GetFriendsQuery.Data.Friendship] {
        let result = try await connector.getFriendsQuery.execute(
            username: username
        )
        return result.data.friendships
    }
}
