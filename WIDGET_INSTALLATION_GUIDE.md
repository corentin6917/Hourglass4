# 📱 Guide d'Installation du Widget Hourglass

## 🎯 Vue d'ensemble

Le widget Hourglass affiche en temps réel :
- ✅ **Grains gagnés aujourd'hui** vs hier
- 🔥 **Streak actuel** (jours consécutifs)
- ⏰ **Countdown jusqu'à 20h** (deadline)
- 📊 **Objectifs validés/en attente**
- 🎨 **Design moderne** avec 3 tailles (Small, Medium, Large)

---

## 📦 Fichiers créés

```
HourglassWidget/
├── HourglassWidget.swift          # Widget principal avec 3 vues
├── SharedDataManager.swift        # Partage de données App ↔ Widget
├── Info.plist                     # Configuration du widget
└── HourglassWidget.entitlements   # App Groups

Hourglass 4/
├── WidgetUpdateHelper.swift       # Helper pour mise à jour auto
└── Hourglass4.entitlements        # App Groups (app principale)
```

---

## 🛠️ Installation (Étapes dans Xcode)

### Étape 1 : Ajouter le Widget Extension Target

1. **Ouvrir Xcode**
   ```bash
   open "/Users/corentinsoula/Desktop/Hourglass 4/Hourglass 4.xcworkspace"
   ```

2. **Créer le target du widget**
   - File → New → Target...
   - Chercher "Widget Extension"
   - Cliquer "Next"

3. **Configurer le target**
   - Product Name: `HourglassWidget`
   - Team: (votre équipe de développement)
   - Organization Identifier: `com.hourglass` (ou votre ID)
   - Language: Swift
   - ✅ Cocher "Include Configuration Intent" (optionnel)
   - Cliquer "Finish"

4. **Supprimer les fichiers par défaut**
   - Xcode créera automatiquement des fichiers
   - Supprimer `HourglassWidget.swift` et `HourglassWidgetBundle.swift` générés
   - Garder uniquement le dossier `HourglassWidget/`

5. **Ajouter nos fichiers au target**
   - Clic droit sur le dossier `HourglassWidget` → Add Files...
   - Sélectionner `HourglassWidget.swift` et `SharedDataManager.swift`
   - ✅ Cocher "Copy items if needed"
   - ✅ Cocher le target "HourglassWidget"
   - Cliquer "Add"

---

### Étape 2 : Configurer App Groups

#### 2.1 Dans l'app principale (Hourglass 4)

1. **Aller dans Project Settings**
   - Sélectionner le projet `Hourglass 4` dans le navigateur
   - Target: `Hourglass 4`
   - Onglet "Signing & Capabilities"

2. **Ajouter App Groups**
   - Cliquer sur "+ Capability"
   - Chercher et ajouter "App Groups"

3. **Créer le groupe**
   - Cliquer sur "+"
   - Nom: `group.com.hourglass.hourglass4`
   - ✅ Cocher la case pour activer

4. **Ajouter l'entitlements**
   - Toujours dans "Signing & Capabilities"
   - Code Signing Entitlements: `Hourglass 4/Hourglass4.entitlements`

#### 2.2 Dans le widget (HourglassWidget)

1. **Aller dans le target du widget**
   - Target: `HourglassWidget`
   - Onglet "Signing & Capabilities"

2. **Ajouter App Groups**
   - Cliquer sur "+ Capability"
   - Ajouter "App Groups"
   - ✅ Cocher `group.com.hourglass.hourglass4` (même nom !)

3. **Ajouter l'entitlements**
   - Code Signing Entitlements: `HourglassWidget/HourglassWidget.entitlements`

---

### Étape 3 : Configurer le Bundle Identifier

1. **Widget target**
   - Target: `HourglassWidget`
   - Onglet "General"
   - Bundle Identifier: `com.hourglass.hourglass4.HourglassWidget`
   - Deployment Target: iOS 16.0 minimum

