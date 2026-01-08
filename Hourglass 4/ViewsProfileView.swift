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

struct ProfileView: View {
    let viewModel: HourglassViewModel?

    @State private var showEditProfile = false
    @State private var showFindFriends = false
    @State private var showMessages = false
    @State private var unreadMessagesCount = 0
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 0) {
                    // Header violet/rose "Mon Profil"
                    ProfileHeaderSection(showEditProfile: $showEditProfile)
                    
                    VStack(spacing: 24) {
                        // Card de profil principal
                        MainProfileCard(viewModel: viewModel)
                            .padding(.horizontal)
                            .padding(.top, 24)
                        
                        // Section "Mes Sabliers Complices"
            FriendsSection(showFindFriends: $showFindFriends)
                .padding(.horizontal)
                        
                        // Section Paramètres
                        SettingsSection()
                            .padding(.horizontal)
                        
                        Spacer(minLength: 40)
                    }
                }
            }
            .navigationTitle("Mon Compte")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                // Bouton Messages avec badge
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showMessages = true
                    } label: {
                        ZStack(alignment: .topTrailing) {
                            Image(systemName: "envelope.fill")
                                .foregroundStyle(.purple)

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
            .onAppear {
                Task {
                    // Charger le nombre de messages non lus
                    unreadMessagesCount = (try? await FriendMessageManager.shared.getUnreadMessagesCount()) ?? 0
                }
            }
        }
    }
}

// MARK: - Profile Header Section (Violet/Rose)

struct ProfileHeaderSection: View {
    @Binding var showEditProfile: Bool
    
    var body: some View {
        ZStack {
            // Gradient violet/rose
            LinearGradient(
                colors: [
                    Color(red: 0.7, green: 0.4, blue: 0.9),  // Violet
                    Color(red: 0.9, green: 0.4, blue: 0.7)   // Rose
                ],
                startPoint: .leading,
                endPoint: .trailing
            )
            .frame(height: 100)
            
            HStack {
                Text("Mon Profil")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundStyle(.white)
                
                Spacer()
                
                Button {
                    showEditProfile = true
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "pencil")
                            .font(.subheadline)
                        Text("Modifier")
                            .font(.subheadline)
                            .fontWeight(.medium)
                    }
                    .foregroundStyle(.white)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background {
                        Capsule()
                            .fill(Color.white.opacity(0.2))
                    }
                }
            }
            .padding(.horizontal, 24)
        }
    }
}

// MARK: - Main Profile Card

struct MainProfileCard: View {
    let viewModel: HourglassViewModel?

    @State private var userData: UserData? = nil
    @State private var isLoading = true
    @State private var showShareOptions = false
    @State private var showImagePicker = false
    @State private var selectedImage: UIImage? = nil
    @State private var isUploadingImage = false
    @State private var uploadError: String? = nil

    var username: String {
        userData?.username ?? "Utilisateur"
    }

    var displayName: String {
        userData?.displayName ?? Auth.auth().currentUser?.displayName ?? "Utilisateur"
    }

    var email: String {
        userData?.email ?? Auth.auth().currentUser?.email ?? "email@exemple.com"
    }

