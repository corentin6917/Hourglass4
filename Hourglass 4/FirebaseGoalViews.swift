//
//  FirebaseGoalViews.swift
//  Hourglass 4
//
//  Vues pour les objectifs stockés dans Firebase
//

import SwiftUI
#if canImport(UIKit)
import UIKit
#endif

// MARK: - Create Goal View (Firebase)

struct FirebaseCreateGoalView: View {
    @Environment(\.dismiss) var dismiss
    @StateObject private var goalManager = GoalManager.shared

    @State private var title = ""
    @State private var description = ""
    @State private var selectedCategory: GoalCategory = .personal
    @State private var selectedEffort: GoalEffort = .medium
    @State private var suggestedGrains = 2.5
    @State private var adjustment: Double = 0.0
    @State private var recentCount = 0
    @State private var isEstimating = false
    @State private var estimateTask: Task<Void, Never>?
    @State private var isCreating = false

    // Exemples suggérés par catégorie
    var categoryExamples: [String] {
        switch selectedCategory {
        case .physical:
            return ["Courir 30min", "Yoga 45min", "Nager 1km"]
        case .social:
            return ["Appeler un ami", "Voir famille", "Sortir"]
        case .creative:
            return ["Dessiner", "Écrire", "Créer"]
        case .professional:
            return ["Lire 30min", "Coder 1h", "Projet"]
        case .learning:
            return ["Apprendre", "Étudier", "Former"]
        case .personal:
            return ["Méditer 10min", "Ranger bureau", "Réfléchir"]
        case .household:
            return ["Cuisiner", "Nettoyer", "Ranger"]
        }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                // Background blanc
                Color.white
                    .ignoresSafeArea()

                VStack(spacing: 0) {
                    // Header simple avec +
                    HStack(spacing: 8) {
                        Text("+")
                            .font(.system(size: 24, weight: .semibold))
                            .foregroundStyle(.orange)

                        Text("Nouvel Objectif (0/3)")
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundStyle(.black)

                        Spacer()
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 20)
                    .padding(.bottom, 24)
                    .background(Color.white)

                    ScrollView {
                        VStack(alignment: .leading, spacing: 24) {
                            // Question principale
                            VStack(alignment: .leading, spacing: 12) {
                                Text("Que veux-tu accomplir aujourd'hui ?")
                                    .font(.system(size: 16, weight: .regular))
                                    .foregroundStyle(.black)

                                TextField("Ex: Courir 30 minutes", text: $title)
                                    .font(.system(size: 16))
                                    .padding(16)
                                    .background(
                                        RoundedRectangle(cornerRadius: 8)
                                            .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                                            .background(
                                                RoundedRectangle(cornerRadius: 8)
                                                    .fill(Color.white)
                                            )
                                    )
                            }

                            // Catégorie dropdown simple
                            VStack(alignment: .leading, spacing: 12) {
                                Text("Catégorie")
                                    .font(.system(size: 16, weight: .regular))
                                    .foregroundStyle(.black)

                                Menu {
                                    ForEach(GoalCategory.allCases, id: \.self) { category in
                                        Button {
                                            selectedCategory = category
                                        } label: {
                                            HStack {
                                                Text(category.emoji)
                                                Text(category.displayName)
                                            }
                                        }
                                    }
                                } label: {
                                    HStack(spacing: 12) {
                                        Text(selectedCategory.emoji)
                                            .font(.system(size: 18))
                                        Text(selectedCategory.displayName)
                                            .font(.system(size: 16))
                                            .foregroundStyle(.black)
                                        Spacer()
                                        Image(systemName: "chevron.down")
                                            .font(.system(size: 12))
                                            .foregroundStyle(.gray)
                                    }
                                    .padding(16)
                                    .background(
                                        RoundedRectangle(cornerRadius: 8)
                                            .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                                            .background(
                                                RoundedRectangle(cornerRadius: 8)
                                                    .fill(Color.white)
                                            )
                                    )
                                }
                            }

                            // Card Valeur suggérée (fond beige)
                            VStack(alignment: .leading, spacing: 16) {
                                HStack {
                                    Text("Valeur suggérée")
                                        .font(.system(size: 14, weight: .regular))
                                        .foregroundStyle(.black.opacity(0.7))

                                    Spacer()

                                    if isEstimating {
                                        ProgressView()
                                            .progressViewStyle(CircularProgressViewStyle(tint: .orange))
                                    } else if !title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                                        Text("\(recentCount)x / 30j")
                                            .font(.system(size: 12))
                                            .foregroundStyle(.black.opacity(0.5))
                                    }
                                }

                                HStack(spacing: 8) {
                                    Image(systemName: "sparkles")
                                        .font(.system(size: 20))
                                        .foregroundStyle(.orange)

                                    Text(String(format: "%.1f", finalGrains))
                                        .font(.system(size: 32, weight: .bold))
                                        .foregroundStyle(.orange)

                                    Text("grains")
                                        .font(.system(size: 16))
                                        .foregroundStyle(.black.opacity(0.6))
                                }

                                VStack(alignment: .leading, spacing: 8) {
                                    Text("Effort perçu")
                                        .font(.system(size: 13))
                                        .foregroundStyle(.black.opacity(0.6))

                                    HStack(spacing: 8) {
                                        ForEach(GoalEffort.allCases, id: \.self) { effort in
                                            Button {
                                                selectedEffort = effort
                                                updateSuggestion()
                                            } label: {
                                                Text(effort.displayName)
                                                    .font(.system(size: 13, weight: .semibold))
                                                    .foregroundStyle(selectedEffort == effort ? .white : .black)
                                                    .padding(.horizontal, 12)
                                                    .padding(.vertical, 8)
                                                    .background(
                                                        Capsule()
                                                            .fill(selectedEffort == effort ? Color.orange : Color.white)
                                                            .overlay(
                                                                Capsule()
                                                                    .stroke(Color.orange.opacity(0.3), lineWidth: 1)
                                                            )
                                                    )
                                            }
                                        }
                                    }
                                }

                                VStack(alignment: .leading, spacing: 6) {
                                    Text("Ajustement (±1 grain)")
                                        .font(.system(size: 13))
                                        .foregroundStyle(.black.opacity(0.6))

                                    Slider(value: $adjustment, in: -1...1, step: 0.5)
                                        .tint(.orange)

                                    Text("Final: \(String(format: "%.1f", finalGrains)) grains")
                                        .font(.system(size: 12))
                                        .foregroundStyle(.black.opacity(0.6))
                                }
                            }
                            .padding(20)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Color.orange.opacity(0.15))
                            )

                            // Bouton Ajouter l'objectif
                            Button {
                                Task {
                                    await createGoal()
                                }
                            } label: {
                                Group {
                                    if isCreating {
                                        ProgressView()
                                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                    } else {
                                        Text("Ajouter l'objectif")
                                            .font(.system(size: 16, weight: .semibold))
                                    }
                                }
                                .foregroundStyle(.white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 16)
                                .background(
                                    RoundedRectangle(cornerRadius: 8)
                                        .fill(title.isEmpty ? Color.gray : Color.orange)
                                )
                            }
                            .disabled(title.isEmpty || isCreating)

                            // Exemples pour cette catégorie
                            VStack(alignment: .leading, spacing: 12) {
                                Text("Exemples pour cette catégorie :")
                                    .font(.system(size: 14))
                                    .foregroundStyle(.black.opacity(0.6))

                                HStack(spacing: 8) {
                                    ForEach(categoryExamples.prefix(3), id: \.self) { example in
                                        Button {
                                            title = example
                                        } label: {
                                            Text(example)
                                                .font(.system(size: 14))
                                                .padding(.horizontal, 16)
                                                .padding(.vertical, 10)
                                                .background(
                                                    RoundedRectangle(cornerRadius: 8)
                                                        .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                                                        .background(
                                                            RoundedRectangle(cornerRadius: 8)
                                                                .fill(Color.white)
                                                        )
                                                )
                                                .foregroundStyle(.black)
                                        }
                                    }
                                }
                            }

                            Spacer(minLength: 40)
                        }
                        .padding(.horizontal, 20)
                        .padding(.top, 8)
                    }
                }
            }
            .navigationBarTitleDisplayMode(.inline)
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
            .onAppear {
                updateSuggestion()
            }
            .onChange(of: title) { _, _ in
                recalcSuggestion()
            }
            .onChange(of: selectedCategory) { _, _ in
                updateSuggestion()
            }
        }
    }

    private func createGoal() async {
        isCreating = true

        do {
            _ = try await goalManager.createGoal(
                title: title,
                description: description.isEmpty ? nil : description,
                category: selectedCategory,
                baseValue: finalGrains
            )

            await MainActor.run {
                dismiss()
            }
        } catch {
            print("Erreur de création: \(error.localizedDescription)")
            isCreating = false
        }
    }

    private var finalGrains: Double {
        let value = roundToHalf(suggestedGrains + adjustment)
        return min(10.0, max(0.5, value))
    }

    private func recalcSuggestion() {
        estimateTask?.cancel()

        let normalized = title.trimmingCharacters(in: .whitespacesAndNewlines)
        guard normalized.count >= 3 else {
            recentCount = 0
            updateSuggestion()
            return
        }

        isEstimating = true
        estimateTask = Task {
            try? await Task.sleep(nanoseconds: 300_000_000)
            if Task.isCancelled { return }

            let count = await goalManager.countRecentGoals(matching: normalized, withinDays: 30)
            if Task.isCancelled { return }

            await MainActor.run {
                recentCount = count
                isEstimating = false
                updateSuggestion()
            }
        }
    }

    private func updateSuggestion() {
        let base = GoalSuggestionEngine.calculateGrainValue(
            for: title,
            category: selectedCategory,
            estimatedDuration: nil,
            difficulty: selectedEffort.difficulty
        )
        let multiplier = rarityMultiplier(for: recentCount)
        suggestedGrains = roundToHalf(base * multiplier)
        adjustment = min(1, max(-1, adjustment))
    }

    private func rarityMultiplier(for count: Int) -> Double {
        switch count {
        case 0:
            return 1.25
        case 1...2:
            return 1.15
        case 3...5:
            return 1.0
        case 6...10:
            return 0.9
        case 11...20:
            return 0.8
        default:
            return 0.7
        }
    }

    private func roundToHalf(_ value: Double) -> Double {
        round(value * 2) / 2
    }
}

