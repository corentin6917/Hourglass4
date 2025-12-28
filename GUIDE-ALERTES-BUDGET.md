# Guide de configuration des alertes budgétaires Firebase

## 🎯 Pourquoi configurer des alertes ?

Pour recevoir un email automatique si vos coûts dépassent certains seuils et éviter les mauvaises surprises.

---

## 📧 Configuration pas à pas

### Étape 1 : Accéder aux budgets

1. Allez sur : https://console.cloud.google.com/billing/budgets?project=hourglass4
2. Cliquez sur "Créer un budget"

---

### Étape 2 : Configurer le budget

#### 2.1 - Nom du budget
- Nom : `Hourglass4 - Alerte développement`

#### 2.2 - Projets
- Sélectionnez : `Hourglass4`

#### 2.3 - Période
- Type : Mensuel
- Période : Mois calendaire

#### 2.4 - Montant du budget
- **Montant : 10€ par mois**
  (Ajustez selon vos besoins)

---

### Étape 3 : Configurer les seuils d'alerte

Configurez 4 alertes :

| Pourcentage | Montant | Action recommandée |
|-------------|---------|-------------------|
| 50% | 5€ | Vérifier que l'instance est bien arrêtée |
| 75% | 7,50€ | Vérifier les coûts inhabituels |
| 90% | 9€ | Arrêter immédiatement l'instance |
| 100% | 10€ | Investigation urgente |

**Pour chaque seuil :**
1. Cochez "Pourcentage du budget"
2. Entrez le pourcentage (50, 75, 90, 100)
3. Cochez "Envoyer un email aux contacts de facturation"

---

### Étape 4 : Ajouter votre email

1. Dans "Actions", sélectionnez "Email"
2. Ajoutez votre adresse email
3. Cochez "Activer les notifications Cloud Monitoring"

---

### Étape 5 : Créer le budget

- Cliquez sur "Terminer"
- Votre alerte est maintenant active ! 🎉

---

## 📊 Ce qui va se passer

### Vous recevrez un email automatique :

**À 5€ (50%) :**
```
Alerte Budget Hourglass4
Votre projet a atteint 50% de votre budget mensuel de 10€.
Coût actuel : 5,00€
```

**Action :** Vérifiez que l'instance est bien arrêtée

---

**À 7,50€ (75%) :**
```
Alerte Budget Hourglass4
Votre projet a atteint 75% de votre budget mensuel de 10€.
Coût actuel : 7,50€
```

**Action :** Vérifiez s'il y a des coûts inhabituels

---

**À 9€ (90%) :**
```
⚠️ Alerte Budget Hourglass4
Votre projet a atteint 90% de votre budget mensuel de 10€.
Coût actuel : 9,00€
```

**Action urgente :** Arrêtez l'instance immédiatement

---

**À 10€ (100%) :**
```
🚨 ALERTE CRITIQUE - Budget dépassé
Votre projet a atteint 100% de votre budget mensuel de 10€.
Coût actuel : 10,00€
```

**Action urgente :** Allez sur la console et identifiez la source

---

## 💡 Budgets recommandés selon votre situation

### Phase développement (MAINTENANT)
- **Budget mensuel : 10€**
- Seuils : 50%, 75%, 90%, 100%
- Coût réel attendu : ~5-7€/mois

### Phase pré-lancement (0-100 utilisateurs)
- **Budget mensuel : 15€**
- Seuils : 60%, 80%, 100%
- Coût réel attendu : ~10€/mois

### Phase lancement (100-1000 utilisateurs)
- **Budget mensuel : 30€**
- Seuils : 70%, 90%, 100%
- Coût réel attendu : ~20-25€/mois

---

## 🔍 Surveiller vos coûts quotidiennement

### Liens utiles à bookmarker

1. **Vue d'ensemble facturation :**
   https://console.cloud.google.com/billing?project=hourglass4

2. **Rapports détaillés :**
   https://console.cloud.google.com/billing/reports?project=hourglass4

3. **Instances Cloud SQL :**
   https://console.cloud.google.com/sql/instances?project=hourglass4

4. **Budgets et alertes :**
   https://console.cloud.google.com/billing/budgets?project=hourglass4

---

## ✅ Checklist de vérification mensuelle

Chaque début de mois :

- [ ] Vérifier le coût total du mois précédent
- [ ] Vérifier que l'instance est arrêtée si pas en dev
- [ ] Vérifier les coûts Firestore (lectures/écritures)
- [ ] Vérifier les coûts Authentication
- [ ] Ajuster les budgets si nécessaire

---

## 📱 Application mobile Google Cloud (optionnel)

Pour surveiller vos coûts sur mobile :

1. Téléchargez "Google Cloud" sur l'App Store
2. Connectez-vous avec votre compte
3. Sélectionnez le projet Hourglass4
4. Activez les notifications push
5. Vous recevrez des alertes sur votre téléphone

---

**Dernière mise à jour :** 17 décembre 2024
