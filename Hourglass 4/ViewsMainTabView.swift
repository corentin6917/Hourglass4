//
//  MainTabView.swift
//  Hourglass 4
//
//  Created by Corentin Soula on 13/11/2025.
//

import SwiftUI
import Combine
#if canImport(UIKit)
import UIKit
#endif

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

// MARK: - Hourglass View (Vue Sablier)

struct HourglassView: View {
    let viewModel: HourglassViewModel?
    @State private var showProfile = false
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 30) {
                    // En-tête avec saison
                    if let profile = viewModel?.userProfile {
                        SeasonHeaderView(season: profile.currentSeason)
                            .padding(.top)
                    }
                    
                    // Le Sablier Réaliste
                    SimpleRealisticHourglass(
                        topFill: min((viewModel?.potentialGrainsToday() ?? 5.0) / 10.0, 1.0),
                        bottomFill: min((viewModel?.earnedGrainsToday() ?? 5.0) / 10.0, 1.0)
                    )
                    .frame(height: 420)
                    .padding()
                    
                    // Statistiques du jour
                    TodayStatsView(viewModel: viewModel)
                        .padding(.horizontal)
                    
                    // Ratio de vie
                    if let profile = viewModel?.userProfile {
                        LifeRatioCard(profile: profile)
                            .padding(.horizontal)
                    }
                    
                    Spacer(minLength: 40)
                }
            }
            .navigationTitle("⏳ HOURGLASS")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showProfile = true
                    } label: {
                        Circle()
                            .fill(Color.orange.gradient)
                            .frame(width: 36, height: 36)
                            .overlay {
                                Text("CS")
                                    .font(.caption)
                                    .fontWeight(.bold)
                                    .foregroundStyle(.white)
                            }
                    }
                }
            }
            .sheet(isPresented: $showProfile) {
                ProfileView(viewModel: viewModel)
            }
        }
    }
}

// MARK: - Objectives View (Mes Objectifs)

struct ObjectivesView: View {
    let viewModel: HourglassViewModel?
    @State private var showNewGoal = false
    @State private var showProfile = false
    
    var todayGoals: [Goal] {
        viewModel?.todayGoals ?? []
    }
    
    var potentialAllocated: Double {
        todayGoals.reduce(0) { $0 + $1.grainValue }
    }
    
    var potentialRemaining: Double {
        10.0 - potentialAllocated
    }
    
    var completedGoals: [Goal] {
        todayGoals.filter { $0.status == .completed }
    }
    
    var pendingGoals: [Goal] {
        todayGoals.filter { $0.status == .pending }
    }
    
    var grainsEarned: Double {
        completedGoals.reduce(0) { $0 + $1.grainValue }
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    // Section: Potentiel du Jour
                    PotentialCardView(
                        allocated: potentialAllocated,
                        remaining: potentialRemaining
                    )
                    .padding(.horizontal)
                    
                    // Règles
                    InfoBannerView(
                        message: "Règles : Tu dois définir entre 1 et 3 objectifs par jour, pour un maximum de 10 grains au total."
                    )
                    .padding(.horizontal)
                    
                    // Statistiques en cartes
                    HStack(spacing: 12) {
                        ObjectiveStatCard(
                            icon: "clock",
                            value: "\(pendingGoals.count)",
                            label: "En cours",
                            color: .gray
                        )
                        
                        ObjectiveStatCard(
                            icon: "checkmark.circle",
                            value: String(format: "%.1f", grainsEarned),
                            label: "Gagnés",
                            color: .green
                        )
                        
                        ObjectiveStatCard(
                            icon: "arrow.up.right",
                            value: "\(completedGoals.count)/\(todayGoals.count)",
                            label: "Objectifs",
                            color: .orange
                        )
                    }
                    .padding(.horizontal)
                    
                    // Bouton Nouvel Objectif
                    if todayGoals.count < 3 && potentialRemaining > 0 {
                        Button {
                            showNewGoal = true
                        } label: {
                            HStack {
                                Image(systemName: "plus.circle.fill")
                                    .font(.title2)
                                
                                Text("Nouvel Objectif (\(todayGoals.count)/3)")
                                    .font(.headline)
                            }
                            .foregroundStyle(.orange)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background {
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Color.orange.opacity(0.1))
                            }
                        }
                        .padding(.horizontal)
                    }
                    
                    // Liste des objectifs
                    if !todayGoals.isEmpty {
                        VStack(alignment: .leading, spacing: 16) {
                            Text("Objectifs d'aujourd'hui")
                                .font(.headline)
                                .padding(.horizontal)
                            
                            ForEach(todayGoals) { goal in
                                GoalCardView(goal: goal, viewModel: viewModel)
                                    .padding(.horizontal)
                            }
                        }
                    }
                    
