//  ProfileView.swift
//  Hourglass 4
//
//  Created by Corentin Soula on 13/11/2025.
//

import SwiftUI
import UIKit
import FirebaseAuth
import FirebaseFirestore
import MessageUI
import UserNotifications

struct ProfileView: View {
    let viewModel: HourglassViewModel?

    @State private var showEditProfile = false
    @State private var showFindFriends = false
    @State private var showMessages = false
    @State private var unreadMessagesCount = 0
    @State private var showSettings = false
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    MainProfileCard(viewModel: viewModel, showEditProfile: $showEditProfile)

                    FriendsSection(showFindFriends: $showFindFriends)

                    Spacer(minLength: 24)
                }
                .padding(.horizontal)
                .padding(.top, 12)
            }
            .background(Color(uiColor: .systemGroupedBackground))
            .navigationTitle("")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        showSettings = true
                    } label: {
                        Image(systemName: "gearshape")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundStyle(.secondary)
                    }
                }

                // Bouton Messages avec badge
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showMessages = true
                    } label: {
                        ZStack(alignment: .topTrailing) {
                            Image(systemName: "message.fill")
                                .foregroundStyle(.orange)

                            if unreadMessagesCount > 0 {
                                Text("\(unreadMessagesCount)")
                                    .font(.caption2)
                                    .fontWeight(.bold)
                                    .foregroundStyle(.white)
                                    .padding(4)
                                    .background {
                                        Circle()
                                            .fill(.red)
                                    }
                                    .offset(x: 8, y: -8)
                            }
                        }
                    }
                }

                // Bouton Fermer
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .sheet(isPresented: $showEditProfile) {
                EditProfileView(viewModel: viewModel)
            }
            .sheet(isPresented: $showFindFriends) {
                FindFriendView()
            }
            .sheet(isPresented: $showMessages) {
                NotificationsView(viewModel: viewModel)
            }
            .sheet(isPresented: $showSettings) {
                SettingsView()
            }
            .onAppear {
                Task {
                    // Charger le nombre de messages non lus
                    unreadMessagesCount = (try? await FriendMessageManager.shared.getUnreadMessagesCount()) ?? 0
                }
            }
        }
    }
}

// MARK: - Main Profile Card

struct MainProfileCard: View {
    let viewModel: HourglassViewModel?
    @Binding var showEditProfile: Bool

    @State private var userData: UserData? = nil
    @State private var isLoading = true
    @State private var showShareOptions = false
    @State private var showImagePicker = false
    @State private var selectedImage: UIImage? = nil
    @State private var isUploadingImage = false
    @State private var uploadError: String? = nil
    @State private var friendsCount = 0

    var username: String {
        userData?.username ?? "Utilisateur"
    }

    var displayName: String {
        let name = userData?.displayName?.trimmingCharacters(in: .whitespacesAndNewlines)
        if let name, !name.isEmpty {
            return name
        }
        let authName = Auth.auth().currentUser?.displayName?.trimmingCharacters(in: .whitespacesAndNewlines)
        if let authName, !authName.isEmpty {
            return authName
        }
        return "Utilisateur"
    }

    var email: String {
        userData?.email ?? Auth.auth().currentUser?.email ?? "email@exemple.com"
    }

    var isPublic: Bool {
        userData?.isPublic ?? true
    }

