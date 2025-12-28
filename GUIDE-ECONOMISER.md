# Guide pour réduire vos coûts Firebase à presque 0€

## Résumé de vos économies

- ✅ **Instances zombies supprimées** : ~10€/mois économisés
- 📊 **Coût actuel estimé** : ~10€/mois (principalement `hourglass4-instance`)
- 🎯 **Objectif** : ~0-2€/mois pendant le développement

---

## 💰 D'où viennent vos coûts ?

Même sans utilisateurs, vous payez pour :

1. **Instance Cloud SQL qui tourne 24/7** (~80% des coûts)
   - `hourglass4-instance` fonctionne en permanence
   - Vous payez pour le **temps d'exécution**, pas l'utilisation

2. **Stockage PostgreSQL** (~10%)
   - Le disque alloué coûte même si presque vide

3. **Backups automatiques** (~5%)
   - Sauvegardes stockées automatiquement

4. **Bande passante réseau** (~5%)
   - Connexions Xcode ↔ Cloud SQL

---

## 🛠️ Comment payer 0€ pendant le développement

### Option 1 : Arrêter/Démarrer l'instance manuellement (RAPIDE)

**Quand arrêter :**
- Chaque soir quand vous arrêtez de coder
- Week-ends
- Vacances

**Comment faire :**

1. **Arrêter l'instance** (économie : ~80% des coûts)
   - Allez sur : https://console.cloud.google.com/sql/instances?project=hourglass4
   - Cliquez sur `hourglass4-instance`
   - Cliquez sur **"ARRÊTER"** en haut
   - Confirmation : OK

2. **Démarrer l'instance** (prend ~30-60 secondes)
   - Même page : https://console.cloud.google.com/sql/instances?project=hourglass4
   - Cliquez sur `hourglass4-instance`
   - Cliquez sur **"DÉMARRER"** en haut
   - Attendez que le statut devienne vert

**Exemple de routine :**
- **Matin** (quand vous commencez à coder) : DÉMARRER l'instance
- **Soir** (quand vous arrêtez) : ARRÊTER l'instance
- **Économie** : Si vous codez 4h/jour, vous économisez ~83% des coûts (20h sur 24h arrêtées)

---

### Option 2 : Utiliser l'émulateur local (MODE DEV 100% GRATUIT)

**Avantages :**
- ✅ 100% gratuit
- ✅ Développement hors ligne possible
- ✅ Pas besoin de démarrer/arrêter Cloud SQL
- ✅ Base de données réinitialisable facilement

**Comment utiliser :**

1. **Lancer l'émulateur :**
   ```bash
   cd ~/Desktop/Hourglass\ 4
   ./start-emulator.sh
   ```

2. **Dans Xcode, pointer vers l'émulateur :**
   - Modifier votre code Swift pour utiliser `localhost:9399`
   - Au lieu de `hourglass4-instance`

3. **Quand tester en production :**
   - Démarrez `hourglass4-instance`
   - Changez la config pour pointer vers Cloud SQL
   - Testez
   - Arrêtez l'instance après

---

## 📊 Estimation des coûts après optimisation

### Scénario 1 : Arrêt manuel (4h de dev/jour)
- Instance active : 4h/jour × 30 jours = 120h/mois
- Instance arrêtée : 600h/mois
- **Coût estimé : ~2-3€/mois** (83% d'économie)

### Scénario 2 : Émulateur local + production occasionnelle
- Développement : 100% sur émulateur (gratuit)
- Production : 10h/mois sur Cloud SQL
- **Coût estimé : ~0,50-1€/mois** (95% d'économie)

---

## ⚠️ Recommandations importantes

1. **Prenez l'habitude d'arrêter l'instance** chaque soir
   - Ajoutez un rappel sur votre téléphone
   - Ou marquez-le sur votre routine de fermeture

2. **Surveillez vos coûts**
   - Console Firebase : https://console.firebase.google.com/project/hourglass4/usage
   - Configurez des alertes budgétaires à 5€/mois

3. **Avant le lancement de l'app**
   - Redimensionnez l'instance selon vos besoins réels
   - Activez l'auto-scaling si disponible
   - Considérez une instance "shared" au lieu de "enterprise" pour démarrer

---

## 🎯 Actions à faire MAINTENANT

- [ ] Arrêter `hourglass4-instance` si vous ne codez pas actuellement
- [ ] Mettre un rappel quotidien pour arrêter l'instance le soir
- [ ] Tester l'émulateur local demain matin
- [ ] Configurer une alerte budgétaire Firebase à 5€/mois

---

## 📞 Liens utiles

- Instances Cloud SQL : https://console.cloud.google.com/sql/instances?project=hourglass4
- Coûts Firebase : https://console.firebase.google.com/project/hourglass4/usage
- Documentation Data Connect : https://firebase.google.com/docs/data-connect

---

**Dernière mise à jour :** 17 décembre 2024
**Économies réalisées ce mois-ci :** ~10€ (instances zombies supprimées)
