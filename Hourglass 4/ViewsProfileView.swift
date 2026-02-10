//  ProfileView.swift
//  Hourglass 4
//
//  Created by Corentin Soula on 13/11/2025.
//

import SwiftUI
import UIKit
import FirebaseAuth
import FirebaseFirestore
import FirebaseFunctions
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
    @EnvironmentObject private var tutorialManager: TutorialManager
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    MainProfileCard(viewModel: viewModel, showEditProfile: $showEditProfile)

                    PendingRequestsSection()

                    FindFriendsSection(showFindFriends: $showFindFriends)

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
                            .frame(width: 34, height: 34, alignment: .center)
                    }
                    .padding(.leading, 6)
                }

                // Boutons à droite
                ToolbarItem(placement: .topBarTrailing) {
                    HStack(spacing: 12) {
                        Button {
                            showMessages = true
                        } label: {
                            ZStack(alignment: .topTrailing) {
                                Image(systemName: "message")
                                    .font(.system(size: 18, weight: .semibold))
                                    .foregroundStyle(.orange)
                                    .symbolRenderingMode(.hierarchical)

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
                            .padding(8)
                            .contentShape(Circle())
                        }

                        Button {
                            dismiss()
                        } label: {
                            Image(systemName: "xmark")
                                .foregroundStyle(.secondary)
                        }
                    }
                    .padding(.trailing, 6)
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
            .onChange(of: tutorialManager.isActive) { _, isActive in
                if isActive {
                    dismiss()
                }
            }
            .onReceive(NotificationCenter.default.publisher(for: .showIntroPresentation)) { _ in
                dismiss()
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
    @State private var heritageTotal: Double = 0
    @State private var isLoadingHeritage = true
    @State private var showHeritageInfo = false
    @State private var showPinnedVictories = false
    @State private var pendingFriendRequestsCount = 0
    @State private var showAllFriends = false

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

                    if pendingFriendRequestsCount > 0 {
                        Text("\(pendingFriendRequestsCount)")
                            .font(.caption2)
                            .fontWeight(.bold)
                            .foregroundStyle(.white)
                            .padding(4)
                            .background(
                                Circle()
                                    .fill(.red)
                            )
                            .offset(x: 0, y: -66)
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

                VStack(spacing: 12) {
                    HStack(spacing: 24) {
                        Button {
                            showAllFriends = true
                        } label: {
                            StatItem(title: "\(friendsCount)", subtitle: "Complices")
                        }
                        .buttonStyle(.plain)
                        Divider()
                            .frame(height: 30)
                        StatItem(
                            title: isLoadingHeritage ? "…" : "\(Int(heritageTotal))",
                            subtitle: "Sablier"
                        )
                        .onTapGesture {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                showHeritageInfo.toggle()
                            }
                        }
                        Divider()
                            .frame(height: 30)
                        StatItem(title: isPublic ? "Public" : "Privé", subtitle: "Profil")
                    }

                    if showHeritageInfo {
                        VStack(alignment: .leading, spacing: 10) {
                            Text("Ton Sablier")
                                .font(.system(size: 14, weight: .semibold))

                            Text("C'est le total de tous les grains que tu as accumulés depuis le début. Chaque objectif validé contribue à ton sablier qui grandit jour après jour.")
                                .font(.system(size: 12))
                                .foregroundStyle(.secondary)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                        .padding(16)
                        .background {
                            RoundedRectangle(cornerRadius: 16)
                                .fill(Color(uiColor: .systemBackground))
                                .shadow(color: .orange.opacity(0.25), radius: 16, x: 0, y: 8)
                        }
                        .frame(maxWidth: 280)
                        .transition(.scale.combined(with: .opacity))
                        .onTapGesture {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                showHeritageInfo = false
                            }
                        }
                    }
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
                                    .foregroundStyle(.orange)
                            }
                    }
                }

                Button {
                    showPinnedVictories = true
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "pin.fill")
                            .font(.system(size: 14, weight: .semibold))
                        Text("Victoires épinglées")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                    }
                    .foregroundStyle(.orange)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 8)
                    .background {
                        Capsule()
                            .fill(Color.orange.opacity(0.12))
                    }
                }
                .buttonStyle(.plain)
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
            loadHeritageTotal()
            loadPendingFriendRequestsCount()
        }
        .onReceive(NotificationCenter.default.publisher(for: .profileDidUpdate)) { _ in
            loadUserData()
            loadPendingFriendRequestsCount()
        }
        .sheet(isPresented: $showShareOptions) {
            ShareProfileView(shareText: generateShareText())
        }
        .sheet(isPresented: $showPinnedVictories) {
            PinnedVictoriesView(userId: Auth.auth().currentUser?.uid ?? "", displayName: displayName)
        }
        .sheet(isPresented: $showAllFriends) {
            FriendsListView()
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

    private func loadHeritageTotal() {
        guard let currentUserId = Auth.auth().currentUser?.uid else {
            isLoadingHeritage = false
            return
        }

        isLoadingHeritage = true
        let db = Firestore.firestore()

        Task {
            do {
                let snapshot = try await db.collection("goals")
                    .whereField("userId", isEqualTo: currentUserId)
                    .whereField("status", isEqualTo: GoalStatus.completed.rawValue)
                    .getDocuments()

                let total = snapshot.documents.reduce(0.0) { partial, doc in
                    let value = doc.data()["grainValue"] as? Double ?? 0.0
                    return partial + value
                }

                try await db.collection("users").document(currentUserId).setData(
                    ["heritageTotal": total],
                    merge: true
                )

                await MainActor.run {
                    heritageTotal = total
                    isLoadingHeritage = false
                }
            } catch {
                await MainActor.run {
                    isLoadingHeritage = false
                }
            }
        }
    }

    private func loadPendingFriendRequestsCount() {
        Task {
            do {
                let requests = try await FriendManager.shared.getPendingFriendRequests()
                await MainActor.run {
                    pendingFriendRequestsCount = requests.count
                }
            } catch {
                await MainActor.run {
                    pendingFriendRequestsCount = 0
                }
            }
        }
    }

    private func generateShareText() -> String {
        var text = "Rejoins-moi sur Hourglass 4 !\n\n"
        text += "👤 \(displayName)\n"
        text += "✨ @\(username)\n"

        text += "\n👉 Clique ici pour m'ajouter :\n"
        let normalizedUsername = username.trimmingCharacters(in: .whitespacesAndNewlines)
        let encodedUsername = normalizedUsername.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? normalizedUsername
        text += "hourglass://addFriend?username=\(encodedUsername)"

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

struct TrianglePointer: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.midX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.minY))
        path.closeSubpath()
        return path
    }
}

// MARK: - Friends Section

struct FriendsSection: View {
    @Binding var showFindFriends: Bool
    @State private var friends: [UserData] = []
    @State private var isLoading = true
    @State private var errorText: String?
    @State private var isExpanded = false

