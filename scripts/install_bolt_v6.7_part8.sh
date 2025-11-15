
# ═══════════════════════════════════════════════════════════════════════════
# FONCTION: Build et démarrage des conteneurs
# ═══════════════════════════════════════════════════════════════════════════
build_and_start() {
    print_section "BUILD ET DÉMARRAGE DES CONTENEURS"

    cd "$INSTALL_DIR"

    print_step "Vérification de la configuration docker-compose..."
    if docker compose config &> /dev/null; then
        print_success "Configuration valide"
    else
        print_error "Configuration docker-compose invalide"
        docker compose config
        exit 1
    fi

    print_step "Build des images Docker (plusieurs minutes)..."
    echo -e "${YELLOW}Build en cours...${NC}"

    if docker compose build --no-cache 2>&1 | tee /tmp/docker_build.log; then
        print_success "Build réussi"
    else
        print_error "Échec du build"
        echo ""
        echo "Logs d'erreur:"
        tail -n 20 /tmp/docker_build.log
        exit 1
    fi

    print_step "Démarrage des conteneurs..."
    if docker compose up -d; then
        print_success "Conteneurs démarrés"
    else
        print_error "Échec du démarrage"
        exit 1
    fi

    echo ""
}

test_services() {
    print_section "TESTS POST-INSTALLATION"

    print_step "Attente du démarrage des services (30s)..."
    sleep 30

    print_step "Test du container bolt-nginx..."
    if docker ps | grep -q "bolt-nginx"; then
        print_success "bolt-nginx: Running"
    else
        print_error "bolt-nginx: Not running"
    fi

    print_step "Test du container bolt-core..."
    if docker ps | grep -q "bolt-core"; then
        print_success "bolt-core: Running"
    else
        print_error "bolt-core: Not running"
    fi

    print_step "Test du container bolt-home..."
    if docker ps | grep -q "bolt-home"; then
        print_success "bolt-home: Running"
    else
        print_error "bolt-home: Not running"
    fi

    print_step "Test du container bolt-user-manager..."
    if docker ps | grep -q "bolt-user-manager"; then
        print_success "bolt-user-manager: Running"
    else
        print_error "bolt-user-manager: Not running"
    fi

    print_step "Test du container bolt-mariadb..."
    if docker ps | grep -q "bolt-mariadb"; then
        print_success "bolt-mariadb: Running"
    else
        print_error "bolt-mariadb: Not running"
    fi

    print_step "Test de connectivité port $HOST_PORT_BOLT..."
    if nc -z -w5 $LOCAL_IP $HOST_PORT_BOLT 2>/dev/null || timeout 5 bash -c "cat < /dev/null > /dev/tcp/$LOCAL_IP/$HOST_PORT_BOLT" 2>/dev/null; then
        print_success "Port $HOST_PORT_BOLT accessible"
    else
        print_warning "Port $HOST_PORT_BOLT non accessible (attendre quelques secondes)"
    fi

    print_step "Test de connectivité port $HOST_PORT_HOME..."
    if nc -z -w5 $LOCAL_IP $HOST_PORT_HOME 2>/dev/null || timeout 5 bash -c "cat < /dev/null > /dev/tcp/$LOCAL_IP/$HOST_PORT_HOME" 2>/dev/null; then
        print_success "Port $HOST_PORT_HOME accessible"
    else
        print_warning "Port $HOST_PORT_HOME non accessible (attendre quelques secondes)"
    fi

    print_step "Test de connectivité port $HOST_PORT_UM..."
    if nc -z -w5 $LOCAL_IP $HOST_PORT_UM 2>/dev/null || timeout 5 bash -c "cat < /dev/null > /dev/tcp/$LOCAL_IP/$HOST_PORT_UM" 2>/dev/null; then
        print_success "Port $HOST_PORT_UM accessible"
    else
        print_warning "Port $HOST_PORT_UM non accessible (attendre quelques secondes)"
    fi

    echo ""
}

