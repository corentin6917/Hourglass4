//  ProfileView.swift
//  Hourglass 4
//
//  Created by Corentin Soula on 13/11/2025.
//

import SwiftUI
import FirebaseAuth
import FirebaseFirestore
import MessageUI

struct ProfileView: View {
    let viewModel: HourglassViewModel?
    
    @State private var showEditProfile = false
    @State private var showFindFriends = false
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
                FindFriendsView()
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
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [.purple, .pink],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 100, height: 100)
                        .overlay {
                            Text(username.prefix(1).uppercased())
                                .font(.system(size: 40, weight: .bold))
                                .foregroundStyle(.white)
                        }

                    // Badge caméra
                    Circle()
                        .fill(.purple)
                        .frame(width: 32, height: 32)
                        .overlay {
                            Image(systemName: "camera.fill")
                                .font(.system(size: 14))
                                .foregroundStyle(.white)
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
}

// MARK: - Friends Section

struct FriendsSection: View {
    @Binding var showFindFriends: Bool
    
    let friends: [Friend] = [
        Friend(id: "1", name: "linos.martos", email: "linos.martos@gmail.com", joinDate: "30/10/2025", profileColor: .blue),
        Friend(id: "2", name: "romain.cublier", email: "romain.cublier@gmail.com", joinDate: "03/11/2025", profileColor: .purple)
    ]
    
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
            
            DisclosureGroup(
                isExpanded: .constant(true),
                content: {
                    VStack(spacing: 12) {
                        ForEach(friends) { friend in
                            FriendCard(friend: friend)
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
        .padding()
        .background {
            RoundedRectangle(cornerRadius: 20)
                .fill(Color(uiColor: .systemBackground))
                .shadow(color: .black.opacity(0.05), radius: 10)
        }
    }
}

struct Friend: Identifiable {
    let id: String
    let name: String
    let email: String
    let joinDate: String
    let profileColor: Color
}

struct FriendCard: View {
    let friend: Friend
    
    var body: some View {
        HStack(spacing: 16) {
            Circle()
                .fill(LinearGradient(colors: [friend.profileColor, friend.profileColor.opacity(0.6)], startPoint: .topLeading, endPoint: .bottomTrailing))
                .frame(width: 50, height: 50)
                .overlay {
                    Text(friend.name.prefix(1).uppercased())
                        .font(.title3)
                        .fontWeight(.bold)
                        .foregroundStyle(.white)
                }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(friend.name)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                Text(friend.email)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                HStack(spacing: 4) {
                    Image(systemName: "sparkles")
                        .font(.caption2)
                        .foregroundStyle(.orange)
                    Text("Depuis \(friend.joinDate)")
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
                
                Button {} label: {
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
            
            Button {} label: {
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
    @State private var isLoading = true

    var body: some View {
        NavigationStack {
            if isLoading {
                ProgressView()
            } else {
                Form {
                    Section("Informations") {
                        TextField("Nom complet", text: $fullName)
                        TextField("Nom d'utilisateur", text: $username)
                            .textInputAutocapitalization(.never)
                        TextField("Email", text: $email)
                            .textInputAutocapitalization(.never)
                            .keyboardType(.emailAddress)
                            .disabled(true) // L'email ne peut pas être modifié facilement
                            .foregroundStyle(.secondary)
                    }

                    Section {
                        Text("Note : La modification du profil sera disponible dans une prochaine version.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                .navigationTitle("Modifier le profil")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Annuler") { dismiss() }
                    }
                    ToolbarItem(placement: .confirmationAction) {
                        Button("Enregistrer") { dismiss() }
                            .disabled(true) // Désactivé pour l'instant
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
}

struct FindFriendsView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var searchText = ""
    
    var body: some View {
        NavigationStack {
            VStack {
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundStyle(.secondary)
                    TextField("Rechercher par email ou username", text: $searchText)
                        .textInputAutocapitalization(.never)
                }
                .padding()
                .background {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color(uiColor: .secondarySystemBackground))
                }
                .padding()
                
                if searchText.isEmpty {
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
                }
                Spacer()
            }
            .navigationTitle("Trouver des Complices")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Fermer") { dismiss() }
                }
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

