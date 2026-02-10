//
//  ContentView.swift
//  Hourglass 4
//
//  Created by Corentin Soula on 29/10/2025.
//

import SwiftUI
import SwiftData
import FirebaseAuth

struct ContentView: View {
    @StateObject private var viewModel: HourglassViewModel
    @EnvironmentObject private var tutorialManager: TutorialManager

    init(modelContext: ModelContext) {
        _viewModel = StateObject(wrappedValue: HourglassViewModel(modelContext: modelContext))
    }
    
    var body: some View {
        MainTabView(viewModel: viewModel)
            .onAppear {
                // Initialiser le profil utilisateur si nécessaire
                viewModel.initializeUserIfNeeded()
                // S'assurer que le profil Firestore existe et est normalisé
                Task {
                    try? await UserManager.shared.ensureCurrentUserProfile()
                    guard let uid = Auth.auth().currentUser?.uid else {
                        await tutorialManager.startIfNeeded()
                        return
                    }
                    let completed = (try? await UserManager.shared.getTutorialCompleted(uid: uid)) ?? true
                    if completed {
                        await tutorialManager.startIfNeeded()
                    } else {
                        await MainActor.run {
                            tutorialManager.showIntroPresentation = true
                        }
                    }
                }
            }
    }
}

struct IntroPresentationView: View {
    var onStart: () -> Void
    var onSkip: () -> Void

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [
                    Color(red: 1.0, green: 0.98, blue: 0.95),
                    Color(red: 1.0, green: 0.92, blue: 0.82)
                ],
                startPoint: .topLeading,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            VStack(spacing: 20) {
                Spacer()

                ZStack {
                    Circle()
                        .fill(Color.orange.opacity(0.15))
                        .frame(width: 140, height: 140)
                    Image(systemName: "hourglass")
                        .font(.system(size: 64, weight: .regular))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [Color(red: 0.98, green: 0.53, blue: 0.08), Color(red: 0.95, green: 0.66, blue: 0.21)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                }

                Text("Des objectifs simples, un sablier qui grandit.")
                    .font(.system(size: 28, weight: .bold))
                    .foregroundStyle(.black)
                    .multilineTextAlignment(.center)

                Text("Tu gagnes des grains quand tu réalises tes objectifs.")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 28)

                VStack(spacing: 12) {
                    IntroBullet(text: "Tu définis tes objectifs du jour.")
                    IntroBullet(text: "Tu les valides avec une photo.")
                    IntroBullet(text: "À 21h, le fil s’ouvre : tu vois ce que tes amis ont accompli.")
                }
                .padding(.top, 6)

                Spacer()

                VStack(spacing: 10) {
                    Button(action: onStart) {
                        Text("Commencer le tour")
                            .font(.system(size: 17, weight: .semibold))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 54)
                            .background(
                                LinearGradient(
                                    colors: [Color.orange, Color.orange.opacity(0.85)],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .cornerRadius(14)
                    }

                }
                .padding(.horizontal, 28)
                .padding(.bottom, 30)
            }
        }
    }
}

struct IntroBullet: View {
    let text: String

    var body: some View {
        HStack(spacing: 10) {
            Circle()
                .fill(Color.orange)
                .frame(width: 7, height: 7)
            Text(text)
                .font(.system(size: 15, weight: .medium))
                .foregroundStyle(.black.opacity(0.85))
            Spacer()
        }
        .padding(.horizontal, 28)
    }
}

#Preview {
    do {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try ModelContainer(
            for: UserProfile.self, Goal.self, Grain.self,
            configurations: config
        )
        
        return ContentView(modelContext: container.mainContext)
            .environmentObject(TutorialManager.shared)
    } catch {
        return Text("Erreur de prévisualisation: \(error.localizedDescription)")
    }
}
