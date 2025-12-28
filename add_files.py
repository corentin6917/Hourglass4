#!/usr/bin/env python3
import os
import sys

# Chemin vers le projet
proj_path = "/Users/corentinsoula/Desktop/Hourglass 4/Hourglass 4.xcodeproj/project.pbxproj"

# Lire le fichier
with open(proj_path, 'r') as f:
    content = f.read()

# Nouveaux fichiers à ajouter
new_files = [
    "ProfileImageManager.swift",
    "ProfileImageView.swift",
    "ImagePicker.swift"
]

# Vérifier si les fichiers sont déjà dans le projet
for filename in new_files:
    if filename in content:
        print(f"✅ {filename} déjà dans le projet")
    else:
        print(f"❌ {filename} MANQUANT dans le projet")

print("\nPour ajouter ces fichiers, utilisez Xcode :")
print("1. Dans Xcode, clic droit sur le dossier 'Hourglass 4'")
print("2. Add Files to 'Hourglass 4'...")
print("3. Sélectionnez ProfileImageManager.swift, ProfileImageView.swift, ImagePicker.swift")
print("4. Cochez 'Copy items if needed' et 'Add to targets: Hourglass 4'")
print("5. Cliquez sur 'Add'")
