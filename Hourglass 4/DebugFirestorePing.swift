import SwiftUI
import FirebaseFirestore
import FirebaseAuth
import FirebaseCore

/// Petit écran de debug pour vérifier que l'app écrit bien dans Firestore.
struct DebugFirestorePingView: View {
    @State private var status: String = "Appuie sur Ping pour tester l'écriture"
    @State private var lastDocId: String?
    @State private var isLoading = false
    @State private var configInfo: String = ""

    var body: some View {
        NavigationStack {
            VStack(spacing: 16) {
                Text(status)
                    .multilineTextAlignment(.center)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                if let lastDocId = lastDocId {
                    Text("Dernier doc: \(lastDocId)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)
                }

                Button(action: sendPing) {
                    if isLoading {
                        ProgressView()
                            .progressViewStyle(.circular)
                    } else {
                        Label("Envoyer un ping Firestore", systemImage: "bolt.fill")
                            .font(.headline)
                    }
                }
                .buttonStyle(.borderedProminent)
                .disabled(isLoading)

                if !configInfo.isEmpty {
                    Text(configInfo)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.leading)
                }

                Spacer()
            }
            .padding()
            .navigationTitle("Debug Firestore")
            .navigationBarTitleDisplayMode(.inline)
            .onAppear {
                if let opts = FirebaseApp.app()?.options {
                    configInfo = "ProjectID: \(opts.projectID ?? "nil") | AppID: \(opts.googleAppID) | APIKey: \(opts.apiKey) | BundleID: \(Bundle.main.bundleIdentifier ?? "nil")"
                } else {
                    configInfo = "FirebaseApp non initialisé"
                }
            }
        }
    }

    private func sendPing() {
        isLoading = true
        status = "Vérification de la connexion..."

        // Timeout au cas où le callback n'arrive jamais
        DispatchQueue.main.asyncAfter(deadline: .now() + 6) {
            if self.isLoading {
                self.isLoading = false
                self.status = "Aucune réponse (timeout). Vérifie le réseau, le plist ou les règles."
                print("DEBUG Firestore ping timeout")
            }
        }

        print("DEBUG Firestore ping start (currentUser: \(String(describing: Auth.auth().currentUser?.uid)))")

        if Auth.auth().currentUser == nil {
            Auth.auth().signInAnonymously { _, error in
                if let error = error {
                    DispatchQueue.main.async {
                        isLoading = false
                        status = "Auth anonyme impossible: \(error.localizedDescription)"
                        print("DEBUG Firestore ping anon auth error: \(error)")
                    }
                    return
                }
                print("DEBUG Firestore ping anon auth success")
                self.performPing()
            }
        } else {
            performPing()
        }
    }

    private func performPing() {
        status = "Écriture en cours..."
        let db = Firestore.firestore()
        let payload: [String: Any] = [
            "ts": Timestamp(date: Date()),
            "uid": Auth.auth().currentUser?.uid ?? "no_auth",
            "device": UIDevice.current.name
        ]

        db.collection("debug_ping").addDocument(data: payload) { error in
            DispatchQueue.main.async {
                isLoading = false
                if let error = error {
                    status = "Erreur d'écriture: \(error.localizedDescription)"
                    print("DEBUG Firestore ping error: \(error)")
                } else {
                    status = "Ping écrit. Vérifie la collection debug_ping dans Firestore (racine)."
                    print("DEBUG Firestore ping success")
                    // Impossible de récupérer l'ID ici sans snapshot, mais on signale le succès.
                }
            }
        }
    }
}