    var body: some View {
        VStack(spacing: 0) {
            Button {
                withAnimation(.easeInOut(duration: 0.2)) {
                    isExpanded.toggle()
                }
            } label: {
                HStack(spacing: 12) {
                    SettingsIcon(symbol: "person.2.fill", color: .orange)
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
                    Group {
                        if friends.count > 3 {
                            ScrollView(.vertical, showsIndicators: true) {
                                VStack(spacing: 12) {
                                    ForEach(friends) { friend in
                                        RealFriendCard(friend: friend) {
                                            loadFriends()
                                        }
                                    }
                                }
                            }
                            .frame(maxHeight: 246)
                        } else {
                            VStack(spacing: 12) {
                                ForEach(friends) { friend in
                                    RealFriendCard(friend: friend) {
                                        loadFriends()
                                    }
                                }
                            }
                        }
                    }
                    .padding()
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

}

struct PendingRequestsSection: View {
    @State private var pendingRequests: [FriendRequest] = []
    @State private var isLoadingRequests = false

    var body: some View {
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
                        }
                    }
                }
                .padding(.horizontal)
                .padding(.bottom, 4)
            }
        }
        .padding()
        .background {
            RoundedRectangle(cornerRadius: 20)
                .fill(Color(uiColor: .systemBackground))
                .shadow(color: .black.opacity(0.05), radius: 10)
        }
        .onAppear {
            loadPendingRequests()
        }
        .onReceive(NotificationCenter.default.publisher(for: UIApplication.willEnterForegroundNotification)) { _ in
            loadPendingRequests()
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
                    pendingRequests = []
                    isLoadingRequests = false
                }
                print("Erreur chargement demandes: \(error.localizedDescription)")
            }
        }
    }
}

struct FindFriendsSection: View {
    @Binding var showFindFriends: Bool

