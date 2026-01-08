//
//  ProfileImagePicker.swift
//  Hourglass 4
//
//  Sélecteur d'image pour photo de profil
//  Permet de choisir entre caméra et pellicule
//

import SwiftUI
import UIKit

struct ProfileImagePicker: UIViewControllerRepresentable {
    @Binding var selectedImage: UIImage?
    @Environment(\.dismiss) private var dismiss

    let sourceType: UIImagePickerController.SourceType

    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.sourceType = sourceType
        picker.delegate = context.coordinator
        return picker
    }

    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let parent: ProfileImagePicker

        init(_ parent: ProfileImagePicker) {
            self.parent = parent
        }

        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
            if let image = info[.originalImage] as? UIImage {
                parent.selectedImage = image
            }
            parent.dismiss()
        }

        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            parent.dismiss()
        }
    }
}

// Vue pour choisir la source (caméra ou pellicule)
struct ProfileImageSourcePicker: View {
    @Binding var selectedImage: UIImage?
    @Environment(\.dismiss) private var dismiss

    @State private var showCamera = false
    @State private var showPhotoLibrary = false

    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                Text("Choisir une photo de profil")
                    .font(.title2)
                    .fontWeight(.bold)
                    .padding(.top, 32)

                VStack(spacing: 16) {
                    // Option Caméra
                    Button {
                        showCamera = true
                    } label: {
                        HStack(spacing: 16) {
                            ZStack {
                                Circle()
                                    .fill(Color.purple.opacity(0.1))
                                    .frame(width: 60, height: 60)

                                Image(systemName: "camera.fill")
                                    .font(.title2)
                                    .foregroundStyle(.purple)
                            }

                            VStack(alignment: .leading, spacing: 4) {
                                Text("Prendre une photo")
                                    .font(.headline)
                                    .foregroundStyle(.primary)
                                Text("Utiliser la caméra")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }

                            Spacer()

                            Image(systemName: "chevron.right")
                                .foregroundStyle(.secondary)
                        }
                        .padding()
                        .background {
                            RoundedRectangle(cornerRadius: 16)
                                .fill(Color(uiColor: .secondarySystemBackground))
                        }
                    }

                    // Option Pellicule
                    Button {
                        showPhotoLibrary = true
                    } label: {
                        HStack(spacing: 16) {
                            ZStack {
                                Circle()
                                    .fill(Color.pink.opacity(0.1))
                                    .frame(width: 60, height: 60)

                                Image(systemName: "photo.fill")
                                    .font(.title2)
                                    .foregroundStyle(.pink)
                            }

                            VStack(alignment: .leading, spacing: 4) {
                                Text("Choisir de la pellicule")
                                    .font(.headline)
                                    .foregroundStyle(.primary)
                                Text("Sélectionner une photo existante")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }

                            Spacer()

                            Image(systemName: "chevron.right")
                                .foregroundStyle(.secondary)
                        }
                        .padding()
                        .background {
                            RoundedRectangle(cornerRadius: 16)
                                .fill(Color(uiColor: .secondarySystemBackground))
                        }
                    }
                }
                .padding(.horizontal)

                Spacer()
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Annuler") {
                        dismiss()
                    }
                }
            }
            .sheet(isPresented: $showCamera) {
                ProfileImagePicker(selectedImage: $selectedImage, sourceType: .camera)
            }
            .sheet(isPresented: $showPhotoLibrary) {
                ProfileImagePicker(selectedImage: $selectedImage, sourceType: .photoLibrary)
            }
            .onChange(of: selectedImage) { oldValue, newValue in
                if newValue != nil {
                    dismiss()
                }
            }
        }
    }
}