    var body: some View {
        VStack(spacing: 18) {
            if isLoading {
                ProgressView()
                    .padding()
            } else {
                ZStack(alignment: .bottomTrailing) {
                    if isUploadingImage {
                        ZStack {
                            Circle()
                                .fill(Color.gray.opacity(0.2))
                                .frame(width: 96, height: 96)
                            ProgressView()
                        }
                    } else {
                        ProfileImageView(
                            imageURL: userData?.profileImageURL,
                            username: username,
                            size: 96,
                            gradientColors: [.orange, Color(red: 1.0, green: 0.6, blue: 0.0)]
                        )
                        .shadow(color: .black.opacity(0.12), radius: 8, x: 0, y: 4)
                    }

                    Button {
                        showImagePicker = true
                    } label: {
                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: [.orange, Color(red: 1.0, green: 0.6, blue: 0.0)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 30, height: 30)
                            .shadow(color: .orange.opacity(0.4), radius: 4, x: 0, y: 2)
                            .overlay {
                                Image(systemName: "camera.fill")
                                    .font(.system(size: 13))
                                    .foregroundStyle(.white)
                            }
                    }
                    .offset(x: 4, y: 4)
                }

                VStack(spacing: 10) {
                    Text(displayName)
                        .font(.title2)
                        .fontWeight(.bold)

                    Text("@\(username)")
                        .font(.subheadline)
                        .foregroundStyle(.orange)
                        .fontWeight(.semibold)
                }

                HStack(spacing: 28) {
                    StatItem(title: "\(friendsCount)", subtitle: "Complices")
                    Divider()
                        .frame(height: 30)
                    StatItem(title: isPublic ? "Public" : "Privé", subtitle: "Profil")
                }
                .padding(.horizontal, 24)

                HStack(spacing: 10) {
                    Button {
                        showEditProfile = true
                    } label: {
                        Text("Modifier le profil")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundStyle(.primary)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 10)
                            .background {
                                Capsule()
                                    .fill(Color(uiColor: .systemBackground))
                                    .shadow(color: .black.opacity(0.06), radius: 8, x: 0, y: 3)
                            }
                    }

                    Button {
                        showShareOptions = true
                    } label: {
                        Circle()
                            .fill(Color(uiColor: .systemBackground))
                            .frame(width: 38, height: 38)
                            .shadow(color: .black.opacity(0.08), radius: 6, x: 0, y: 3)
                            .overlay {
                                Image(systemName: "square.and.arrow.up")
                                    .font(.system(size: 16, weight: .semibold))
                                    .foregroundStyle(.secondary)
                            }
                    }
                }
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 24)
        .padding(.bottom, 20)
        .background {
            LinearGradient(
                colors: [
                    Color(red: 0.99, green: 0.96, blue: 0.9),
                    Color(uiColor: .systemBackground)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
        }
        .clipShape(RoundedRectangle(cornerRadius: 26))
        .overlay {
            RoundedRectangle(cornerRadius: 26)
                .stroke(Color.black.opacity(0.04), lineWidth: 1)
        }
        .shadow(color: .black.opacity(0.06), radius: 14, x: 0, y: 6)
        .onAppear {
            loadUserData()
            loadFriendsCount()
        }
        .onReceive(NotificationCenter.default.publisher(for: .profileDidUpdate)) { _ in
            loadUserData()
        }
        .sheet(isPresented: $showShareOptions) {
            ShareProfileView(shareText: generateShareText())
        }
        .sheet(isPresented: $showImagePicker) {
            ProfileImageSourcePicker(selectedImage: $selectedImage)
        }
        .onChange(of: selectedImage) { oldValue, newValue in
            if let image = newValue {
                uploadProfileImage(image)
            }
        }
        .alert("Erreur d'upload", isPresented: .constant(uploadError != nil)) {
            Button("OK") {
                uploadError = nil
            }
        } message: {
            if let error = uploadError {
                Text(error)
            }
        }
    }

    private func loadUserData() {
        guard let currentUser = Auth.auth().currentUser else {
            isLoading = false
            return
        }

        Task {
            do {
                let data = try await UserManager.shared.getUserProfile(uid: currentUser.uid)
                await MainActor.run {
                    userData = data
                    isLoading = false
                }
            } catch {
                print("Erreur lors du chargement du profil: \(error.localizedDescription)")
                await MainActor.run {
                    isLoading = false
                }
            }
        }
    }

    private func loadFriendsCount() {
        Task {
            do {
                let friends = try await FriendManager.shared.getFriends()
                await MainActor.run {
                    friendsCount = friends.count
                }
            } catch {
                print("Erreur lors du chargement des amis: \(error.localizedDescription)")
            }
        }
    }

    private func generateShareText() -> String {
        var text = "Rejoins-moi sur Hourglass 4 !\n\n"
        text += "👤 \(displayName)\n"
        text += "✨ @\(username)\n"

        if let birthDate = userData?.birthDate {
            text += "🎂 Né(e) le \(AppTimeZone.formatDate(birthDate, style: .medium))\n"
        }

        text += "\n⏳ Télécharge l'app Hourglass 4 pour me suivre !"

        return text
    }

    private func uploadProfileImage(_ image: UIImage) {
        isUploadingImage = true
        uploadError = nil

        Task {
            do {
                let imageURL = try await ProfileImageManager.shared.uploadProfileImage(image)

                // Recharger le profil utilisateur pour afficher la nouvelle photo
                await MainActor.run {
                    if userData != nil {
                        loadUserData()
                    }
                    isUploadingImage = false
                    selectedImage = nil
                }

                print("✅ Photo de profil uploadée avec succès: \(imageURL)")
            } catch {
                await MainActor.run {
                    uploadError = error.localizedDescription
                    isUploadingImage = false
                    selectedImage = nil
                }
                print("❌ Erreur lors de l'upload de la photo: \(error.localizedDescription)")
            }
        }
    }
}

struct StatItem: View {
    let title: String
    let subtitle: String

    var body: some View {
        VStack(spacing: 4) {
            Text(title)
                .font(.headline)
                .fontWeight(.bold)
            Text(subtitle)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(minWidth: 80)
    }
}

// MARK: - Friends Section

struct FriendsSection: View {
    @Binding var showFindFriends: Bool
    @State private var friends: [UserData] = []
    @State private var isLoading = true
    @State private var errorText: String?
    @State private var isExpanded = false
    @State private var pendingRequests: [FriendRequest] = []
    @State private var isLoadingRequests = false

    var body: some View {
        VStack(spacing: 0) {
            Button {
                withAnimation(.easeInOut(duration: 0.2)) {
                    isExpanded.toggle()
                }
            } label: {
                HStack(spacing: 12) {
                    SettingsIcon(symbol: "person.2.fill", color: .blue)
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Sabliers Complices")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundStyle(.primary)
                        Text(subtitleText)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                    Image(systemName: "chevron.right")
                        .foregroundStyle(.secondary)
                        .rotationEffect(.degrees(isExpanded ? 90 : 0))
                }
                .padding()
            }
            .buttonStyle(.plain)

            if isExpanded {
                Divider()

                if isLoading {
                    ProgressView()
                        .padding()
                } else if friends.isEmpty {
                    VStack(spacing: 8) {
                        Text("Aucun complice pour le moment")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                        if let errorText {
                            Text(errorText)
                                .font(.caption2)
                                .foregroundStyle(.red)
                        }
                    }
                    .padding()
                } else {
                    VStack(spacing: 12) {
                        ForEach(friends) { friend in
                            RealFriendCard(friend: friend) {
                                loadFriends()
                            }
                        }
                    }
                    .padding()
                }

                Divider()

                Button {
                    showFindFriends = true
                } label: {
                    HStack(spacing: 12) {
                        SettingsIcon(symbol: "magnifyingglass", color: .orange)
                        Text("Trouver des complices")
                            .font(.subheadline)
                            .foregroundStyle(.primary)
                        Spacer()
                        Image(systemName: "chevron.right")
                            .foregroundStyle(.secondary)
                    }
                    .padding()
                }
                .buttonStyle(.plain)

                Divider()

                VStack(alignment: .leading, spacing: 10) {
                    HStack(spacing: 10) {
                        SettingsIcon(symbol: "person.badge.plus", color: .orange)
                        Text("Demandes reçues")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundStyle(.primary)

                        Spacer()

                        if pendingRequests.count > 0 {
                            Text("\(pendingRequests.count)")
                                .font(.caption)
                                .fontWeight(.semibold)
                                .foregroundStyle(.orange)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background {
                                    Capsule()
                                        .fill(Color.orange.opacity(0.15))
                                }
                        }
                    }
                    .padding(.horizontal)

                    if isLoadingRequests {
                        ProgressView()
                            .padding(.horizontal)
                    } else if pendingRequests.isEmpty {
                        Text("Aucune demande en attente")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .padding(.horizontal)
                    } else {
                        VStack(spacing: 10) {
                            ForEach(pendingRequests) { request in
                                PendingRequestCard(request: request) {
                                    loadPendingRequests()
                                    loadFriends()
                                }
                            }
                        }
                        .padding(.horizontal)
                        .padding(.bottom, 4)
                    }
                }
            }
        }
        .padding()
        .background {
            RoundedRectangle(cornerRadius: 20)
                .fill(Color(uiColor: .systemBackground))
                .shadow(color: .black.opacity(0.05), radius: 10)
        }
        .onAppear {
            loadFriends()
            loadPendingRequests()
        }
        .onChange(of: isExpanded) { _, newValue in
            if newValue {
                loadPendingRequests()
            }
        }
    }

    private var subtitleText: String {
        if isLoading {
            return "Chargement..."
        }

        if friends.isEmpty {
            return "Aucune connexion"
        }

        let suffix = friends.count > 1 ? "connexions" : "connexion"
        return "\(friends.count) \(suffix)"
    }

    private func loadFriends() {
        isLoading = true
        errorText = nil

        Task {
            do {
                let friendsList = try await FriendManager.shared.getFriends()
                await MainActor.run {
                    friends = friendsList
                    isLoading = false
                }
            } catch {
                print("Erreur lors du chargement des amis: \(error.localizedDescription)")
                await MainActor.run {
                    isLoading = false
                    errorText = "Erreur: \(error.localizedDescription)"
                }
            }
        }
    }

    private func loadPendingRequests() {
        isLoadingRequests = true

        Task {
            do {
                let requests = try await FriendManager.shared.getPendingFriendRequests()
                await MainActor.run {
                    pendingRequests = requests
                    isLoadingRequests = false
                }
            } catch {
                await MainActor.run {
                    isLoadingRequests = false
                }
                print("Erreur chargement demandes: \(error.localizedDescription)")
            }
        }
    }
}

struct RealFriendCard: View {
    let friend: UserData
    let onUpdate: () -> Void
    @State private var showDeleteConfirmation = false
    @State private var showFriendProfile = false

    var displayName: String {
        let name = friend.displayName?.trimmingCharacters(in: .whitespacesAndNewlines)
        return (name?.isEmpty == false) ? name! : friend.username
    }

    var friendSince: String {
        AppTimeZone.formatDate(friend.createdAt, style: .short)
    }

    var profileColor: Color {
        let colors: [Color] = [.blue, .purple, .green, .orange, .pink, .cyan]
        let index = abs(friend.uid.hashValue) % colors.count
        return colors[index]
    }

    var body: some View {
        HStack(spacing: 14) {
            Button {
                showFriendProfile = true
            } label: {
                HStack(spacing: 14) {
                    if let imageURL = friend.profileImageURL, !imageURL.isEmpty {
                        ProfileImageView(
                            imageURL: imageURL,
                            username: friend.username,
                            size: 46,
                            gradientColors: [profileColor, profileColor.opacity(0.6)]
                        )
                    } else {
                        Circle()
                            .fill(LinearGradient(colors: [profileColor, profileColor.opacity(0.6)], startPoint: .topLeading, endPoint: .bottomTrailing))
                            .frame(width: 46, height: 46)
                            .overlay {
                                Text(friend.username.prefix(1).uppercased())
                                    .font(.subheadline)
                                    .fontWeight(.bold)
                                    .foregroundStyle(.white)
                            }
                    }

                    VStack(alignment: .leading, spacing: 4) {
                        Text(displayName)
                            .font(.subheadline)
                            .fontWeight(.semibold)
                        Text("@\(friend.username)")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Text("Depuis \(friendSince)")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }

                    Spacer()
                }
            }
            .buttonStyle(.plain)

            Button {
                showDeleteConfirmation = true
            } label: {
                Image(systemName: "trash")
                    .font(.caption)
                    .foregroundStyle(.gray)
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .background {
            RoundedRectangle(cornerRadius: 15)
                .fill(Color(uiColor: .secondarySystemBackground))
        }
        .alert("Supprimer cet ami ?", isPresented: $showDeleteConfirmation) {
            Button("Annuler", role: .cancel) {}
            Button("Supprimer", role: .destructive) {
                removeFriend()
            }
        } message: {
            Text("Êtes-vous sûr de vouloir retirer @\(friend.username) de vos amis ?")
        }
        .sheet(isPresented: $showFriendProfile) {
            FriendProfileView(friend: friend)
        }
    }

    private func removeFriend() {
        Task {
            do {
                try await FriendManager.shared.removeFriend(friend.uid)
                await MainActor.run {
                    onUpdate()
                }
            } catch {
                print("Erreur suppression ami: \(error.localizedDescription)")
            }
        }
    }
}

struct SettingsRow<Trailing: View>: View {
    let symbol: String
    let color: Color
    let title: String
    let subtitle: String?
    @ViewBuilder let trailing: Trailing

    init(
        symbol: String,
        color: Color,
        title: String,
        subtitle: String?,
        @ViewBuilder trailing: () -> Trailing
    ) {
        self.symbol = symbol
        self.color = color
        self.title = title
        self.subtitle = subtitle
        self.trailing = trailing()
    }

    var body: some View {
        HStack(spacing: 12) {
            SettingsIcon(symbol: symbol, color: color)

            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.subheadline)
                    .foregroundStyle(.primary)
                if let subtitle {
                    Text(subtitle)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            Spacer()

            trailing
        }
        .padding()
    }
}

struct SettingsIcon: View {
    let symbol: String
    let color: Color

    var body: some View {
        Circle()
            .fill(color.opacity(0.18))
            .frame(width: 34, height: 34)
            .overlay {
                Image(systemName: symbol)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(color)
            }
    }
}

// MARK: - Settings View

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @AppStorage("settings.notificationsEnabled") private var notificationsEnabled = true
    @AppStorage("settings.soundsEnabled") private var soundsEnabled = true
    @AppStorage("settings.calmModeEnabled") private var calmModeEnabled = false
    @AppStorage("settings.timezoneIdentifier") private var timezoneIdentifier = TimeZone.current.identifier

    @State private var showShareSheet = false
    @State private var showHelp = false
    @State private var showAbout = false
    @State private var showTimezonePicker = false
    @State private var showTutorial = false
    @State private var showLogoutConfirmation = false
    @State private var showDeleteConfirmation = false
    @State private var isPublic = true
    @State private var isLoadingProfile = false

    private var timezoneLabel: String {
        let tz = TimeZone(identifier: timezoneIdentifier) ?? .current
        return tz.localizedName(for: .standard, locale: Locale(identifier: "fr_FR")) ?? tz.identifier
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color(uiColor: .systemGroupedBackground)
                    .ignoresSafeArea()

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 16) {
                        SettingsProfileHeader()
                            .padding(.horizontal, 20)

                        VStack(spacing: 0) {
                            SettingsRow(
                                symbol: "eye.fill",
                                color: .orange,
                                title: "Profil public",
                                subtitle: isPublic ? "Visible" : "Privé"
                            ) {
                                if isLoadingProfile {
                                    ProgressView()
                                        .scaleEffect(0.8)
                                } else {
                                    Toggle("", isOn: $isPublic)
                                        .labelsHidden()
                                }
                            }

                            Divider()

                            SettingsRow(
                                symbol: "bell.fill",
                                color: .orange,
                                title: "Notifications",
                                subtitle: notificationsEnabled ? "Activées" : "Désactivées"
                            ) {
                                Toggle("", isOn: $notificationsEnabled)
                                    .labelsHidden()
                            }

                            Divider()

                            SettingsRow(
                                symbol: "speaker.wave.2.fill",
                                color: .green,
                                title: "Sons",
                                subtitle: soundsEnabled ? "Activés" : "Désactivés"
                            ) {
                                Toggle("", isOn: $soundsEnabled)
                                    .labelsHidden()
                            }

                            Divider()

                            SettingsRow(
                                symbol: "moon.fill",
                                color: .purple,
                                title: "Mode calme",
                                subtitle: calmModeEnabled ? "Activé" : "Désactivé"
                            ) {
                                Toggle("", isOn: $calmModeEnabled)
                                    .labelsHidden()
                            }
                        }
                        .background {
                            RoundedRectangle(cornerRadius: 20)
                                .fill(Color(uiColor: .systemBackground))
                                .shadow(color: .black.opacity(0.05), radius: 10)
                        }
                        .padding(.horizontal, 20)

                        VStack(spacing: 0) {
                            Button {
                                showTimezonePicker = true
                            } label: {
                                SettingsRow(
                                    symbol: "globe.europe.africa.fill",
                                    color: .blue,
                                    title: "Fuseau horaire",
                                    subtitle: timezoneLabel
                                ) {
                                    Image(systemName: "chevron.right")
                                        .foregroundStyle(.secondary)
                                }
                            }
                            .buttonStyle(.plain)

                            Divider()

                            Button {
                                showShareSheet = true
                            } label: {
                                SettingsRow(
                                    symbol: "square.and.arrow.up",
                                    color: .orange,
                                    title: "Partager Hourglass",
                                    subtitle: nil
                                ) {
                                    Image(systemName: "chevron.right")
                                        .foregroundStyle(.secondary)
                                }
                            }
                            .buttonStyle(.plain)

                            Divider()

                            Button {
                                showHelp = true
                            } label: {
                                SettingsRow(
                                    symbol: "questionmark.circle.fill",
                                    color: .gray,
                                    title: "Aide",
                                    subtitle: nil
                                ) {
                                    Image(systemName: "chevron.right")
                                        .foregroundStyle(.secondary)
                                }
                            }
                            .buttonStyle(.plain)

                            Divider()

                            Button {
                                showTutorial = true
                            } label: {
                                SettingsRow(
                                    symbol: "arrow.counterclockwise",
                                    color: .purple,
                                    title: "Revoir le tutoriel",
                                    subtitle: nil
                                ) {
                                    Image(systemName: "chevron.right")
                                        .foregroundStyle(.secondary)
                                }
                            }
                            .buttonStyle(.plain)

                            Divider()

                            Button {
                                showAbout = true
                            } label: {
                                SettingsRow(
                                    symbol: "info.circle.fill",
                                    color: .gray,
                                    title: "À propos",
                                    subtitle: nil
                                ) {
                                    Image(systemName: "chevron.right")
                                        .foregroundStyle(.secondary)
                                }
                            }
                            .buttonStyle(.plain)
                        }
                        .background {
                            RoundedRectangle(cornerRadius: 20)
                                .fill(Color(uiColor: .systemBackground))
                                .shadow(color: .black.opacity(0.05), radius: 10)
                        }
                        .padding(.horizontal, 20)

                        Button(role: .destructive) {
                            showLogoutConfirmation = true
                        } label: {
                            Text("Se déconnecter")
                                .font(.subheadline)
                                .fontWeight(.semibold)
                                .foregroundStyle(.red)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 14)
                                .background {
                                    RoundedRectangle(cornerRadius: 16)
                                        .fill(Color(uiColor: .systemBackground))
                                        .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 4)
                                }
                        }
                        .padding(.horizontal, 20)
                        .padding(.top, 6)

                        Button(role: .destructive) {
                            showDeleteConfirmation = true
                        } label: {
                            Text("Supprimer mon compte")
                                .font(.subheadline)
                                .fontWeight(.semibold)
                                .foregroundStyle(.red)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 14)
                                .background {
                                    RoundedRectangle(cornerRadius: 16)
                                        .fill(Color(uiColor: .systemBackground))
                                        .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 4)
                                }
                        }
                        .padding(.horizontal, 20)

                        Text(appVersionText)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .padding(.bottom, 20)
                    }
                    .padding(.top, 12)
                }
            }
            .navigationTitle("Réglages")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Fermer") {
                        dismiss()
                    }
                }
            }
            .sheet(isPresented: $showShareSheet) {
                ShareSheet(activityItems: [shareText])
            }
            .sheet(isPresented: $showTimezonePicker) {
                TimezonePickerView(selectedIdentifier: $timezoneIdentifier)
            }
            .sheet(isPresented: $showHelp) {
                SettingsHelpView()
            }
            .sheet(isPresented: $showAbout) {
                SettingsAboutView()
            }
            .alert("Déconnexion", isPresented: $showLogoutConfirmation) {
                Button("Annuler", role: .cancel) {}
                Button("Déconnexion", role: .destructive) {
                    do {
                        try Auth.auth().signOut()
                        dismiss()
                    } catch {
                        print("Erreur de déconnexion: \(error)")
                    }
                }
            }
            .alert("Revoir le tutoriel", isPresented: $showTutorial) {
                Button("OK", role: .cancel) { }
            }
            .alert("Supprimer le compte", isPresented: $showDeleteConfirmation) {
                Button("Annuler", role: .cancel) {}
                Button("Supprimer", role: .destructive) {}
            } message: {
                Text("Cette action est irréversible.")
            }
            .onAppear {
                guard let currentUser = Auth.auth().currentUser else { return }
                isLoadingProfile = true
                Task {
                    do {
                        let data = try await UserManager.shared.getUserProfile(uid: currentUser.uid)
                        await MainActor.run {
                            isPublic = data?.isPublic ?? true
                            isLoadingProfile = false
                        }
                    } catch {
                        await MainActor.run {
                            isLoadingProfile = false
                        }
                        print("Erreur chargement visibilité profil: \(error.localizedDescription)")
                    }
                }
            }
            .onChange(of: isPublic) { _, _ in
                guard let currentUser = Auth.auth().currentUser else { return }
                Task {
                    do {
                        try await Firestore.firestore().collection("users").document(currentUser.uid).updateData([
                            "isPublic": isPublic
                        ])
                        NotificationCenter.default.post(name: .profileDidUpdate, object: nil)
                    } catch {
                        print("Erreur mise à jour visibilité profil: \(error.localizedDescription)")
                    }
                }
            }
            .onChange(of: notificationsEnabled) { _, newValue in
                handleNotificationsToggle(newValue)
            }
            .onChange(of: soundsEnabled) { _, _ in
                rescheduleNotificationsIfNeeded()
            }
            .onChange(of: calmModeEnabled) { _, _ in
                rescheduleNotificationsIfNeeded()
            }
            .onChange(of: timezoneIdentifier) { _, _ in
                rescheduleNotificationsIfNeeded()
            }
        }
    }

    private var shareText: String {
        "Rejoins-moi sur Hourglass ⏳"
    }

    private var appVersionText: String {
        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
        let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
        return "Version \(version) (\(build))"
    }

    private func handleNotificationsToggle(_ enabled: Bool) {
        Task {
            if enabled {
                do {
                    let authorized = try await NotificationManager.shared.requestAuthorization()
                    if authorized {
                        try await NotificationManager.shared.scheduleDailyNotifications()
                    } else {
                        await MainActor.run {
                            notificationsEnabled = false
                        }
                    }
                } catch {
                    print("Erreur lors de l'activation des notifications: \(error)")
                    await MainActor.run {
                        notificationsEnabled = false
                    }
                }
            } else {
                let center = UNUserNotificationCenter.current()
                center.removeAllPendingNotificationRequests()
                center.removeAllDeliveredNotifications()
            }
        }
    }

    private func rescheduleNotificationsIfNeeded() {
        guard notificationsEnabled else { return }

        Task {
            do {
                let authorized = try await NotificationManager.shared.requestAuthorization()
                if authorized {
                    try await NotificationManager.shared.scheduleDailyNotifications()
                }
            } catch {
                print("Erreur lors de la mise à jour des notifications: \(error)")
            }
        }
    }

    
}

