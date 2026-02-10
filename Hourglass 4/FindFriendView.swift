//
//  FindFriendView.swift
//  Hourglass 4
//
//  Vue pour rechercher et ajouter des amis via Firestore
//

import SwiftUI
import Contacts

struct FindFriendView: View {
    @StateObject private var viewModel = FindFriendViewModelV2()
    @Environment(\.dismiss) private var dismiss
    @State private var searchTask: Task<Void, Never>?
    @State private var hasSearched = false
    @State private var contactSuggestions: [UserData] = []
    @State private var isLoadingContactSuggestions = false
    @State private var contactsPermissionStatus = CNContactStore.authorizationStatus(for: .contacts)

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    // Barre de recherche
                    searchBar
                    contactSuggestionsSection

                    // Résultat de recherche
                    if viewModel.isSearching {
                        ProgressView()
                            .padding()
                    } else if let user = viewModel.searchResult {
                        userResultCard(user)
                    } else if viewModel.searchQuery.isEmpty {
                        emptyStateView
                    } else if hasSearched {
                        noResultView
                    }

                    // Messages d'erreur/succès
                    if let errorMessage = viewModel.errorMessage,
                       shouldShowError(errorMessage) {
                        Text(errorMessage)
                            .font(.caption)
                            .foregroundStyle(.red)
                            .padding(.horizontal)
                    }

