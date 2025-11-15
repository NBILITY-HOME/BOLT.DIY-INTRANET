
#═══════════════════════════════════════════════════════════════════════════
# FONCTION: Création du fichier .htpasswd
#═══════════════════════════════════════════════════════════════════════════
create_htpasswd() {
    print_section "CRÉATION FICHIER .HTPASSWD"

    print_step "Génération du fichier .htpasswd..."

    if command -v htpasswd &> /dev/null; then
        # Utiliser htpasswd si disponible
        htpasswd -cb "$NGINX_DIR/.htpasswd" "$ADMIN_USER" "$ADMIN_PASSWORD"
        print_success ".htpasswd créé avec htpasswd"
    else
        # Fallback: utiliser openssl
        print_warning "htpasswd non disponible, utilisation de openssl..."
        HASH=$(openssl passwd -apr1 "$ADMIN_PASSWORD")
        echo "$ADMIN_USER:$HASH" > "$NGINX_DIR/.htpasswd"
        print_success ".htpasswd créé avec openssl"
    fi

    chmod 644 "$NGINX_DIR/.htpasswd"
    echo ""
}

#═══════════════════════════════════════════════════════════════════════════
# FONCTION: Build et démarrage des conteneurs
#═══════════════════════════════════════════════════════════════════════════
build_and_start_containers() {
    print_section "BUILD ET DÉMARRAGE DES CONTENEURS"

    cd "$PROJECT_ROOT"

    # Arrêter les conteneurs existants
    print_step "Arrêt des conteneurs existants..."
    docker-compose down -v 2>/dev/null || true
    print_success "Conteneurs arrêtés"

    # Build
    print_step "Build des images Docker..."
    if docker-compose build --no-cache; then
        print_success "Build réussi"
    else
        print_error "Échec du build"
        exit 1
    fi

    # Démarrage
    print_step "Démarrage des conteneurs..."
    if docker-compose up -d; then
        print_success "Conteneurs démarrés"
    else
        print_error "Échec du démarrage"
        exit 1
    fi

    # Attendre que les services soient prêts
    print_step "Attente du démarrage des services (30s)..."
    sleep 30

    # Vérifier les conteneurs
    print_step "Vérification de l'état des conteneurs..."
    echo ""
    docker-compose ps
    echo ""

    # Vérifier les healthchecks
    print_step "Vérification des healthchecks..."
    HEALTHY=0
    for i in {1..10}; do
        if docker-compose ps | grep -q "healthy"; then
            HEALTHY=1
            break
        fi
        echo "  Tentative $i/10..."
        sleep 5
    done

    if [ $HEALTHY -eq 1 ]; then
        print_success "Services démarrés et opérationnels"
    else
        print_warning "Certains services peuvent encore être en cours de démarrage"
        print_warning "Vérifiez les logs: docker-compose logs"
    fi

    echo ""
}

#═══════════════════════════════════════════════════════════════════════════
# FONCTION: Affichage du résumé
#═══════════════════════════════════════════════════════════════════════════
display_summary() {
    print_section "INSTALLATION TERMINÉE"

    echo -e "${GREEN}${BOLD}"
    echo "╔═══════════════════════════════════════════════════════════════════════════╗"
    echo "║                                                                           ║"
    echo "║                    ✓ INSTALLATION RÉUSSIE                                ║"
    echo "║                                                                           ║"
    echo "╚═══════════════════════════════════════════════════════════════════════════╝"
    echo -e "${NC}"
    echo ""

    echo -e "${BOLD}📊 RÉCAPITULATIF:${NC}"
    echo ""
    echo "┌─────────────────────────────────────────────────────────────────────────┐"
    echo "│ ${BOLD}Services déployés:${NC}                                                     │"
    echo "├─────────────────────────────────────────────────────────────────────────┤"
    echo "│ • Bolt.DIY (AI Code Generator)                                          │"
    echo "│ • User Manager v2.0 (MVC Architecture - 45 fichiers)                    │"
    echo "│ • MariaDB 10.11                                                          │"
    echo "│ • Nginx Reverse Proxy                                                    │"
    echo "└─────────────────────────────────────────────────────────────────────────┘"
    echo ""

    echo "┌─────────────────────────────────────────────────────────────────────────┐"
    echo "│ ${BOLD}URLs d'accès:${NC}                                                          │"
    echo "├─────────────────────────────────────────────────────────────────────────┤"
    echo "│ • Page d'accueil:   http://$LOCAL_IP:$HOST_PORT_HOME                   │"
    echo "│ • Bolt.DIY:         http://$LOCAL_IP:$HOST_PORT_BOLT                   │"
    echo "│ • User Manager:     http://$LOCAL_IP:$HOST_PORT_UM                     │"
    echo "└─────────────────────────────────────────────────────────────────────────┘"
    echo ""

    echo "┌─────────────────────────────────────────────────────────────────────────┐"
    echo "│ ${BOLD}Identifiants:${NC}                                                          │"
    echo "├─────────────────────────────────────────────────────────────────────────┤"
    echo "│ • Utilisateur:      $ADMIN_USER                                         │"
    echo "│ • Mot de passe:     ••••••••                                            │"
    echo "└─────────────────────────────────────────────────────────────────────────┘"
    echo ""

    echo "┌─────────────────────────────────────────────────────────────────────────┐"
    echo "│ ${BOLD}Commandes utiles:${NC}                                                      │"
    echo "├─────────────────────────────────────────────────────────────────────────┤"
    echo "│ • Voir les logs:        docker-compose logs -f                          │"
    echo "│ • Arrêter:              docker-compose down                             │"
    echo "│ • Redémarrer:           docker-compose restart                          │"
    echo "│ • Statut:               docker-compose ps                               │"
    echo "│ • Rebuild:              docker-compose build --no-cache                 │"
    echo "└─────────────────────────────────────────────────────────────────────────┘"
    echo ""

    echo "┌─────────────────────────────────────────────────────────────────────────┐"
    echo "│ ${BOLD}Nouveautés v7.0:${NC}                                                       │"
    echo "├─────────────────────────────────────────────────────────────────────────┤"
    echo "│ ✓ Clonage intelligent depuis GitHub                                     │"
    echo "│ ✓ User Manager v2.0 complet (45 fichiers)                               │"
    echo "│ ✓ Architecture MVC (Controllers, Models, Middleware, Utils)             │"
    echo "│ ✓ Frontend JS moderne (9 modules)                                       │"
    echo "│ ✓ Vérification intégrité automatique                                    │"
    echo "│ ✓ Configuration .env complète                                           │"
    echo "│ ✓ Volumes Docker logs/cache/uploads                                     │"
    echo "│ ✓ PHP 8.1 + Composer autoload PSR-4                                     │"
    echo "└─────────────────────────────────────────────────────────────────────────┘"
    echo ""

    echo -e "${YELLOW}${BOLD}⚠️  IMPORTANT:${NC}"
    echo "  • Les services peuvent mettre 1-2 minutes à être pleinement opérationnels"
    echo "  • En cas de problème, consultez: docker-compose logs"
    echo "  • Documentation complète: ./DATA-LOCAL/user-manager/README.md"
    echo ""

    echo -e "${CYAN}${BOLD}📚 Ressources:${NC}"
    echo "  • Repository: https://github.com/NBILITY-HOME/BOLT.DIY-INTRANET"
    echo "  • Support: contact@nbility.fr"
    echo ""

    echo -e "${GREEN}${BOLD}🎉 Bon développement avec BOLT.DIY Nbility !${NC}"
    echo ""
}