struct SettingsProfileHeader: View {
    @State private var userData: UserData? = nil
    @State private var isLoading = true

    var body: some View {
        HStack(spacing: 14) {
            if isLoading {
                Circle()
                    .fill(Color.gray.opacity(0.2))
                    .frame(width: 54, height: 54)
                    .overlay {
                        ProgressView()
                    }
            } else {
                ProfileImageView(
                    imageURL: userData?.profileImageURL,
                    username: userData?.username ?? "U",
                    size: 54,
                    gradientColors: [.orange, Color(red: 1.0, green: 0.6, blue: 0.0)]
                )
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(displayName)
                    .font(.headline)
                    .fontWeight(.semibold)

                Text("@\(userData?.username ?? "utilisateur")")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            Spacer()
        }
        .padding(16)
        .background {
            RoundedRectangle(cornerRadius: 20)
                .fill(Color(uiColor: .systemBackground))
                .shadow(color: .black.opacity(0.06), radius: 10, x: 0, y: 6)
        }
        .onAppear {
            loadUserData()
        }
    }

    private func loadUserData() {
        guard let currentUser = Auth.auth().currentUser else {
            isLoading = false
            return
        }

        Task {
            do {
                let data = try await UserManager.shared.getUserProfile(uid: currentUser.uid)
                await MainActor.run {
                    userData = data
                    isLoading = false
                }
            } catch {
                print("Erreur lors du chargement du profil: \(error.localizedDescription)")
                await MainActor.run {
                    isLoading = false
                }
            }
        }
    }

    private var displayName: String {
        let name = userData?.displayName?.trimmingCharacters(in: .whitespacesAndNewlines)
        return (name?.isEmpty == false) ? name! : "Utilisateur"
    }
}

struct TimezonePickerView: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var selectedIdentifier: String
    @State private var searchText = ""