                    if let successMessage = viewModel.successMessage {
                        Text(successMessage)
                            .font(.caption)
                            .foregroundStyle(.green)
                            .padding(.horizontal)
                    }
                }
                .padding(.vertical, 12)
            }
            .navigationTitle("Trouver des amis")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Fermer") { dismiss() }
                }
            }
            .onAppear {
                contactsPermissionStatus = CNContactStore.authorizationStatus(for: .contacts)
                Task { await viewModel.refreshPendingRelationUserIds() }
                Task { await viewModel.loadFriends() }
                if contactsPermissionStatus == .authorized {
                    Task { await loadContactSuggestions() }
                }
            }
            .onDisappear {
                searchTask?.cancel()
            }
        }
    }

    // MARK: - Search Bar

    private var searchBar: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(.secondary)

            TextField("Username", text: $viewModel.searchQuery)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled(true)
                .onSubmit {
                    triggerSearch()
                }
                .onChange(of: viewModel.searchQuery) { newValue in
                    searchTask?.cancel()
                    hasSearched = false
                    let trimmedQuery = newValue.trimmingCharacters(in: .whitespacesAndNewlines)

                    guard !trimmedQuery.isEmpty else {
                        viewModel.clearSearch()
                        return
                    }

                    guard trimmedQuery.count >= 2 else { return }

                    searchTask = Task {
                        try? await Task.sleep(nanoseconds: 350_000_000)
                        if Task.isCancelled { return }
                        await viewModel.searchUser()
                        if Task.isCancelled { return }
                        hasSearched = true
                    }
                }

            if !viewModel.searchQuery.isEmpty {
                Button {
                    viewModel.clearSearch()
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding()
        .background {
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.secondarySystemBackground))
        }
        .padding()
    }

    private var contactSuggestionsSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Label("Suggestions via tes contacts", systemImage: "person.2.badge.gearshape.fill")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.primary)
                Spacer()
            }
            .padding(.horizontal)

            if contactsPermissionStatus == .authorized {
                if isLoadingContactSuggestions {
                    ProgressView("Recherche des contacts...")
                        .font(.caption)
                        .padding(.horizontal)
                } else if contactSuggestions.isEmpty {
                    Text("Aucun contact inscrit trouvé pour le moment.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .padding(.horizontal)
                } else {
                    VStack(spacing: 8) {
                        ForEach(contactSuggestions.prefix(6)) { user in
                            contactSuggestionRow(user)
                        }
                    }
                    .padding(.horizontal)
                }
            } else if contactsPermissionStatus == .denied || contactsPermissionStatus == .restricted {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Accès contacts refusé")
                        .font(.caption.weight(.semibold))
                        .foregroundColor(.orange)
                    Text("Active les contacts dans Réglages pour voir les amis déjà présents sur Hourglass.")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
                .padding(.horizontal)
            } else {
                Button {
                    Task { await requestContactsAndLoad() }
                } label: {
                    Label("Autoriser les contacts", systemImage: "person.crop.circle.badge.plus")
                        .font(.subheadline.weight(.semibold))
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .tint(.orange)
                .padding(.horizontal)
            }
        }
    }

    private func contactSuggestionRow(_ user: UserData) -> some View {
        let isPending = viewModel.isRequestPending(for: user.uid)
        let isFriend = viewModel.isFriend(user.uid)

        return HStack(spacing: 12) {
            Circle()
                .fill(LinearGradient(colors: [.orange, .pink], startPoint: .topLeading, endPoint: .bottomTrailing))
                .frame(width: 34, height: 34)
                .overlay {
                    Text(user.username.prefix(1).uppercased())
                        .font(.subheadline.weight(.bold))
                        .foregroundColor(.white)
                }

            VStack(alignment: .leading, spacing: 2) {
                if let displayName = user.displayName, !displayName.isEmpty {
                    Text(displayName)
                        .font(.subheadline.weight(.semibold))
                        .lineLimit(1)
                }
                Text("@\(user.username)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Button {
                Task {
                    if isFriend {
                        return
                    } else if isPending {
                        await viewModel.cancelFriendRequest(to: user)
                    } else {
                        await viewModel.sendFriendRequest(to: user)
                    }
                }
            } label: {
                Label(
                    isFriend ? "Amis" : (isPending ? "En attente" : "Ajouter"),
                    systemImage: isFriend ? "checkmark.circle.fill" : (isPending ? "clock.fill" : "person.badge.plus")
                )
                .font(.caption.weight(.semibold))
                .foregroundColor(isFriend ? Color.secondary : (isPending ? Color.orange : Color.white))
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background {
                    if isFriend {
                        Capsule()
                            .stroke(Color.secondary.opacity(0.4), lineWidth: 1)
                    } else if isPending {
                        Capsule()
                            .stroke(Color.orange.opacity(0.6), lineWidth: 1)
                    } else {
                        Capsule()
                            .fill(Color.orange)
                    }
                }
            }
            .buttonStyle(.plain)
            .disabled(viewModel.isSendingRequest || isFriend)
        }
        .padding(10)
        .background {
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.secondarySystemBackground))
        }
    }

    private func triggerSearch() {
        searchTask?.cancel()
        let trimmedQuery = viewModel.searchQuery.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedQuery.isEmpty else {
            viewModel.clearSearch()
            hasSearched = false
            return
        }

        searchTask = Task {
            await viewModel.searchUser()
            if Task.isCancelled { return }
            hasSearched = true
        }
    }

    private func requestContactsAndLoad() async {
        let store = CNContactStore()
        let granted = await withCheckedContinuation { continuation in
            store.requestAccess(for: .contacts) { ok, _ in
                continuation.resume(returning: ok)
            }
        }
        await MainActor.run {
            contactsPermissionStatus = CNContactStore.authorizationStatus(for: .contacts)
        }
        if granted {
            await loadContactSuggestions()
        }
    }

    private func loadContactSuggestions() async {
        guard CNContactStore.authorizationStatus(for: .contacts) == .authorized else { return }
        await MainActor.run {
            isLoadingContactSuggestions = true
        }

        let phoneNumbers = ContactPhoneReader.readNormalizedPhoneNumbers()

        do {
            let users = try await FriendManager.shared.suggestUsersByPhoneNumbers(phoneNumbers)
            await MainActor.run {
                contactSuggestions = users
                isLoadingContactSuggestions = false
            }
        } catch {
            await MainActor.run {
                isLoadingContactSuggestions = false
            }
        }
    }

    // MARK: - User Result Card

    private func userResultCard(_ user: UserData) -> some View {
        let isPending = viewModel.isRequestPending(for: user.uid)
        let isFriend = viewModel.isFriend(user.uid)

        return HStack(spacing: 14) {
            if let imageURL = user.profileImageURL, !imageURL.isEmpty {
                ProfileImageView(
                    imageURL: imageURL,
                    username: user.username,
                    size: 46,
                    gradientColors: [.orange, .orange.opacity(0.6)]
                )
            } else {
                Circle()
                    .fill(LinearGradient(colors: [.orange, .pink], startPoint: .topLeading, endPoint: .bottomTrailing))
                    .frame(width: 46, height: 46)
                    .overlay {
                        Text(user.username.prefix(1).uppercased())
                            .font(.subheadline.weight(.bold))
                            .foregroundStyle(.white)
                    }
            }

            VStack(alignment: .leading, spacing: 4) {
                if let displayName = user.displayName, !displayName.isEmpty {
                    Text(displayName)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .lineLimit(1)
                }
                Text("@\(user.username)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Button {
                Task {
                    if isFriend {
                        return
                    } else if isPending {
                        await viewModel.cancelFriendRequest(to: user)
                    } else {
                        await viewModel.sendFriendRequest(to: user)
                    }
                }
            } label: {
                if viewModel.isSendingRequest {
                    ProgressView()
                        .progressViewStyle(.circular)
                } else {
                    Label(
                        isFriend ? "Amis" : (isPending ? "En attente" : "Ajouter"),
                        systemImage: isFriend ? "checkmark.circle.fill" : (isPending ? "clock.fill" : "person.badge.plus.fill")
                    )
                    .font(.caption.weight(.semibold))
                    .foregroundColor(isFriend ? Color.secondary : (isPending ? Color.orange : Color.white))
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background {
                        if isFriend {
                            Capsule()
                                .stroke(Color.secondary.opacity(0.4), lineWidth: 1)
                        } else if isPending {
                            Capsule()
                                .stroke(Color.orange.opacity(0.6), lineWidth: 1)
                        } else {
                            Capsule()
                                .fill(Color.orange)
                        }
                    }
                }
            }
            .buttonStyle(.plain)
            .disabled(viewModel.isSendingRequest || isFriend)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .frame(maxWidth: .infinity)
        .background {
            RoundedRectangle(cornerRadius: 15)
                .fill(Color.orange.opacity(0.06))
        }
        .padding()
    }

    // MARK: - Empty States

    private var emptyStateView: some View {
        VStack(spacing: 16) {
            Image(systemName: "person.2.fill")
                .font(.system(size: 60))
                .foregroundStyle(.orange.opacity(0.6))
            Text("Trouve tes amis")
                .font(.title3)
                .fontWeight(.medium)
            Text("Recherche par username")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .padding()
    }

    private var noResultView: some View {
        VStack(spacing: 16) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 60))
                .foregroundStyle(.secondary.opacity(0.5))
            Text("Aucun résultat")
                .font(.title3)
                .fontWeight(.medium)
            Text("Essaie une autre recherche")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .padding()
    }

    private func shouldShowError(_ message: String) -> Bool {
        let lower = message.lowercased()
        return !(lower.contains("déjà ami") || lower.contains("deja ami") || lower.contains("already friend"))
    }
}

