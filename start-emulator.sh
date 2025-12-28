#!/bin/bash

echo "🚀 Démarrage de l'émulateur Firebase Data Connect..."
echo "💰 Mode développement GRATUIT activé !"
echo ""
echo "⚠️  Assurez-vous d'avoir arrêté hourglass4-instance sur Google Cloud pour ne pas payer !"
echo ""

cd "$(dirname "$0")"
firebase emulators:start --only dataconnect