    private var filteredTimezones: [String] {
        let all = TimeZone.knownTimeZoneIdentifiers
        if searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return all
        }

        let query = searchText.lowercased()
        return all.filter { identifier in
            identifier.lowercased().contains(query) ||
            (TimeZone(identifier: identifier)?.localizedName(for: .standard, locale: Locale(identifier: "fr_FR"))?.lowercased().contains(query) ?? false)
        }
    }

    var body: some View {
        NavigationStack {
            List {
                ForEach(filteredTimezones, id: \.self) { identifier in
                    Button {
                        selectedIdentifier = identifier
                        dismiss()
                    } label: {
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(TimeZone(identifier: identifier)?.localizedName(for: .standard, locale: Locale(identifier: "fr_FR")) ?? identifier)
                                    .foregroundStyle(.primary)
                                Text(identifier)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }

                            Spacer()

                            if identifier == selectedIdentifier {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundStyle(.orange)
                            }
                        }
                    }
                }
            }
            .searchable(text: $searchText, prompt: "Rechercher un fuseau horaire")
            .navigationTitle("Fuseau horaire")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Fermer") { dismiss() }
                }
            }
        }
    }
}

struct SettingsHelpView: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 16) {
                Text("Besoin d'aide ?")
                    .font(.title2)
                    .fontWeight(.bold)

