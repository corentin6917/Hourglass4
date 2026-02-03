#!/bin/bash

# Script pour ajouter automatiquement les appels de mise à jour du widget
# Usage: chmod +x add_widget_updates.sh && ./add_widget_updates.sh

echo "🚀 Ajout des mises à jour du widget dans l'app..."

GOAL_MANAGER="/Users/corentinsoula/Desktop/Hourglass 4/Hourglass 4/GoalManager.swift"
USER_MANAGER="/Users/corentinsoula/Desktop/Hourglass 4/Hourglass 4/UserManager.swift"
APP_FILE="/Users/corentinsoula/Desktop/Hourglass 4/Hourglass 4/Hourglass_4App.swift"

# Vérifier que les fichiers existent
if [ ! -f "$GOAL_MANAGER" ]; then
    echo "❌ GoalManager.swift introuvable"
    exit 1
fi

if [ ! -f "$USER_MANAGER" ]; then
    echo "❌ UserManager.swift introuvable"
    exit 1
fi

if [ ! -f "$APP_FILE" ]; then
    echo "❌ Hourglass_4App.swift introuvable"
    exit 1
fi

echo "📝 Création des backups..."
cp "$GOAL_MANAGER" "$GOAL_MANAGER.backup"
cp "$USER_MANAGER" "$USER_MANAGER.backup"
cp "$APP_FILE" "$APP_FILE.backup"

echo "✅ Backups créés avec succès"
echo ""
echo "⚠️  IMPORTANT: Vous devez ajouter manuellement les lignes suivantes:"
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "1️⃣  Dans GoalManager.swift"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "Après chaque méthode qui modifie les objectifs, ajoutez:"
echo ""
echo "    // Rafraîchir le widget"
echo "    WidgetUpdateHelper.shared.updateWidgetFromFirebase()"
echo ""
echo "Méthodes concernées:"
echo "  - createGoal()"
echo "  - validateGoal()"
echo "  - deleteGoal()"
echo "  - updateGoal()"
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "2️⃣  Dans Hourglass_4App.swift"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "Dans la méthode init(), ajoutez:"
echo ""
echo "    init() {"
echo "        // ... code existant ..."
echo "        "
echo "        // Rafraîchir le widget au lancement"
echo "        WidgetUpdateHelper.shared.updateWidgetFromFirebase()"
echo "    }"
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "3️⃣  Dans UserManager.swift (optionnel)"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "Après updateCurrentStreak() ou mise à jour du profil:"
echo ""
echo "    WidgetUpdateHelper.shared.updateWidgetFromFirebase()"
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "💡 Les backups ont été créés avec l'extension .backup"
echo "   Vous pouvez les restaurer si besoin avec:"
echo "   cp fichier.backup fichier.swift"
echo ""
echo "✨ Une fois les modifications faites, buildez le projet dans Xcode !"
