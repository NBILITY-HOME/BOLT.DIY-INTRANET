#!/bin/bash
#═══════════════════════════════════════════════════════════════════════════
# Script d'assemblage - BOLT.DIY Nbility v7.0
# Concatène tous les fichiers parts en un seul script
#═══════════════════════════════════════════════════════════════════════════

echo "🔧 Assemblage du script install_bolt_v7.0.sh..."
echo ""

# Vérifier que tous les parts existent
PARTS=(
    "install_bolt_v7.0_part1.sh"
    "install_bolt_v7.0_part2.sh"
    "install_bolt_v7.0_part3.sh"
    "install_bolt_v7.0_part4.sh"
    "install_bolt_v7.0_part5.sh"
    "install_bolt_v7.0_part6.sh"
)

ALL_OK=true
for part in "${PARTS[@]}"; do
    if [ ! -f "$part" ]; then
        echo "❌ Fichier manquant: $part"
        ALL_OK=false
    else
        echo "✓ $part"
    fi
done

if [ "$ALL_OK" = false ]; then
    echo ""
    echo "❌ Certains fichiers sont manquants. Assemblage impossible."
    exit 1
fi

echo ""
echo "📝 Assemblage en cours..."

# Créer le script principal avec header
cat > install_bolt_v7.0.sh << 'MAIN_HEADER'
#!/bin/bash
#═══════════════════════════════════════════════════════════════════════════
# BOLT.DIY NBILITY - Installation Script v7.0 (ASSEMBLÉ)
# Architecture Multi-Ports + User Manager v2.0 COMPLET + MariaDB + Docker
# © Copyright Nbility 2025 - contact@nbility.fr
#
# 🆕 SCRIPT ASSEMBLÉ AUTOMATIQUEMENT
# Généré à partir des fichiers modulaires (parts 1-6)
#
# Pour modifier ce script:
# 1. Éditez les fichiers install_bolt_v7.0_partX.sh
# 2. Relancez: ./assemble.sh
#
# Repository: https://github.com/NBILITY-HOME/BOLT.DIY-INTRANET
#═══════════════════════════════════════════════════════════════════════════
MAIN_HEADER

# Concaténer tous les parts
for part in "${PARTS[@]}"; do
    echo "  + $part"
    cat "$part" >> install_bolt_v7.0.sh
done

# Ajouter la fonction main() à la fin
cat >> install_bolt_v7.0.sh << 'MAIN_FUNCTION'

#═══════════════════════════════════════════════════════════════════════════
# FONCTION PRINCIPALE
#═══════════════════════════════════════════════════════════════════════════
main() {
    print_banner
    check_prerequisites
    check_internet_and_github
    get_configuration
    clone_repository
    verify_github_files
    install_composer_dependencies
    generate_docker_compose
    generate_nginx_conf
    generate_usermanager_dockerfile
    generate_health_php
    generate_env_files
    create_sql_files
    create_htpasswd
    build_and_start_containers
    display_summary
}

# Lancement
main "$@"
MAIN_FUNCTION

# Rendre exécutable
chmod +x install_bolt_v7.0.sh

# Stats
LINES=$(wc -l < install_bolt_v7.0.sh)
SIZE=$(du -h install_bolt_v7.0.sh | cut -f1)

echo ""
echo "✅ Assemblage terminé!"
echo ""
echo "📊 Statistiques:"
echo "  • Fichier: install_bolt_v7.0.sh"
echo "  • Lignes: $LINES"
echo "  • Taille: $SIZE"
echo ""
echo "🚀 Pour lancer l'installation:"
echo "   ./install_bolt_v7.0.sh"
echo ""