                Text("Écris-nous si tu as une question ou un souci avec Hourglass.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                Spacer()
            }
            .padding(24)
            .navigationTitle("Aide")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Fermer") { dismiss() }
                }
            }
        }
    }
}

struct SettingsAboutView: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            VStack(spacing: 12) {
                Text("Hourglass")
                    .font(.title2)
                    .fontWeight(.bold)

                Text("L'app qui transforme tes journées en grains de vie.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)

                Spacer()
            }
            .padding(24)
            .navigationTitle("À propos")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Fermer") { dismiss() }
                }
            }
        }
    }
}

struct ShareSheet: UIViewControllerRepresentable {
    let activityItems: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: activityItems, applicationActivities: nil)
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

extension Notification.Name {
    static let profileDidUpdate = Notification.Name("profileDidUpdate")
}

struct EditProfileView: View {
    let viewModel: HourglassViewModel?
    @Environment(\.dismiss) private var dismiss
    @State private var fullName = ""
    @State private var username = ""
    @State private var email = ""
    @State private var selectedGender: Gender = .notSpecified
    @State private var birthDate = Date()
    @State private var isPublic = true
    @State private var isLoading = true
    @State private var isSaving = false
    @State private var errorMessage: String?
    @State private var successMessage: String?

    var body: some View {
        NavigationStack {
            if isLoading {
                ProgressView()
            } else {
                Form {
                    Section("Informations personnelles") {
                        TextField("Nom complet", text: $fullName)
                        TextField("Nom d'utilisateur", text: $username)
                            .textInputAutocapitalization(.never)
                        TextField("Email", text: $email)
                            .textInputAutocapitalization(.never)
                            .keyboardType(.emailAddress)
                            .disabled(true) // L'email ne peut pas être modifié facilement
                            .foregroundStyle(.secondary)
                    }

                    Section("Informations supplémentaires") {
                        Picker("Genre", selection: $selectedGender) {
                            ForEach(Gender.allCases, id: \.self) { gender in
                                Text(gender.displayName).tag(gender)
                            }
                        }

                        DatePicker(
                            "Date de naissance",
                            selection: $birthDate,
                            in: ...Date(),
                            displayedComponents: .date
                        )
                    }

                    Section("Confidentialité") {
                        Toggle("Profil public", isOn: $isPublic)
                    }

                    if let errorMessage {
                        Section {
                            Text(errorMessage)
                                .font(.caption)
                                .foregroundStyle(.red)
                        }
                    }

                    if let successMessage {
                        Section {
                            Text(successMessage)
                                .font(.caption)
                                .foregroundStyle(.green)
                        }
                    }
                }
                .navigationTitle("Modifier le profil")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Annuler") { dismiss() }
                    }
                    ToolbarItem(placement: .confirmationAction) {
                        Button {
                            saveProfile()
                        } label: {
                            if isSaving {
                                ProgressView()
                            } else {
                                Text("Enregistrer")
                            }
                        }
                        .disabled(isSaving)
                    }
                }
            }
        }
        .onAppear {
            loadUserData()
        }
    }

    private func loadUserData() {
        guard let currentUser = Auth.auth().currentUser else {
            isLoading = false
            return
        }

        Task {
            do {
                let data = try await UserManager.shared.getUserProfile(uid: currentUser.uid)
                await MainActor.run {
                    fullName = data?.displayName ?? ""
                    username = data?.username ?? ""
                    email = data?.email ?? currentUser.email ?? ""
                    selectedGender = data?.gender ?? .notSpecified
                    birthDate = data?.birthDate ?? Date()
                    isPublic = data?.isPublic ?? true
                    isLoading = false
                }
            } catch {
                print("Erreur lors du chargement du profil: \(error.localizedDescription)")
                await MainActor.run {
                    email = currentUser.email ?? ""
                    isLoading = false
                }
            }
        }
    }

    private func saveProfile() {
        guard let currentUser = Auth.auth().currentUser else {
            errorMessage = "Utilisateur non connecté"
            return
        }

        isSaving = true
        errorMessage = nil
        successMessage = nil

        Task {
            do {
                // Mettre à jour le profil dans Firestore
                let db = Firestore.firestore()
                try await db.collection("users").document(currentUser.uid).updateData([
                    "displayName": fullName,
                    "gender": selectedGender.rawValue,
                    "birthDate": Timestamp(date: birthDate),
                    "isPublic": isPublic
                ])

                await MainActor.run {
                    isSaving = false
                    successMessage = "Profil mis à jour !"

                    // Fermer après 1.5 secondes
                    Task {
                        try? await Task.sleep(nanoseconds: 1_500_000_000)
                        dismiss()
                    }
                }
            } catch {
                await MainActor.run {
                    isSaving = false
                    errorMessage = "Erreur : \(error.localizedDescription)"
                }
            }
        }
    }
}

