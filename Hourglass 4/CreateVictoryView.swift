//
//  CreateVictoryView.swift
//  Hourglass 4
//
//  Vue pour créer et poster une victoire
//

import SwiftUI

struct CreateVictoryView: View {
    let goalTitle: String
    let goalEmoji: String

    @Environment(\.dismiss) private var dismiss
    @State private var selectedImage: UIImage?
    @State private var showImagePicker = false
    @State private var isPosting = false
    @State private var postError: String?

    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                // Info de l'objectif
                VStack(spacing: 8) {
                    Text(goalEmoji)
                        .font(.system(size: 60))

                    Text(goalTitle)
                        .font(.title2)
                        .fontWeight(.bold)
                        .multilineTextAlignment(.center)
                }
                .padding()

                // Zone photo
                VStack(spacing: 16) {
                    if let image = selectedImage {
                        Image(uiImage: image)
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(maxWidth: .infinity)
                            .frame(height: 350)
                            .clipShape(RoundedRectangle(cornerRadius: 20))
                            .padding(.horizontal)

                        Button {
                            selectedImage = nil
                        } label: {
                            Label("Changer la photo", systemImage: "arrow.triangle.2.circlepath")
                                .font(.headline)
                                .foregroundStyle(.blue)
                        }
                    } else {
                        Button {
                            showImagePicker = true
                        } label: {
                            VStack(spacing: 16) {
                                Image(systemName: "camera.fill")
                                    .font(.system(size: 50))

                                VStack(spacing: 4) {
                                    Text("Ajouter une photo de preuve")
                                        .font(.headline)

                                    Text("Photo non retouchée requise")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                            }
                            .foregroundStyle(.blue)
                            .frame(maxWidth: .infinity)
                            .frame(height: 250)
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
                }

                if let error = postError {
                    Text(error)
                        .font(.caption)
                        .foregroundStyle(.red)
                        .padding()
                }

                Spacer()

                // Bouton Publier
                Button {
                    Task {
                        await postVictory()
                    }
                } label: {
                    if isPosting {
                        ProgressView()
                            .frame(maxWidth: .infinity)
                            .padding()
                    } else {
                        Text("Publier ma victoire")
                            .font(.headline)
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background {
                                RoundedRectangle(cornerRadius: 15)
                                    .fill(selectedImage == nil ? Color.gray : Color.green)
                            }
                    }
                }
                .disabled(selectedImage == nil || isPosting)
                .padding(.horizontal)
            }
            .navigationTitle("Valider ma victoire")
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

    private func postVictory() async {
        guard let image = selectedImage else { return }

        isPosting = true
        postError = nil

        do {
            _ = try await VictoryManager.shared.createVictory(
                goalTitle: goalTitle,
                goalEmoji: goalEmoji,
                photoImage: image
            )

            await MainActor.run {
                dismiss()
            }
        } catch {
            await MainActor.run {
                postError = error.localizedDescription
                isPosting = false
            }
        }
    }
}

#Preview {
    CreateVictoryView(goalTitle: "Courir 30 min", goalEmoji: "🏃")
}
