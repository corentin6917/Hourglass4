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
    @State private var showSplash = true

    var body: some View {
        ZStack {
            Group {
                if isAuthenticated {
                    ContentView(modelContext: modelContext)
                } else {
                    // LoginView gère la création et la connexion Email/Password
                    // Le RootView observe l'état Auth et bascule automatiquement
                    LoginView()
                }
            }

            if showSplash {
                SplashView()
                    .transition(.opacity)
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

            if showSplash {
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.6) {
                    withAnimation(.easeOut(duration: 0.3)) {
                        showSplash = false
                    }
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

struct SplashView: View {
    var body: some View {
        ZStack {
            Color.white
                .ignoresSafeArea()

            ShimmeringText(text: "Hourglass")
        }
    }
}

struct ShimmeringText: View {
    let text: String

    private var characters: [String] {
        text.map { String($0) }
    }

    var body: some View {
        HStack(spacing: 0) {
            ForEach(Array(characters.enumerated()), id: \.offset) { index, char in
                ShimmerLetter(char: char, delay: Double(index) * 0.12)
            }
        }
    }
}

struct ShimmerLetter: View {
    let char: String
    let delay: Double
    @State private var animate = false

    var body: some View {
        ZStack {
            Text(char)
                .font(.system(size: 36, weight: .bold))
                .foregroundStyle(.orange)

            Text(char)
                .font(.system(size: 36, weight: .bold))
                .foregroundStyle(
                    LinearGradient(
                        colors: [
                            Color.orange.opacity(0.4),
                            Color.white.opacity(0.9),
                            Color.orange.opacity(0.4)
                        ],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .mask(
                    Rectangle()
                        .fill(Color.white)
                        .offset(x: animate ? 40 : -40)
                )
        }
        .onAppear {
            withAnimation(.linear(duration: 1.6).repeatForever(autoreverses: false).delay(delay)) {
                animate = true
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
