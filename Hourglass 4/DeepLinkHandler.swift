//
//  DeepLinkHandler.swift
//  Hourglass 4
//
//  Deep link handler for friend requests and other app features
//

import Foundation
import SwiftUI
import Combine

@MainActor
class DeepLinkHandler: ObservableObject {
    static let shared = DeepLinkHandler()

    @Published var pendingFriendRequest: String? = nil
    @Published var showFriendRequestSheet = false

    private init() {}

    // Handle incoming URLs
    func handle(_ url: URL) {
        guard url.scheme == "hourglass" else { return }

        // Parse the URL path and query parameters
        let host = url.host
        let queryItems = URLComponents(url: url, resolvingAgainstBaseURL: false)?.queryItems

        switch host {
        case "addFriend":
            if let username = queryItems?.first(where: { $0.name == "username" })?.value {
                pendingFriendRequest = username
                showFriendRequestSheet = true
            }
        default:
            break
        }
    }

    // Clear the pending request
    func clearPendingRequest() {
        pendingFriendRequest = nil
        showFriendRequestSheet = false
    }
}
