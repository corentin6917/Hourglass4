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
    @EnvironmentObject private var tutorialManager: TutorialManager

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
        .onReceive(NotificationCenter.default.publisher(for: .switchToVictoryFeed)) { _ in
            selectedTab = 0
        }
        .onChange(of: tutorialManager.currentTab) { _, newValue in
            selectedTab = newValue
        }
        .onChange(of: selectedTab) { _, newValue in
            guard tutorialManager.isActive, newValue != tutorialManager.currentTab else { return }
            selectedTab = tutorialManager.currentTab
        }
        .overlay(alignment: .bottomLeading) {
            // Anchor approximatif du bouton "Fil" (tab bar iOS) pour le tutoriel.
            Color.clear
                .frame(width: 46, height: 40)
                .padding(.leading, 42)
                .padding(.bottom, 6)
                .tutorialAnchor("feed.tab")
                .allowsHitTesting(false)
        }
    }
}

#Preview {
    MainTabView(viewModel: nil)
        .environmentObject(TutorialManager.shared)
}