2. **Vérifier l'app principale**
   - Target: `Hourglass 4`
   - Bundle Identifier: `com.hourglass.hourglass4`

---

### Étape 4 : Ajouter les fichiers à l'app principale

1. **Ajouter WidgetUpdateHelper.swift**
   - Déjà créé dans `Hourglass 4/`
   - Vérifier qu'il est bien dans le target `Hourglass 4`

2. **Ajouter SharedDataManager.swift à l'app**
   - Clic droit sur `SharedDataManager.swift`
   - File Inspector → Target Membership
   - ✅ Cocher `Hourglass 4` ET `HourglassWidget`
   - Le fichier doit être accessible aux 2 targets

---

### Étape 5 : Intégrer les mises à jour dans l'app

#### 5.1 Dans GoalManager.swift

Ajoutez ceci après chaque modification d'objectif :

```swift
// Dans GoalManager.swift

// Après createGoal()
func createGoal(...) async throws -> Goal {
    // ... code existant ...

    // Rafraîchir le widget
    WidgetUpdateHelper.shared.updateWidgetFromFirebase()

    return goal
}

// Après validateGoal()
func validateGoal(...) async throws {
    // ... code existant ...

    // Rafraîchir le widget
    WidgetUpdateHelper.shared.updateWidgetFromFirebase()
}

// Après deleteGoal()
func deleteGoal(...) async throws {
    // ... code existant ...

    // Rafraîchir le widget
    WidgetUpdateHelper.shared.updateWidgetFromFirebase()
}
```

#### 5.2 Dans Hourglass_4App.swift

Rafraîchir le widget au lancement :

```swift
// Dans Hourglass_4App.swift

@main
struct Hourglass_4App: App {
    // ... code existant ...

    init() {
        // ... code existant ...

        // Rafraîchir le widget au lancement
        WidgetUpdateHelper.shared.updateWidgetFromFirebase()
    }
}
```

#### 5.3 Dans UserManager.swift

Rafraîchir après mise à jour du profil :

```swift
// Dans UserManager.swift

// Après toute modification du profil
func updateProfile(...) async throws {
    // ... code existant ...

    // Rafraîchir le widget
    WidgetUpdateHelper.shared.updateWidgetFromFirebase()
}
```

---

### Étape 6 : Build & Run

1. **Sélectionner le scheme**
   - En haut à gauche dans Xcode
   - Scheme: `Hourglass 4` (PAS HourglassWidget)
   - Device: iPhone (simulateur ou réel)

2. **Build le projet**
   - Cmd + B
   - Résoudre les erreurs éventuelles

3. **Run l'app**
   - Cmd + R
   - L'app devrait se lancer normalement

---

### Étape 7 : Ajouter le Widget à l'écran d'accueil

1. **Sur votre iPhone/Simulator**
   - Aller sur l'écran d'accueil
   - Long press sur l'écran
   - Cliquer sur "+" en haut à gauche

2. **Chercher "Hourglass"**
   - Trouver le widget Hourglass
   - Choisir la taille (Small, Medium ou Large)
   - Cliquer "Add Widget"

3. **Positionner le widget**
   - Glisser-déposer où vous voulez
   - Cliquer "Done"

---

## 🔧 Troubleshooting

### Le widget n'apparaît pas dans la liste

**Solution :**
- Vérifier que le target `HourglassWidget` est bien configuré
- Clean Build Folder (Cmd + Shift + K)
- Rebuild (Cmd + B)
- Redémarrer Xcode

### Le widget affiche 0 partout

**Solution :**
- Vérifier que l'App Group est identique dans les 2 targets
- Dans `SharedDataManager.swift`, vérifier `appGroupID = "group.com.hourglass.hourglass4"`
- Lancer l'app une fois pour initialiser les données
- Attendre 15 minutes ou redémarrer l'app

### Erreur de compilation "Module not found"

