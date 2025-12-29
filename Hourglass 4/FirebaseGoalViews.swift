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
    @State private var estimatedGrains = 2.0
    @State private var isCreating = false

    var body: some View {
        NavigationStack {
            Form {
                Section("Objectif") {
                    TextField("Ex: Courir 30 min", text: $title)

                    TextField("Description (optionnel)", text: $description, axis: .vertical)
                        .lineLimit(3...5)
                }

                Section("Catégorie") {
                    Picker("Catégorie", selection: $selectedCategory) {
                        ForEach(GoalCategory.allCases, id: \.self) { category in
                            Text("\(category.emoji) \(category.displayName)")
                                .tag(category)
                        }
                    }
                }

                Section("Valeur estimée") {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text(String(format: "%.1f grains", estimatedGrains))
                                .font(.headline)
                                .foregroundStyle(.orange)

                            Spacer()
                        }

                        Slider(value: $estimatedGrains, in: 0.5...10.0, step: 0.5)

                        Text("L'app ajustera cette valeur selon tes habitudes et la difficulté.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .navigationTitle("Nouvel Objectif")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Annuler") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Créer") {
                        Task {
                            await createGoal()
                        }
                    }
                    .disabled(title.isEmpty || isCreating)
                }
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
                baseValue: estimatedGrains
            )

            await MainActor.run {
                dismiss()
            }
        } catch {
            print("Erreur de création: \(error.localizedDescription)")
            isCreating = false
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
