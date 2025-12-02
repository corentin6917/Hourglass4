# Instructions de déploiement Data Connect

## Problème actuel

Votre schéma Data Connect dans Firebase Console montre encore `id: UUID!` pour la table User, mais le code local utilise `id: String!`. Firebase Data Connect ne peut pas modifier le type d'une colonne existante, il faut donc recréer le service.

## Solution : Déployer le nouveau schéma

### Prérequis

Votre système utilise Node.js v10.14.2 qui est trop ancien. Firebase CLI nécessite Node 14+.

### Option 1 : Mettre à jour Node.js puis utiliser Firebase CLI

1. **Installer Node.js version récente** (16+ recommandé)
   ```bash
   # Téléchargez depuis https://nodejs.org
   # Ou utilisez nvm:
   curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.0/install.sh | bash
   nvm install 18
   nvm use 18
   ```

2. **Installer Firebase CLI**
   ```bash
   sudo npm install -g firebase-tools
   ```

3. **Se connecter à Firebase**
   ```bash
   firebase login
   ```

4. **Supprimer l'ancien service**
   ```bash
   cd "/Users/corentinsoula/Desktop/Hourglass 4"
   firebase dataconnect:services:delete hourglass4-service --location=europe-west9 --force
   ```

5. **Déployer le nouveau schéma**
   ```bash
   firebase dataconnect:deploy --force
   ```

### Option 2 : Via la Console Firebase (plus simple)

1. Allez sur https://console.firebase.google.com
2. Sélectionnez votre projet **Hourglass 4**
3. Menu → **Data Connect**
4. Cliquez sur le service **hourglass4-service**
5. Cliquez sur les 3 points ⋮ → **Delete service**
6. Confirmez la suppression

7. Une fois supprimé, vous pouvez soit :
   - **A. Créer le service manuellement** via l'interface web en copiant le contenu de `dataconnect/schema/schema.gql`
   - **B. Déployer via CLI** après avoir installé Firebase CLI (voir Option 1)

## Vérification

Après le déploiement, vérifiez dans la Console Firebase que :
- Le service `hourglass4-service` existe
- La table `User` a bien `id: String` (varchar(128))
- La table `Friendship` existe avec les bonnes colonnes

## Fichiers du nouveau schéma

Les fichiers sont déjà créés dans :
```
dataconnect/
├── schema/
│   └── schema.gql           # User.id: String! ✓
├── mutations/
│   ├── createUser.gql
│   ├── createFriendship.gql
│   └── updateFriendshipStatus.gql
├── queries/
│   ├── getUserByUsername.gql
│   ├── getUserByEmail.gql
│   ├── getPendingFriendRequests.gql
│   └── getFriends.gql
└── dataconnect.yaml
```

## Après le déploiement

Une fois le schéma déployé avec succès, l'application devrait fonctionner :
1. Créer un compte → L'UID de Firebase Auth devient l'ID dans Data Connect
2. Rechercher des amis par username ou email
3. Envoyer des demandes d'amis
4. Accepter/refuser des demandes