    var body: some View {
        VStack(spacing: 0) {
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
        }
        .background {
            RoundedRectangle(cornerRadius: 20)
                .fill(Color(uiColor: .systemBackground))
                .shadow(color: .black.opacity(0.05), radius: 10)
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
                .fill(Color.orange.opacity(0.06))
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

struct FriendsListView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var friends: [UserData] = []
    @State private var isLoading = true

    var body: some View {
        NavigationStack {
            ScrollView {
                if isLoading {
                    ProgressView()
                        .padding()
                } else if friends.isEmpty {
                    VStack(spacing: 12) {
                        Image(systemName: "person.2.fill")
                            .font(.system(size: 44))
                            .foregroundStyle(.orange.opacity(0.6))
                        Text("Aucun complice")
                            .font(.headline)
                        Text("Ajoute des amis pour les voir ici.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .padding()
                } else {
                    VStack(spacing: 12) {
                        ForEach(friends) { friend in
                            RealFriendCard(friend: friend) {
                                Task { await loadFriends() }
                            }
                        }
                    }
                    .padding()
                }
            }
            .navigationTitle("Complices")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Fermer") { dismiss() }
                }
            }
            .onAppear {
                Task { await loadFriends() }
            }
        }
    }

    private func loadFriends() async {
        isLoading = true
        do {
            let friendsList = try await FriendManager.shared.getFriends()
            await MainActor.run {
                friends = friendsList
                isLoading = false
            }
        } catch {
            await MainActor.run {
                friends = []
                isLoading = false
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
            .fill(
                LinearGradient(
                    colors: [color.opacity(0.22), color.opacity(0.08)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .overlay {
                Circle()
                    .stroke(color.opacity(0.25), lineWidth: 1)
            }
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
    @EnvironmentObject private var tutorialManager: TutorialManager
    @AppStorage("settings.notificationsEnabled") private var notificationsEnabled = true
    @AppStorage("settings.soundsEnabled") private var soundsEnabled = true
    @AppStorage("settings.calmModeEnabled") private var calmModeEnabled = false
    @AppStorage("settings.timezoneIdentifier") private var timezoneIdentifier = TimeZone.current.identifier

    @State private var showShareSheet = false
    @State private var showHelp = false
    @State private var showAbout = false
    @State private var showTimezonePicker = false
    @State private var showLogoutConfirmation = false
    @State private var showDeleteConfirmation = false
    @State private var showDeletePhraseConfirmation = false
    @State private var deletePhraseInput = ""
    @State private var isPublic = true
    @State private var isLoadingProfile = false
    @State private var showIntroPresentation = false

    private var timezoneLabel: String {
        let tz = TimeZone(identifier: timezoneIdentifier) ?? .current
        return tz.localizedName(for: .standard, locale: Locale(identifier: "fr_FR")) ?? tz.identifier
    }

    private let accentOrange = Color(red: 1.0, green: 0.6, blue: 0.0)
    private let accentCoral = Color(red: 1.0, green: 0.45, blue: 0.35)
    private let accentSand = Color(red: 0.98, green: 0.72, blue: 0.36)
    private let accentPeach = Color(red: 1.0, green: 0.68, blue: 0.4)
    private let accentRose = Color(red: 0.95, green: 0.55, blue: 0.62)
    private let deletePhrase = "SUPPRIMER MON COMPTE"

    private var isDeletePhraseValid: Bool {
        deletePhraseInput.trimmingCharacters(in: .whitespacesAndNewlines).uppercased() == deletePhrase
    }

    var body: some View {
        NavigationStack {
            ZStack {
                LinearGradient(
                    colors: [
                        Color.white,
                        Color.orange.opacity(0.05)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 16) {
                        SettingsProfileHeader()
                            .padding(.horizontal, 20)

                        VStack(spacing: 0) {
                            SettingsRow(
                                symbol: "eye.fill",
                                color: accentOrange,
                                title: "Profil public",
                                subtitle: isPublic ? "Visible" : "Privé"
                            ) {
                                if isLoadingProfile {
                                    ProgressView()
                                        .scaleEffect(0.8)
                                } else {
                                    Toggle("", isOn: $isPublic)
                                        .labelsHidden()
                                        .tint(accentOrange)
                                }
                            }

                            Divider()

                            SettingsRow(
                                symbol: "bell.fill",
                                color: accentCoral,
                                title: "Notifications",
                                subtitle: notificationsEnabled ? "Activées" : "Désactivées"
                            ) {
                                Toggle("", isOn: $notificationsEnabled)
                                    .labelsHidden()
                                    .tint(accentCoral)
                            }

                            Divider()

                            SettingsRow(
                                symbol: "speaker.wave.2.fill",
                                color: accentSand,
                                title: "Sons",
                                subtitle: soundsEnabled ? "Activés" : "Désactivés"
                            ) {
                                Toggle("", isOn: $soundsEnabled)
                                    .labelsHidden()
                                    .tint(accentSand)
                            }

                            Divider()

                            SettingsRow(
                                symbol: "moon.fill",
                                color: accentRose,
                                title: "Mode calme",
                                subtitle: calmModeEnabled ? "Activé" : "Désactivé"
                            ) {
                                Toggle("", isOn: $calmModeEnabled)
                                    .labelsHidden()
                                    .tint(accentRose)
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
                                    color: accentPeach,
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
                                    color: accentOrange,
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
                                    color: accentSand,
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
                                showIntroPresentation = true
                            } label: {
                                SettingsRow(
                                    symbol: "arrow.counterclockwise",
                                    color: accentCoral,
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
                                    color: accentPeach,
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
            .fullScreenCover(isPresented: $showIntroPresentation) {
                IntroPresentationView(
                    onStart: {
                        showIntroPresentation = false
                        dismiss()
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                            tutorialManager.start(force: true)
                        }
                    },
                    onSkip: {
                        showIntroPresentation = false
                        dismiss()
                        Task {
                            if let uid = Auth.auth().currentUser?.uid {
                                try? await UserManager.shared.setTutorialCompleted(uid: uid, completed: true)
                            }
                        }
                    }
                )
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
            .alert("Supprimer le compte", isPresented: $showDeleteConfirmation) {
                Button("Annuler", role: .cancel) {}
                Button("Supprimer", role: .destructive) {
                    deletePhraseInput = ""
                    showDeletePhraseConfirmation = true
                }
            } message: {
                Text("Cette action est irréversible.")
            }
            .alert("Confirmation finale", isPresented: $showDeletePhraseConfirmation) {
                TextField("Tape \(deletePhrase)", text: $deletePhraseInput)
                    .textInputAutocapitalization(.characters)
                Button("Annuler", role: .cancel) {
                    deletePhraseInput = ""
                }
                Button("Confirmer la suppression", role: .destructive) {
                    // TODO: Brancher ici la suppression définitive du compte (Auth + Firestore + Storage).
                }
                .disabled(!isDeletePhraseValid)
            } message: {
                Text("Pour confirmer, recopie exactement : \(deletePhrase)")
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

struct SettingsPhoneView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var phoneInput = ""
    @State private var savedPhone: String?
    @State private var accountPhone: String?
    @State private var isSaving = false
    @State private var feedbackMessage: String?

    private var isVerified: Bool {
        guard let savedPhone, let accountPhone else { return false }
        return savedPhone == accountPhone
    }

    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 16) {
                Text("Ajoute un numéro pour améliorer les suggestions d'amis via contacts.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                if let savedPhone {
                    HStack {
                        Text("Numéro enregistré : \(mask(savedPhone))")
                            .font(.subheadline.weight(.semibold))
                        Spacer()
                        Text(isVerified ? "Vérifié" : "Non vérifié")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(isVerified ? .green : .orange)
                    }
                    .padding(12)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color(uiColor: .secondarySystemBackground))
                    )
                }

                TextField("Ex: +33612345678", text: $phoneInput)
                    .textInputAutocapitalization(.never)
                    .keyboardType(.phonePad)
                    .padding(12)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color(uiColor: .secondarySystemBackground))
                    )

                if let accountPhone {
                    Button {
                        phoneInput = accountPhone
                    } label: {
                        Label("Utiliser le numéro du compte", systemImage: "arrow.down.circle")
                            .font(.subheadline.weight(.semibold))
                    }
                    .buttonStyle(.bordered)
                }

                Button {
                    Task { await savePhone() }
                } label: {
                    if isSaving {
                        ProgressView()
                            .frame(maxWidth: .infinity)
                    } else {
                        Text("Enregistrer")
                            .fontWeight(.semibold)
                            .frame(maxWidth: .infinity)
                    }
                }
                .buttonStyle(.borderedProminent)
                .tint(.orange)
                .disabled(isSaving)

                if let feedbackMessage {
                    Text(feedbackMessage)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()
            }
            .padding(20)
            .navigationTitle("Numéro")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Fermer") { dismiss() }
                }
            }
            .onAppear {
                accountPhone = UserManager.normalizeToE164(Auth.auth().currentUser?.phoneNumber)
                Task { await loadSavedPhone() }
            }
        }
    }

    private func loadSavedPhone() async {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        if let data = try? await UserManager.shared.getUserProfile(uid: uid) {
            await MainActor.run {
                savedPhone = UserManager.normalizeToE164(data.phoneE164)
            }
        }
    }

    private func savePhone() async {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        let normalized = UserManager.normalizeToE164(phoneInput)
        guard let normalized else {
            await MainActor.run {
                feedbackMessage = "Numéro invalide. Utilise un format international (ex: +33...)."
            }
            return
        }

        await MainActor.run {
            isSaving = true
            feedbackMessage = nil
        }

        do {
            try await Firestore.firestore().collection("users").document(uid).setData(
                ["phone_e164": normalized],
                merge: true
            )
            await MainActor.run {
                savedPhone = normalized
                feedbackMessage = "Numéro enregistré."
                isSaving = false
            }
        } catch {
            await MainActor.run {
                feedbackMessage = "Impossible d'enregistrer le numéro."
                isSaving = false
            }
        }
    }

    private func mask(_ phone: String) -> String {
        let digits = phone.filter(\.isNumber)
        guard digits.count > 4 else { return phone }
        let suffix = digits.suffix(2)
        return "••••••\(suffix)"
    }
}

struct SettingsAboutView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var showTerms = false
    @State private var showPrivacy = false

    var body: some View {
        NavigationStack {
            VStack(spacing: 16) {
                Text("Hourglass")
                    .font(.title2)
                    .fontWeight(.bold)

                Text("L'app qui transforme tes journées en grains de vie.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)

                Button {
                    showTerms = true
                } label: {
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Conditions générales d'utilisation")
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(.primary)
                            Text("Consulter les règles d'utilisation de l'app")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                        Image(systemName: "chevron.right")
                            .foregroundStyle(.secondary)
                    }
                    .padding(14)
                    .background(
                        RoundedRectangle(cornerRadius: 14)
                            .fill(Color(uiColor: .secondarySystemBackground))
                    )
                }
                .buttonStyle(.plain)

                Button {
                    showPrivacy = true
                } label: {
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Politique de confidentialité")
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(.primary)
                            Text("Comprendre quelles données sont utilisées")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                        Image(systemName: "chevron.right")
                            .foregroundStyle(.secondary)
                    }
                    .padding(14)
                    .background(
                        RoundedRectangle(cornerRadius: 14)
                            .fill(Color(uiColor: .secondarySystemBackground))
                    )
                }
                .buttonStyle(.plain)

                Spacer()
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
            .padding(24)
            .navigationTitle("À propos")
            .navigationBarTitleDisplayMode(.inline)
            .tint(.orange)
            .sheet(isPresented: $showTerms) {
                SettingsTermsView()
            }
            .sheet(isPresented: $showPrivacy) {
                SettingsPrivacyView()
            }
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Fermer") { dismiss() }
                        .fontWeight(.semibold)
                        .foregroundStyle(.orange)
                }
            }
        }
    }
}

struct SettingsTermsView: View {
    @Environment(\.dismiss) private var dismiss
    private let lastUpdate = "3 février 2026"

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 14) {
                    Text("Conditions Générales d'Utilisation")
                        .font(.title3.weight(.bold))
                    Text("Dernière mise à jour : \(lastUpdate)")
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    ForEach(Array(termsSections.enumerated()), id: \.offset) { _, section in
                        sectionTitle(section.title)
                        ForEach(Array(section.paragraphs.enumerated()), id: \.offset) { _, paragraph in
                            sectionText(paragraph)
                        }
                        if !section.bullets.isEmpty {
                            VStack(alignment: .leading, spacing: 6) {
                                ForEach(Array(section.bullets.enumerated()), id: \.offset) { _, bullet in
                                    Text("• \(bullet)")
                                        .font(.footnote)
                                        .foregroundStyle(.secondary)
                                        .fixedSize(horizontal: false, vertical: true)
                                }
                            }
                            .padding(.top, 2)
                        }
                    }
                }
                .padding(20)
            }
            .navigationTitle("CGU")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Fermer") { dismiss() }
                }
            }
        }
    }