struct FindFriendsView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var searchText = ""
    @State private var searchResults: [UserData] = []
    @State private var isSearching = false
    @State private var errorMessage: String?
    @State private var pendingRequests: [FriendRequest] = []

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Barre de recherche
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundStyle(.secondary)
                    TextField("Rechercher par email ou username", text: $searchText)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled(true)
                        .onSubmit {
                            performSearch()
                        }

                    if !searchText.isEmpty {
                        Button {
                            searchText = ""
                            searchResults = []
                        } label: {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundStyle(.secondary)
                        }
                    }
                }
                .padding()
                .background {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color(uiColor: .secondarySystemBackground))
                }
                .padding()

                // Demandes en attente
                if !pendingRequests.isEmpty {
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Image(systemName: "bell.badge.fill")
                                .foregroundStyle(.red)
                            Text("Demandes en attente (\(pendingRequests.count))")
                                .font(.headline)
                        }
                        .padding(.horizontal)

                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 12) {
                                ForEach(pendingRequests) { request in
                                    PendingRequestCard(request: request) {
                                        loadPendingRequests()
                                    }
                                }
                            }
                            .padding(.horizontal)
                        }
                    }
                    .padding(.vertical)

                    Divider()
                }

                // Résultats de recherche
                if isSearching {
                    ProgressView()
                        .padding()
                    Spacer()
                } else if searchText.isEmpty {
                    VStack(spacing: 16) {
                        Image(systemName: "person.2.fill")
                            .font(.system(size: 60))
                            .foregroundStyle(.blue.opacity(0.5))
                        Text("Trouve tes Sabliers Complices")
                            .font(.title3)
                            .fontWeight(.medium)
                        Text("Recherche par email ou nom d'utilisateur")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    .padding()
                    Spacer()
                } else if searchResults.isEmpty {
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
                    Spacer()
                } else {
                    ScrollView {
                        VStack(spacing: 12) {
                            ForEach(searchResults) { user in
                                UserSearchResultCard(user: user)
                            }
                        }
                        .padding()
                    }
                }

                if let errorMessage = errorMessage {
                    Text(errorMessage)
                        .font(.caption)
                        .foregroundStyle(.red)
                        .padding()
                }
            }
            .navigationTitle("Trouver des Complices")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Fermer") { dismiss() }
                }
            }
            .onAppear {
                loadPendingRequests()
            }
        }
    }

    private func performSearch() {
        guard !searchText.isEmpty else {
            searchResults = []
            return
        }

        isSearching = true
        errorMessage = nil

        Task {
            do {
                let results = try await FriendManager.shared.searchUsers(query: searchText)
                await MainActor.run {
                    searchResults = results
                    isSearching = false
                }
            } catch {
                await MainActor.run {
                    errorMessage = "Erreur lors de la recherche: \(error.localizedDescription)"
                    isSearching = false
                }
            }
        }
    }

    private func loadPendingRequests() {
        Task {
            do {
                let requests = try await FriendManager.shared.getPendingFriendRequests()
                await MainActor.run {
                    pendingRequests = requests
                }
            } catch {
                print("Erreur lors du chargement des demandes: \(error.localizedDescription)")
            }
        }
    }
}