enum GoalEffort: String, CaseIterable {
    case light
    case medium
    case intense

    var displayName: String {
        switch self {
        case .light:
            return "Léger"
        case .medium:
            return "Moyen"
        case .intense:
            return "Intense"
        }
    }

    var difficulty: Difficulty {
        switch self {
        case .light:
            return .easy
        case .medium:
            return .medium
        case .intense:
            return .hard
        }
    }
}

// MARK: - Goal Card (Firebase)

struct FirebaseGoalCard: View {
    let goal: FirebaseGoal

    @State private var showValidation = false
    @State private var showPhoto = false

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(goal.category.emoji)
                    .font(.title2)

                VStack(alignment: .leading, spacing: 4) {
                    Text(goal.title)
                        .font(.headline)

                    if let description = goal.goalDescription {
                        Text(description)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }

                Spacer()

                VStack(alignment: .trailing) {
                    Text(String(format: "%.1f", goal.grainValue))
                        .font(.title3)
                        .fontWeight(.bold)
                        .foregroundStyle(.orange)

                    Text("grains")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }

            // Bouton de validation (si en attente)
            if goal.status == .pending {
                Button {
                    showValidation = true
                } label: {
                    HStack {
                        Image(systemName: "camera.fill")
                            .font(.headline)

                        Text("Valider avec photo")
                            .font(.headline)
                            .fontWeight(.semibold)
                    }
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background {
                        RoundedRectangle(cornerRadius: 10)
                            .fill(Color.green)
                    }
                }
            }

            // Badge de statut (si complété)
            if goal.status == .completed {
                HStack(spacing: 8) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.title3)
                        .foregroundStyle(.green)

                    Text("Objectif validé")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundStyle(.green)

                    Spacer()
                }
                .padding(.vertical, 8)

