//
//  ContentView.swift
//  Hourglass 4
//
//  Created by Corentin Soula on 29/10/2025.
//

import SwiftUI
import SwiftData

struct ContentView: View {
    @StateObject private var viewModel: HourglassViewModel
    
    init(modelContext: ModelContext) {
        _viewModel = StateObject(wrappedValue: HourglassViewModel(modelContext: modelContext))
    }
    
    var body: some View {
        MainTabView(viewModel: viewModel)
            .onAppear {
                // Initialiser le profil utilisateur si nécessaire
                viewModel.initializeUserIfNeeded()
                // S'assurer que le profil Firestore existe et est normalisé
                Task { try? await UserManager.shared.ensureCurrentUserProfile() }
            }
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
    } catch {
        return Text("Erreur de prévisualisation: \(error.localizedDescription)")
    }
}

