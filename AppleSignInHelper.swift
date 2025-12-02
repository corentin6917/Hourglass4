//
//  AppleSignInHelper.swift
//  Hourglass 4
//
//  Gère le flux "Sign in with Apple" et l'intégration Firebase (OAuth Apple).
//

import Foundation
import AuthenticationServices
import CryptoKit
import FirebaseAuth
import Combine

final class AppleSignInHelper: ObservableObject {
    @Published var isSigningIn = false
    private(set) var currentNonce: String?

    // Configure la requête Apple avec les scopes et le nonce haché (requis par Firebase)
    func configure(_ request: ASAuthorizationAppleIDRequest) {
        let nonce = randomNonceString()
        currentNonce = nonce
        request.requestedScopes = [.fullName, .email]
        request.nonce = sha256(nonce)
    }

    // Traite le résultat Apple et signe auprès de Firebase avec les credentials OAuth
    func handle(result: Result<ASAuthorization, Error>) async throws {
        switch result {
        case .success(let auth):
            guard let appleIDCredential = auth.credential as? ASAuthorizationAppleIDCredential else {
                throw NSError(domain: "AppleSignIn", code: -1, userInfo: [NSLocalizedDescriptionKey: "Identifiants Apple invalides"])
            }
            guard let nonce = currentNonce else {
                throw NSError(domain: "AppleSignIn", code: -2, userInfo: [NSLocalizedDescriptionKey: "Nonce manquant"])
            }
            guard let appleIDToken = appleIDCredential.identityToken,
                  let idTokenString = String(data: appleIDToken, encoding: .utf8) else {
                throw NSError(domain: "AppleSignIn", code: -3, userInfo: [NSLocalizedDescriptionKey: "Impossible de lire le token Apple"])
            }

            let credential = OAuthProvider.appleCredential(
                withIDToken: idTokenString,
                rawNonce: nonce,
                fullName: nil
            )

            _ = try await Auth.auth().signIn(with: credential)
            // Create or normalize the Firestore user profile right after successful sign-in
            try? await UserManager.shared.ensureCurrentUserProfile()
        case .failure(let error):
            throw error
        }
    }
}

// MARK: - Nonce helpers

private func sha256(_ input: String) -> String {
    let inputData = Data(input.utf8)
    let hashed = SHA256.hash(data: inputData)
    return hashed.compactMap { String(format: "%02x", $0) }.joined()
}

private func randomNonceString(length: Int = 32) -> String {
    precondition(length > 0)
    let charset: [Character] = Array("0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._")
    var result = ""
    var remainingLength = length

    while remainingLength > 0 {
        var random: UInt8 = 0
        let errorCode = SecRandomCopyBytes(kSecRandomDefault, 1, &random)
        if errorCode != errSecSuccess {
            fatalError("Unable to generate nonce. SecRandomCopyBytes failed with OSStatus \(errorCode)")
        }

        if random < charset.count {
            result.append(charset[Int(random)])
            remainingLength -= 1
        }
    }

    return result
}

