//
//  FriendProfileView.swift
//  Hourglass 4
//
//  Vue pour afficher le profil détaillé d'un ami
//

import SwiftUI

struct FriendProfileView: View {
    let friend: UserData
    @Environment(\.dismiss) private var dismiss
    @State private var showTransferConfirmation = false
    @State private var showVictories = false
    @State private var showMessage = false
    @State private var transferSuccess = false

    var displayName: String {
        let name = friend.displayName?.trimmingCharacters(in: .whitespacesAndNewlines)
        return (name?.isEmpty == false) ? name! : friend.username
    }

    var profileColor: Color {
        let colors: [Color] = [.blue, .purple, .green, .orange, .pink, .cyan]
        let index = abs(friend.uid.hashValue) % colors.count
        return colors[index]
    }

    var friendSince: String {
        AppTimeZone.formatDate(friend.createdAt, style: .long)
    }

    var ageText: String {
        let calendar = AppTimeZone.calendar
        let now = Date()
        let ageComponents = calendar.dateComponents([.year], from: friend.birthDate, to: now)
        if let age = ageComponents.year {
            return "\(age) ans"
        }
        return "N/A"
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Header avec avatar
                    headerSection

                    // Informations personnelles
                    infoSection

                    // Actions rapides
                    actionsSection

                    Spacer(minLength: 40)
                }
                .padding()
            }
            .background(Color(uiColor: .systemGroupedBackground))
            .navigationTitle("Profil")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Fermer") {
                        dismiss()
                    }
                }
            }
            // Confirmation pour transfuser un grain
            .alert("Transfuser un Grain", isPresented: $showTransferConfirmation) {
                Button("Annuler", role: .cancel) { }
                Button("Confirmer") {
                    Task {
                        await transferGrain()
                    }
                }
            } message: {
                Text("Voulez-vous vraiment transfuser 1 Grain à \(displayName) ? Ce geste symbolise votre soutien et votre amitié.")
            }
            // Message de succès après transfert
            .alert("Grain Transfusé !", isPresented: $transferSuccess) {
                Button("OK", role: .cancel) { }
            } message: {
                Text("Vous avez transfusé 1 Grain à \(displayName) avec succès ! 💖")
            }
            // Vue des victoires
            .sheet(isPresented: $showVictories) {
                FriendVictoriesView(friend: friend)
            }
            // Interface de messagerie (navigation vers ConversationView)
            .navigationDestination(isPresented: $showMessage) {
                ConversationView(friend: friend)
            }
        }
    }

    // MARK: - Actions

    private func transferGrain() async {
        do {
            // Transfuser 1 grain via Firestore
            try await GrainTransferManager.shared.transferGrain(
                to: friend.uid,
                amount: 1.0,
                message: nil
            )
            transferSuccess = true
        } catch {
            print("Erreur lors du transfert de grain: \(error)")
            // TODO: Afficher une alerte d'erreur
        }
    }

    // MARK: - Header Section

    private var headerSection: some View {
        VStack(spacing: 16) {
            // Avatar
            ProfileImageView(
                imageURL: friend.profileImageURL,
                username: friend.username,
                size: 120,
                gradientColors: [profileColor, profileColor.opacity(0.6)]
            )
            .shadow(color: profileColor.opacity(0.3), radius: 20)

            // Nom et username
            VStack(spacing: 4) {
                Text(displayName)
                    .font(.title2)
                    .fontWeight(.bold)

                Text("@\(friend.username)")
                    .font(.subheadline)
                    .foregroundStyle(.purple)

                HStack(spacing: 6) {
                    Image(systemName: "sparkles")
                        .font(.caption)
                        .foregroundStyle(.orange)
                    Text("Ami depuis le \(friendSince)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .padding(.top, 4)
            }
        }
        .padding(.vertical, 24)
    }

    // MARK: - Info Section

    private var infoSection: some View {
        VStack(spacing: 16) {
            Text("Informations")
                .font(.headline)
                .frame(maxWidth: .infinity, alignment: .leading)

            VStack(spacing: 12) {
                InfoRow(
                    icon: "envelope.fill",
                    iconColor: .blue,
                    title: "Email",
                    value: friend.email
                )

                InfoRow(
                    icon: "birthday.cake.fill",
                    iconColor: .pink,
                    title: "Âge",
                    value: ageText
                )

                InfoRow(
                    icon: "person.fill",
                    iconColor: .purple,
                    title: "Genre",
                    value: friend.gender.displayName
                )
            }
            .padding()
            .background {
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color(uiColor: .systemBackground))
                    .shadow(color: .black.opacity(0.05), radius: 10)
            }
        }
    }

    // MARK: - Actions Section

    private var actionsSection: some View {
        VStack(spacing: 16) {
            Text("Actions")
                .font(.headline)
                .frame(maxWidth: .infinity, alignment: .leading)

            VStack(spacing: 12) {
                // Bouton Transfuser un Grain
                Button {
                    showTransferConfirmation = true
                } label: {
                    HStack {
                        Image(systemName: "heart.fill")
                            .foregroundStyle(.red)
                        Text("Transfuser 1 Grain")
                            .fontWeight(.medium)
                        Spacer()
                        Image(systemName: "chevron.right")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .padding()
                    .background {
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color(uiColor: .systemBackground))
                    }
                }
                .buttonStyle(.plain)

                // Bouton Voir ses victoires
                Button {
                    showVictories = true
                } label: {
                    HStack {
                        Image(systemName: "trophy.fill")
                            .foregroundStyle(.yellow)
                        Text("Voir ses victoires")
                            .fontWeight(.medium)
                        Spacer()
                        Image(systemName: "chevron.right")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .padding()
                    .background {
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color(uiColor: .systemBackground))
                    }
                }
                .buttonStyle(.plain)

                // Bouton Envoyer un message
                Button {
                    showMessage = true
                } label: {
                    HStack {
                        Image(systemName: "message.fill")
                            .foregroundStyle(.green)
                        Text("Envoyer un message")
                            .fontWeight(.medium)
                        Spacer()
                        Image(systemName: "chevron.right")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .padding()
                    .background {
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color(uiColor: .systemBackground))
                    }
                }
                .buttonStyle(.plain)
            }
            .shadow(color: .black.opacity(0.05), radius: 10)
        }
    }
}

// MARK: - Info Row Component

struct InfoRow: View {
    let icon: String
    let iconColor: Color
    let title: String
    let value: String

    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(iconColor)
                .frame(width: 32)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text(value)
                    .font(.subheadline)
                    .fontWeight(.medium)
            }

            Spacer()
        }
    }
}

#Preview {
    FriendProfileView(
        friend: UserData(
            uid: "test123",
            email: "ami@test.com",
            username: "johndoe",
            displayName: "John Doe",
            gender: .male,
            birthDate: Date().addingTimeInterval(-25 * 365 * 24 * 60 * 60),
            createdAt: Date().addingTimeInterval(-30 * 24 * 60 * 60)
        )
    )
}