                // Bouton pour voir la photo
                if goal.photoURL != nil {
                    Button {
                        showPhoto = true
                    } label: {
                        HStack {
                            Image(systemName: "photo")
                                .font(.subheadline)

                            Text("Voir la photo")
                                .font(.subheadline)
                                .fontWeight(.medium)
                        }
                        .foregroundStyle(.blue)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background {
                            RoundedRectangle(cornerRadius: 10)
                                .fill(Color.blue.opacity(0.1))
                        }
                    }
                }
            }
        }
        .padding()
        .background {
            RoundedRectangle(cornerRadius: 15)
                .fill(Color(uiColor: .systemBackground))
                .shadow(color: .black.opacity(0.05), radius: 5)
        }
        .sheet(isPresented: $showValidation) {
            FirebaseValidateGoalView(goal: goal)
        }
        .sheet(isPresented: $showPhoto) {
            if let photoURL = goal.photoURL {
                GoalPhotoView(photoURL: photoURL, goalTitle: goal.title)
            }
        }
    }
}

// MARK: - View Photo Sheet

struct GoalPhotoView: View {
    let photoURL: String
    let goalTitle: String
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            VStack {
                AsyncImage(url: URL(string: photoURL)) { phase in
                    switch phase {
                    case .empty:
                        ProgressView()
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                    case .success(let image):
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                    case .failure:
                        VStack(spacing: 12) {
                            Image(systemName: "photo.fill")
                                .font(.system(size: 60))
                                .foregroundStyle(.secondary)
                            Text("Impossible de charger la photo")
                                .font(.headline)
                                .foregroundStyle(.secondary)
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                    @unknown default:
                        EmptyView()
                    }
                }
            }
            .navigationTitle(goalTitle)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Fermer") {
                        dismiss()
                    }
                }
            }
        }
    }
}

