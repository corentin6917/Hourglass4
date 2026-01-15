#!/bin/bash

# Script de nettoyage complet pour Hourglass 4
# Usage: ./clean-build.sh

echo "🧹 Nettoyage en cours..."

# 1. Tuer tous les processus xcodebuild
killall xcodebuild 2>/dev/null
echo "✓ Processus xcodebuild tués"

# 2. Nettoyer le build
cd "/Users/corentinsoula/Desktop/Hourglass 4"
rm -rf build/
echo "✓ Dossier build/ supprimé"

# 3. Nettoyer DerivedData
rm -rf ~/Library/Developer/Xcode/DerivedData/Hourglass*
echo "✓ DerivedData nettoyé"

# 4. Nettoyer les caches Swift
rm -rf ~/Library/Caches/org.swift.swiftpm/
rm -rf ~/Library/Developer/Xcode/DerivedData/ModuleCache.noindex/
echo "✓ Caches Swift nettoyés"

# 5. Résoudre les dépendances
echo "📦 Résolution des dépendances..."
xcodebuild -resolvePackageDependencies -scheme "Hourglass 4" 2>&1 | grep -E "(Resolved|error:)" || true

echo ""
echo "✅ Nettoyage terminé!"
echo "Tu peux maintenant ouvrir Xcode et faire Cmd+B"
