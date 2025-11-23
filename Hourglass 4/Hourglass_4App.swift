//
//  Hourglass_4App.swift
//  Hourglass 4
//
//  Created by Corentin Soula on 29/10/2025.
//

import SwiftUI
import SwiftData

@main
struct Hourglass_4App: App {
    
    // Configuration de SwiftData
    let modelContainer: ModelContainer
    
    init() {
        do {
            modelContainer = try ModelContainer(
                for: UserProfile.self,
                     Grain.self,
                     Goal.self,
                     TimeCapsule.self,
                     SocialInteraction.self,
                     SocialPact.self
            )
        } catch {
            fatalError("Impossible de créer le ModelContainer: \(error)")
        }
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView(modelContext: modelContainer.mainContext)
                .modelContainer(modelContainer)
        }
    }
}
