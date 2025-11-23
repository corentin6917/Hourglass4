# ⏳ HOURGLASS - L'Héritage des Accomplissements

![Swift](https://img.shields.io/badge/Swift-5.9-orange.svg)
![iOS](https://img.shields.io/badge/iOS-17.0+-blue.svg)
![SwiftUI](https://img.shields.io/badge/SwiftUI-5.0-green.svg)
![SwiftData](https://img.shields.io/badge/SwiftData-Latest-purple.svg)

## 🎯 Le Concept

HOURGLASS est un réseau social expérimental basé sur l'intention et l'accomplissement, où l'effort quotidien est récompensé par des **Grains** qui construisent ton héritage émotionnel. Le but est de briser le cercle de la survie en motivant l'action concrète.

Chaque jour, vous avez un potentiel de **10 "Grains de Vie"** représentés par des grains de sable dans un sablier. Votre mission ? Accomplir de petites victoires pour faire tomber ces grains dans la partie basse de votre sablier personnel.

**Ce qui n'est pas gagné est perdu à jamais** – une piqûre de rappel que chaque journée perdue est perdue pour toujours.

## 📱 Fonctionnalités Principales

### 🌅 Cycle Quotidien

- **8h00 - Matin** : Réinitialisation du sablier avec 10 grains blancs de potentiel
- **Journée** : Accomplissez vos objectifs et capturez des preuves photographiques
- **20h00 - Soir** : Validation de la journée, les grains gagnés tombent dans l'héritage
- **Minuit** : Nettoyage du sablier pour le lendemain

### 🎯 Système d'Objectifs

- **Création d'objectifs personnalisés** avec calcul automatique de valeur en grains
- **7 catégories** : Physique, Social, Créatif, Professionnel, Apprentissage, Personnel, Maison
- **Dévaluation progressive** : les objectifs répétés perdent de la valeur (incite à se dépasser)
- **Validation par photo** : preuve non retouchée de l'accomplissement

### 📊 Ratio de Vie

Le **Ratio de Vie** est l'indicateur clé de l'application :

```
Ratio = (Grains Accumulés) / (Jours Vécus × 10) × 100
```

- **< 30%** : "Tu survis plus que tu ne vis"
- **30-50%** : "Tu vis modérément"
- **50-70%** : "Tu vis intensément"
- **70%+** : "Tu vis exceptionnellement"

### 🌦️ Saisons de Vie

L'application détecte automatiquement votre état émotionnel et adapte son comportement :

- **🌨️ Hiver** : < 4 grains/jour (mode compassion)
- **🌸 Printemps** : Progression positive (encouragement)
- **☀️ Été** : > 7 grains/jour (célébration)
- **🍂 Automne** : Période de réflexion (introspection)

### 🔥 Mode Phénix

Système de soutien automatique pour les moments difficiles :

- **Activation automatique** si < 3 grains/jour pendant 14 jours
- **Micro-victoires × 3** : valorise les petits pas
- **Tunnel de lumière** : visualisation de la sortie
- **Messages de survivants** : soutien communautaire

### ⭐ Interactions Sociales

- **Éclat de Grain** (0.2 grain) : boost authentique qui coûte de ta réserve
- **Transfusion** (1+ grain) : acte d'empathie fort pour aider un ami
- **Commentaires** (0.1 grain) : encouragements réfléchis

### 📦 Capsules Temporelles

Tous les 100 jours, l'app génère automatiquement :

- Montage vidéo des meilleures victoires
- Graphique de progression
- Messages à soi-même
- Musique épique personnalisée

## 🏗️ Architecture

### Technologies

- **SwiftUI** : Interface utilisateur déclarative
- **SwiftData** : Persistance locale des données
- **Swift Concurrency** : Async/await pour les opérations asynchrones
- **Charts** : Visualisations de progression
- **UserNotifications** : Rappels quotidiens

### Modèles de Données

```
UserProfile (Utilisateur principal)
├── Grain[] (Grains blancs et dorés)
├── Goal[] (Objectifs quotidiens)
├── TimeCapsule[] (Capsules tous les 100 jours)
└── Statistics (Ratio, streak, saison)
```

### Structure du Projet

```
Hourglass 4/
├── Models/
│   ├── Grain.swift
│   ├── Goal.swift
│   ├── UserProfile.swift
│   ├── TimeCapsule.swift
│   └── SocialInteraction.swift
├── ViewModels/
│   └── HourglassViewModel.swift
├── Views/
│   ├── HourglassMainView.swift
│   ├── GoalsView.swift
│   ├── VictoryFeedView.swift
│   └── ProfileView.swift
├── Services/
│   ├── GoalSuggestionEngine.swift
│   └── NotificationManager.swift
└── ContentView.swift
```

## 🚀 Installation & Configuration

### Prérequis

- Xcode 15.0+
- iOS 17.0+
- Swift 5.9+

### Lancement

1. Cloner le projet
2. Ouvrir `Hourglass 4.xcodeproj` dans Xcode
3. Build et Run sur simulateur ou device

### Permissions Requises

L'app demande les permissions suivantes :

- **Camera** : Pour capturer les photos de validation
- **Notifications** : Pour les rappels quotidiens (8h et 20h)

Ajoutez ces clés dans `Info.plist` :

```xml
<key>NSCameraUsageDescription</key>
<string>HOURGLASS utilise la caméra pour capturer la preuve de tes accomplissements</string>
<key>NSPhotoLibraryUsageDescription</key>
<string>HOURGLASS a besoin d'accéder à tes photos pour sauvegarder tes victoires</string>
```

## 🎨 Design Principles

### Principes Fondamentaux Inviolables

1. **Les Grains Ne Peuvent JAMAIS Être Achetés**
   - Pas de transactions financières
   - Chaque grain est mérité

2. **Privacy-First**
   - Photos chiffrées et éphémères (24h)
   - Pas de tracking publicitaire
   - Pas de revente de données

3. **Anti-Toxicité Structurelle**
   - Pas de classement public
   - Focus sur ta progression personnelle
   - Pas de compétition toxique

4. **Bienveillance par Design**
   - Mode Phénix automatique
   - Saisons de Vie pour normaliser les cycles
   - Jamais de culpabilisation

## 📈 Roadmap

### Phase 1 : MVP (Actuel)
- ✅ Modèles de données SwiftData
- ✅ Sablier animé avec visualisation
- ✅ Création et validation d'objectifs
- ✅ Système de ratio et statistiques
- ✅ Saisons de vie
- ✅ Mode Phénix

### Phase 2 : Social
- ⏳ Backend pour synchronisation
- ⏳ Fil des victoires en temps réel
- ⏳ Système de boost et transfusion
- ⏳ Pactes (couples et amis)

### Phase 3 : Avancé
- ⏳ Capsules temporelles avec vidéo
- ⏳ Fil des Légendes mensuel
- ⏳ Système de détection des événements exceptionnels
- ⏳ Algorithme de suggestion d'upgrade intelligent

### Phase 4 : Plateforme
- ⏳ Version iPad optimisée
- ⏳ Widget iOS
- ⏳ Apple Watch companion app
- ⏳ API publique pour intégrations tierces

## 🤝 Contribution

Ce projet est une démonstration de concept. Si vous souhaitez contribuer :

1. Fork le projet
2. Créez une branche (`git checkout -b feature/AmazingFeature`)
3. Commit vos changements (`git commit -m 'Add some AmazingFeature'`)
4. Push sur la branche (`git push origin feature/AmazingFeature`)
5. Ouvrez une Pull Request

## 📄 Licence

Ce projet est sous licence MIT. Voir le fichier `LICENSE` pour plus de détails.

## 👨‍💻 Auteur

**Corentin Soula**

## 🙏 Remerciements

- Inspiré par les concepts de gamification positive
- Design influencé par les principes de psychologie comportementale
- Communauté SwiftUI pour les exemples d'animations

---

**⏳ "Chaque grain compte. Chaque jour compte. Vis pleinement."**
