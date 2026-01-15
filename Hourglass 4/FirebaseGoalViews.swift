//
//  FirebaseGoalViews.swift
//  Hourglass 4
//
//  Vues pour les objectifs stockés dans Firebase
//

import SwiftUI
#if canImport(FirebaseAuth)
import FirebaseAuth
#endif
#if canImport(FirebaseFirestore)
import FirebaseFirestore
#endif
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
    @State private var suggestedGrains = 3.0
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
                    headerSection

                    ScrollView {
                        VStack(alignment: .leading, spacing: 24) {
                            mainQuestionSection
                            suggestedValueCard
                            addGoalButton
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

    private var mainQuestionSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Que veux-tu accomplir aujourd'hui ?")
                .font(.system(size: 17, weight: .semibold))
                .foregroundStyle(.primary)

            TextField("Ex: Courir 30 minutes", text: $title)
                .font(.system(size: 16))
                .padding(16)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color(uiColor: .systemGray6))
                )
        }
    }

    private var suggestedValueCard: some View {
        VStack(alignment: .leading, spacing: 20) {
            HStack(alignment: .center) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Valeur suggérée")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(.primary)

                    if isEstimating {
                        HStack(spacing: 6) {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .orange))
                                .scaleEffect(0.7)
                            Text("Calcul...")
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }
                    } else if !title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                        Text("Fait \(recentCount) fois ces 30 derniers jours")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                }

                Spacer()
            }

            HStack(alignment: .firstTextBaseline, spacing: 8) {
                Image(systemName: "sparkles")
                    .font(.system(size: 24))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.orange, Color(red: 1.0, green: 0.6, blue: 0.0)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )

                Text("\(Int(ceil(finalGrains)))")
                    .font(.system(size: 48, weight: .bold))
                    .foregroundStyle(.orange)

                Text("grains")
                    .font(.system(size: 18, weight: .medium))
                    .foregroundStyle(.secondary)
            }

            Divider()

            VStack(alignment: .leading, spacing: 12) {
                Text("Effort perçu")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(.primary)

                HStack(spacing: 10) {
                    ForEach(GoalEffort.allCases, id: \.self) { effort in
                        Button {
                            selectedEffort = effort
                            updateSuggestion()
                        } label: {
                            Text(effort.displayName)
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundStyle(selectedEffort == effort ? .white : .orange)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 10)
                                .background(
                                    RoundedRectangle(cornerRadius: 10)
                                        .fill(selectedEffort == effort ? Color.orange : Color.clear)
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 10)
                                                .stroke(Color.orange, lineWidth: selectedEffort == effort ? 0 : 1.5)
                                        )
                                )
                        }
                        .buttonStyle(.plain)
                    }
                }
            }

            VStack(alignment: .leading, spacing: 10) {
                Text("Ajustement manuel")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(.primary)

                HStack(spacing: 12) {
                    Text("−1")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(.secondary)

                    Slider(value: $adjustment, in: -1...1, step: 1.0)
                        .tint(.orange)

                    Text("+1")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(.secondary)
                }

                if adjustment != 0 {
                    Text("Ajusté de \(adjustment > 0 ? "+" : "")\(Int(adjustment)) grain\(abs(adjustment) > 1 ? "s" : "")")
                        .font(.caption)
                        .foregroundStyle(.orange)
                }
            }
        }
        .padding(24)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(
                    LinearGradient(
                        colors: [
                            Color.orange.opacity(0.12),
                            Color.orange.opacity(0.06)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(Color.orange.opacity(0.2), lineWidth: 1)
                )
        )
    }

    private var addGoalButton: some View {
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
                        .font(.system(size: 17, weight: .semibold))
                }
            }
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(title.isEmpty ? Color.gray.opacity(0.3) : Color.orange)
                    .shadow(
                        color: title.isEmpty ? .clear : .orange.opacity(0.3),
                        radius: 8,
                        x: 0,
                        y: 4
                    )
            )
        }
        .disabled(title.isEmpty || isCreating)
    }

    private var headerSection: some View {
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
        let value = roundUpGrain(suggestedGrains + adjustment)
        return min(10.0, max(1.0, value))
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
        suggestedGrains = roundUpGrain(base * multiplier)
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

    private func roundUpGrain(_ value: Double) -> Double {
        ceil(value)
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
    @State private var showCommentEditor = false

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
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
                    Text("\(Int(ceil(goal.grainValue)))")
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
                    .foregroundStyle(.orange)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background {
                        RoundedRectangle(cornerRadius: 10)
                            .fill(Color.orange.opacity(0.12))
                            .overlay {
                                RoundedRectangle(cornerRadius: 10)
                                    .stroke(Color.orange.opacity(0.35), lineWidth: 1)
                            }
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

                    Button {
                        showCommentEditor = true
                    } label: {
                        HStack {
                            Image(systemName: "quote.bubble")
                                .font(.subheadline)

                            Text("Ajouter / modifier le commentaire")
                                .font(.subheadline)
                                .fontWeight(.medium)
                        }
                        .foregroundStyle(.orange)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background {
                            RoundedRectangle(cornerRadius: 10)
                                .fill(Color.orange.opacity(0.12))
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
        .sheet(isPresented: $showCommentEditor) {
            GoalVictoryCommentEditor(goal: goal)
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

// MARK: - Commentaire de victoire (Objectifs)

struct GoalVictoryCommentEditor: View {
    let goal: FirebaseGoal

    @Environment(\.dismiss) private var dismiss
    @State private var commentText = ""
    @State private var initialComment = ""
    @State private var isLoading = true
    @State private var isSaving = false
    @State private var errorMessage: String?
    @State private var resolvedVictoryId: String?
    @FocusState private var isCommentFocused: Bool

    private var trimmedComment: String {
        commentText.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private var trimmedInitial: String {
        initialComment.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 16) {
                Text("Ton commentaire")
                    .font(.headline)

                if isLoading {
                    ProgressView()
                } else if resolvedVictoryId == nil {
                    Text("Impossible de retrouver cette victoire pour l’instant.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                } else {
                    TextField("Ajoute un commentaire pour ta victoire", text: $commentText, axis: .vertical)
                        .lineLimit(2...4)
                        .submitLabel(.done)
                        .focused($isCommentFocused)
                        .onSubmit { isCommentFocused = false }
                        .padding(12)
                        .background {
                            RoundedRectangle(cornerRadius: 14)
                                .fill(Color.orange.opacity(0.08))
                                .overlay {
                                    RoundedRectangle(cornerRadius: 14)
                                        .stroke(Color.orange.opacity(0.18), lineWidth: 1)
                                }
                        }

                    Button {
                        Task { await saveComment() }
                    } label: {
                        if isSaving {
                            ProgressView()
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 10)
                        } else {
                            Text(trimmedInitial.isEmpty ? "Ajouter" : "Mettre à jour")
                                .font(.subheadline)
                                .fontWeight(.semibold)
                                .foregroundStyle(.white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 10)
                                .background {
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(Color.orange)
                                }
                        }
                    }
                    .disabled(isSaving || trimmedComment == trimmedInitial)
                }

                if let errorMessage {
                    Text(errorMessage)
                        .font(.caption)
                        .foregroundStyle(.red)
                }

                Spacer()
            }
            .padding()
            .navigationTitle("Commentaire")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Fermer") { dismiss() }
                }
                ToolbarItem(placement: .keyboard) {
                    Button("Terminer") { isCommentFocused = false }
                }
            }
            .task {
                await loadComment()
            }
        }
    }

    private func loadComment() async {
        isLoading = true
        errorMessage = nil

        do {
            let victoryId = try await resolveVictoryId()
            resolvedVictoryId = victoryId

            if let victoryId {
                let comment = try await VictoryManager.shared.fetchVictoryComment(victoryId: victoryId) ?? ""
                await MainActor.run {
                    initialComment = comment
                    commentText = comment
                }
            }
        } catch {
            await MainActor.run {
                errorMessage = error.localizedDescription
            }
        }

        isLoading = false
    }

    private func resolveVictoryId() async throws -> String? {
        if let victoryId = goal.victoryId, !victoryId.isEmpty {
            return victoryId
        }

        guard let photoURL = goal.photoURL,
              let currentUserId = Auth.auth().currentUser?.uid else {
            return nil
        }

        if let victoryId = try await VictoryManager.shared.fetchVictoryIdByPhotoURL(photoURL, userId: currentUserId) {
            let db = Firestore.firestore()
            try await db.collection("goals").document(goal.goalId).updateData([
                "victoryId": victoryId
            ])
            return victoryId
        }

        return nil
    }

    private func saveComment() async {
        guard let victoryId = resolvedVictoryId else {
            await MainActor.run {
                errorMessage = "Victoire introuvable."
            }
            return
        }

        isSaving = true
        errorMessage = nil

        do {
            try await VictoryManager.shared.updateVictoryComment(victoryId: victoryId, comment: commentText)
            await MainActor.run {
                initialComment = trimmedComment
                commentText = trimmedComment
                isCommentFocused = false
            }
        } catch {
            await MainActor.run {
                errorMessage = error.localizedDescription
            }
        }

        isSaving = false
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
    @State private var commentText: String = ""
    @FocusState private var isCommentFocused: Bool

    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                // Info objectif
                VStack(spacing: 8) {
                    Text(goal.title)
                        .font(.title2)
                        .fontWeight(.bold)

                    HStack {
                        Text("\(Int(ceil(goal.grainValue)))")
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
                            .foregroundStyle(.orange)
                            .frame(maxWidth: .infinity)
                            .frame(height: 200)
                            .background {
                                RoundedRectangle(cornerRadius: 20)
                                    .fill(Color.orange.opacity(0.08))
                                    .overlay {
                                        RoundedRectangle(cornerRadius: 20)
                                            .stroke(Color.orange, style: StrokeStyle(lineWidth: 2, dash: [10]))
                                    }
                            }
                            .padding(.horizontal)
                        }
                    }

                    Text("📸 Photo non retouchée requise")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                VStack(alignment: .leading, spacing: 10) {
                    HStack(spacing: 8) {
                        Image(systemName: "quote.bubble")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(.orange)
                        Text("Commentaire (optionnel)")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.horizontal)

                    TextField("Ex: Premiere sortie longue 💪", text: $commentText, axis: .vertical)
                        .lineLimit(2...3)
                        .submitLabel(.done)
                        .focused($isCommentFocused)
                        .onSubmit { isCommentFocused = false }
                        .padding(14)
                        .background {
                            RoundedRectangle(cornerRadius: 16)
                                .fill(
                                    LinearGradient(
                                        colors: [
                                            Color.orange.opacity(0.08),
                                            Color(uiColor: .secondarySystemBackground)
                                        ],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .overlay {
                                    RoundedRectangle(cornerRadius: 16)
                                        .stroke(Color.orange.opacity(0.15), lineWidth: 1)
                                }
                        }
                        .padding(.horizontal)
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
                                    .fill(Color.orange)
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
                ToolbarItem(placement: .keyboard) {
                    Button("Terminer") {
                        isCommentFocused = false
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
                photoImage: image,
                comment: commentText
            )

            // 2. Valider l'objectif dans Firebase avec l'URL de la photo
            try await goalManager.validateGoal(goal, photoURL: victory.photoURL, victoryId: victory.victoryId)

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
