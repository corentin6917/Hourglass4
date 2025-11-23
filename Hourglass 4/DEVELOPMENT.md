# 🚀 Guide de Développement HOURGLASS

## Table des Matières

1. [Architecture](#architecture)
2. [Modèles de Données](#modèles-de-données)
3. [ViewModels](#viewmodels)
4. [Services](#services)
5. [Vues](#vues)
6. [Notifications](#notifications)
7. [Bonnes Pratiques](#bonnes-pratiques)
8. [Exemples d'Utilisation](#exemples-dutilisation)

---

## Architecture

HOURGLASS suit l'architecture **MVVM (Model-View-ViewModel)** avec SwiftData pour la persistance.

```
┌─────────────┐
│    Views    │ ← SwiftUI
└──────┬──────┘
       │
┌──────▼──────┐
│ ViewModels  │ ← @Observable
└──────┬──────┘
       │
┌──────▼──────┐
│   Models    │ ← SwiftData @Model
└─────────────┘
       │
┌──────▼──────┐
│  Services   │ ← Business Logic
└─────────────┘
```

### Principes

- **Single Source of Truth** : SwiftData comme unique source
- **Reactive** : @Observable pour la réactivité automatique
- **Async/Await** : Pour toutes les opérations asynchrones
- **Type-Safe** : Utilisation maximale du système de types Swift

---

## Modèles de Données

### UserProfile

Le modèle central de l'application.

```swift
let profile = UserProfile(username: "Marie")
profile.totalGrainsEarned = 250.0
profile.currentSeason = .summer

// Calcul du ratio
let ratio = profile.lifeRatio() // 70%
let interpretation = profile.ratioInterpretation() // "Tu vis exceptionnellement"
```

### Goal

Représente un objectif quotidien.

```swift
let goal = Goal(
    title: "Courir 10km",
    description: "Course matinale au parc",
    baseValue: 3.5,
    category: .physical
)

// Validation avec photo
let imageData = image.jpegData(compressionQuality: 0.7)!
goal.validate(with: imageData)

// Vérifier le statut
if goal.status == .completed {
    print("Objectif accompli ! \(goal.grainValue) grains gagnés")
}
```

### Grain

Unité de base du système.

```swift
// Grain de potentiel (blanc)
let potentialGrain = Grain(
    type: .potential,
    value: 1.0,
    source: .goal
)

// Grain gagné (doré)
let earnedGrain = Grain(
    type: .earned,
    value: 2.5,
    earnedDate: Date(),
    source: .goal
)

// Grain reçu d'un boost
let boostGrain = Grain(
    type: .earned,
    value: 0.2,
    source: .boost
)
```

---

## ViewModels

### HourglassViewModel

ViewModel principal qui gère tout l'état de l'application.

```swift
// Initialisation
let viewModel = HourglassViewModel(modelContext: modelContext)

// Créer un objectif
viewModel.createGoal(
    title: "Méditer 15 min",
    category: .personal,
    baseValue: 2.0
)

// Valider un objectif
if let imageData = image.jpegData(compressionQuality: 0.7) {
    viewModel.validateGoal(goal, with: imageData)
}

// Effectuer le reset matinal (à 8h)
viewModel.performMorningReset()

// Effectuer la validation du soir (à 20h)
viewModel.performEveningValidation()

// Obtenir le potentiel du jour
let potential = viewModel.potentialGrainsToday() // 8.5 grains

// Obtenir les grains gagnés aujourd'hui
let earned = viewModel.earnedGrainsToday() // 5.0 grains
```

---

## Services

### GoalSuggestionEngine

Moteur intelligent de suggestion et d'évaluation des objectifs.

```swift
// Calculer automatiquement la valeur d'un objectif
let value = GoalSuggestionEngine.calculateGrainValue(
    for: "Courir un marathon",
    category: .physical,
    difficulty: .hard
)
// Résultat : ~10.0 grains (détecte "marathon" comme mot-clé)

// Suggérer un upgrade
if let upgrade = GoalSuggestionEngine.suggestUpgrade(
    for: goal,
    userProfile: profile
) {
    print("Suggestion : \(upgrade.upgradedGoal)")
    print("Nouvelle valeur : \(upgrade.newGrainValue) grains")
}

// Obtenir des suggestions pour un utilisateur
let suggestions = GoalSuggestionEngine.suggestGoalsForUser(profile)
for suggestion in suggestions {
    print("\(suggestion.category.emoji) \(suggestion.title) - \(suggestion.estimatedValue) grains")
}
```

### NotificationManager

Gestion des notifications locales.

```swift
// Demander l'autorisation
let authorized = try await NotificationManager.shared.requestAuthorization()

if authorized {
    // Planifier les notifications quotidiennes (8h et 20h)
    try await NotificationManager.shared.scheduleDailyNotifications()
}

// Envoyer une notification de streak
try await NotificationManager.shared.sendStreakNotification(days: 30)

// Notifier l'activation du mode Phénix
try await NotificationManager.shared.sendPhoenixModeNotification()

// Notifier une nouvelle capsule temporelle
try await NotificationManager.shared.sendTimeCapsuleNotification(dayCount: 100)
```

---

## Vues

### Structure Recommandée

```swift
struct MyView: View {
    // Environment
    @Environment(\.modelContext) private var modelContext
    
    // ViewModel
    let viewModel: HourglassViewModel?
    
    // State
    @State private var isPresented = false
    
    var body: some View {
        // UI
    }
    
    // MARK: - Private Methods
    
    private func performAction() {
        // Logic
    }
}
```

### Exemple : Créer une Vue Personnalisée

```swift
struct CustomGoalCard: View {
    let goal: Goal
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(goal.category.emoji)
                    .font(.largeTitle)
                
                VStack(alignment: .leading) {
                    Text(goal.title)
                        .font(.headline)
                    
                    if let description = goal.goalDescription {
                        Text(description)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                
                Spacer()
                
                // Badge de grains
                GrainBadge(value: goal.grainValue)
            }
        }
        .padding()
        .background {
            RoundedRectangle(cornerRadius: 15)
                .fill(goal.category.categoryColor().opacity(0.1))
        }
    }
}

struct GrainBadge: View {
    let value: Double
    
    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: "sparkles")
            Text(String(format: "%.1f", value))
                .fontWeight(.semibold)
        }
        .font(.caption)
        .foregroundStyle(.yellow)
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background {
            Capsule()
                .fill(Color.yellow.opacity(0.2))
        }
    }
}
```

---

## Notifications

### Configuration dans Info.plist

```xml
<key>NSCameraUsageDescription</key>
<string>HOURGLASS utilise la caméra pour capturer la preuve de tes accomplissements</string>

<key>NSPhotoLibraryUsageDescription</key>
<string>HOURGLASS a besoin d'accéder à tes photos pour sauvegarder tes victoires</string>
```

### Gestion des Notifications

```swift
// Dans votre App
@main
struct HourglassApp: App {
    init() {
        // Configurer les notifications au démarrage
        Task {
            try? await NotificationManager.shared.requestAuthorization()
            try? await NotificationManager.shared.scheduleDailyNotifications()
        }
    }
}
```

---

## Bonnes Pratiques

### 1. Utilisation de SwiftData

```swift
// ✅ BON : Utiliser @Query pour les listes
@Query(sort: \Goal.createdAt, order: .reverse)
private var goals: [Goal]

// ✅ BON : Insérer dans le contexte
modelContext.insert(newGoal)
try modelContext.save()

// ❌ MAUVAIS : Ne pas créer de copies
// let goalCopy = goal // Éviter
```

### 2. Gestion des Erreurs

```swift
// ✅ BON : Gérer les erreurs avec do-catch
do {
    viewModel.createGoal(...)
    try modelContext.save()
} catch {
    print("Erreur : \(error.localizedDescription)")
    // Afficher une alerte à l'utilisateur
}

// ✅ BON : Utiliser des erreurs typées
enum GoalError: Error {
    case invalidTitle
    case tooManyGoals
}
```

### 3. Animations

```swift
// ✅ BON : Utiliser withAnimation pour les changements d'état
withAnimation(.easeInOut(duration: 0.3)) {
    showDetails = true
}

// ✅ BON : Animation de chute des grains
.animation(
    .easeInOut(duration: AppConstants.UI.grainFallAnimationDuration),
    value: grainsFalling
)
```

### 4. Performance

```swift
// ✅ BON : Lazy loading pour les listes longues
ScrollView {
    LazyVStack {
        ForEach(items) { item in
            ItemView(item: item)
        }
    }
}

// ✅ BON : @Attribute(.externalStorage) pour les gros fichiers
@Attribute(.externalStorage)
var proofImageData: Data?
```

---

## Exemples d'Utilisation

### Exemple 1 : Créer un Objectif et le Valider

```swift
// 1. Créer le ViewModel
let viewModel = HourglassViewModel(modelContext: modelContext)

// 2. Créer un objectif
viewModel.createGoal(
    title: "Faire 50 pompes",
    description: "Séance de musculation",
    category: .physical,
    baseValue: 2.5
)

// 3. Valider avec une photo
let image = UIImage(named: "proof")!
let imageData = image.jpegData(compressionQuality: 0.7)!
viewModel.validateGoal(goal, with: imageData)

// 4. Vérifier les grains gagnés
print("Grains gagnés : \(viewModel.earnedGrainsToday())")
```

### Exemple 2 : Afficher le Sablier

```swift
struct SimplifiedHourglassView: View {
    let profile: UserProfile
    
    var body: some View {
        VStack(spacing: 20) {
            // Partie haute (potentiel)
            VStack {
                Text("Potentiel")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                
                Circle()
                    .fill(Color.white)
                    .frame(width: 100, height: 100)
                    .overlay {
                        Text("\(Int(profile.grainsEarnedToday()))")
                            .font(.largeTitle)
                    }
            }
            
            // Goulot
            Rectangle()
                .fill(Color.gray)
                .frame(width: 30, height: 20)
            
            // Partie basse (héritage)
            VStack {
                Circle()
                    .fill(LinearGradient(
                        colors: [.yellow, .orange],
                        startPoint: .top,
                        endPoint: .bottom
                    ))
                    .frame(width: 150, height: 150)
                    .overlay {
                        VStack {
                            Text("\(Int(profile.totalGrainsEarned))")
                                .font(.largeTitle)
                                .fontWeight(.bold)
                            Text("grains")
                                .font(.caption)
                        }
                        .foregroundStyle(.white)
                    }
                
                Text("Héritage")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }
}
```

### Exemple 3 : Système de Streak

```swift
struct StreakTracker {
    let profile: UserProfile
    
    func checkAndUpdateStreak() async throws {
        let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: Date())!
        
        // Vérifier si l'utilisateur a gagné des grains hier
        let yesterdayGrains = profile.grains.filter { grain in
            guard let earnedDate = grain.earnedDate else { return false }
            return Calendar.current.isDate(earnedDate, inSameDayAs: yesterday)
        }
        
        if yesterdayGrains.isEmpty {
            // Reset de la streak
            profile.currentStreak = 0
        }
        
        // Vérifier les grains aujourd'hui
        let todayGrains = profile.grainsEarnedToday()
        
        if todayGrains > 0 {
            profile.currentStreak += 1
            
            if profile.currentStreak > profile.longestStreak {
                profile.longestStreak = profile.currentStreak
            }
            
            // Notifier si milestone
            if profile.currentStreak % 7 == 0 {
                try await NotificationManager.shared.sendStreakNotification(
                    days: profile.currentStreak
                )
            }
        }
    }
}
```

### Exemple 4 : Analyser les Patterns

```swift
struct PatternAnalyzer {
    let profile: UserProfile
    
    func analyzeLastMonth() -> MonthlyReport {
        let calendar = Calendar.current
        let now = Date()
        let monthAgo = calendar.date(byAdding: .month, value: -1, to: now)!
        
        let recentGrains = profile.grains.filter { grain in
            guard let earnedDate = grain.earnedDate else { return false }
            return earnedDate >= monthAgo && grain.type == .earned
        }
        
        let total = recentGrains.reduce(0.0) { $0 + $1.value }
        let average = total / 30.0
        
        // Déterminer la saison suggérée
        let suggestedSeason: LifeSeason
        if average < 4.0 {
            suggestedSeason = .winter
        } else if average >= 7.0 {
            suggestedSeason = .summer
        } else if average > profile.averageGrainsLastMonth() {
            suggestedSeason = .spring
        } else {
            suggestedSeason = .autumn
        }
        
        return MonthlyReport(
            totalGrains: total,
            averagePerDay: average,
            suggestedSeason: suggestedSeason
        )
    }
}

struct MonthlyReport {
    let totalGrains: Double
    let averagePerDay: Double
    let suggestedSeason: LifeSeason
}

extension UserProfile {
    func averageGrainsLastMonth() -> Double {
        // Implémenter le calcul du mois précédent
        return 5.5 // Placeholder
    }
}
```

---

## Debugging

### Activer les Logs Verbeux

```swift
if AppConfig.verboseLogging {
    print("🔍 [DEBUG] Goal created: \(goal.title)")
    print("🔍 [DEBUG] Grain value: \(goal.grainValue)")
}
```

### Simuler les Horaires

```swift
// Pour tester sans attendre 8h ou 20h
AppConfig.simulateTimeSlots = true

// Forcer le reset matinal
viewModel.performMorningReset()

// Forcer la validation du soir
viewModel.performEveningValidation()
```

---

## Tests

Voir `Tests/HourglassTests.swift` pour les tests complets.

```swift
@Test("Mon test personnalisé")
func testCustomFeature() async throws {
    let profile = UserProfile(username: "Test")
    profile.totalGrainsEarned = 100
    
    #expect(profile.lifeRatio() > 0)
}
```

---

**⏳ Happy Coding !**
