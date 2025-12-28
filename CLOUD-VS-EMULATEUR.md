# Cloud SQL vs Émulateur Local - Guide pratique

## 🤔 La différence en une phrase

**Cloud SQL** = Base de données sur internet (Google) → Coûte de l'argent
**Émulateur** = Base de données sur votre Mac → Gratuit

---

## 📱 OPTION 1 : REDÉMARRER CLOUD SQL

### Comment ça marche ?

```
Votre Mac (Xcode)  →  Internet  →  Google Cloud (Paris)
                                      ↓
                                 PostgreSQL
```

### Étapes concrètes

**1. Démarrer l'instance :**
- Allez sur https://console.cloud.google.com/sql/instances?project=hourglass4
- Cliquez "DÉMARRER"
- Attendez 30 secondes

**2. Lancer votre app dans Xcode :**
- Run (Cmd+R)
- L'app se connecte automatiquement à Cloud SQL
- Vous voyez vos données réelles

**3. Quand vous arrêtez de coder :**
- Retournez sur la console
- Cliquez "ARRÊTER"

### Coût
```
1 heure active : ~0,40€
8 heures (1 journée) : ~3,20€
24h/24 (1 mois) : ~10€
```

### Quand l'utiliser ?
✅ Tester avec les vraies données
✅ Vérifier que l'app fonctionne en "production"
✅ Tester depuis un vrai iPhone (pas simulateur)
✅ Juste avant de déployer

---

## 💻 OPTION 2 : UTILISER L'ÉMULATEUR

### Comment ça marche ?

```
Votre Mac (Xcode)  →  Votre Mac (Émulateur PostgreSQL)
                              ↓
                         Base locale
```

### Étapes concrètes

**1. Démarrer l'émulateur :**
```bash
cd ~/Desktop/Hourglass\ 4
./start-emulator.sh
```

**2. Modifier temporairement votre code :**
Pour que l'app pointe vers l'émulateur au lieu du cloud

**3. Lancer votre app dans Xcode :**
- Run (Cmd+R)
- L'app se connecte à l'émulateur local
- Vous voyez des données de test (locales)

**4. Quand vous arrêtez de coder :**
- Ctrl+C dans le terminal (arrête l'émulateur)
- C'est tout !

### Coût
```
0€ (100% gratuit)
```

### Quand l'utiliser ?
✅ Développement quotidien
✅ Tester une nouvelle feature
✅ Débugger
✅ Travailler sans internet

---

## 🔄 WORKFLOW RECOMMANDÉ

### Phase 1 : Développement quotidien (95% du temps)

**Utilisez l'émulateur :**
```
Lundi-Vendredi, 9h-18h :
1. ./start-emulator.sh
2. Coder dans Xcode
3. Tester en local
4. Ctrl+C pour arrêter

Coût : 0€
```

### Phase 2 : Test final avant déploiement (5% du temps)

**Utilisez Cloud SQL :**
```
Avant chaque mise à jour importante :
1. Démarrer hourglass4-instance
2. Tester l'app avec vraies données
3. Vérifier que tout fonctionne
4. Arrêter hourglass4-instance

Coût : ~0,20-0,40€ (30-60 min)
```

---

## 💡 EXEMPLE CONCRET : UNE SEMAINE DE DEV

### Scénario : Vous ajoutez une nouvelle fonctionnalité "Stories"

**Lundi - Mercredi : Développement**
```bash
# Chaque jour
./start-emulator.sh

# Coder dans Xcode
# - Créer les vues
# - Tester avec données fictives
# - Débugger

# Arrêt
Ctrl+C

Coût : 0€ × 3 jours = 0€
```

**Jeudi : Test en conditions réelles**
```
1. Démarrer hourglass4-instance (console Cloud)
2. Tester avec vraies données pendant 2h
3. Corriger les bugs trouvés sur l'émulateur
4. Arrêter hourglass4-instance

Coût : 2h × 0,40€ = 0,80€
```

**Vendredi : Test final avant déploiement**
```
1. Démarrer hourglass4-instance
2. Test complet pendant 1h
3. Tout fonctionne ✅
4. Arrêter hourglass4-instance

Coût : 1h × 0,40€ = 0,40€
```

**Total semaine : 1,20€ au lieu de 16,80€ (si Cloud SQL 24/7)**
**Économie : 15,60€ par semaine**

---

## ⚖️ AVANTAGES / INCONVÉNIENTS

### Cloud SQL (Redémarrer)

**Avantages :**
✅ Données réelles
✅ Configuration automatique
✅ Test en conditions production
✅ Accessible depuis partout

**Inconvénients :**
❌ Coûte de l'argent
❌ Nécessite internet
❌ Plus lent (latence réseau)
❌ Prend 30s à démarrer

---

### Émulateur Local

**Avantages :**
✅ 100% gratuit
✅ Ultra rapide (pas de réseau)
✅ Fonctionne hors ligne
✅ Pas besoin de démarrer/arrêter instance

**Inconvénients :**
❌ Données séparées (pas les vraies)
❌ Faut modifier le code temporairement
❌ Seulement accessible sur votre Mac
❌ Données perdues à chaque redémarrage

---

## 🎯 QUOI CHOISIR ?

### Pour le développement quotidien → ÉMULATEUR
```
✅ Gratuit
✅ Rapide
✅ Pas de gestion de l'instance
```

### Pour les tests finaux → CLOUD SQL
```
✅ Vraies données
✅ Conditions réelles
✅ Validation avant déploiement
```

---

## 📊 ÉCONOMIES RÉALISÉES

### Si vous utilisez Cloud SQL 24/7 (avant)
```
30 jours × 24h × 0,40€/h = ~288€/mois
(Ou forfait fixe ~10€/mois)
```

### Si vous utilisez l'émulateur + tests occasionnels
```
Émulateur : 0€
Tests Cloud SQL : 5h/mois × 0,40€ = 2€/mois
TOTAL : 2€/mois

Économie : 8€/mois (80%)
```

---

## 🔧 COMMENT CONFIGURER L'ÉMULATEUR ?

Pour utiliser l'émulateur, il faut modifier temporairement le code pour pointer vers `localhost` au lieu de Cloud SQL.

**Fichier à modifier :** `DataConnectManager.swift` (ligne 289)

**Cloud SQL (production) :**
```swift
let urlString = "https://firebasedataconnect.googleapis.com/v1beta/projects/hourglass4/..."
```

**Émulateur (développement) :**
```swift
let urlString = "http://localhost:9399/..."
```

💡 **Je peux vous aider à automatiser ce changement avec un switch "Mode Dev / Mode Production"**

---

## ✅ RÉSUMÉ

| Question | Réponse |
|----------|---------|
| **Quelle est la différence ?** | Cloud SQL = sur internet (coûte), Émulateur = sur votre Mac (gratuit) |
| **Lequel utiliser ?** | Émulateur pour dev quotidien, Cloud SQL pour tests finaux |
| **Combien j'économise ?** | ~8€/mois avec bonne pratique |
| **C'est compliqué de basculer ?** | Non, 1 ligne de code à changer |

---

## 🚀 PROCHAINE ÉTAPE

Voulez-vous que je :
1. Configure l'émulateur pour que vous puissiez commencer à développer gratuitement ?
2. Crée un switch automatique "Dev/Production" dans votre code ?
3. Teste l'émulateur ensemble ?

---

**Dernière mise à jour :** 17 décembre 2024
