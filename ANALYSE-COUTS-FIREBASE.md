# Analyse complète des coûts Firebase - Hourglass4

## 📊 Services Firebase utilisés dans votre projet

Basé sur l'analyse de votre code, voici TOUS les services Firebase que vous utilisez :

### 1. ✅ Cloud SQL / Data Connect
**État :** Instance active
**Coût actuel :** ~10€/mois (après suppression des zombies)
**Ce qui coûte :**
- Temps d'exécution de l'instance (24/7) : ~8€/mois
- Stockage du disque PostgreSQL : ~1-2€/mois
- Backups automatiques : ~0,50€/mois
- Bande passante réseau : ~0,50€/mois

**Action déjà prise :** ✅ Suppression de 2 instances zombies (-9,50€/mois)
**Action recommandée :** ⚠️ Arrêter l'instance quand vous ne codez pas (-8€/mois)

---

### 2. ✅ Firebase Authentication
**État :** Actif (utilisé dans votre app)
**Coût :** **GRATUIT jusqu'à 10,000 utilisateurs/mois**
**Ce qui est gratuit :**
- Authentification email/password : illimité
- Authentification anonyme : illimité
- Utilisateurs actifs : jusqu'à 10,000/mois

**Ce qui peut coûter (si dépassement) :**
- Au-delà de 10,000 utilisateurs actifs/mois : 0,03€ par utilisateur
- Vérification par SMS : 0,05€ par SMS
- Vérification téléphone : coûts selon volume

**Votre situation :** 🟢 GRATUIT (0 utilisateur actuellement)

---

### 3. ✅ Cloud Firestore
**État :** Actif (utilisé pour Users, Posts, Friendships, etc.)
**Coût :** **GRATUIT dans le plan Spark jusqu'à :**
- 50,000 lectures/jour
- 20,000 écritures/jour
- 20,000 suppressions/jour
- 1 GB de stockage
- 10 GB/mois de bande passante réseau sortante