    var body: some View {
        VStack(spacing: 20) {
            if isLoading {
                ProgressView()
                    .padding()
            } else {
                // Photo de profil
                ZStack(alignment: .bottomTrailing) {
                    if isUploadingImage {
                        // Afficher un spinner pendant l'upload
                        ZStack {
                            Circle()
                                .fill(Color.gray.opacity(0.3))
                                .frame(width: 100, height: 100)
                            ProgressView()
                        }
                    } else {
                        ProfileImageView(
                            imageURL: userData?.profileImageURL,
                            username: username,
                            size: 100,
                            gradientColors: [.purple, .pink]
                        )
                    }

                    // Badge caméra cliquable
                    Button {
                        showImagePicker = true
                    } label: {
                        Circle()
                            .fill(.purple)
                            .frame(width: 32, height: 32)
                            .overlay {
                                Image(systemName: "camera.fill")
                                    .font(.system(size: 14))
                                    .foregroundStyle(.white)
                            }
                    }
                    .offset(x: 5, y: 5)
                }

                // Informations
                VStack(spacing: 12) {
                    Text(displayName)
                        .font(.title2)
                        .fontWeight(.bold)

                    Text("@\(username)")
                        .font(.subheadline)
                        .foregroundStyle(.purple)

                    HStack(spacing: 6) {
                        Image(systemName: "envelope.fill")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Text(email)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }

                    HStack(spacing: 6) {
                        Image(systemName: "eye.fill")
                            .font(.caption)
                            .foregroundStyle(.blue)
                        Text("Profil public")
                            .font(.subheadline)
                            .foregroundStyle(.blue)
                    }

                    Button {
                        showShareOptions = true
                    } label: {
                        HStack(spacing: 6) {
                            Image(systemName: "square.and.arrow.up")
                                .font(.subheadline)
                            Text("Partager mon profil")
                                .font(.subheadline)
                                .fontWeight(.medium)
                        }
                        .foregroundStyle(.purple)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background {
                            Capsule()
                                .stroke(Color.purple, lineWidth: 1.5)
                        }
                    }
                    .padding(.top, 8)
                }
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 24)
        .background {
            RoundedRectangle(cornerRadius: 20)
                .fill(Color(uiColor: .systemBackground))
                .shadow(color: .black.opacity( 0.05), radius: 10)
        }
        .onAppear {
            loadUserData()
        }
        .sheet(isPresented: $showShareOptions) {
            ShareOptionsView(shareText: generateShareText())
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

    private func generateShareText() -> String {
        var text = "Rejoins-moi sur Hourglass 4 !\n\n"
        text += "👤 \(displayName)\n"
        text += "✨ @\(username)\n"

        if let birthDate = userData?.birthDate {
            let formatter = DateFormatter()
            formatter.dateStyle = .medium
            text += "🎂 Né(e) le \(formatter.string(from: birthDate))\n"
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

// MARK: - Friends Section

struct FriendsSection: View {
    @Binding var showFindFriends: Bool
    @State private var friends: [UserData] = []
    @State private var isLoading = true
    @State private var errorText: String?

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                HStack(spacing: 8) {
                    Image(systemName: "person.2.fill")
                        .font(.title3)
                        .foregroundStyle(.blue)
                    Text("Mes Sabliers Complices")
                        .font(.headline)
                }
                
                Spacer()
                
                Button {
                    loadFriends()
                } label: {
                    Image(systemName: "arrow.clockwise")
                        .foregroundStyle(.blue)
                }

                Button {
                    showFindFriends = true
                } label: {
                    Text("Trouver des Complices")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundStyle(.white)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background {
                            Capsule()
                                .fill(Color.blue)
                        }
                }
            }
            
            if isLoading {
                ProgressView()
                    .padding()
            } else if friends.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "person.2.slash")
                        .font(.system(size: 40))
                        .foregroundStyle(.secondary)
                    Text("Aucun complice pour le moment")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    Text("Ajoute des amis pour partager tes victoires !")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                    if let errorText {
                        Text(errorText)
                            .font(.caption2)
                            .foregroundStyle(.red)
                    }
                }
                .padding()
            } else {
                DisclosureGroup(
                    isExpanded: .constant(true),
                    content: {
                        VStack(spacing: 12) {
                            ForEach(friends) { friend in
                                RealFriendCard(friend: friend) {
                                    loadFriends()
                                }
                            }
                        }
                        .padding(.top, 12)
                    },
                    label: {
                        HStack(spacing: 8) {
                            Image(systemName: "heart.fill")
                                .foregroundStyle(.red)
                            Text("Mes Sabliers Complices (\(friends.count))")
                                .font(.subheadline)
                                .fontWeight(.semibold)
                        }
                    }
                )
                .tint(.red)
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

struct RealFriendCard: View {
    let friend: UserData
    let onUpdate: () -> Void
    @State private var showDeleteConfirmation = false
    @State private var showFriendProfile = false

    var displayName: String {
        friend.displayName ?? friend.username
    }

    var friendSince: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        return formatter.string(from: friend.createdAt)
    }

    var profileColor: Color {
        let colors: [Color] = [.blue, .purple, .green, .orange, .pink, .cyan]
        let index = abs(friend.uid.hashValue) % colors.count
        return colors[index]
    }

    var body: some View {
        HStack(spacing: 16) {
            Circle()
                .fill(LinearGradient(colors: [profileColor, profileColor.opacity(0.6)], startPoint: .topLeading, endPoint: .bottomTrailing))
                .frame(width: 50, height: 50)
                .overlay {
                    Text(friend.username.prefix(1).uppercased())
                        .font(.title3)
                        .fontWeight(.bold)
                        .foregroundStyle(.white)
                }

            VStack(alignment: .leading, spacing: 4) {
                Text(displayName)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                Text("@\(friend.username)")
                    .font(.caption)
                    .foregroundStyle(.purple)
                HStack(spacing: 4) {
                    Image(systemName: "sparkles")
                        .font(.caption2)
                        .foregroundStyle(.orange)
                    Text("Depuis \(friendSince)")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 8) {
                Button {} label: {
                    HStack(spacing: 4) {
                        Image(systemName: "heart.fill")
                            .font(.caption2)
                        Text("Transfuser 1 Grain")
                            .font(.caption2)
                            .fontWeight(.medium)
                    }
                    .foregroundStyle(.red)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background {
                        Capsule()
                            .stroke(Color.red.opacity(0.3), lineWidth: 1)
                    }
                }

                Button {
                    showFriendProfile = true
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "sparkles")
                            .font(.caption2)
                        Text("Voir le profil")
                            .font(.caption2)
                            .fontWeight(.medium)
                    }
                    .foregroundStyle(.blue)
                }
            }

            Button {
                showDeleteConfirmation = true
            } label: {
                Image(systemName: "trash")
                    .font(.caption)
                    .foregroundStyle(.gray)
            }
        }
        .padding()
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

struct SettingsSection: View {
    @State private var showTutorial = false
    @State private var showLogoutConfirmation = false
    @State private var showDeleteConfirmation = false
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: 8) {
                Image(systemName: "gearshape.fill")
                    .foregroundStyle(.gray)
                Text("Paramètres")
                    .font(.headline)
            }
            .padding()
            .padding(.bottom, 8)
            
            Divider()

            Button { showTutorial = true } label: {
                HStack(spacing: 12) {
                    Image(systemName: "arrow.counterclockwise")
                        .foregroundStyle(.blue)
                    Text("Revoir le tutoriel")
                        .foregroundStyle(.primary)
                    Spacer()
                }
                .padding()
            }

            Divider()
            
            Button { showLogoutConfirmation = true } label: {
                HStack(spacing: 12) {
                    Text("Déconnexion")
                        .foregroundStyle(.primary)
                    Spacer()
                }
                .padding()
            }
            
            Divider()
            
            Button { showDeleteConfirmation = true } label: {
                HStack(spacing: 12) {
                    Image(systemName: "trash")
                        .foregroundStyle(.red)
                    Text("Supprimer mon compte")
                        .foregroundStyle(.red)
                    Spacer()
                }
                .padding()
            }
        }
        .background {
            RoundedRectangle(cornerRadius: 20)
                .fill(Color(uiColor: .systemBackground))
                .shadow(color: .black.opacity(0.05), radius: 10)
        }
        .alert("Revoir le tutoriel", isPresented: $showTutorial) {
            Button("OK", role: .cancel) { }
        }
        .alert("Déconnexion", isPresented: $showLogoutConfirmation) {
            Button("Annuler", role: .cancel) { }
            Button("Déconnexion", role: .destructive) {
                do {
                    try Auth.auth().signOut()
                    dismiss() // Ferme la feuille de profil
                } catch {
                    print("Erreur de déconnexion: \(error)")
                }
            }
        }
        .alert("Supprimer le compte", isPresented: $showDeleteConfirmation) {
            Button("Annuler", role: .cancel) { }
            Button("Supprimer", role: .destructive) {}
        }
    }
}

struct EditProfileView: View {
    let viewModel: HourglassViewModel?
    @Environment(\.dismiss) private var dismiss
    @State private var fullName = ""
    @State private var username = ""
    @State private var email = ""
    @State private var selectedGender: Gender = .notSpecified
    @State private var birthDate = Date()
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
                    "birthDate": Timestamp(date: birthDate)
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
            if isProcessing {
                ProgressView()
                    .scaleEffect(0.8)
            } else {
                HStack(spacing: 8) {
                    Button {
                        acceptRequest()
                    } label: {
                        Image(systemName: "checkmark")
                            .font(.caption)
                            .foregroundStyle(.white)
                            .frame(width: 32, height: 32)
                            .background(Color.green)
                            .clipShape(Circle())
                    }

                    Button {
                        rejectRequest()
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
        }
        .frame(width: 150)
        .padding()
        .background {
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.secondarySystemBackground))
                .shadow(color: .black.opacity(0.05), radius: 5)
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

// MARK: - Share Options View

struct ShareOptionsView: View {
    let shareText: String
    @Environment(\.dismiss) private var dismiss
    @State private var showMessageComposer = false
    @State private var showMailComposer = false
    @State private var showCopyConfirmation = false

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Header
                VStack(spacing: 12) {
                    Image(systemName: "person.circle.fill")
                        .font(.system(size: 60))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [.purple, .pink],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )

                    Text("Partager mon profil")
                        .font(.title2)
                        .fontWeight(.bold)

                    Text("Choisis comment partager ton profil")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .padding(.top, 32)
                .padding(.bottom, 32)

                // Options de partage
                VStack(spacing: 16) {
                    // SMS
                    Button {
                        showMessageComposer = true
                    } label: {
                        HStack(spacing: 16) {
                            ZStack {
                                Circle()
                                    .fill(Color.green.opacity(0.1))
                                    .frame(width: 50, height: 50)

                                Image(systemName: "message.fill")
                                    .font(.title3)
                                    .foregroundStyle(.green)
                            }

                            VStack(alignment: .leading, spacing: 4) {
                                Text("Message")
                                    .font(.headline)
                                    .foregroundStyle(.primary)
                                Text("Partager par SMS")
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
                                .fill(Color(.secondarySystemBackground))
                        }
                    }

                    // Mail
                    Button {
                        showMailComposer = true
                    } label: {
                        HStack(spacing: 16) {
                            ZStack {
                                Circle()
                                    .fill(Color.blue.opacity(0.1))
                                    .frame(width: 50, height: 50)

                                Image(systemName: "envelope.fill")
                                    .font(.title3)
                                    .foregroundStyle(.blue)
                            }

                            VStack(alignment: .leading, spacing: 4) {
                                Text("Mail")
                                    .font(.headline)
                                    .foregroundStyle(.primary)
                                Text("Partager par email")
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
                                .fill(Color(.secondarySystemBackground))
                        }
                    }

                    // Copier
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
                                    .fill(Color.purple.opacity(0.1))
                                    .frame(width: 50, height: 50)

                                Image(systemName: "doc.on.doc.fill")
                                    .font(.title3)
                                    .foregroundStyle(.purple)
                            }

                            VStack(alignment: .leading, spacing: 4) {
                                Text("Copier")
                                    .font(.headline)
                                    .foregroundStyle(.primary)
                                Text("Copier dans le presse-papiers")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }

                            Spacer()

                            if showCopyConfirmation {
                                Image(systemName: "checkmark.circle.fill")
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
                                .fill(Color(.secondarySystemBackground))
                        }
                    }
                }
                .padding(.horizontal)

                Spacer()
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Fermer") {
                        dismiss()
                    }
                }
            }
            .sheet(isPresented: $showMessageComposer) {
                MessageComposeView(body: shareText)
            }
            .sheet(isPresented: $showMailComposer) {
                MailComposeView(subject: "Rejoins-moi sur Hourglass 4 !", body: shareText)
            }
        }
    }
}

