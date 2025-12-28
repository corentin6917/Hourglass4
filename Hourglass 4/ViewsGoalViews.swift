//
//  GoalViews.swift
//  Hourglass 4
//
//  Created by Corentin Soula on 13/11/2025.
//

import SwiftUI
#if canImport(UIKit)
import UIKit
#endif

// MARK: - Goal Card

struct GoalCardView: View {
    let goal: Goal
    let viewModel: HourglassViewModel?
    
    @State private var showValidation = false
    
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
            baseValue: estimatedGrains,
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
                    validateGoal()
                } label: {
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
                    photoImage: image
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