    private var termsSections: [TermsSection] {
        [
            TermsSection(
                title: "1. Éditeur et contact",
                paragraphs: [
                    "L'application Hourglass 4 (ci-après « l'Application ») est éditée par [Nom société / Nom prénom], [forme juridique], immatriculée sous le numéro [SIREN/SIRET], dont le siège est situé [adresse complète].",
                    "Pour toute question, vous pouvez écrire à : support [email support] ; demandes juridiques et données personnelles [email juridique]."
                ]
            ),
            TermsSection(
                title: "2. Acceptation des conditions",
                paragraphs: [
                    "Les présentes Conditions Générales d'Utilisation (« CGU ») encadrent l'accès et l'utilisation de l'Application.",
                    "En créant un compte ou en utilisant l'Application, vous reconnaissez avoir lu et accepté les CGU.",
                    "Si vous n'acceptez pas ces CGU, vous ne devez pas utiliser l'Application."
                ]
            ),
            TermsSection(
                title: "3. Âge minimum et utilisateurs mineurs",
                paragraphs: [
                    "L'Application n'est pas destinée aux utilisateurs de moins de 13 ans.",
                    "Si vous avez entre 13 et 15 ans, vous déclarez disposer de l'autorisation de votre représentant légal pour utiliser l'Application.",
                    "En cas de doute sur la compréhension de ces CGU, demandez l'aide d'un adulte de confiance."
                ]
            ),
            TermsSection(
                title: "4. Objet de l'application",
                paragraphs: [
                    "Hourglass 4 permet de créer des objectifs quotidiens, de les valider, de suivre votre progression via un système de grains et d'interagir avec d'autres utilisateurs."
                ]
            ),
            TermsSection(
                title: "5. Création de compte et sécurité",
                paragraphs: [
                    "Vous vous engagez à fournir des informations exactes lors de la création et de la gestion de votre compte.",
                    "Vous êtes responsable de la confidentialité de vos identifiants, de votre appareil et de toute action effectuée depuis votre compte.",
                    "Vous devez nous signaler rapidement toute utilisation non autorisée de votre compte."
                ]
            ),
            TermsSection(
                title: "6. Disponibilité de l'application",
                paragraphs: [
                    "L'Application est fournie « en l'état ». Nous faisons des efforts raisonnables pour en assurer la continuité, sans garantie d'absence d'interruption, de bug ou d'indisponibilité temporaire.",
                    "Des opérations de maintenance, des mises à jour ou des incidents techniques peuvent affecter l'accès au service."
                ]
            ),
            TermsSection(
                title: "7. Utilisation autorisée",
                paragraphs: [
                    "Vous vous engagez à utiliser l'application conformément à la loi et de manière respectueuse des autres."
                ],
                bullets: [
                    "Contenus illicites, haineux, menaçants ou harcelants interdits.",
                    "Usurpation d'identité, fraude et automatisation abusive interdites.",
                    "Tentatives de perturbation technique du service interdites."
                ]
            ),
            TermsSection(
                title: "8. Règles communautaires",
                paragraphs: [
                    "Les échanges doivent rester respectueux. Toute forme de harcèlement, intimidation, discrimination ou diffusion de contenus choquants est interdite.",
                    "Nous pouvons modérer les contenus, masquer certains éléments ou restreindre des interactions afin de préserver un environnement sûr."
                ]
            ),
            TermsSection(
                title: "9. Fonctionnement des objectifs quotidiens",
                paragraphs: [
                    "Vous définissez vous-même vos objectifs quotidiens. L'Application propose des suggestions, mais vous restez responsable de vos choix.",
                    "Hourglass 4 ne constitue pas un service médical, psychologique ou de coaching professionnel.",
                    "Vous devez adapter vos objectifs à votre situation personnelle, votre santé et vos capacités."
                ]
            ),
            TermsSection(
                title: "10. Grains et progression",
                paragraphs: [
                    "Les grains sont une mécanique interne de progression et de motivation.",
                    "Le calcul des grains peut évoluer pour améliorer l'expérience utilisateur."
                ],
                bullets: [
                    "Les grains n'ont aucune valeur monétaire.",
                    "Ils ne peuvent pas être convertis en argent, en cryptomonnaie ou en avantage financier.",
                    "Ils ne constituent pas un droit patrimonial ni un titre de propriété."
                ]
            ),
            TermsSection(
                title: "11. Complices, fil et interactions",
                paragraphs: [
                    "Vous êtes responsable de vos interactions sociales (amis, commentaires, messages, réactions).",
                    "Hourglass 4 peut limiter certaines fonctionnalités sociales en cas d'abus, de spam ou de non-respect des CGU."
                ]
            ),
            TermsSection(
                title: "12. Contenus publiés",
                paragraphs: [
                    "Vous restez propriétaire des contenus que vous publiez dans l'Application.",
                    "En publiant un contenu, vous accordez à Hourglass 4 une licence non exclusive, mondiale, gratuite et limitée au fonctionnement du service pour héberger, traiter, afficher et distribuer ce contenu au sein de l'Application.",
                    "Cette licence prend fin lorsque le contenu est supprimé, sous réserve des obligations légales de conservation."
                ],
                bullets: [
                    "Vous garantissez disposer des droits nécessaires sur les contenus que vous publiez.",
                    "Vous vous engagez à ne pas publier de contenu portant atteinte aux droits de tiers."
                ]
            ),
            TermsSection(
                title: "13. Contenus signalés et modération",
                paragraphs: [
                    "Tout utilisateur peut signaler un contenu ou un comportement qu'il estime contraire aux CGU ou à la loi.",
                    "Nous pouvons, selon la gravité des faits, supprimer un contenu, masquer un profil, suspendre temporairement un compte ou procéder à une suppression définitive."
                ]
            ),
            TermsSection(
                title: "14. Notifications et permissions",
                paragraphs: [
                    "Si vous activez les notifications, Hourglass 4 peut vous envoyer des rappels liés à vos objectifs et à l'activité de l'application.",
                    "Vous pouvez modifier les permissions à tout moment depuis l'application ou les réglages iOS."
                ]
            ),
            TermsSection(
                title: "15. Services tiers et dépendances techniques",
                paragraphs: [
                    "L'Application peut s'appuyer sur des services tiers (par exemple hébergement cloud, envoi de notifications, authentification).",
                    "Leur indisponibilité peut impacter temporairement certaines fonctionnalités sans engager la responsabilité d'Hourglass 4 au-delà des obligations légales applicables."
                ]
            ),
            TermsSection(
                title: "16. Propriété intellectuelle",
                paragraphs: [
                    "Le code, l'interface, les éléments graphiques, la marque « Hourglass 4 » et les éléments distinctifs de l'Application sont protégés par les lois sur la propriété intellectuelle.",
                    "Toute reproduction, extraction, décompilation, adaptation ou réutilisation non autorisée est interdite, sauf disposition légale impérative."
                ]
            ),
            TermsSection(
                title: "17. Suspension et suppression de compte",
                paragraphs: [
                    "Nous pouvons suspendre ou supprimer un compte en cas de violation des CGU, d'abus ou de risque de sécurité.",
                    "Vous pouvez demander la suppression de votre compte selon les modalités prévues dans l'application."
                ]
            ),
            TermsSection(
                title: "18. Résiliation par l'utilisateur",
                paragraphs: [
                    "Vous pouvez cesser d'utiliser l'Application à tout moment.",
                    "La désinstallation de l'Application ne supprime pas automatiquement votre compte ; utilisez la fonction de suppression prévue dans les réglages de l'app."
                ]
            ),
            TermsSection(
                title: "19. Limitation de responsabilité",
                paragraphs: [
                    "Dans les limites autorisées par la loi, Hourglass 4 ne pourra pas être tenue responsable des dommages indirects, immatériels ou consécutifs liés à l'usage de l'Application.",
                    "Vous utilisez l'Application sous votre responsabilité, notamment pour les choix d'objectifs personnels, physiques ou organisationnels."
                ]
            ),
            TermsSection(
                title: "20. Données personnelles",
                paragraphs: [
                    "Le traitement des données personnelles est encadré par la Politique de confidentialité de l'Application.",
                    "Cette politique précise les catégories de données, les finalités de traitement, les durées de conservation et vos droits."
                ]
            ),
            TermsSection(
                title: "21. Modifications des CGU",
                paragraphs: [
                    "Nous pouvons modifier les présentes CGU pour refléter une évolution du service, des obligations légales ou des mesures de sécurité.",
                    "En cas de modification substantielle, une information sera affichée dans l'Application."
                ]
            ),
            TermsSection(
                title: "22. Droit applicable et juridiction",
                paragraphs: [
                    "Sauf disposition impérative contraire, les présentes CGU sont soumises au droit français.",
                    "En cas de litige, et après tentative de résolution amiable, compétence est attribuée aux juridictions du ressort de [ville], sous réserve des règles protectrices applicables aux consommateurs."
                ]
            ),
            TermsSection(
                title: "23. Contact",
                paragraphs: [
                    "Pour toute question relative aux présentes CGU : [email support/juridique].",
                    "Adresse postale : [adresse postale complète].",
                    "Nous vous recommandons de conserver une copie des CGU à jour."
                ]
            )
        ]
    }

