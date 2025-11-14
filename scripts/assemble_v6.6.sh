#!/bin/bash
echo "╔══════════════════════════════════════════════════════════╗"
echo "║  Assemblage du script install_bolt_nbility_v6.6.sh       ║"
echo "╚══════════════════════════════════════════════════════════╝"
echo ""

echo "🔍 Vérification des fichiers..."
missing=0
for i in {1..8}; do
    if [ ! -f "install_bolt_nbility_v6.6_part${i}.sh" ]; then
        echo "❌ Fichier manquant: install_bolt_nbility_v6.6_part${i}.sh"
        missing=1
    else
        echo "✅ install_bolt_nbility_v6.6_part${i}.sh trouvé"
    fi
done

if [ $missing -eq 1 ]; then
    echo ""
    echo "❌ Certains fichiers sont manquants. Abandon."
    exit 1
fi

echo ""
echo "🔧 Assemblage en cours..."

cat install_bolt_nbility_v6.6_part1.sh \
    install_bolt_nbility_v6.6_part2.sh \
    install_bolt_nbility_v6.6_part3.sh \
    install_bolt_nbility_v6.6_part4.sh \
    install_bolt_nbility_v6.6_part5.sh \
    install_bolt_nbility_v6.6_part6.sh \
    install_bolt_nbility_v6.6_part7.sh \
    install_bolt_nbility_v6.6_part8.sh > install_bolt_nbility_v6.6.sh

chmod +x install_bolt_nbility_v6.6.sh

lines=$(wc -l < install_bolt_nbility_v6.6.sh)

echo ""
echo "✅ Assemblage terminé !"
echo ""
echo "📊 Statistiques:"
echo "   - Lignes totales: $lines"
echo "   - Fichier: install_bolt_nbility_v6.6.sh"
echo ""

if [ $lines -gt 1600 ]; then
    echo "✅ Le script semble complet"
else
    echo "⚠️  Le script semble incomplet (seulement $lines lignes)"
fi

echo ""
echo "🚀 Pour lancer l'installation:"
echo "   ./install_bolt_nbility_v6.6.sh"
echo ""