// MARK: - Pending Request Card

struct PendingRequestCardView: View {
    let request: FriendRequest
    let onAction: (RequestAction) -> Void

    enum RequestAction {
        case accept, reject
    }

    var body: some View {
        VStack(spacing: 12) {
            // Avatar
            Circle()
                .fill(LinearGradient(colors: [.blue, .cyan], startPoint: .topLeading, endPoint: .bottomTrailing))
                .frame(width: 60, height: 60)
                .overlay {
                    Text(request.fromUsername.prefix(1).uppercased())
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundStyle(.white)
                }

            // Infos
            VStack(spacing: 4) {
                if let displayName = request.fromDisplayName, !displayName.isEmpty {
                    Text(displayName)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .lineLimit(1)
                }
                Text("@\(request.fromUsername)")
                    .font(.caption)
                    .foregroundStyle(.blue)
                    .lineLimit(1)
            }

            // Boutons
            HStack(spacing: 8) {
                Button {
                    onAction(.accept)
                } label: {
                    Image(systemName: "checkmark")
                        .font(.caption)
                        .foregroundStyle(.white)
                        .frame(width: 32, height: 32)
                        .background(Color.green)
                        .clipShape(Circle())
                }

                Button {
                    onAction(.reject)
                } label: {
                    Image(systemName: "xmark")
                        .font(.caption)
                        .foregroundStyle(.white)
                        .frame(width: 32, height: 32)
                        .background(Color.red)
                        .clipShape(Circle())
                }
            }
        }
        .frame(width: 150)
        .padding()
        .background {
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.secondarySystemBackground))
                .shadow(color: .black.opacity(0.05), radius: 5)
        }
    }
}

private enum ContactPhoneReader {
    static func readNormalizedPhoneNumbers(limit: Int = 500) -> [String] {
        let store = CNContactStore()
        let keys: [CNKeyDescriptor] = [CNContactPhoneNumbersKey as CNKeyDescriptor]
        let request = CNContactFetchRequest(keysToFetch: keys)

        var numbers = Set<String>()
        do {
            try store.enumerateContacts(with: request) { contact, stop in
                for phone in contact.phoneNumbers {
                    if let normalized = normalizePhone(phone.value.stringValue) {
                        numbers.insert(normalized)
                        if numbers.count >= limit {
                            stop.pointee = true
                            break
                        }
                    }
                }
            }
        } catch {
            return []
        }

        return Array(numbers)
    }

    private static func normalizePhone(_ raw: String) -> String? {
        var value = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        if value.isEmpty { return nil }

        value = value.replacingOccurrences(of: "[^0-9+]", with: "", options: .regularExpression)
        if value.hasPrefix("00") {
            value = "+" + value.dropFirst(2)
        }

        if value.hasPrefix("+") {
            let digits = value.dropFirst().filter(\.isNumber)
            guard digits.count >= 8 else { return nil }
            return "+" + digits
        }

        let digits = value.filter(\.isNumber)
        guard digits.count >= 9 else { return nil }

        let region = Locale.current.regionCode ?? "FR"
        if region == "FR", digits.hasPrefix("0"), digits.count == 10 {
            return "+33" + digits.dropFirst()
        }
        if region == "US", digits.count == 10 {
            return "+1" + digits
        }

        return nil
    }
}

#Preview {
    FindFriendView()
}