**Ce qui peut coûter (plan Blaze - facturation à l'usage) :**
- Lectures : 0,036€ par 100,000 documents après quota
- Écritures : 0,108€ par 100,000 documents après quota
- Suppressions : 0,012€ par 100,000 documents après quota
- Stockage : 0,18€ par GB/mois après 1 GB
- Bande passante : 0,12€ par GB après 10 GB

**Votre situation :** 🟢 GRATUIT (0 utilisateur, très peu de données)

**Collections utilisées dans votre code :**
- `debug_ping` (test)
- Utilisateurs, Posts, Friendships, etc.

---

### 4. ❌ Firebase Storage
**État :** NON utilisé dans votre code
**Coût potentiel :** N/A

---

### 5. ❌ Cloud Functions
**État :** NON utilisé dans votre code
**Coût potentiel :** N/A

---

### 6. ❌ Firebase Hosting
**État :** NON utilisé dans votre code
**Coût potentiel :** N/A

---

### 7. ❌ Cloud Messaging (Notifications Push)
**État :** NON détecté dans votre code
**Coût :** GRATUIT (illimité)

---

## 💰 RÉSUMÉ DES COÛTS ACTUELS

| Service | Coût actuel/mois | Peut être gratuit ? |
|---------|------------------|---------------------|
| Cloud SQL (Data Connect) | ~10€ | ✅ Oui (avec émulateur local) |
| Firebase Auth | 0€ | ✅ Déjà gratuit |
| Cloud Firestore | 0€ | ✅ Déjà gratuit |
| **TOTAL** | **~10€/mois** | **Oui, réductible à 0-2€** |

---

## ⚠️ RISQUES DE COÛTS FUTURS

### Quand vous aurez des utilisateurs réels

#### 1. Cloud SQL / Data Connect
**Risque :** 🔴 ÉLEVÉ
- Instance qui tourne 24/7 : 10-20€/mois selon la taille
- Avec 1000 utilisateurs actifs : besoin d'upgrade (+20-50€/mois)
- **Recommandation :** Utiliser un tier adapté + auto-scaling

#### 2. Cloud Firestore
**Risque :** 🟡 MOYEN
- Plan gratuit généreux (50k lectures/jour)
- Avec 1000 utilisateurs : probablement encore gratuit
- Avec 10,000 utilisateurs actifs : ~5-10€/mois
- **Recommandation :** Optimiser les requêtes, utiliser le cache

#### 3. Firebase Authentication
**Risque :** 🟢 FAIBLE
- Gratuit jusqu'à 10,000 utilisateurs/mois
- Au-delà : 0,03€/utilisateur (très peu)
- **Recommandation :** Aucune action nécessaire

#### 4. Bande passante réseau
**Risque :** 🟡 MOYEN
- Firestore : 10 GB/mois gratuit
- Cloud SQL : coûts selon usage
- **Recommandation :** Optimiser la taille des données

---

## 🎯 PLAN D'OPTIMISATION DES COÛTS

### Phase 1 : Développement (MAINTENANT) - Objectif : 0-2€/mois
- [x] Supprimer instances zombies (-9,50€) ✅ FAIT
- [ ] Arrêter Cloud SQL quand pas en dev (-8€)
- [ ] Utiliser émulateur local (gratuit)
- [ ] Downgrade instance vers micro (-4€)

**Coût cible : 0-2€/mois**

---

### Phase 2 : Pré-lancement (Avant les premiers utilisateurs)
- [ ] Configurer alertes budgétaires (5€, 10€, 20€)
- [ ] Choisir le bon tier d'instance Cloud SQL
- [ ] Optimiser les requêtes Firestore
- [ ] Implémenter le cache local

**Coût cible : 5-10€/mois (0-100 utilisateurs)**

---

### Phase 3 : Post-lancement (Avec utilisateurs)
- [ ] Monitorer les coûts quotidiennement
- [ ] Activer auto-scaling si nécessaire
- [ ] Optimiser les lectures Firestore
- [ ] Considérer un CDN pour les assets

**Coût cible : Évolutif selon utilisateurs**

---

## 📈 ESTIMATION DES COÛTS PAR NOMBRE D'UTILISATEURS

| Utilisateurs actifs | Cloud SQL | Firestore | Auth | Total/mois |
|---------------------|-----------|-----------|------|------------|
| 0 (développement) | 2€ * | 0€ | 0€ | **2€** |
| 100 | 10€ | 0€ | 0€ | **10€** |
| 1,000 | 20€ | 2€ | 0€ | **22€** |
| 10,000 | 50€ | 10€ | 0€ | **60€** |
| 50,000 | 150€ | 50€ | 120€ | **320€** |

*Avec arrêt/démarrage manuel de l'instance

---

## ✅ ACTIONS IMMÉDIATES RECOMMANDÉES

### 1. Arrêter l'instance Cloud SQL maintenant
**Économie :** ~8€/mois
**Temps :** 30 secondes
**Lien :** https://console.cloud.google.com/sql/instances?project=hourglass4

### 2. Configurer des alertes budgétaires
**But :** Éviter les mauvaises surprises
**Temps :** 2 minutes
**Seuils recommandés :** 5€, 10€, 20€
**Lien :** https://console.cloud.google.com/billing/budgets?project=hourglass4

### 3. Tester l'émulateur local demain
**But :** Développer gratuitement
**Temps :** 10 minutes
**Commande :** `./start-emulator.sh`

---

## 📞 LIENS UTILES

- **Console Cloud SQL :** https://console.cloud.google.com/sql/instances?project=hourglass4
- **Console Firestore :** https://console.firebase.google.com/project/hourglass4/firestore
- **Estimation coûts :** https://console.firebase.google.com/project/hourglass4/usage
- **Alertes budgétaires :** https://console.cloud.google.com/billing/budgets?project=hourglass4
- **Calculateur Firebase :** https://firebase.google.com/pricing

---

**Dernière mise à jour :** 17 décembre 2024
**Économies déjà réalisées :** 9,50€/mois (instances zombies)
**Économies potentielles restantes :** 8-10€/mois
