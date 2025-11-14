#!/bin/bash
# Script d'assemblage automatique pour install_bolt_nbility_v6.5.sh

echo "╔══════════════════════════════════════════════════════════╗"
echo "║  Assemblage du script install_bolt_nbility_v6.5.sh       ║"
echo "╚══════════════════════════════════════════════════════════╝"
echo ""

# Vérification des fichiers
echo "🔍 Vérification des fichiers..."
missing=0
for i in 1 2 3 4 5; do
    if [ ! -f "install_bolt_nbility_v6.5_part${i}.sh" ]; then
        echo "❌ Fichier manquant: install_bolt_nbility_v6.5_part${i}.sh"
        missing=1
    else
        echo "✅ install_bolt_nbility_v6.5_part${i}.sh trouvé"
    fi
done

if [ $missing -eq 1 ]; then
    echo ""
    echo "❌ Certains fichiers sont manquants. Abandon."
    exit 1
fi

echo ""
echo "🔧 Assemblage en cours..."

# Assemblage
cat install_bolt_nbility_v6.5_part1.sh \
    install_bolt_nbility_v6.5_part2.sh \
    install_bolt_nbility_v6.5_part3.sh \
    install_bolt_nbility_v6.5_part4.sh \
    install_bolt_nbility_v6.5_part5.sh > install_bolt_nbility_v6.5.sh

# Rendre exécutable
chmod +x install_bolt_nbility_v6.5.sh

# Vérification
lines=$(wc -l < install_bolt_nbility_v6.5.sh)

echo ""
echo "✅ Assemblage terminé !"
echo ""
echo "📊 Statistiques:"
echo "   - Lignes totales: $lines"
echo "   - Fichier: install_bolt_nbility_v6.5.sh"
echo ""

if [ $lines -gt 1800 ]; then
    echo "✅ Le script semble complet (1889 lignes attendues)"
else
    echo "⚠️  Le script semble incomplet (seulement $lines lignes)"
fi

echo ""
echo "🚀 Pour lancer l'installation:"
echo "   ./install_bolt_nbility_v6.5.sh"
echo ""
