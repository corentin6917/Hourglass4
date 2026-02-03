//
//  DeepLinkManager.swift
//  Hourglass 4
//
//  Gère les deep links depuis les widgets et notifications
//

import Foundation
import SwiftUI
import Combine

enum AppDeepLink: String {
    case validateGoal = "validate-goal"
    case objectives = "objectives"
    case feed = "feed"
    case profile = "profile"

    init?(url: URL) {
        guard url.scheme == "hourglass",
              let host = url.host else {
            return nil
        }
        self.init(rawValue: host)
    }
}

class DeepLinkManager: ObservableObject {
    @Published var activeDeepLink: AppDeepLink?
    @Published var shouldShowCamera = false

    static let shared = DeepLinkManager()

    private init() {}

    func handle(_ url: URL) {
        guard let deepLink = AppDeepLink(url: url) else {
            print("⚠️ Invalid deep link: \(url)")
            return
        }

        print("✅ Deep link detected: \(deepLink.rawValue)")

        switch deepLink {
        case .validateGoal:
            // Ouvrir directement la caméra de validation
            shouldShowCamera = true
            activeDeepLink = .validateGoal

        case .objectives:
            activeDeepLink = .objectives

        case .feed:
            activeDeepLink = .feed

        case .profile:
            activeDeepLink = .profile
        }
    }

    func reset() {
        activeDeepLink = nil
        shouldShowCamera = false
    }
}

// MARK: - Extension pour MainTabView
extension View {
    func handleDeepLinks() -> some View {
        self.modifier(DeepLinkViewModifier())
    }
}

struct DeepLinkViewModifier: ViewModifier {
    @StateObject private var deepLinkManager = DeepLinkManager.shared
    @State private var showingImagePicker = false
    @State private var selectedGoal: Goal?

    func body(content: Content) -> some View {
        content
            .onOpenURL { url in
                deepLinkManager.handle(url)
            }
            .sheet(isPresented: $deepLinkManager.shouldShowCamera) {
                // Ouvrir la caméra pour valider un objectif
                NavigationStack {
                    ValidateGoalCameraView()
                }
            }
            .onChange(of: deepLinkManager.activeDeepLink) { _, newValue in
                if newValue == .validateGoal {
                    // Déclencher l'ouverture de la caméra
                    showingImagePicker = true
                }
            }
    }
}

// MARK: - Vue pour la caméra de validation
struct ValidateGoalCameraView: View {
    @Environment(\.dismiss) var dismiss
    @StateObject private var goalManager = GoalManager.shared
    @State private var selectedGoal: FirebaseGoal?

    var pendingGoals: [FirebaseGoal] {
        goalManager.todayGoals.filter { $0.status == .pending }
    }

    var body: some View {
        VStack(spacing: 20) {
            if pendingGoals.isEmpty {
                // Aucun objectif à valider
                VStack(spacing: 16) {
                    Text("✓")
                        .font(.system(size: 64))
                        .foregroundColor(.green)

                    Text("Tous tes objectifs sont validés !")
                        .font(.title2)
                        .fontWeight(.bold)

                    Text("Reviens demain pour de nouveaux défis")
                        .font(.body)
                        .foregroundColor(.secondary)

                    Button("Fermer") {
                        dismiss()
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.orange)
                    .padding(.top)
                }
                .padding()
            } else {
                // Liste des objectifs à valider
                VStack(alignment: .leading, spacing: 12) {
                    Text("Valider un objectif")
                        .font(.title2)
                        .fontWeight(.bold)

                    Text("Choisis l'objectif que tu veux valider et prends une photo")
                        .font(.subheadline)
                        .foregroundColor(.secondary)

                    ScrollView {
                        VStack(spacing: 12) {
                            ForEach(pendingGoals) { goal in
                                GoalValidationCard(goal: goal) {
                                    selectedGoal = goal
                                }
                            }
                        }
                        .padding(.vertical)
                    }
                }
                .padding()
            }
        }
        .navigationTitle("Validation")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("Fermer") {
                    dismiss()
                }
            }
        }
        .sheet(item: $selectedGoal) { goal in
            FirebaseValidateGoalView(goal: goal)
        }
    }
}

// MARK: - Card pour valider un objectif
struct GoalValidationCard: View {
    let goal: FirebaseGoal
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 12) {
                // Emoji de catégorie
                Text(goal.category.emoji)
                    .font(.system(size: 32))

                VStack(alignment: .leading, spacing: 4) {
                    Text(goal.title)
                        .font(.headline)
                        .foregroundColor(.primary)

                    Text("+\(Int(goal.grainValue)) grains")
                        .font(.subheadline)
                        .foregroundColor(.orange)
                }

                Spacer()

                // Icône caméra
                Image(systemName: "camera.fill")
                    .font(.system(size: 20))
                    .foregroundColor(.orange)
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.orange.opacity(0.1))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.orange.opacity(0.3), lineWidth: 1)
                    )
            )
        }
        .buttonStyle(.plain)
    }
}
