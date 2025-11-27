//
//  RootView.swift
//  Hourglass 4
//
//  Affiche LoginView tant que l'utilisateur n'est pas authentifié via Firebase,
//  puis bascule sur le contenu principal une fois connecté.
//

import SwiftUI
import FirebaseAuth
import SwiftData

struct RootView: View {
    let modelContext: ModelContext

    @State private var isAuthenticated: Bool = false
    @State private var authListenerHandle: AuthStateDidChangeListenerHandle?

    var body: some View {
        Group {
            if isAuthenticated {
                ContentView(modelContext: modelContext)
            } else {
                // LoginView gère la création et la connexion Email/Password
                // Le RootView observe l'état Auth et bascule automatiquement
                LoginView()
            }
        }
        .onAppear {
            // État initial
            isAuthenticated = Auth.auth().currentUser != nil
            // Observer les changements d'état
            authListenerHandle = Auth.auth().addStateDidChangeListener { _, user in
                DispatchQueue.main.async {
                    isAuthenticated = (user != nil)
                }
            }
        }
        .onDisappear {
            if let handle = authListenerHandle {
                Auth.auth().removeStateDidChangeListener(handle)
                authListenerHandle = nil
            }
        }
    }
}

#Preview {
    do {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try ModelContainer(
            for: UserProfile.self, Goal.self, Grain.self,
            configurations: config
        )
        return RootView(modelContext: container.mainContext)
    } catch {
        return Text("Erreur de prévisualisation: \(error.localizedDescription)")
    }
}
