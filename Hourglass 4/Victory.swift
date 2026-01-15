//
//  Victory.swift
//  Hourglass 4
//
//  Modèle pour les victoires/accomplissements quotidiens
//

import Foundation
import FirebaseFirestore

struct Victory: Identifiable, Codable {
    var id: String { victoryId }
    let victoryId: String
    let userId: String
    let username: String
    let displayName: String?
    let profileImageURL: String?
    let comment: String?

    // Détails de la victoire
    let goalTitle: String
    let goalEmoji: String
    let photoURL: String  // URL de la photo de preuve

    // Métadonnées
    let createdAt: Date
    let visibleAt: Date   // Visible à partir de 20h le jour de création
    let expiresAt: Date   // Expire à 20h le lendemain

    // Interactions sociales
    var boostCount: Int
    var commentCount: Int
    var boostedBy: [String] // userIds qui ont boosté

    init(
        victoryId: String = UUID().uuidString,
        userId: String,
        username: String,
        displayName: String?,
        profileImageURL: String?,
        comment: String? = nil,
        goalTitle: String,
        goalEmoji: String,
        photoURL: String,
        createdAt: Date = Date(),
        boostCount: Int = 0,
        commentCount: Int = 0,
        boostedBy: [String] = []
    ) {
        self.victoryId = victoryId
        self.userId = userId
        self.username = username
        self.displayName = displayName
        self.profileImageURL = profileImageURL
        self.comment = comment
        self.goalTitle = goalTitle
        self.goalEmoji = goalEmoji
        self.photoURL = photoURL
        self.createdAt = createdAt

        var calendar = AppTimeZone.calendar
        calendar.timeZone = TimeZone.current // Utiliser le fuseau horaire local

        // Visible à partir de 21h le jour de création
        var todayComponents = calendar.dateComponents([.year, .month, .day], from: createdAt)
        todayComponents.hour = 21
        todayComponents.minute = 0
        todayComponents.timeZone = calendar.timeZone
        self.visibleAt = calendar.date(from: todayComponents) ?? createdAt

        // Expire le lendemain à 21h (24h de visibilité)
        let tomorrow = calendar.date(byAdding: .day, value: 1, to: createdAt) ?? createdAt
        var tomorrowComponents = calendar.dateComponents([.year, .month, .day], from: tomorrow)
        tomorrowComponents.hour = 21
        tomorrowComponents.minute = 0
        tomorrowComponents.timeZone = calendar.timeZone
        self.expiresAt = calendar.date(from: tomorrowComponents) ?? tomorrow

        self.boostCount = boostCount
        self.commentCount = commentCount
        self.boostedBy = boostedBy
    }

    var isExpired: Bool {
        return Date() > expiresAt
    }

    var isVisible: Bool {
        let now = Date()
        return now >= visibleAt && now <= expiresAt
    }

    var timeAgoString: String {
        let calendar = AppTimeZone.calendar
        let now = Date()

        // Formatter pour l'heure
        let timeFormatter = DateFormatter()
        timeFormatter.dateFormat = "HH:mm"
        timeFormatter.timeZone = AppTimeZone.current
        let timeString = timeFormatter.string(from: createdAt)

        // Vérifier si c'est aujourd'hui
        if calendar.isDateInToday(createdAt) {
            return "Aujourd'hui à \(timeString)"
        }

        // Vérifier si c'était hier
        if calendar.isDateInYesterday(createdAt) {
            return "Hier à \(timeString)"
        }

        // Pour les dates plus anciennes, afficher la date complète
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "d MMM"
        dateFormatter.locale = Locale(identifier: "fr_FR")
        dateFormatter.timeZone = AppTimeZone.current
        let dateString = dateFormatter.string(from: createdAt)

        return "\(dateString) à \(timeString)"
    }

    var dictionary: [String: Any] {
        return [
            "victoryId": victoryId,
            "userId": userId,
            "username": username,
            "displayName": displayName ?? "",
            "profileImageURL": profileImageURL ?? "",
            "comment": comment ?? "",
            "goalTitle": goalTitle,
            "goalEmoji": goalEmoji,
            "photoURL": photoURL,
            "createdAt": Timestamp(date: createdAt),
            "visibleAt": Timestamp(date: visibleAt),
            "expiresAt": Timestamp(date: expiresAt),
            "boostCount": boostCount,
            "commentCount": commentCount,
            "boostedBy": boostedBy
        ]
    }

    static func from(document: QueryDocumentSnapshot) -> Victory? {
        let data = document.data()

        guard let victoryId = data["victoryId"] as? String,
              let userId = data["userId"] as? String,
              let username = data["username"] as? String,
              let goalTitle = data["goalTitle"] as? String,
              let goalEmoji = data["goalEmoji"] as? String,
              let photoURL = data["photoURL"] as? String,
              let createdAtTimestamp = data["createdAt"] as? Timestamp else {
            return nil
        }

        return Victory(
            victoryId: victoryId,
            userId: userId,
            username: username,
            displayName: data["displayName"] as? String,
            profileImageURL: data["profileImageURL"] as? String,
            comment: data["comment"] as? String,
            goalTitle: goalTitle,
            goalEmoji: goalEmoji,
            photoURL: photoURL,
            createdAt: createdAtTimestamp.dateValue(),
            boostCount: data["boostCount"] as? Int ?? 0,
            commentCount: data["commentCount"] as? Int ?? 0,
            boostedBy: data["boostedBy"] as? [String] ?? []
        )
    }
}

struct VictoryComment: Identifiable, Codable {
    var id: String { commentId }
    let commentId: String
    let victoryId: String
    let userId: String
    let username: String
    let displayName: String?
    let profileImageURL: String?
    let text: String
    let createdAt: Date

    var timeAgoString: String {
        let calendar = AppTimeZone.calendar
        let now = Date()

        // Formatter pour l'heure
        let timeFormatter = DateFormatter()
        timeFormatter.dateFormat = "HH:mm"
        timeFormatter.timeZone = AppTimeZone.current
        let timeString = timeFormatter.string(from: createdAt)

        // Vérifier si c'est aujourd'hui
        if calendar.isDateInToday(createdAt) {
            return "Aujourd'hui à \(timeString)"
        }

        // Vérifier si c'était hier
        if calendar.isDateInYesterday(createdAt) {
            return "Hier à \(timeString)"
        }

        // Pour les dates plus anciennes, afficher la date complète
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "d MMM"
        dateFormatter.locale = Locale(identifier: "fr_FR")
        dateFormatter.timeZone = AppTimeZone.current
        let dateString = dateFormatter.string(from: createdAt)

        return "\(dateString) à \(timeString)"
    }

    var dictionary: [String: Any] {
        return [
            "commentId": commentId,
            "victoryId": victoryId,
            "userId": userId,
            "username": username,
            "displayName": displayName ?? "",
            "profileImageURL": profileImageURL ?? "",
            "text": text,
            "createdAt": Timestamp(date: createdAt)
        ]
    }
}
