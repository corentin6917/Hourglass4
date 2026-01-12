//
//  FriendProfileView.swift
//  Hourglass 4
//
//  Vue pour afficher le profil détaillé d'un ami
//

import SwiftUI
import FirebaseFirestore

struct FriendProfileView: View {
    let friend: UserData
    @Environment(\.dismiss) private var dismiss
    @State private var showTransferConfirmation = false
    @State private var showVictories = false
    @State private var showMessage = false
    @State private var transferSuccess = false
    @State private var heritageTotal: Double = 0
    @State private var isLoadingHeritage = true
    @State private var showPinnedVictories = false
    @State private var showHeritageInfo = false

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
                    VStack(spacing: 12) {
                        headerSection

                        if showHeritageInfo {
                            heritageInfoBubble
                        }
                    }

                    // Actions rapides
                    actionsSection

                    Spacer(minLength: 40)
                }
                .padding()
            }
            .background(
                LinearGradient(
                    colors: [
                        Color(uiColor: .systemGroupedBackground),
                        Color.orange.opacity(0.05)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
            .navigationTitle("Profil")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Fermer") {
                        dismiss()
                    }
                }
            }
            .onAppear {
                loadHeritageTotal()
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
            .sheet(isPresented: $showPinnedVictories) {
                pinnedVictoriesSheet
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

    private func loadHeritageTotal() {
        isLoadingHeritage = true
        let db = Firestore.firestore()

        Task {
            do {
                let snapshot = try await db.collection("goals")
                    .whereField("userId", isEqualTo: friend.uid)
                    .whereField("status", isEqualTo: GoalStatus.completed.rawValue)
                    .getDocuments()

                let total = snapshot.documents.reduce(0.0) { partial, doc in
                    let value = doc.data()["grainValue"] as? Double ?? 0.0
                    return partial + value
                }

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

    // MARK: - Header Section

    private var headerSection: some View {
        VStack(spacing: 16) {
            ProfileImageView(
                imageURL: friend.profileImageURL,
                username: friend.username,
                size: 110,
                gradientColors: [profileColor, profileColor.opacity(0.6)]
            )
            .shadow(color: profileColor.opacity(0.25), radius: 18, x: 0, y: 8)

            VStack(spacing: 6) {
                Text(displayName)
                    .font(.title2)
                    .fontWeight(.bold)

                Text("@\(friend.username)")
                    .font(.subheadline)
                    .foregroundStyle(.orange)

                HStack(spacing: 10) {
                    StatPill(
                        icon: "sparkles",
                        text: isLoadingHeritage ? "…" : "\(Int(heritageTotal)) grains",
                        tint: .orange
                    )
                    .onTapGesture {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                            showHeritageInfo.toggle()
                        }
                    }

                    StatPill(
                        icon: friend.isPublic ? "lock.open" : "lock",
                        text: friend.isPublic ? "Public" : "Privé",
                        tint: .gray
                    )
                }
                .padding(.top, 4)

                HStack(spacing: 6) {
                    Image(systemName: "calendar")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text("Ami depuis le \(friendSince)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .padding(.top, 2)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 20)
        .padding(.horizontal, 16)
        .background {
            RoundedRectangle(cornerRadius: 22)
                .fill(
                    LinearGradient(
                        colors: [
                            Color(red: 0.99, green: 0.96, blue: 0.9),
                            Color(uiColor: .systemBackground)
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .overlay {
                    RoundedRectangle(cornerRadius: 22)
                        .stroke(Color.black.opacity(0.04), lineWidth: 1)
                }
                .shadow(color: .black.opacity(0.06), radius: 16, x: 0, y: 8)
        }
    }

    // MARK: - Info Section

    private var infoSection: some View {
        VStack(spacing: 16) {
            Text("Informations")
                .font(.headline)
                .frame(maxWidth: .infinity, alignment: .leading)

            HStack(spacing: 12) {
                InfoMiniCard(
                    icon: "hourglass",
                    tint: .orange,
                    title: "Héritage",
                    value: isLoadingHeritage ? "…" : "\(Int(heritageTotal))"
                )

                InfoMiniCard(
                    icon: "birthday.cake.fill",
                    tint: .pink,
                    title: "Âge",
                    value: ageText
                )
            }
        }
    }

    // MARK: - Actions Section

    private var actionsSection: some View {
        HStack(spacing: 16) {
            // Bouton Victoires épinglées
            Button {
                showPinnedVictories = true
            } label: {
                VStack(spacing: 10) {
                    Circle()
                        .fill(Color.orange.opacity(0.12))
                        .frame(width: 54, height: 54)
                        .overlay {
                            Image(systemName: "pin.fill")
                                .font(.title3)
                                .foregroundStyle(.orange)
                        }

                    Text("Victoires\népinglées")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .multilineTextAlignment(.center)
                        .foregroundStyle(.primary)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 18)
                .background {
                    RoundedRectangle(cornerRadius: 20)
                        .fill(Color(uiColor: .systemBackground))
                        .shadow(color: .black.opacity(0.06), radius: 12, x: 0, y: 6)
                }
            }
            .buttonStyle(.plain)

            // Bouton Envoyer un message
            Button {
                showMessage = true
            } label: {
                VStack(spacing: 10) {
                    Circle()
                        .fill(Color.green.opacity(0.12))
                        .frame(width: 54, height: 54)
                        .overlay {
                            Image(systemName: "message.fill")
                                .font(.title3)
                                .foregroundStyle(.green)
                        }

                    Text("Envoyer un\nmessage")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .multilineTextAlignment(.center)
                        .foregroundStyle(.primary)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 18)
                .background {
                    RoundedRectangle(cornerRadius: 20)
                        .fill(Color(uiColor: .systemBackground))
                        .shadow(color: .black.opacity(0.06), radius: 12, x: 0, y: 6)
                }
            }
            .buttonStyle(.plain)
        }
    }

    private var heritageInfoBubble: some View {
        VStack(spacing: 0) {
            InfoBubbleTriangleUp()
                .fill(Color(uiColor: .systemBackground))
                .frame(width: 20, height: 10)
                .shadow(color: .orange.opacity(0.15), radius: 4, x: 0, y: -2)

            VStack(alignment: .leading, spacing: 10) {
                HStack(spacing: 8) {
                    Image(systemName: "hourglass.circle.fill")
                        .font(.title3)
                        .foregroundStyle(
                            LinearGradient(
                                colors: [.orange, Color(red: 1.0, green: 0.6, blue: 0.0)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )

                    Text("Héritage de \(displayName)")
                        .font(.headline)
                        .fontWeight(.bold)
                }

                Text("C'est le total de tous les grains que \(displayName) a accumulés depuis le début. Chaque objectif validé contribue à son héritage qui grandit jour après jour.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(16)
            .background {
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color(uiColor: .systemBackground))
                    .shadow(color: .orange.opacity(0.25), radius: 16, x: 0, y: 8)
            }
        }
        .frame(maxWidth: 280)
        .transition(.scale.combined(with: .opacity))
        .onTapGesture {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                showHeritageInfo = false
            }
        }
    }

    private var pinnedVictoriesSheet: some View {
        PinnedVictoriesView(userId: friend.uid, displayName: displayName)
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

struct InfoMiniCard: View {
    let icon: String
    let tint: Color
    let title: String
    let value: String

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Circle()
                .fill(tint.opacity(0.15))
                .frame(width: 36, height: 36)
                .overlay {
                    Image(systemName: icon)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(tint)
                }

            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)

            Text(value)
                .font(.headline)
                .fontWeight(.semibold)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
        .background {
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(uiColor: .systemBackground))
                .shadow(color: .black.opacity(0.05), radius: 10)
        }
    }
}

struct StatPill: View {
    let icon: String
    let text: String
    let tint: Color

    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
                .font(.caption)
            Text(text)
                .font(.caption)
                .fontWeight(.semibold)
        }
        .foregroundStyle(tint)
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background {
            Capsule()
                .fill(tint.opacity(0.12))
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
