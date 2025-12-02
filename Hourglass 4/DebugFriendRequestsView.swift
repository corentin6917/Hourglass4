import SwiftUI
import FirebaseFirestore
import FirebaseAuth

/// Vue de debug pour visualiser les friendRequests et friendships du compte connecté.
struct DebugFriendRequestsView: View {
    @State private var requests: [FriendRequestDoc] = []
    @State private var friendships: [FriendshipDoc] = []
    @State private var status: String = "Chargement..."
    @State private var isLoading = false

    var body: some View {
        NavigationStack {
            List {
                Section("Friend Requests") {
                    if requests.isEmpty {
                        Text("Aucune demande")
                            .foregroundStyle(.secondary)
                    } else {
                        ForEach(requests) { req in
                            VStack(alignment: .leading, spacing: 4) {
                                Text("from: \(req.fromUsername) (\(req.fromUserId))")
                                    .font(.footnote)
                                Text("to: \(req.toUserId)")
                                    .font(.footnote)
                                Text("status: \(req.status)")
                                    .font(.footnote)
                                if let createdAt = req.createdAt {
                                    Text("createdAt: \(createdAt.formatted())")
                                        .font(.caption2)
                                        .foregroundStyle(.secondary)
                                }
                            }
                        }
                    }
                }

                Section("Friendships") {
                    if friendships.isEmpty {
                        Text("Aucun ami")
                            .foregroundStyle(.secondary)
                    } else {
                        ForEach(friendships) { f in
                            VStack(alignment: .leading, spacing: 4) {
                                Text("user1: \(f.user1Id)")
                                    .font(.footnote)
                                Text("user2: \(f.user2Id)")
                                    .font(.footnote)
                                if let createdAt = f.createdAt {
                                    Text("createdAt: \(createdAt.formatted())")
                                        .font(.caption2)
                                        .foregroundStyle(.secondary)
                                }
                            }
                        }
                    }
                }
            }
            .navigationTitle("Debug Amis")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        Task { await loadData() }
                    } label: {
                        Label("Rafraîchir", systemImage: "arrow.clockwise")
                    }
                }
            }
            .overlay {
                if isLoading {
                    ProgressView(status)
                }
            }
            .task {
                await loadData()
            }
        }
    }

    private func loadData() async {
        guard let currentUid = Auth.auth().currentUser?.uid else {
            await MainActor.run {
                status = "Non connecté"
                requests = []
                friendships = []
            }
            return
        }

        await MainActor.run {
            isLoading = true
            status = "Chargement..."
        }

        do {
            let db = Firestore.firestore()
            // Chargement des friendRequests où toUserId == currentUid
            let reqSnap = try await db.collection("friendRequests")
                .whereField("toUserId", isEqualTo: currentUid)
                .whereField("status", isEqualTo: "pending")
                .getDocuments()

            let reqs = reqSnap.documents.map { doc -> FriendRequestDoc in
                let data = doc.data()
                return FriendRequestDoc(
                    id: doc.documentID,
                    fromUserId: data["fromUserId"] as? String ?? "",
                    fromUsername: data["fromUsername"] as? String ?? "",
                    fromDisplayName: data["fromDisplayName"] as? String ?? "",
                    toUserId: data["toUserId"] as? String ?? "",
                    status: data["status"] as? String ?? "",
                    createdAt: (data["createdAt"] as? Timestamp)?.dateValue()
                )
            }

            // Chargement des friendships où currentUid est user1 ou user2
            let fs1 = try await db.collection("friendships")
                .whereField("user1Id", isEqualTo: currentUid)
                .getDocuments()
            let fs2 = try await db.collection("friendships")
                .whereField("user2Id", isEqualTo: currentUid)
                .getDocuments()

            let friends: [FriendshipDoc] = (fs1.documents + fs2.documents).map { doc in
                let data = doc.data()
                return FriendshipDoc(
                    id: doc.documentID,
                    user1Id: data["user1Id"] as? String ?? "",
                    user2Id: data["user2Id"] as? String ?? "",
                    createdAt: (data["createdAt"] as? Timestamp)?.dateValue()
                )
            }

            await MainActor.run {
                self.requests = reqs
                self.friendships = friends
                self.status = "OK"
                self.isLoading = false
            }
        } catch {
            await MainActor.run {
                status = "Erreur: \(error.localizedDescription)"
                isLoading = false
            }
        }
    }
}

private struct FriendRequestDoc: Identifiable {
    let id: String
    let fromUserId: String
    let fromUsername: String
    let fromDisplayName: String
    let toUserId: String
    let status: String
    let createdAt: Date?
}

private struct FriendshipDoc: Identifiable {
    let id: String
    let user1Id: String
    let user2Id: String
    let createdAt: Date?
}
