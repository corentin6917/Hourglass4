//
//
//  MainTabView.swift
//  Hourglass 4
//
//  Created by Corentin Soula on 13/11/2025.
//

import SwiftUI

/// Vue principale avec navigation par onglets
struct MainTabView: View {
    @State private var selectedTab = 1 // Commence sur "Sablier"
    let viewModel: HourglassViewModel?

    var body: some View {
        TabView(selection: $selectedTab) {
            // Onglet 1: Fil des Victoires
            VictoryFeedView(viewModel: viewModel)
                .tabItem {
                    Label("Fil", systemImage: "sparkles")
                }
                .tag(0)

            // Onglet 2: Sablier (centre)
            HourglassView(viewModel: viewModel)
                .tabItem {
                    Label("Sablier", systemImage: "hourglass")
                }
                .tag(1)

            // Onglet 3: Objectifs
            ObjectivesView(viewModel: viewModel)
                .tabItem {
                    Label("Objectifs", systemImage: "target")
                }
                .tag(2)
        }
        .tint(.orange)
    }
}

#Preview {
    MainTabView(viewModel: nil)
}
