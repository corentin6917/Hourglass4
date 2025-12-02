# Firebase Data Connect - Hourglass 4

## 📋 Configuration requise

1. **Firebase CLI** installé
2. **Projet Firebase** créé
3. **Firebase Data Connect** activé

---

## 🚀 Déploiement

### Étape 1 : Installer Firebase CLI

```bash
curl -sL https://firebase.tools | bash
```

### Étape 2 : Se connecter à Firebase

```bash
firebase login
```

### Étape 3 : Initialiser Data Connect

Depuis le dossier racine du projet :

```bash
cd "/Users/corentinsoula/Desktop/Hourglass 4"
firebase dataconnect:deploy
```

### Étape 4 : Vérifier le déploiement

1. Allez sur https://console.firebase.google.com
2. Sélectionnez votre projet **Hourglass 4**
3. Menu → **Data Connect**
4. Vous devriez voir :
   - Service: `hourglass4-service`
   - Tables: `User`, `Friendship`

---

## 📁 Structure des fichiers

```
dataconnect/
├── schema/
│   └── schema.gql           # Schéma avec User (String ID!) et Friendship
├── mutations/
│   ├── createUser.gql        # Créer un utilisateur (UID = ID)
│   ├── createFriendship.gql  # Envoyer demande d'ami
│   └── updateFriendshipStatus.gql # Accepter/refuser
├── queries/
│   ├── getUserByUsername.gql # Recherche par username
│   ├── getUserByEmail.gql    # Recherche par email
│   ├── getPendingFriendRequests.gql # Demandes en attente
│   └── getFriends.gql        # Liste des amis
└── dataconnect.yaml          # Configuration
```

---

## 🔑 Points clés

### 1. User.id = Firebase Auth UID (String!)

Le champ `id` dans la table `User` est de type **String** (et non UUID) car il correspond à l'**UID de Firebase Authentication**.

```gql
type User @table {
  id: String! @col(name: "id", dataType: "varchar(128)") @primaryKey
  # ...
}
```

### 2. Création utilisateur dans SignUpView

Après `Auth.auth().createUser()`, on appelle immédiatement :

```swift
try await DataConnectManager.shared.createUser(
    uid: user.uid, // ← L'UID devient l'ID dans Data Connect
    email: email,
    username: username,
    // ...
)
```

### 3. Recherche insensible à la casse

Le champ `username_lower` stocke le username en minuscules pour permettre la recherche insensible à la casse.

---

## 🧪 Tester

### 1. Créer 2 comptes
- Compte 1 : `soula.corentin@gmail.com` / username: `corentinsoula`
- Compte 2 : `soula.corentin@icloud.com` / username: `corentin`

### 2. Rechercher
Dans la `FindFriendView`, cherchez :
- `corentinsoula` → Trouve le compte 1
- `CorentinSoula` → Trouve aussi (insensible à la casse)
- `soula.corentin@icloud.com` → Trouve le compte 2

### 3. Envoyer demande
Cliquez sur "Ajouter comme ami" → La demande apparaît dans les "Demandes en attente" du compte 2

### 4. Accepter
Le compte 2 accepte → Les deux deviennent amis

---

## 🔧 Dépannage

### Erreur : "Table User not found"
→ Vous devez déployer le schéma : `firebase dataconnect:deploy`

### Erreur : "Invalid authentication"
→ Vérifiez que l'utilisateur est connecté et que le token est valide

### Erreur : "GraphQL error"
→ Vérifiez les logs dans Firebase Console → Data Connect → Logs

---

## 📚 Ressources

- [Firebase Data Connect Docs](https://firebase.google.com/docs/data-connect)
- [GraphQL Docs](https://graphql.org/learn/)
