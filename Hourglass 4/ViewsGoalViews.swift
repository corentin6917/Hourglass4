//
//  GoalViews.swift
//  Hourglass 4
//
//  Created by Corentin Soula on 13/11/2025.
//

import SwiftUI
import FirebaseAuth
#if canImport(UIKit)
import UIKit
#endif

// MARK: - Goal Card

struct GoalCardView: View {
    let goal: Goal
    let viewModel: HourglassViewModel?

    @State private var showValidation = false
    @State private var isPinned = false
    @State private var isLoadingPin = false

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

                VStack(alignment: .trailing, spacing: 4) {
                    Text("\(Int(ceil(goal.grainValue)))")
                        .font(.title3)
                        .fontWeight(.bold)
                        .foregroundStyle(.orange)

                    Text("grains")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }

                // Pin button (only shown for completed goals)
                if goal.status == .completed {
                    Button {
                        Task {
                            await togglePin()
                        }
                    } label: {
                        Image(systemName: isPinned ? "pin.fill" : "pin")
                            .font(.system(size: 16))
                            .foregroundStyle(.orange)
                            .frame(width: 32, height: 32)
                            .background {
                                Circle()
                                    .fill(Color.orange.opacity(0.1))
                            }
                    }
                    .disabled(isLoadingPin)
                    .opacity(isLoadingPin ? 0.5 : 1.0)
                }
            }
            
            Divider()
            
            HStack {
                // Badge de statut
                HStack(spacing: 4) {
                    Image(systemName: goal.status == .completed ? "checkmark.circle.fill" : "clock")
                        .font(.caption)
                    
                    Text(goal.status == .completed ? "Complété" : "En cours")
                        .font(.caption)
                }
                .foregroundStyle(goal.status == .completed ? .green : .gray)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background {
                    Capsule()
                        .fill((goal.status == .completed ? Color.green : Color.gray).opacity(0.2))
                }
                
                Spacer()
                
                // Bouton d'action
                if goal.status == .pending {
                    Button {
                        showValidation = true
                    } label: {
                        Text("Valider")
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundStyle(.white)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 6)
                            .background {
                                Capsule()
                                    .fill(Color.green)
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
            ValidateGoalView(goal: goal, viewModel: viewModel)
        }
        .task {
            if goal.status == .completed {
                await loadPinState()
            }
        }
    }

    private func loadPinState() async {
        guard let currentUserId = Auth.auth().currentUser?.uid else { return }
        do {
            let goalKey = "\(goal.title)_\(Int(goal.createdAt.timeIntervalSince1970))"
            let pinned = try await GoalPinManager.shared.isGoalPinned(goalKey, userId: currentUserId)
            await MainActor.run {
                isPinned = pinned
            }
        } catch {
            print("Error loading pin state: \(error.localizedDescription)")
        }
    }

    private func togglePin() async {
        guard let currentUserId = Auth.auth().currentUser?.uid else { return }
        isLoadingPin = true

        do {
            let goalKey = "\(goal.title)_\(Int(goal.createdAt.timeIntervalSince1970))"
            if isPinned {
                try await GoalPinManager.shared.unpinGoal(goalKey, userId: currentUserId)
                await MainActor.run { isPinned = false }
            } else {
                try await GoalPinManager.shared.pinGoal(goalKey, userId: currentUserId, goalData: [
                    "title": goal.title,
                    "emoji": goal.category.emoji,
                    "grainValue": goal.grainValue,
                    "createdAt": goal.createdAt.timeIntervalSince1970
                ])
                await MainActor.run { isPinned = true }
            }
        } catch {
            print("Error toggling pin: \(error.localizedDescription)")
        }

        isLoadingPin = false
    }
}

// MARK: - Create Goal View

struct CreateGoalView: View {
    let viewModel: HourglassViewModel?
    
    @Environment(\.dismiss) var dismiss
    
    @State private var title = ""
    @State private var description = ""
    @State private var selectedCategory: GoalCategory = .personal
    @State private var estimatedGrains = 2.0
    
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
                            Text("\(Int(ceil(estimatedGrains))) grains")
                                .font(.headline)
                                .foregroundStyle(.orange)
                            
                            Spacer()
                        }
                        
                        Slider(value: $estimatedGrains, in: 1.0...10.0, step: 1.0)
                        
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
                        createGoal()
                    }
                    .disabled(title.isEmpty)
                }
            }
        }
    }
    
    private func createGoal() {
        let goal = Goal(
            title: title,
            description: description.isEmpty ? nil : description,
            baseValue: ceil(estimatedGrains),
            category: selectedCategory
        )
        
        viewModel?.addGoal(goal)
        dismiss()
    }
}

// MARK: - Validate Goal View

#if canImport(UIKit) && !os(macOS)
struct ValidateGoalView: View {
    let goal: Goal
    let viewModel: HourglassViewModel?
    
    @Environment(\.dismiss) private var dismiss
    @State private var selectedImage: UIImage?
    @State private var showImagePicker = false
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
                    validateGoal()
                } label: {
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
                .disabled(selectedImage == nil)
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
                GoalCameraPicker(image: $selectedImage)
            }
        }
    }
    
    private func validateGoal() {
        guard let image = selectedImage,
              let imageData = image.jpegData(compressionQuality: 0.8) else {
            return
        }

        // Créer et poster la victoire sur le fil
        Task {
            do {
                _ = try await VictoryManager.shared.createVictory(
                    goalTitle: goal.title,
                    goalEmoji: goal.category.emoji,
                    photoImage: image,
                    comment: commentText
                )

                // Valider l'objectif localement
                await MainActor.run {
                    viewModel?.validateGoal(goal, with: imageData)
                    dismiss()
                }
            } catch {
                print("Erreur lors de la création de la victoire: \(error.localizedDescription)")
                // Même en cas d'erreur, on valide quand même l'objectif localement
                await MainActor.run {
                    viewModel?.validateGoal(goal, with: imageData)
                    dismiss()
                }
            }
        }
    }
}

// MARK: - Image Picker

struct GoalCameraPicker: UIViewControllerRepresentable {
    @Binding var image: UIImage?
    @Environment(\.dismiss) private var dismiss
    
    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.delegate = context.coordinator
        picker.sourceType = .camera
        picker.cameraCaptureMode = .photo
        return picker
    }
    
    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let parent: GoalCameraPicker

        init(_ parent: GoalCameraPicker) {
            self.parent = parent
        }

        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
            if let image = info[.originalImage] as? UIImage {
                parent.image = image
            }
            parent.dismiss()
        }

        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            parent.dismiss()
        }
    }
}
#endif
