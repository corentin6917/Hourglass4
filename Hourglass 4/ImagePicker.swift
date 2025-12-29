//
//  ImagePicker.swift
//  Hourglass 4
//
//  Wrapper SwiftUI pour UIImagePickerController
//  TEMPORAIRE: Autorise la pellicule pour les tests sur simulateur
//  TODO: Retirer .photoLibrary avant la version finale
//

import SwiftUI
import UIKit

struct ImagePicker: UIViewControllerRepresentable {
    @Binding var selectedImage: UIImage?
    @Environment(\.dismiss) private var dismiss

    // TEMPORAIRE: Paramètre pour choisir la source (caméra ou pellicule)
    var sourceType: UIImagePickerController.SourceType = .camera

    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()

        // Sur simulateur, utiliser la pellicule car pas de caméra disponible
        #if targetEnvironment(simulator)
        picker.sourceType = .photoLibrary
        #else
        // Sur device réel, utiliser la source spécifiée (caméra par défaut)
        picker.sourceType = sourceType
        if sourceType == .camera {
            picker.cameraCaptureMode = .photo
            picker.cameraDevice = .rear
        }
        #endif

        picker.delegate = context.coordinator
        return picker
    }

    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let parent: ImagePicker

        init(_ parent: ImagePicker) {
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
