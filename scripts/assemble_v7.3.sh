#!/bin/bash

#═══════════════════════════════════════════════════════════════════════════
# Script d'assemblage Bolt.DIY v7.3
# Combine les 6 parties en un seul fichier install_bolt_v7.3.sh
# © Copyright Nbility 2025 - contact@nbility.fr
#═══════════════════════════════════════════════════════════════════════════

set -e

# Couleurs
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Fichiers sources
PARTS=(
    "install_bolt_v7.3_part1.sh"
    "install_bolt_v7.3_part2.sh"
    "install_bolt_v7.3_part3.sh"
    "install_bolt_v7.3_part4.sh"
    "install_bolt_v7.3_part5.sh"
    "install_bolt_v7.3_part6.sh"
)

# Fichier de sortie
OUTPUT="install_bolt_v7.3.sh"

# Bannière
echo ""
echo -e "${BLUE}═══════════════════════════════════════════════════════════════════════════${NC}"
echo -e "${BLUE}  ASSEMBLAGE BOLT.DIY V7.3${NC}"
echo -e "${BLUE}═══════════════════════════════════════════════════════════════════════════${NC}"
echo ""

# Vérifier que tous les fichiers existent
echo -e "${YELLOW}▶${NC} Vérification des fichiers sources..."
ALL_OK=true
for part in "${PARTS[@]}"; do
    if [ -f "$part" ]; then
        echo -e "${GREEN}✓${NC} $part présent"
    else
        echo -e "${RED}✗${NC} $part manquant"
        ALL_OK=false
    fi
done

if [ "$ALL_OK" = false ]; then
    echo ""
    echo -e "${RED}✗ Erreur: Des fichiers sources sont manquants${NC}"
    exit 1
fi

echo ""
echo -e "${YELLOW}▶${NC} Suppression de l'ancien fichier assemblé (si existant)..."
rm -f "$OUTPUT"
echo -e "${GREEN}✓${NC} Nettoyage effectué"

echo ""
echo -e "${YELLOW}▶${NC} Assemblage des parties..."

# Assembler les fichiers
for part in "${PARTS[@]}"; do
    echo -e "${BLUE}  • Ajout de $part${NC}"
    cat "$part" >> "$OUTPUT"
    echo "" >> "$OUTPUT"  # Ligne vide entre les parties
done

# Rendre le fichier exécutable
chmod +x "$OUTPUT"

echo ""
echo -e "${GREEN}✓${NC} Assemblage terminé"

# Statistiques
TOTAL_LINES=$(wc -l < "$OUTPUT")
TOTAL_SIZE=$(wc -c < "$OUTPUT")
TOTAL_SIZE_KB=$((TOTAL_SIZE / 1024))

echo ""
echo -e "${BLUE}═══════════════════════════════════════════════════════════════════════════${NC}"
echo -e "${BLUE}  STATISTIQUES${NC}"
echo -e "${BLUE}═══════════════════════════════════════════════════════════════════════════${NC}"
echo ""
echo -e "${GREEN}📄 Fichier:${NC} $OUTPUT"
echo -e "${GREEN}📏 Lignes:${NC} $TOTAL_LINES"
echo -e "${GREEN}💾 Taille:${NC} $TOTAL_SIZE_KB KB ($TOTAL_SIZE octets)"
echo -e "${GREEN}✓ Exécutable:${NC} Oui"
echo ""

# Afficher les détails des parties
echo -e "${BLUE}═══════════════════════════════════════════════════════════════════════════${NC}"
echo -e "${BLUE}  DÉTAILS DES PARTIES${NC}"
echo -e "${BLUE}═══════════════════════════════════════════════════════════════════════════${NC}"
echo ""

for part in "${PARTS[@]}"; do
    LINES=$(wc -l < "$part")
    printf "${GREEN}%-35s${NC} %5d lignes\n" "$part" "$LINES"
done

echo ""
echo -e "${BLUE}═══════════════════════════════════════════════════════════════════════════${NC}"
echo -e "${BLUE}  NOUVEAUTÉS V7.3${NC}"
echo -e "${BLUE}═══════════════════════════════════════════════════════════════════════════${NC}"
echo ""
echo -e "${GREEN}✅ Suppression des générateurs de fichiers source${NC}"
echo -e "${GREEN}✅ Utilisation exclusive des fichiers GitHub${NC}"
echo -e "${GREEN}✅ home.html → index.html (standard web)${NC}"
echo -e "${GREEN}✅ Vérifications strictes avec arrêt si fichier manquant${NC}"
echo -e "${GREEN}✅ Support de 4 clés API (Groq, OpenAI, Anthropic, Google)${NC}"
echo -e "${GREEN}✅ Script réduit de ~170 lignes (-11%)${NC}"
echo ""

echo -e "${BLUE}═══════════════════════════════════════════════════════════════════════════${NC}"
echo -e "${BLUE}  UTILISATION${NC}"
echo -e "${BLUE}═══════════════════════════════════════════════════════════════════════════${NC}"
echo ""
echo -e "${YELLOW}Pour lancer l'installation:${NC}"
echo -e "  ./$OUTPUT"
echo ""
echo -e "${YELLOW}Pour modifier le script:${NC}"
echo -e "  1. Modifiez les fichiers install_bolt_v7.3_partX.sh"
echo -e "  2. Relancez: ./assemble_v7.3.sh"
echo ""

echo -e "${GREEN}🎉 Assemblage réussi !${NC}"
echo ""
