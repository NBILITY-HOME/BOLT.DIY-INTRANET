#!/bin/bash

#═══════════════════════════════════════════════════════════════════════════
# Script d'assemblage - Bolt.DIY v7.4
# Assemble toutes les parties en un seul fichier
#═══════════════════════════════════════════════════════════════════════════

OUTPUT_FILE="install_bolt_v7.4.sh"

echo "════════════════════════════════════════════════════════════════════════════"
echo "  ASSEMBLAGE DU SCRIPT BOLT.DIY v7.4"
echo "════════════════════════════════════════════════════════════════════════════"
echo ""

# Vérifier que toutes les parties existent
PARTS=(
    "install_bolt_v7.4_part1.sh"
    "install_bolt_v7.4_part2.sh"
    "install_bolt_v7.4_part3.sh"
    "install_bolt_v7.4_part4.sh"
    "install_bolt_v7.4_part5.sh"
)

echo "📋 Vérification des parties..."
for part in "${PARTS[@]}"; do
    if [ ! -f "$part" ]; then
        echo "❌ Partie manquante: $part"
        exit 1
    fi
    echo "   ✓ $part"
done

echo ""
echo "🔨 Assemblage en cours..."

# Supprimer l'ancien fichier assemblé
rm -f "$OUTPUT_FILE"

# Assembler toutes les parties
cat install_bolt_v7.4_part1.sh > "$OUTPUT_FILE"
tail -n +2 install_bolt_v7.4_part2.sh >> "$OUTPUT_FILE"
tail -n +2 install_bolt_v7.4_part3.sh >> "$OUTPUT_FILE"
tail -n +2 install_bolt_v7.4_part4.sh >> "$OUTPUT_FILE"
tail -n +2 install_bolt_v7.4_part5.sh >> "$OUTPUT_FILE"

# Rendre exécutable
chmod +x "$OUTPUT_FILE"

# Compter les lignes
TOTAL_LINES=$(wc -l < "$OUTPUT_FILE")

echo ""
echo "════════════════════════════════════════════════════════════════════════════"
echo "  ✅ ASSEMBLAGE TERMINÉ"
echo "════════════════════════════════════════════════════════════════════════════"
echo ""
echo "📄 Fichier créé: $OUTPUT_FILE"
echo "📊 Taille: $TOTAL_LINES lignes"
echo "✅ Exécutable: Oui"
echo ""
echo "🚀 Pour installer Bolt.DIY:"
echo "   ./$OUTPUT_FILE"
echo ""