// MARK: - User Search Result Card

struct UserSearchResultCard: View {
    let user: UserData
    @State private var isSendingRequest = false
    @State private var requestSent = false
    @State private var alreadyFriends = false
    @State private var errorMessage: String?

    var body: some View {
        HStack(spacing: 16) {
            // Avatar
            Circle()
                .fill(LinearGradient(colors: [.purple, .pink], startPoint: .topLeading, endPoint: .bottomTrailing))
                .frame(width: 50, height: 50)
                .overlay {
                    Text(user.username.prefix(1).uppercased())
                        .font(.title3)
                        .fontWeight(.bold)
                        .foregroundStyle(.white)
                }

            // Infos
            VStack(alignment: .leading, spacing: 4) {
                if let displayName = user.displayName, !displayName.isEmpty {
                    Text(displayName)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                }
                Text("@\(user.username)")
                    .font(.caption)
                    .foregroundStyle(.purple)
                Text(user.email)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            // Bouton d'action
            if alreadyFriends {
                HStack(spacing: 4) {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(.green)
                    Text("Amis")
                        .font(.caption)
                        .foregroundStyle(.green)
                }
            } else if requestSent {
                HStack(spacing: 4) {
                    Image(systemName: "clock.fill")
                        .foregroundStyle(.orange)
                    Text("En attente")
                        .font(.caption)
                        .foregroundStyle(.orange)
                }
            } else {
                Button {
                    sendFriendRequest()
                } label: {
                    if isSendingRequest {
                        ProgressView()
                            .scaleEffect(0.8)
                    } else {
                        Image(systemName: "person.badge.plus.fill")
                            .foregroundStyle(.blue)
                    }
                }
                .disabled(isSendingRequest)
            }
        }
        .padding()
        .background {
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.secondarySystemBackground))
        }
        .onAppear {
            checkFriendshipStatus()
        }
    }

    private func checkFriendshipStatus() {
        Task {
            do {
                let isFriend = try await FriendManager.shared.checkFriendship(with: user.uid)
                await MainActor.run {
                    alreadyFriends = isFriend
                }
            } catch {
                print("Erreur vérification amitié: \(error.localizedDescription)")
            }
        }
    }

    private func sendFriendRequest() {
        isSendingRequest = true
        errorMessage = nil

        Task {
            do {
                try await FriendManager.shared.sendFriendRequest(to: user.uid)
                await MainActor.run {
                    isSendingRequest = false
                    requestSent = true
                }
            } catch {
                await MainActor.run {
                    isSendingRequest = false
                    errorMessage = error.localizedDescription
                }
            }
        }
    }
}