**Solution :**
- Aller dans Build Phases du target `HourglassWidget`
- Vérifier que `SharedDataManager.swift` est dans "Compile Sources"
- Vérifier que WidgetKit et SwiftUI sont importés

### Le widget ne se met pas à jour

**Solution :**
- Vérifier que `WidgetUpdateHelper.shared.updateWidgetFromFirebase()` est appelé
- Vérifier les permissions App Groups dans Developer Portal
- Forcer le refresh : `WidgetCenter.shared.reloadAllTimelines()`

---

## 🎨 Personnalisation

### Changer les couleurs

Dans `HourglassWidget.swift`, modifier les gradients :

```swift
// Ligne ~40-45
LinearGradient(
    colors: [Color.orange, Color.yellow], // <- Changer ici
    startPoint: .topLeading,
    endPoint: .bottomTrailing
)
```

### Changer le countdown

Par défaut, countdown jusqu'à 20h. Pour modifier :

Dans `SharedDataManager.swift` :

```swift
// Ligne ~60
components.hour = 20 // <- Changer l'heure ici
```

### Ajouter des deep links

Pour ouvrir l'app en cliquant sur le widget :

```swift
// Dans SmallWidgetView, ajouter :
.widgetURL(URL(string: "hourglass://open")!)

// Puis dans Hourglass_4App.swift :
.onOpenURL { url in
    if url.absoluteString == "hourglass://open" {
        // Naviguer vers un écran spécifique
    }
}
```

---

## 📊 Rafraîchissement automatique

Le widget se rafraîchit :
- ✅ Toutes les 15 minutes (Timeline)
- ✅ À chaque modification d'objectif
- ✅ Au lancement de l'app
- ✅ Quand l'app passe en background

Pour forcer un refresh manuel :

```swift
WidgetCenter.shared.reloadAllTimelines()
```

---

## 🚀 Tester le widget

### Preview dans Xcode

Les previews sont disponibles en bas de `HourglassWidget.swift` :

```swift
#Preview(as: .systemSmall) {
    HourglassWidget()
}
```

Pour voir les previews :
- Ouvrir `HourglassWidget.swift`
- Cmd + Option + Return
- Le canvas s'ouvre à droite

### Tester les différents états

Modifier les valeurs dans les previews :

```swift
WidgetEntry(
    date: .now,
    grainsToday: 3,        // <- Peu de grains (rouge)
    grainsYesterday: 7,
    currentStreak: 5,
    pendingGoals: 4,       // <- Beaucoup en attente (urgent)
    completedGoals: 1,
    timeUntilDeadline: 1800 // <- 30 minutes (urgent !)
)
```

---

## 🎉 Résultat final

Vous aurez 3 widgets disponibles :

### 📱 Small (2x2)
- Grains du jour (gros)
- Streak avec flamme
- Comparaison vs hier

### 📱 Medium (4x2)
- Grains + progress bar
- Streak
- Objectifs complétés/en attente
- Countdown

### 📱 Large (4x4)
- Tout ce qui précède
- Stats détaillées en grille
- Message motivationnel dynamique
- Comparaison complète

---

## 💡 Prochaines améliorations

- [ ] Widget interactif (iOS 17+) avec boutons
- [ ] Configuration personnalisée (couleurs, stats affichées)
- [ ] Widget Lock Screen (iOS 16+)
- [ ] Live Activities pour le countdown (iOS 16.1+)
- [ ] Deep links vers objectifs spécifiques
- [ ] Support iPad avec grandes tailles

---

## 📞 Besoin d'aide ?

Si vous rencontrez des problèmes :

1. Vérifier que l'App Group est identique partout
2. Clean Build Folder (Cmd + Shift + K)
3. Supprimer l'app du simulateur/device
4. Rebuild et redéployer
5. Vérifier les logs dans Console.app

---

**Le widget est prêt ! 🎉**

Lancez Xcode et suivez les étapes ci-dessus pour l'activer.