                    Spacer(minLength: 40)
                }
                .padding(.vertical)
            }
            .navigationTitle("Mes Objectifs")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showProfile = true
                    } label: {
                        Circle()
                            .fill(Color.orange.gradient)
                            .frame(width: 36, height: 36)
                            .overlay {
                                Text("CS")
                                    .font(.caption)
                                    .fontWeight(.bold)
                                    .foregroundStyle(.white)
                            }
                    }
                }
            }
            .sheet(isPresented: $showNewGoal) {
                CreateGoalView(viewModel: viewModel)
            }
            .sheet(isPresented: $showProfile) {
                ProfileView(viewModel: viewModel)
            }
        }
    }
}

// MARK: - Potential Card

struct PotentialCardView: View {
    let allocated: Double
    let remaining: Double
    
    var total: Double {
        10.0
    }
    
    var progress: Double {
        allocated / total
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("POTENTIEL DU JOUR")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    
                    HStack(alignment: .firstTextBaseline, spacing: 4) {
                        Text("\(Int(total))")
                            .font(.system(size: 48, weight: .bold))
                            .foregroundStyle(.orange)
                        
                        Text("grains")
                            .font(.title3)
                            .foregroundStyle(.orange)
                    }
                    
                    Text("Valeur fixe quotidienne")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                
                Spacer()
                
                Image(systemName: "sparkles")
                    .font(.system(size: 40))
                    .foregroundStyle(.orange)
            }
            
            Divider()
            
            // Potentiel alloué
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("Potentiel alloué")
                        .font(.subheadline)
                    
                    Spacer()
                    
                    Text(String(format: "%.1f / %.0f grains", allocated, total))
                        .font(.subheadline)
                        .foregroundStyle(.orange)
                }
                
                // Barre de progression
                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color.gray.opacity(0.2))
                        
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color.orange)
                            .frame(width: geometry.size.width * progress)
                    }
                }
                .frame(height: 12)
                
                HStack {
                    Image(systemName: "hourglass")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    
                    Text("Il te reste \(String(format: "%.1f", remaining)) grains à allouer")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding()
        .background {
            RoundedRectangle(cornerRadius: 15)
                .fill(Color.orange.opacity(0.1))
                .overlay {
                    RoundedRectangle(cornerRadius: 15)
                        .stroke(Color.orange.opacity(0.3), lineWidth: 2)
                }
        }
    }
}

// MARK: - Info Banner

struct InfoBannerView: View {
    let message: String
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "info.circle")
                .foregroundStyle(.blue)
            
            Text(message)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background {
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.blue.opacity(0.1))
        }
    }
}

// MARK: - Objective Stat Card

struct ObjectiveStatCard: View {
    let icon: String
    let value: String
    let label: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(color)
            
            Text(value)
                .font(.title)
                .fontWeight(.bold)
                .foregroundStyle(color)
            
            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background {
            RoundedRectangle(cornerRadius: 12)
                .fill(color.opacity(0.1))
        }
    }
}

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

// MARK: - Victory Feed View

struct VictoryFeedView: View {
    let viewModel: HourglassViewModel?
    @State private var showProfile = false
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // Banner info
                    InfoBannerView(
                        message: "Gratuit à consulter ! Voir le fil des victoires ne coûte aucun grain. Soutiens tes amis avec des Éclats (0.2 grain) ou Commentaires (0.1 grain)."
                    )
                    .padding(.horizontal)
                    .padding(.top)
                    
                    // État vide
                    VStack(spacing: 16) {
                        Image(systemName: "sparkles")
                            .font(.system(size: 60))
                            .foregroundStyle(.purple)
                            .padding()
                            .background {
                                Circle()
                                    .fill(Color.purple.opacity(0.1))
                            }
                        
                        Text("Aucune victoire récente")
                            .font(.title2)
                            .fontWeight(.bold)
                        
                        Text("Les accomplissements de tes amis avec preuves photo apparaîtront ici.")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 40)
                    }
                    .padding(.vertical, 60)
                    
                    Spacer()
                }
            }
            .navigationTitle("Fil")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showProfile = true
                    } label: {
                        Circle()
                            .fill(Color.orange.gradient)
                            .frame(width: 36, height: 36)
                            .overlay {
                                Text("CS")
                                    .font(.caption)
                                    .fontWeight(.bold)
                                    .foregroundStyle(.white)
                            }
                    }
                }
            }
            .sheet(isPresented: $showProfile) {
                ProfileView(viewModel: viewModel)
            }
        }
    }
}

// MARK: - Create Goal View

struct CreateGoalView: View {
    let viewModel: HourglassViewModel?
    
    @Environment(\.dismiss) private var dismiss
    
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
                ImagePicker(image: $selectedImage)
            }
        }
    }
    
    private func validateGoal() {
        guard let image = selectedImage,
              let imageData = image.jpegData(compressionQuality: 0.8) else {
            return
        }
        
        viewModel?.validateGoal(goal, with: imageData)
        dismiss()
    }
}

// MARK: - Image Picker

struct ImagePicker: UIViewControllerRepresentable {
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
        let parent: ImagePicker
        
        init(_ parent: ImagePicker) {
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

// Version macOS : Désactivée pour l'instant
// L'app fonctionne uniquement sur iOS/iPadOS

#Preview {
    MainTabView(viewModel: nil)
}