// MARK: - Validate Goal View (Firebase)

#if canImport(UIKit) && !os(macOS)
struct FirebaseValidateGoalView: View {
    let goal: FirebaseGoal

    @Environment(\.dismiss) private var dismiss
    @StateObject private var goalManager = GoalManager.shared

    @State private var selectedImage: UIImage?
    @State private var showImagePicker = false
    @State private var isValidating = false

    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                // Info objectif
                VStack(spacing: 8) {
                    Text(goal.category.emoji)
                        .font(.system(size: 60))

                    Text(goal.title)
                        .font(.title2)
                        .fontWeight(.bold)

                    HStack {
                        Text(String(format: "%.1f", goal.grainValue))
                            .font(.title)
                            .fontWeight(.bold)
                            .foregroundStyle(.orange)

                        Text("grains")
                            .font(.headline)
                            .foregroundStyle(.secondary)
                    }
                }
                .padding()

                // Zone photo
                VStack(spacing: 12) {
                    if let image = selectedImage {
                        Image(uiImage: image)
                            .resizable()
                            .scaledToFill()
                            .frame(height: 300)
                            .clipShape(RoundedRectangle(cornerRadius: 20))
                            .padding(.horizontal)
                    } else {
                        Button {
                            showImagePicker = true
                        } label: {
                            VStack(spacing: 12) {
                                Image(systemName: "camera.fill")
                                    .font(.system(size: 40))

                                Text("Ajouter une photo de preuve")
                                    .font(.headline)
                            }
                            .foregroundStyle(.blue)
                            .frame(maxWidth: .infinity)
                            .frame(height: 200)
                            .background {
                                RoundedRectangle(cornerRadius: 20)
                                    .fill(Color.blue.opacity(0.1))
                                    .overlay {
                                        RoundedRectangle(cornerRadius: 20)
                                            .stroke(Color.blue, style: StrokeStyle(lineWidth: 2, dash: [10]))
                                    }
                            }
                            .padding(.horizontal)
                        }
                    }

                    Text("📸 Photo non retouchée requise")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                // Bouton valider
                Button {
                    Task {
                        await validateGoal()
                    }
                } label: {
                    if isValidating {
                        ProgressView()
                            .frame(maxWidth: .infinity)
                            .padding()
                    } else {
                        Text("Valider l'objectif")
                            .font(.headline)
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background {
                                RoundedRectangle(cornerRadius: 15)
                                    .fill(Color.green)
                            }
                            .padding(.horizontal)
                    }
                }
                .disabled(selectedImage == nil || isValidating)
            }
            .padding(.vertical)
            .navigationTitle("Validation")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Annuler") {
                        dismiss()
                    }
                }
            }
            .sheet(isPresented: $showImagePicker) {
                ImagePicker(selectedImage: $selectedImage)
            }
        }
    }

    private func validateGoal() async {
        guard let image = selectedImage else {
            return
        }

        isValidating = true

        do {
            // 1. Créer et poster la victoire sur le fil
            let victory = try await VictoryManager.shared.createVictory(
                goalTitle: goal.title,
                goalEmoji: goal.category.emoji,
                photoImage: image
            )

            // 2. Valider l'objectif dans Firebase avec l'URL de la photo
            try await goalManager.validateGoal(goal, photoURL: victory.photoURL)

            await MainActor.run {
                dismiss()
            }
        } catch {
            print("Erreur de validation: \(error.localizedDescription)")
            isValidating = false
        }
    }
}
#endif

#Preview {
    FirebaseCreateGoalView()
}
