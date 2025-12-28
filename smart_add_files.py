#!/usr/bin/env python3
"""
Script intelligent pour ajouter des fichiers Swift au projet Xcode
en copiant la structure d'un fichier existant
"""
import uuid
import re
import sys

proj_path = "/Users/corentinsoula/Desktop/Hourglass 4/Hourglass 4.xcodeproj/project.pbxproj"

# Lire le contenu actuel
with open(proj_path, 'r') as f:
    content = f.read()

# Fichiers à ajouter
files_to_add = [
    "ProfileImageManager.swift",
    "ProfileImageView.swift",
    "ImagePicker.swift"
]

# Vérifier si les fichiers sont déjà dans le projet
for filename in files_to_add:
    if filename in content:
        print(f"✅ {filename} est déjà dans le projet")
        sys.exit(0)

# Trouver un fichier de référence (LoginView.swift) pour copier sa structure
ref_file = "LoginView.swift"
if ref_file not in content:
    print(f"❌ Fichier de référence {ref_file} introuvable")
    sys.exit(1)

# Extraire l'ID du fichier de référence dans PBXFileReference
file_ref_match = re.search(r'([A-F0-9]{24}) /\* ' + ref_file + r' \*/ = \{isa = PBXFileReference;', content)
if not file_ref_match:
    print(f"❌ Impossible de trouver la référence pour {ref_file}")
    sys.exit(1)

ref_file_id = file_ref_match.group(1)

# Extraire l'ID dans PBXBuildFile
build_file_match = re.search(r'([A-F0-9]{24}) /\* ' + ref_file + r' in Sources \*/ = \{isa = PBXBuildFile; fileRef = ' + ref_file_id, content)
if not build_file_match:
    print(f"❌ Impossible de trouver le build file pour {ref_file}")
    sys.exit(1)

ref_build_id = build_file_match.group(1)

# Générer des IDs uniques
def generate_xcode_id():
    return ''.join([f'{b:02X}' for b in uuid.uuid4().bytes[:12]])

# Préparer les entrées pour chaque fichier
entries_to_add = []

for filename in files_to_add:
    file_ref_id = generate_xcode_id()
    build_file_id = generate_xcode_id()

    entries_to_add.append({
        'filename': filename,
        'file_ref_id': file_ref_id,
        'build_file_id': build_file_id
    })

# 1. Ajouter dans PBXBuildFile section (juste avant la ligne de UserManager.swift)
for entry in entries_to_add:
    build_file_line = f"\t\t{entry['build_file_id']} /* {entry['filename']} in Sources */ = {{isa = PBXBuildFile; fileRef = {entry['file_ref_id']} /* {entry['filename']} */; }};"

    # Trouver la ligne UserManager.swift dans PBXBuildFile et insérer avant
    pattern = r'(\t\t' + ref_build_id + r' /\* ' + ref_file + r'.*?\n)'
    content = re.sub(pattern, build_file_line + '\n' + r'\1', content, count=1)

# 2. Ajouter dans PBXFileReference section (juste avant la ligne de UserManager.swift)
for entry in entries_to_add:
    file_ref_line = f"\t\t{entry['file_ref_id']} /* {entry['filename']} */ = {{isa = PBXFileReference; lastKnownFileType = sourcecode.swift; path = {entry['filename']}; sourceTree = \"<group>\"; }};"

    # Trouver la ligne UserManager.swift dans PBXFileReference et insérer avant
    pattern = r'(\t\t' + ref_file_id + r' /\* ' + ref_file + r'.*?\n)'
    content = re.sub(pattern, file_ref_line + '\n' + r'\1', content, count=1)

# 3. Ajouter dans PBXSourcesBuildPhase (juste avant UserManager.swift)
# Chercher UserManager.swift dans la section files
sources_ref_pattern = r'(\t\t\t\t' + ref_build_id + r' /\* ' + ref_file + r' in Sources \*/,\n)'
for entry in entries_to_add:
    sources_line = f"\t\t\t\t{entry['build_file_id']} /* {entry['filename']} in Sources */,"
    content = re.sub(sources_ref_pattern, sources_line + '\n' + r'\1', content, count=1)

# 4. Ajouter dans PBXGroup (le groupe des fichiers sources)
# Trouver le groupe qui contient UserManager.swift
group_pattern = r'(children = \((?:[^)]|\n)*?' + ref_file_id + r' /\* ' + ref_file + r' \*/,)'
for entry in entries_to_add:
    group_line = f"\t\t\t\t{entry['file_ref_id']} /* {entry['filename']} */,"
    content = re.sub(group_pattern, r'\1\n' + group_line, content, count=1)

# Sauvegarder
with open(proj_path, 'w') as f:
    f.write(content)

print("✅ Fichiers ajoutés au projet Xcode!")
print("\nFichiers ajoutés:")
for entry in entries_to_add:
    print(f"  - {entry['filename']}")
print("\nVous pouvez maintenant rebuild le projet.")
