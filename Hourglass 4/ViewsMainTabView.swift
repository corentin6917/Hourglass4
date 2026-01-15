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
                    Image(systemName: "trophy")
                    Text("Fil")
                }
                .tag(0)

            // Onglet 2: Sablier (centre) - Nouvelle vue minimaliste Today
            HourglassTodayView(viewModel: viewModel)
                .tabItem {
                    Image(systemName: selectedTab == 1 ? "hourglass" : "hourglass")
                    Text("Sablier")
                }
                .tag(1)

            // Onglet 3: Objectifs
            ObjectivesViewFirebase()
                .tabItem {
                    Image(systemName: selectedTab == 2 ? "target" : "target")
                    Text("Objectifs")
                }
                .tag(2)
        }
        .tint(.orange)
        .onReceive(NotificationCenter.default.publisher(for: .switchToObjectivesTab)) { _ in
            selectedTab = 2
        }
    }
}

extension Notification.Name {
    static let switchToObjectivesTab = Notification.Name("switchToObjectivesTab")
}

#Preview {
    MainTabView(viewModel: nil)
}