// MARK: - Message Composer

struct MessageComposeView: UIViewControllerRepresentable {
    let body: String
    @Environment(\.dismiss) private var dismiss

    func makeUIViewController(context: Context) -> MFMessageComposeViewController {
        let controller = MFMessageComposeViewController()
        controller.body = body
        controller.messageComposeDelegate = context.coordinator
        return controller
    }

    func updateUIViewController(_ uiViewController: MFMessageComposeViewController, context: Context) {
        // Rien à mettre à jour
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    class Coordinator: NSObject, MFMessageComposeViewControllerDelegate {
        let parent: MessageComposeView

        init(_ parent: MessageComposeView) {
            self.parent = parent
        }

        func messageComposeViewController(_ controller: MFMessageComposeViewController, didFinishWith result: MessageComposeResult) {
            parent.dismiss()
        }
    }
}

// MARK: - Mail Composer

struct MailComposeView: UIViewControllerRepresentable {
    let subject: String
    let body: String
    @Environment(\.dismiss) private var dismiss

    func makeUIViewController(context: Context) -> MFMailComposeViewController {
        let controller = MFMailComposeViewController()
        controller.setSubject(subject)
        controller.setMessageBody(body, isHTML: false)
        controller.mailComposeDelegate = context.coordinator
        return controller
    }

    func updateUIViewController(_ uiViewController: MFMailComposeViewController, context: Context) {
        // Rien à mettre à jour
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    class Coordinator: NSObject, MFMailComposeViewControllerDelegate {
        let parent: MailComposeView

        init(_ parent: MailComposeView) {
            self.parent = parent
        }

        func mailComposeController(_ controller: MFMailComposeViewController, didFinishWith result: MFMailComposeResult, error: Error?) {
            parent.dismiss()
        }
    }
}

#Preview {
    ProfileView(viewModel: nil)
}