// MARK: - Pending Request Card

struct PendingRequestCard: View {
    let request: FriendRequest
    let onUpdate: () -> Void
    @State private var isProcessing = false

    var body: some View {
        HStack(spacing: 12) {
            Circle()
                .fill(LinearGradient(colors: [.blue, .cyan], startPoint: .topLeading, endPoint: .bottomTrailing))
                .frame(width: 44, height: 44)
                .overlay {
                    Text(request.fromUsername.prefix(1).uppercased())
                        .font(.subheadline)
                        .fontWeight(.bold)
                        .foregroundStyle(.white)
                }

            VStack(alignment: .leading, spacing: 4) {
                if let displayName = request.fromDisplayName, !displayName.isEmpty {
                    Text(displayName)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .lineLimit(1)
                }
                Text("@\(request.fromUsername)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }

            Spacer()

            if isProcessing {
                ProgressView()
                    .scaleEffect(0.8)
            } else {
                HStack(spacing: 6) {
                    Button {
                        acceptRequest()
                    } label: {
                        Text("Accepter")
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundStyle(.white)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 6)
                            .background {
                                Capsule()
                                    .fill(Color.green)
                            }
                    }

                    Button {
                        rejectRequest()
                    } label: {
                        Image(systemName: "xmark")
                            .font(.caption2)
                            .foregroundStyle(.red)
                            .frame(width: 26, height: 26)
                            .background {
                                Circle()
                                    .fill(Color.red.opacity(0.12))
                            }
                    }
                }
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background {
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(uiColor: .secondarySystemBackground))
        }
    }

    private func acceptRequest() {
        isProcessing = true

        Task {
            do {
                try await FriendManager.shared.acceptFriendRequest(request.id)
                await MainActor.run {
                    isProcessing = false
                    onUpdate()
                }
            } catch {
                await MainActor.run {
                    isProcessing = false
                }
                print("Erreur acceptation: \(error.localizedDescription)")
            }
        }
    }

    private func rejectRequest() {
        isProcessing = true

        Task {
            do {
                try await FriendManager.shared.rejectFriendRequest(request.id)
                await MainActor.run {
                    isProcessing = false
                    onUpdate()
                }
            } catch {
                await MainActor.run {
                    isProcessing = false
                }
                print("Erreur refus: \(error.localizedDescription)")
            }
        }
    }
}

// MARK: - Share Profile View

struct ShareProfileView: View {
    let shareText: String
    @Environment(\.dismiss) private var dismiss
    @State private var showCopyConfirmation = false

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Header avec design orange
                VStack(spacing: 16) {
                    ZStack {
                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: [.orange, Color(red: 1.0, green: 0.6, blue: 0.0)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 80, height: 80)
                            .shadow(color: .orange.opacity(0.3), radius: 12, x: 0, y: 6)

                        Image(systemName: "person.circle.fill")
                            .font(.system(size: 40))
                            .foregroundStyle(.white)
                    }

                    Text("Partager mon profil")
                        .font(.title2)
                        .fontWeight(.bold)

                    Text("Choisis comment partager ton profil")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .padding(.top, 32)
                .padding(.bottom, 40)

                // Options de partage
                VStack(spacing: 16) {
                    // Copier le texte
                    Button {
                        UIPasteboard.general.string = shareText
                        showCopyConfirmation = true

                        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                            showCopyConfirmation = false
                        }
                    } label: {
                        HStack(spacing: 16) {
                            ZStack {
                                Circle()
                                    .fill(Color.orange.opacity(0.15))
                                    .frame(width: 56, height: 56)

                                Image(systemName: "doc.on.doc.fill")
                                    .font(.title2)
                                    .foregroundStyle(.orange)
                            }

                            VStack(alignment: .leading, spacing: 4) {
                                Text("Copier le texte")
                                    .font(.headline)
                                    .foregroundStyle(.primary)
                                Text("Copier dans le presse-papiers")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }

                            Spacer()

                            if showCopyConfirmation {
                                Image(systemName: "checkmark.circle.fill")
                                    .font(.title3)
                                    .foregroundStyle(.green)
                                    .transition(.scale.combined(with: .opacity))
                            } else {
                                Image(systemName: "chevron.right")
                                    .foregroundStyle(.secondary)
                            }
                        }
                        .padding()
                        .background {
                            RoundedRectangle(cornerRadius: 16)
                                .fill(Color(uiColor: .secondarySystemBackground))
                        }
                    }
                    .buttonStyle(.plain)

                    // Plus d'options (ouvre le ShareSheet natif)
                    ShareLink(item: shareText) {
                        HStack(spacing: 16) {
                            ZStack {
                                Circle()
                                    .fill(Color.orange.opacity(0.15))
                                    .frame(width: 56, height: 56)

                                Image(systemName: "square.and.arrow.up.fill")
                                    .font(.title2)
                                    .foregroundStyle(.orange)
                            }

                            VStack(alignment: .leading, spacing: 4) {
                                Text("Plus d'options")
                                    .font(.headline)
                                    .foregroundStyle(.primary)
                                Text("Messages, Mail, WhatsApp, etc.")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }

                            Spacer()

                            Image(systemName: "chevron.right")
                                .foregroundStyle(.secondary)
                        }
                        .padding()
                        .background {
                            RoundedRectangle(cornerRadius: 16)
                                .fill(Color(uiColor: .secondarySystemBackground))
                        }
                    }
                    .buttonStyle(.plain)
                }
                .padding(.horizontal, 20)

                Spacer()
            }
            .background(Color(uiColor: .systemGroupedBackground))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.title3)
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
    }
}

#Preview {
    ProfileView(viewModel: nil)
}