    private func sectionTitle(_ text: String) -> some View {
        Text(text)
            .font(.subheadline.weight(.semibold))
            .foregroundStyle(.primary)
            .padding(.top, 4)
    }

    private func sectionText(_ text: String) -> some View {
        Text(text)
            .font(.footnote)
            .foregroundStyle(.secondary)
            .fixedSize(horizontal: false, vertical: true)
    }

    private struct TermsSection {
        let title: String
        let paragraphs: [String]
        var bullets: [String] = []
    }
}

struct SettingsPrivacyView: View {
    @Environment(\.dismiss) private var dismiss
    private let lastUpdate = "3 février 2026"

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 14) {
                    Text("Politique de confidentialité")
                        .font(.title3.weight(.bold))
                    Text("Dernière mise à jour : \(lastUpdate)")
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    ForEach(Array(sections.enumerated()), id: \.offset) { _, section in
                        sectionTitle(section.title)
                        ForEach(Array(section.paragraphs.enumerated()), id: \.offset) { _, paragraph in
                            sectionText(paragraph)
                        }
                        if !section.bullets.isEmpty {
                            VStack(alignment: .leading, spacing: 6) {
                                ForEach(Array(section.bullets.enumerated()), id: \.offset) { _, bullet in
                                    Text("• \(bullet)")
                                        .font(.footnote)
                                        .foregroundStyle(.secondary)
                                        .fixedSize(horizontal: false, vertical: true)
                                }
                            }
                            .padding(.top, 2)
                        }
                    }
                }
                .padding(20)
            }
            .navigationTitle("Confidentialité")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Fermer") { dismiss() }
                }
            }
        }
    }

    private var sections: [PrivacySection] {
        [
            PrivacySection(
                title: "1. Qui est responsable du traitement ?",
                paragraphs: [
                    "Le responsable du traitement des données de l'application Hourglass 4 est [Nom société / Nom prénom], [forme juridique], [adresse complète].",
                    "Contact support : [email support]. Contact données personnelles : [email juridique]."
                ]
            ),
            PrivacySection(
                title: "2. Données que nous collectons",
                paragraphs: [
                    "Nous collectons les données que vous fournissez directement dans l'app et certaines données techniques nécessaires au fonctionnement."
                ],
                bullets: [
                    "Compte : identifiant, pseudo, photo de profil (si fournie).",
                    "Objectifs et progression : objectifs créés, validations, grains, interactions.",
                    "Social : complices, commentaires, réactions, partages.",
                    "Support : messages envoyés au support.",
                    "Technique : type d'appareil, version iOS, logs d'erreurs, identifiants techniques."
                ]
            ),
            PrivacySection(
                title: "3. Permissions de l'app",
                paragraphs: [
                    "Certaines fonctionnalités nécessitent votre autorisation explicite."
                ],
                bullets: [
                    "Notifications : rappels objectifs et activité du fil.",
                    "Photos/caméra : publication de contenus (si activé).",
                    "Contacts : suggestion de complices (si activé)."
                ]
            ),
            PrivacySection(
                title: "4. Pourquoi nous utilisons vos données",
                paragraphs: [
                    "Nous traitons vos données pour fournir le service, sécuriser les comptes, améliorer l'app et respecter la loi."
                ],
                bullets: [
                    "Créer et gérer votre compte.",
                    "Afficher vos objectifs, votre progression et vos interactions.",
                    "Envoyer des notifications si vous les avez acceptées.",
                    "Prévenir les abus, fraudes et contenus interdits.",
                    "Mesurer la performance technique de l'app."
                ]
            ),
            PrivacySection(
                title: "5. Base légale des traitements",
                paragraphs: [
                    "Selon les cas, les traitements reposent sur l'exécution du service, votre consentement, notre intérêt légitime ou nos obligations légales."
                ]
            ),
            PrivacySection(
                title: "6. Partage des données",
                paragraphs: [
                    "Nous ne vendons pas vos données personnelles.",
                    "Vos données peuvent être partagées uniquement avec des prestataires nécessaires au fonctionnement du service ou lorsque la loi l'impose."
                ],
                bullets: [
                    "Hébergement et base de données.",
                    "Services de notifications push.",
                    "Outils de sécurité et de monitoring.",
                    "Autorités compétentes en cas d'obligation légale."
                ]
            ),
            PrivacySection(
                title: "7. Durée de conservation",
                paragraphs: [
                    "Nous conservons les données pendant la durée nécessaire au service et aux obligations légales, puis nous les supprimons ou les anonymisons."
                ]
            ),
            PrivacySection(
                title: "8. Vos droits",
                paragraphs: [
                    "Conformément à la réglementation applicable (RGPD et lois locales), vous pouvez exercer vos droits."
                ],
                bullets: [
                    "Accès à vos données.",
                    "Rectification des données inexactes.",
                    "Suppression de votre compte et de vos données, sous réserve d'obligations légales.",
                    "Opposition ou limitation de certains traitements.",
                    "Retrait du consentement (ex: notifications).",
                    "Portabilité, lorsque applicable."
                ]
            ),
            PrivacySection(
                title: "9. Sécurité",
                paragraphs: [
                    "Nous appliquons des mesures techniques et organisationnelles raisonnables pour protéger vos données contre l'accès non autorisé, la perte ou l'altération."
                ]
            ),
            PrivacySection(
                title: "10. Mineurs",
                paragraphs: [
                    "L'application n'est pas destinée aux enfants de moins de 13 ans. Si nous apprenons qu'un tel compte a été créé, il pourra être supprimé."
                ]
            ),
            PrivacySection(
                title: "11. Transferts internationaux",
                paragraphs: [
                    "Si certains prestataires traitent des données hors de votre pays, nous mettons en place des garanties adaptées (par exemple clauses contractuelles types lorsque nécessaire)."
                ]
            ),
            PrivacySection(
                title: "12. Modifications de cette politique",
                paragraphs: [
                    "Cette politique peut évoluer. En cas de modification importante, une information sera affichée dans l'application."
                ]
            ),
            PrivacySection(
                title: "13. Contact et réclamation",
                paragraphs: [
                    "Pour toute demande liée à vos données : [email juridique].",
                    "Adresse postale : [adresse complète].",
                    "Si vous estimez que vos droits ne sont pas respectés, vous pouvez saisir l'autorité de contrôle compétente (ex : CNIL en France)."
                ]
            )
        ]
    }

    private func sectionTitle(_ text: String) -> some View {
        Text(text)
            .font(.subheadline.weight(.semibold))
            .foregroundStyle(.primary)
            .padding(.top, 4)
    }

    private func sectionText(_ text: String) -> some View {
        Text(text)
            .font(.footnote)
            .foregroundStyle(.secondary)
            .fixedSize(horizontal: false, vertical: true)
    }

    private struct PrivacySection {
        let title: String
        let paragraphs: [String]
        var bullets: [String] = []
    }
}

struct ShareSheet: UIViewControllerRepresentable {
    let activityItems: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: activityItems, applicationActivities: nil)
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

