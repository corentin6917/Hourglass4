//
//  MainTabView.swift
//  Hourglass 4
//
//  Navigation principale - Design minimaliste BeReal-inspired
//  Updated on 2026-01-07
//

import SwiftUI

/// Vue principale avec navigation par onglets - Style minimaliste
struct MainTabView: View {
    @State private var selectedTab = 1 // Commence sur "Sablier"
    let viewModel: HourglassViewModel?

    var body: some View {
        TabView(selection: $selectedTab) {
            // Onglet 1: Fil des Victoires
            VictoryFeedView()
                .tabItem {
                    // Icône seulement, pas de texte pour un look épuré
                    Image(systemName: selectedTab == 0 ? "sparkles" : "sparkles")
                }
                .tag(0)

            // Onglet 2: Sablier (centre) - L'écran principal
            HourglassView(viewModel: viewModel)
                .tabItem {
                    Image(systemName: selectedTab == 1 ? "hourglass" : "hourglass")
                }
                .tag(1)

            // Onglet 3: Objectifs
            ObjectivesViewFirebase()
                .tabItem {
                    Image(systemName: selectedTab == 2 ? "target" : "target")
                }
                .tag(2)
        }
        .tint(Theme.Colors.accent) // Utilise la couleur du nouveau thème
        .onAppear {
            // Style de la tab bar pour un look plus clean
            let appearance = UITabBarAppearance()
            appearance.configureWithTransparentBackground()
            appearance.backgroundColor = UIColor(Theme.Colors.background)

            // Bordure supérieure subtile
            appearance.shadowColor = UIColor(Theme.Colors.border)

            UITabBar.appearance().standardAppearance = appearance
            if #available(iOS 15.0, *) {
                UITabBar.appearance().scrollEdgeAppearance = appearance
            }
        }
    }
}

#Preview {
    MainTabView(viewModel: nil)
}
