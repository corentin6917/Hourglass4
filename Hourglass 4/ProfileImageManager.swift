//
//  ProfileImageManager.swift
//  Hourglass 4
//
//  Gère l'upload et le stockage des photos de profil via Firebase Storage
//

import Foundation
import UIKit
import FirebaseAuth
import FirebaseStorage
import FirebaseFirestore

class ProfileImageManager {
    static let shared = ProfileImageManager()
    private let storage = Storage.storage()
    private let db = Firestore.firestore()

    private init() {}

    // MARK: - Upload Photo de Profil

    /// Upload une photo de profil vers Firebase Storage et met à jour le profil utilisateur
    func uploadProfileImage(_ image: UIImage) async throws -> String {
        guard let currentUserId = Auth.auth().currentUser?.uid else {
            throw NSError(domain: "ProfileImage", code: 401, userInfo: [NSLocalizedDescriptionKey: "Non authentifié"])
        }

        // Compresser l'image (max 800x800, qualité 0.7)
        guard let resizedImage = resizeImage(image, maxSize: 800),
              let imageData = resizedImage.jpegData(compressionQuality: 0.7) else {
            throw NSError(domain: "ProfileImage", code: 400, userInfo: [NSLocalizedDescriptionKey: "Impossible de compresser l'image"])
        }

        // Vérifier la taille (max 5MB)
        let maxSize = 5 * 1024 * 1024 // 5MB
        guard imageData.count <= maxSize else {
            throw NSError(domain: "ProfileImage", code: 400, userInfo: [NSLocalizedDescriptionKey: "L'image est trop volumineuse (max 5MB)"])
        }

        // Créer le chemin dans Storage : profileImages/{userId}/profile.jpg
        let storageRef = storage.reference()
        let imageRef = storageRef.child("profileImages/\(currentUserId)/profile.jpg")

        // Métadonnées
        let metadata = StorageMetadata()
        metadata.contentType = "image/jpeg"

        // Upload l'image
        _ = try await imageRef.putDataAsync(imageData, metadata: metadata)

        // Récupérer l'URL de téléchargement
        let downloadURL = try await imageRef.downloadURL()
        let urlString = downloadURL.absoluteString

        // Mettre à jour le profil utilisateur dans Firestore
        try await db.collection("users").document(currentUserId).updateData([
            "profileImageURL": urlString
        ])

        return urlString
    }

    // MARK: - Supprimer Photo de Profil

    /// Supprime la photo de profil de Firebase Storage et met à jour le profil
    func deleteProfileImage() async throws {
        guard let currentUserId = Auth.auth().currentUser?.uid else {
            throw NSError(domain: "ProfileImage", code: 401, userInfo: [NSLocalizedDescriptionKey: "Non authentifié"])
        }

        let storageRef = storage.reference()
        let imageRef = storageRef.child("profileImages/\(currentUserId)/profile.jpg")

        // Supprimer l'image de Storage
        try await imageRef.delete()

        // Mettre à jour le profil utilisateur dans Firestore
        try await db.collection("users").document(currentUserId).updateData([
            "profileImageURL": FieldValue.delete()
        ])
    }

    // MARK: - Helpers

    /// Redimensionne une image pour optimiser la taille
    private func resizeImage(_ image: UIImage, maxSize: CGFloat) -> UIImage? {
        let size = image.size

        // Si l'image est déjà assez petite, on la retourne telle quelle
        if size.width <= maxSize && size.height <= maxSize {
            return image
        }

        // Calculer la nouvelle taille en gardant le ratio
        let ratio = size.width / size.height
        let newSize: CGSize

        if size.width > size.height {
            newSize = CGSize(width: maxSize, height: maxSize / ratio)
        } else {
            newSize = CGSize(width: maxSize * ratio, height: maxSize)
        }

        // Redimensionner l'image
        UIGraphicsBeginImageContextWithOptions(newSize, false, 1.0)
        image.draw(in: CGRect(origin: .zero, size: newSize))
        let resizedImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()

        return resizedImage
    }
}
