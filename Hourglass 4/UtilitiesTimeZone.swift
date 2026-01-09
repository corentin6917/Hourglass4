//
//  UtilitiesTimeZone.swift
//  Hourglass 4
//
//  Centralise le fuseau horaire choisi par l'utilisateur.
//

import Foundation

enum AppTimeZone {
    private static let storageKey = "settings.timezoneIdentifier"

    static var current: TimeZone {
        let identifier = UserDefaults.standard.string(forKey: storageKey) ?? TimeZone.current.identifier
        return TimeZone(identifier: identifier) ?? .current
    }

    static var calendar: Calendar {
        var calendar = Calendar.current
        calendar.timeZone = current
        return calendar
    }

    static func formatDate(_ date: Date, style: DateFormatter.Style) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "fr_FR")
        formatter.timeZone = current
        formatter.dateStyle = style
        return formatter.string(from: date)
    }
}