print_final_summary() {
    clear
    print_banner

    echo -e "${BOLD}${GREEN}╔══════════════════════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${BOLD}${GREEN}║                                                                              ║${NC}"
    echo -e "${BOLD}${GREEN}║                    ✓ INSTALLATION TERMINÉE AVEC SUCCÈS                       ║${NC}"
    echo -e "${BOLD}${GREEN}║                                                                              ║${NC}"
    echo -e "${BOLD}${GREEN}╚══════════════════════════════════════════════════════════════════════════════╝${NC}"
    echo ""

    echo -e "${BOLD}${CYAN}═══════════════════════════════════════════════════════════════════════════${NC}"
    echo -e "${BOLD}${WHITE}INFORMATIONS D'ACCÈS${NC}"
    echo -e "${BOLD}${CYAN}═══════════════════════════════════════════════════════════════════════════${NC}"
    echo ""

    echo -e "${BOLD}${YELLOW}🏠 Page d'Accueil (PUBLIC - SANS AUTHENTIFICATION):${NC}"
    echo -e "   ${CYAN}http://$LOCAL_IP:$HOST_PORT_HOME${NC}"
    echo ""

    echo -e "${BOLD}${YELLOW}⚡ Bolt.DIY (avec authentification):${NC}"
    echo -e "   ${CYAN}http://$LOCAL_IP:$HOST_PORT_BOLT${NC}"
    echo -e "   ${WHITE}User: ${GREEN}$NGINX_USER${NC}"
    echo -e "   ${WHITE}Pass: ${GREEN}[votre mot de passe]${NC}"
    echo ""

    echo -e "${BOLD}${YELLOW}👥 User Manager (avec authentification):${NC}"
    echo -e "   ${CYAN}http://$LOCAL_IP:$HOST_PORT_UM${NC}"
    echo -e "   ${WHITE}User: ${GREEN}$NGINX_USER${NC}"
    echo -e "   ${WHITE}Pass: ${GREEN}[votre mot de passe]${NC}"
    echo ""

    echo -e "${BOLD}${YELLOW}🚪 Déconnexion User Manager:${NC}"
    echo -e "   ${CYAN}http://$LOCAL_IP:$HOST_PORT_UM/logout.php${NC}"
    echo ""

    echo -e "${BOLD}${CYAN}═══════════════════════════════════════════════════════════════════════════${NC}"
    echo -e "${BOLD}${WHITE}INFORMATIONS SUPER ADMIN${NC}"
    echo -e "${BOLD}${CYAN}═══════════════════════════════════════════════════════════════════════════${NC}"
    echo ""
    echo -e "   ${WHITE}Username: ${GREEN}$ADMIN_USERNAME${NC}"
    echo -e "   ${WHITE}Email:    ${GREEN}$ADMIN_EMAIL${NC}"
    echo ""

    echo -e "${BOLD}${CYAN}═══════════════════════════════════════════════════════════════════════════${NC}"
    echo -e "${BOLD}${WHITE}COMMANDES UTILES${NC}"
    echo -e "${BOLD}${CYAN}═══════════════════════════════════════════════════════════════════════════${NC}"
    echo ""
    echo -e "   ${YELLOW}Voir les logs:${NC}"
    echo -e "   ${CYAN}docker compose logs -f${NC}"
    echo ""
    echo -e "   ${YELLOW}Arrêter les services:${NC}"
    echo -e "   ${CYAN}docker compose down${NC}"
    echo ""
    echo -e "   ${YELLOW}Redémarrer les services:${NC}"
    echo -e "   ${CYAN}docker compose restart${NC}"
    echo ""
    echo -e "   ${YELLOW}Reconstruire après modification:${NC}"
    echo -e "   ${CYAN}docker compose up -d --build${NC}"
    echo ""

    echo -e "${BOLD}${CYAN}═══════════════════════════════════════════════════════════════════════════${NC}"
    echo -e "${BOLD}${WHITE}NOUVEAUTÉS v6.7${NC}"
    echo -e "${BOLD}${CYAN}═══════════════════════════════════════════════════════════════════════════${NC}"
    echo ""
    echo -e "   ${GREEN}✓${NC} Page d'accueil accessible SANS authentification (port $HOST_PORT_HOME)"
    echo -e "   ${GREEN}✓${NC} Bouton de déconnexion dans User Manager"
    echo -e "   ${GREEN}✓${NC} Page de déconnexion dédiée (/logout.php)"
    echo -e "   ${GREEN}✓${NC} Affichage de l'utilisateur connecté"
    echo -e "   ${GREEN}✓${NC} Liens externes avec rel='noopener noreferrer'"
    echo ""

    echo -e "${BOLD}${MAGENTA}Support: contact@nbility.fr${NC}"
    echo -e "${BOLD}${MAGENTA}Documentation: https://github.com/NBILITY-HOME/BOLT.DIY-INTRANET${NC}"
    echo ""
}

# ═══════════════════════════════════════════════════════════════════════════
# MAIN - Fonction principale
# ═══════════════════════════════════════════════════════════════════════════
main() {
    print_banner

    check_prerequisites
    check_internet_and_github
    get_configuration
    clone_repository
    create_directory_structure
    generate_docker_compose
    generate_nginx_conf
    generate_usermanager_dockerfile
    generate_health_php
    generate_env_files
    create_sql_files
    create_usermanager_files
    create_htpasswd
    generate_html_pages
    fix_bolt_dockerfile
    build_and_start
    test_services
    print_final_summary
}

main "$@"
