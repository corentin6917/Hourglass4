#!/usr/bin/env python3
"""
Script pour ajouter automatiquement des fichiers Swift à un projet Xcode
"""
import uuid
import re

proj_path = "/Users/corentinsoula/Desktop/Hourglass 4/Hourglass 4.xcodeproj/project.pbxproj"

# Lire le contenu actuel
with open(proj_path, 'r') as f:
    content = f.read()

# Fichiers à ajouter
files_to_add = [
    ("ProfileImageManager.swift", "Profile image upload/download manager"),
    ("ProfileImageView.swift", "Reusable profile image component"),
    ("ImagePicker.swift", "SwiftUI image picker wrapper")
]

# Générer des IDs uniques pour chaque fichier (24 caractères hex uppercase)
def generate_xcode_id():
    return ''.join([f'{b:02X}' for b in uuid.uuid4().bytes[:12]])

# Pour chaque fichier, créer les entrées nécessaires
pbx_file_refs = []
pbx_build_files = []
pbx_sources_build_phase_entries = []

for filename, comment in files_to_add:
    file_ref_id = generate_xcode_id()
    build_file_id = generate_xcode_id()

    # PBXFileReference
    pbx_file_refs.append(
        f"\t\t{file_ref_id} /* {filename} */ = {{isa = PBXFileReference; lastKnownFileType = sourcecode.swift; path = {filename}; sourceTree = \"<group>\"; }};"
    )

    # PBXBuildFile
    pbx_build_files.append(
        f"\t\t{build_file_id} /* {filename} in Sources */ = {{isa = PBXBuildFile; fileRef = {file_ref_id} /* {filename} */; }};"
    )

    # Sources build phase entry
    pbx_sources_build_phase_entries.append(
        f"\t\t\t\t{build_file_id} /* {filename} in Sources */,"
    )

# Trouver la section PBXBuildFile et insérer
build_file_section = "/* End PBXBuildFile section */"
build_file_insert = "\n".join(pbx_build_files) + "\n"
content = content.replace(build_file_section, build_file_insert + build_file_section)

# Trouver la section PBXFileReference et insérer
file_ref_section = "/* End PBXFileReference section */"
file_ref_insert = "\n".join(pbx_file_refs) + "\n"
content = content.replace(file_ref_section, file_ref_insert + file_ref_section)

# Trouver la section Sources dans PBXSourcesBuildPhase et ajouter les fichiers
# Chercher le pattern: files = ( ... );
sources_pattern = r'(\/\* Sources \*\/ = \{[^}]*files = \(\s*)'
match = re.search(sources_pattern, content, re.DOTALL)
if match:
    insert_pos = match.end()
    sources_insert = "\n".join(pbx_sources_build_phase_entries) + "\n"
    content = content[:insert_pos] + sources_insert + content[insert_pos:]

# Sauvegarder
with open(proj_path, 'w') as f:
    f.write(content)

print("✅ Fichiers ajoutés au projet Xcode!")
print("\nFichiers ajoutés:")
for filename, _ in files_to_add:
    print(f"  - {filename}")
print("\nVous pouvez maintenant build le projet dans Xcode.")