struct EditProfileView: View {
    let viewModel: HourglassViewModel?
    @Environment(\.dismiss) private var dismiss
    @State private var fullName = ""
    @State private var username = ""
    @State private var email = ""
    @State private var phoneInput = ""
    @State private var selectedGender: Gender = .notSpecified
    @State private var birthDate = Date()
    @State private var isPublic = true
    @State private var isLoading = true
    @State private var isSaving = false
    @State private var profileImageURL: String? = nil
    @State private var usernameAvailable: Bool? = nil
    @State private var isCheckingUsername = false
    @State private var originalUsernameLower = ""
    @State private var originalUsername = ""
    @State private var usernameLastChangedAt: Date? = nil
    @State private var isBackfilling = false
    @State private var errorMessage: String?
    @State private var successMessage: String?

    var body: some View {
        NavigationStack {
            if isLoading {
                ProgressView()
            } else {
                ZStack {
                    LinearGradient(
                        colors: [
                            Color(uiColor: .systemGroupedBackground),
                            Color.orange.opacity(0.05)
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                    .ignoresSafeArea()

                    ScrollView(showsIndicators: false) {
                        VStack(spacing: 20) {
                            profileHeader
                            personalInfoCard
                            additionalInfoCard
                            securityCard
                            privacyCard

                            if let errorMessage {
                                Text(errorMessage)
                                    .font(.footnote)
                                    .foregroundStyle(.red)
                            }

                            if let successMessage {
                                Text(successMessage)
                                    .font(.footnote)
                                    .foregroundStyle(.secondary)
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.top, 16)
                        .padding(.bottom, 32)
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

    private var profileHeader: some View {
        VStack(spacing: 8) {
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [
                                Color.orange.opacity(0.18),
                                Color.orange.opacity(0.04)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 64, height: 64)

                ProfileImageView(
                    imageURL: profileImageURL,
                    username: username.isEmpty ? "user" : username,
                    size: 56,
                    gradientColors: [.orange, .orange.opacity(0.6)]
                )
                .overlay {
                    Circle()
                        .stroke(Color.orange.opacity(0.2), lineWidth: 1)
                }
            }

        }
        .frame(maxWidth: .infinity)
        .padding(.top, 0)
    }

    private var personalInfoCard: some View {
        VStack(spacing: 12) {
            Text("Identité")
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(.secondary)
                .frame(maxWidth: .infinity, alignment: .leading)

            HStack(spacing: 10) {
                Image(systemName: "person")
                    .foregroundStyle(.orange)
                TextField("Nom complet", text: $fullName)
                    .textContentType(.name)
                    .textInputAutocapitalization(.words)
                    .autocorrectionDisabled(true)
                    .font(.subheadline)
            }
            .padding(14)
            .background(fieldBackground)

            VStack(alignment: .leading, spacing: 6) {
                ZStack(alignment: .trailing) {
                    HStack(spacing: 10) {
                        Image(systemName: "at")
                            .foregroundStyle(.orange)
                        TextField("Nom d'utilisateur", text: $username)
                            .textInputAutocapitalization(.never)
                            .autocorrectionDisabled(true)
                            .onChange(of: username) { _, _ in
                                checkUsernameAvailability()
                            }
                            .font(.subheadline)
                    }
                    .padding(14)
                    .padding(.trailing, 40)
                    .background(fieldBackground)

                    if isCheckingUsername {
                        ProgressView()
                            .padding(.trailing, 12)
                    } else if let available = usernameAvailable {
                        Image(systemName: available ? "checkmark.circle.fill" : "xmark.circle.fill")
                            .foregroundColor(available ? .green : .red)
                            .padding(.trailing, 12)
                    }
                }

                if let available = usernameAvailable, !available {
                    Text("Ce nom d'utilisateur est déjà pris")
                        .font(.caption)
                        .foregroundColor(.red)
                        .padding(.leading, 4)
                }

                if let message = usernameChangeMessage() {
                    Text(message)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .padding(.leading, 4)
                }
            }

            HStack(spacing: 10) {
                Image(systemName: "envelope")
                    .foregroundStyle(.orange)
                TextField("Email", text: $email)
                    .textInputAutocapitalization(.never)
                    .keyboardType(.emailAddress)
                    .disabled(true)
                    .foregroundStyle(.secondary)
                    .font(.subheadline)
            }
            .padding(14)
            .background(fieldBackground)

            VStack(alignment: .leading, spacing: 6) {
                HStack(spacing: 10) {
                    Image(systemName: "phone")
                        .foregroundStyle(.orange)
                    TextField("Ex: +33612345678", text: $phoneInput)
                        .textInputAutocapitalization(.never)
                        .keyboardType(.phonePad)
                        .font(.subheadline)
                }
                .padding(14)
                .background(fieldBackground)

                Text(phoneHint)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .padding(.leading, 4)
            }
        }
        .padding(18)
        .background(cardBackground)
    }

    private var phoneHint: String {
        let saved = UserManager.normalizeToE164(phoneInput)
        let account = UserManager.normalizeToE164(Auth.auth().currentUser?.phoneNumber)
        if let saved, let account, saved == account {
            return "Numéro vérifié"
        }
        return "Format international recommandé (ex: +33...)."
    }

    private var additionalInfoCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Informations supplémentaires")
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(.secondary)

            Picker("Genre", selection: $selectedGender) {
                ForEach(Gender.allCases, id: \.self) { gender in
                    Text(gender.displayName).tag(gender)
                }
            }
            .pickerStyle(.segmented)
            .tint(.orange)

            HStack {
                Text("Date de naissance")
                    .font(.subheadline)
                Spacer()
                DatePicker(
                    "",
                    selection: $birthDate,
                    in: ...Date(),
                    displayedComponents: .date
                )
                .labelsHidden()
            }
            .padding(12)
            .background(fieldBackground)
        }
        .padding(18)
        .background(cardBackground)
    }

    private var securityCard: some View {
        let hasPasswordProvider = Auth.auth().currentUser?.providerData.contains(where: { $0.providerID == "password" }) ?? false

        return VStack(alignment: .leading, spacing: 12) {
            Text("Sécurité")
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(.secondary)

            NavigationLink {
                ChangePasswordView()
            } label: {
                HStack(spacing: 10) {
                    Image(systemName: "lock.fill")
                        .foregroundStyle(.orange)
                    Text("Modifier le mot de passe")
                        .font(.subheadline)
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .padding(12)
                .background(fieldBackground)
            }
            .buttonStyle(.plain)
            .disabled(!hasPasswordProvider)
            .opacity(hasPasswordProvider ? 1 : 0.5)

            if !hasPasswordProvider {
                Text("Compte sans mot de passe (Apple/Google).")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(18)
        .background(cardBackground)
    }

    private var privacyCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Confidentialité")
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(.secondary)

            Toggle("Profil public", isOn: $isPublic)
                .tint(.orange)
            Text("Contrôle la visibilité de ton profil pour les autres.")
                .font(.caption2)
                .foregroundStyle(.secondary)

            if isAdminEmail(email) {
                Button {
                    backfillUsernames()
                } label: {
                    HStack {
                        if isBackfilling {
                            ProgressView()
                                .scaleEffect(0.9)
                        }
                        Text("Synchroniser les usernames (admin)")
                    }
                }
                .disabled(isBackfilling)
                .font(.footnote)
                .foregroundStyle(.orange)
            }
        }
        .padding(18)
        .background(cardBackground)
    }

    private var cardBackground: some View {
        RoundedRectangle(cornerRadius: 18)
            .fill(
                LinearGradient(
                    colors: [
                        Color(uiColor: .systemBackground),
                        Color.orange.opacity(0.04)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .overlay {
                RoundedRectangle(cornerRadius: 18)
                    .stroke(Color.orange.opacity(0.06), lineWidth: 1)
            }
            .shadow(color: .black.opacity(0.06), radius: 16, x: 0, y: 8)
    }

    private var fieldBackground: some View {
        RoundedRectangle(cornerRadius: 14)
            .fill(Color(uiColor: .secondarySystemBackground))
            .overlay {
                RoundedRectangle(cornerRadius: 14)
                    .stroke(Color.orange.opacity(0.08), lineWidth: 1)
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
                    phoneInput = UserManager.normalizeToE164(data?.phoneE164) ?? UserManager.normalizeToE164(currentUser.phoneNumber) ?? ""
                    selectedGender = data?.gender ?? .notSpecified
                    birthDate = data?.birthDate ?? Date()
                    isPublic = data?.isPublic ?? true
                    profileImageURL = data?.profileImageURL
                    originalUsername = data?.username ?? ""
                    originalUsernameLower = originalUsername.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
                    usernameLastChangedAt = data?.usernameLastChangedAt
                    usernameAvailable = true
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

        let trimmedUsername = username.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedUsernameLower = trimmedUsername.lowercased()

        guard !trimmedUsername.isEmpty else {
            errorMessage = "Le nom d'utilisateur est obligatoire."
            return
        }
        guard trimmedUsername.count >= 3 else {
            errorMessage = "Le nom d'utilisateur doit contenir au moins 3 caractères."
            return
        }
        if trimmedUsernameLower != originalUsernameLower, usernameAvailable != true {
            errorMessage = "Ce nom d'utilisateur n'est pas disponible."
            return
        }

        if trimmedUsernameLower != originalUsernameLower,
           let lastChange = usernameLastChangedAt,
           let nextAllowed = nextUsernameChangeDate(from: lastChange),
           Date() < nextAllowed {
            errorMessage = "Tu pourras changer ton nom d'utilisateur le \(formatDate(nextAllowed))."
            return
        }

        isSaving = true
        errorMessage = nil
        successMessage = nil

        let trimmedPhone = phoneInput.trimmingCharacters(in: .whitespacesAndNewlines)
        let normalizedPhone = UserManager.normalizeToE164(trimmedPhone)
        if !trimmedPhone.isEmpty && normalizedPhone == nil {
            isSaving = false
            errorMessage = "Numéro invalide. Utilise un format international (ex: +33612345678)."
            return
        }

        Task {
            do {
                if trimmedUsernameLower != originalUsernameLower {
                    try await UserManager.shared.claimUsername(
                        trimmedUsername,
                        previousUsername: originalUsernameLower
                    )
                }

                // Mettre à jour le profil dans Firestore (hors username)
                let db = Firestore.firestore()
                try await db.collection("users").document(currentUser.uid).updateData([
                    "displayName": fullName,
                    "gender": selectedGender.rawValue,
                    "birthDate": Timestamp(date: birthDate),
                    "isPublic": isPublic,
                    "phone_e164": normalizedPhone ?? ""
                ])

                await MainActor.run {
                    UserManager.shared.cachedUsers.removeValue(forKey: currentUser.uid)
                    if trimmedUsernameLower != originalUsernameLower {
                        FindFriendViewModelV2.saveCurrentUsername(trimmedUsername)
                        originalUsername = trimmedUsername
                        originalUsernameLower = trimmedUsernameLower
                        usernameLastChangedAt = Date()
                    }

                    isSaving = false
                    successMessage = "Profil mis à jour !"
                    NotificationCenter.default.post(name: .profileDidUpdate, object: nil)

                    // Fermer après 1.5 secondes
                    Task {
                        try? await Task.sleep(nanoseconds: 1_500_000_000)
                        dismiss()
                    }
                }
            } catch {
                await MainActor.run {
                    isSaving = false
                    errorMessage = "Erreur : \(mapFunctionsError(error))"
                }
            }
        }
    }

    private func checkUsernameAvailability() {
        let trimmedUsername = username.trimmingCharacters(in: .whitespacesAndNewlines)
        let normalizedUsername = trimmedUsername.lowercased()

        guard trimmedUsername.count >= 3 else {
            usernameAvailable = nil
            isCheckingUsername = false
            return
        }

        if normalizedUsername == originalUsernameLower {
            usernameAvailable = true
            isCheckingUsername = false
            return
        }

        isCheckingUsername = true
        usernameAvailable = nil

        Task {
            do {
                let available = try await UserManager.shared.isUsernameAvailable(trimmedUsername)
                await MainActor.run {
                    isCheckingUsername = false
                    usernameAvailable = available
                }
            } catch {
                await MainActor.run {
                    isCheckingUsername = false
                    usernameAvailable = nil
                }
            }
        }
    }

    private func backfillUsernames() {
        guard !isBackfilling else { return }
        isBackfilling = true
        errorMessage = nil
        successMessage = nil

        Task {
            do {
                let result = try await UserManager.shared.backfillUsernames()
                let created = intValue(result["created"])
                let skipped = intValue(result["skipped"])
                let conflicts = intValue(result["conflicts"])
                await MainActor.run {
                    isBackfilling = false
                    successMessage = "Backfill OK: \(created) créés, \(skipped) ignorés, \(conflicts) conflits."
                }
            } catch {
                await MainActor.run {
                    isBackfilling = false
                    errorMessage = "Erreur backfill: \(mapFunctionsError(error))"
                }
            }
        }
    }

    private func mapFunctionsError(_ error: Error) -> String {
        let nsError = error as NSError
        if nsError.domain == FunctionsErrorDomain {
            if let message = nsError.userInfo[NSLocalizedDescriptionKey] as? String, !message.isEmpty {
                return message
            }
            if let details = nsError.userInfo[FunctionsErrorDetailsKey] as? String, !details.isEmpty {
                return details
            }
            if let code = FunctionsErrorCode(rawValue: nsError.code) {
                switch code {
                case .alreadyExists:
                    return "Ce nom d'utilisateur est déjà pris."
                case .permissionDenied:
                    return "Accès refusé."
                case .unauthenticated:
                    return "Utilisateur non connecté."
                case .invalidArgument:
                    return "Données invalides."
                default:
                    break
                }
            }
            return "Erreur Functions (\(nsError.code))"
        }
        return "\(error.localizedDescription) (\(nsError.domain) \(nsError.code))"
    }

    private func usernameChangeMessage() -> String? {
        guard let lastChange = usernameLastChangedAt else {
            return "Changement possible tous les 6 mois."
        }

        guard let nextAllowed = nextUsernameChangeDate(from: lastChange) else {
            return nil
        }

        if Date() < nextAllowed {
            return "Changement possible tous les 6 mois. Prochain changement: \(formatDate(nextAllowed))."
        }

        return "Changement possible tous les 6 mois."
    }

    private func nextUsernameChangeDate(from lastChange: Date) -> Date? {
        Calendar.current.date(byAdding: .month, value: 6, to: lastChange)
    }

    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "dd/MM/yyyy"
        return formatter.string(from: date)
    }

    private func intValue(_ value: Any?) -> Int {
        if let number = value as? NSNumber { return number.intValue }
        if let int = value as? Int { return int }
        return 0
    }

    private func isAdminEmail(_ value: String) -> Bool {
        let normalized = value.lowercased()
        return normalized == "soula.corentin@icloud.com" || normalized == "soula.corentin@gmail.com"
    }
}

struct ChangePasswordView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var currentPassword = ""
    @State private var newPassword = ""
    @State private var confirmPassword = ""
    @State private var isSaving = false
    @State private var errorMessage: String?
    @State private var successMessage: String?

    private var hasPasswordProvider: Bool {
        Auth.auth().currentUser?.providerData.contains(where: { $0.providerID == "password" }) ?? false
    }

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [
                    Color(uiColor: .systemGroupedBackground),
                    Color.orange.opacity(0.05)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(spacing: 16) {
                    VStack(spacing: 12) {
                        SecureField("Mot de passe actuel", text: $currentPassword)
                            .textContentType(.password)
                            .padding(14)
                            .background(fieldBackground)

                        SecureField("Nouveau mot de passe", text: $newPassword)
                            .textContentType(.newPassword)
                            .padding(14)
                            .background(fieldBackground)

                        SecureField("Confirmer le nouveau mot de passe", text: $confirmPassword)
                            .textContentType(.newPassword)
                            .padding(14)
                            .background(fieldBackground)
                    }
                    .padding(18)
                    .background(cardBackground)

                    if let errorMessage {
                        Text(errorMessage)
                            .font(.footnote)
                            .foregroundStyle(.red)
                    }

                    if let successMessage {
                        Text(successMessage)
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }

                    Button {
                        changePassword()
                    } label: {
                        HStack(spacing: 8) {
                            if isSaving {
                                ProgressView()
                                    .scaleEffect(0.9)
                            }
                            Text("Mettre à jour")
                                .font(.subheadline.weight(.semibold))
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(Capsule().fill(Color.orange))
                        .foregroundStyle(.white)
                    }
                    .disabled(isSaving || !hasPasswordProvider)
                    .opacity(hasPasswordProvider ? 1 : 0.5)
                }
                .padding(.horizontal, 20)
                .padding(.top, 16)
                .padding(.bottom, 32)
            }
        }
        .navigationTitle("Mot de passe")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Fermer") { dismiss() }
            }
        }
    }

    private var cardBackground: some View {
        RoundedRectangle(cornerRadius: 18)
            .fill(
                LinearGradient(
                    colors: [
                        Color(uiColor: .systemBackground),
                        Color.orange.opacity(0.04)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .overlay {
                RoundedRectangle(cornerRadius: 18)
                    .stroke(Color.orange.opacity(0.08), lineWidth: 1)
            }
    }

    private var fieldBackground: some View {
        RoundedRectangle(cornerRadius: 14)
            .fill(Color(uiColor: .secondarySystemBackground))
            .overlay {
                RoundedRectangle(cornerRadius: 14)
                    .stroke(Color.orange.opacity(0.08), lineWidth: 1)
            }
    }

    private func changePassword() {
        errorMessage = nil
        successMessage = nil

        guard hasPasswordProvider else {
            errorMessage = "Ce compte n'a pas de mot de passe."
            return
        }

        guard let user = Auth.auth().currentUser else {
            errorMessage = "Vous devez être connecté."
            return
        }

        guard let email = user.email else {
            errorMessage = "Email introuvable."
            return
        }

        let trimmedNew = newPassword.trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmedNew.count >= 6 else {
            errorMessage = "Le mot de passe doit faire au moins 6 caractères."
            return
        }

        guard trimmedNew == confirmPassword.trimmingCharacters(in: .whitespacesAndNewlines) else {
            errorMessage = "Les mots de passe ne correspondent pas."
            return
        }

        isSaving = true
        let credential = EmailAuthProvider.credential(withEmail: email, password: currentPassword)
        user.reauthenticate(with: credential) { _, error in
            if error != nil {
                isSaving = false
                errorMessage = "Mot de passe actuel incorrect."
                return
            }

            user.updatePassword(to: trimmedNew) { error in
                isSaving = false
                if let error {
                    errorMessage = "Erreur: \(error.localizedDescription)"
                } else {
                    successMessage = "Mot de passe mis à jour."
                    currentPassword = ""
                    newPassword = ""
                    confirmPassword = ""
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
                    TextField("Rechercher par username", text: $searchText)
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
                        Text("Recherche par nom d'utilisateur")
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
    @State private var userData: UserData? = nil
    @State private var isLoadingProfile = true

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Header avec design orange
                VStack(spacing: 16) {
                    if isLoadingProfile {
                        ZStack {
                            Circle()
                                .fill(Color.gray.opacity(0.2))
                                .frame(width: 80, height: 80)
                            ProgressView()
                        }
                    } else {
                        ProfileImageView(
                            imageURL: userData?.profileImageURL,
                            username: userData?.username ?? "U",
                            size: 80,
                            gradientColors: [.orange, Color(red: 1.0, green: 0.6, blue: 0.0)]
                        )
                        .shadow(color: .orange.opacity(0.3), radius: 12, x: 0, y: 6)
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
                    // Envoyer par SMS
                    Button {
                        sendViaSMS()
                    } label: {
                        ShareOptionRow(
                            icon: "message.fill",
                            color: .green,
                            title: "Envoyer par SMS",
                            subtitle: "Messages"
                        )
                    }
                    .buttonStyle(.plain)

                    // Envoyer par WhatsApp
                    Button {
                        sendViaWhatsApp()
                    } label: {
                        ShareOptionRow(
                            icon: "phone.bubble.fill",
                            color: Color(red: 0.15, green: 0.78, blue: 0.22),
                            title: "Envoyer par WhatsApp",
                            subtitle: "WhatsApp"
                        )
                    }
                    .buttonStyle(.plain)

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
                        ShareOptionRow(
                            icon: "square.and.arrow.up.fill",
                            color: .blue,
                            title: "Plus d'options",
                            subtitle: "Mail, Messenger, etc."
                        )
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
            .onAppear {
                loadUserProfile()
            }
        }
    }

    private func loadUserProfile() {
        guard let currentUser = Auth.auth().currentUser else {
            isLoadingProfile = false
            return
        }

        Task {
            do {
                let data = try await UserManager.shared.getUserProfile(uid: currentUser.uid)
                await MainActor.run {
                    userData = data
                    isLoadingProfile = false
                }
            } catch {
                print("Erreur lors du chargement du profil: \(error.localizedDescription)")
                await MainActor.run {
                    isLoadingProfile = false
                }
            }
        }
    }

    private func sendViaSMS() {
        guard let encodedText = shareText.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
              let smsURL = URL(string: "sms:&body=\(encodedText)") else {
            return
        }

        if UIApplication.shared.canOpenURL(smsURL) {
            UIApplication.shared.open(smsURL)
        }
    }

    private func sendViaWhatsApp() {
        guard let encodedText = shareText.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
              let whatsappURL = URL(string: "whatsapp://send?text=\(encodedText)") else {
            return
        }

        if UIApplication.shared.canOpenURL(whatsappURL) {
            UIApplication.shared.open(whatsappURL)
        }
    }
}

// MARK: - Share Option Row

struct ShareOptionRow: View {
    let icon: String
    let color: Color
    let title: String
    let subtitle: String

    var body: some View {
        HStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(color.opacity(0.15))
                    .frame(width: 56, height: 56)

                Image(systemName: icon)
                    .font(.title2)
                    .foregroundStyle(color)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                    .foregroundStyle(.primary)
                Text(subtitle)
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
}

// MARK: - InfoBubbleTriangle Shape (pour la bulle d'info)

struct InfoBubbleTriangle: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.midX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.minY))
        path.closeSubpath()
        return path
    }
}

struct InfoBubbleTriangleUp: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.midX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
        path.closeSubpath()
        return path
    }
}

#Preview {
    ProfileView(viewModel: nil)
        .environmentObject(TutorialManager.shared)
}
