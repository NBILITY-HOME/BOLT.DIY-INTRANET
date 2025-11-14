
# ═══════════════════════════════════════════════════════════════════════════
# FONCTION: Build et démarrage des conteneurs
# ═══════════════════════════════════════════════════════════════════════════
build_and_start_containers() {
    print_section "BUILD ET DÉMARRAGE DES CONTENEURS"

    cd "$INSTALL_DIR"

    print_step "Vérification de la configuration docker-compose..."
    if docker compose config > /dev/null 2>&1; then
        print_success "Configuration valide"
    else
        print_error "Configuration invalide"
        exit 1
    fi

    print_step "Build des images Docker (plusieurs minutes)..."
    echo -e "${YELLOW}Build en cours...${NC}"

    if docker compose build 2>&1 | tee /tmp/bolt-build.log; then
        print_success "Build réussi"
    else
        print_error "Échec du build (voir /tmp/bolt-build.log)"
        exit 1
    fi

    print_step "Démarrage des conteneurs..."
    if docker compose up -d; then
        print_success "Conteneurs démarrés"
    else
        print_error "Échec du démarrage"
        exit 1
    fi

    print_step "Attente de l'initialisation (10s)..."
    sleep 10

    print_step "État des conteneurs:"
    docker compose ps

    echo ""
}

run_post_install_tests() {
    print_section "TESTS POST-INSTALLATION"

    print_step "Test Bolt.DIY..."
    if curl -f -s -o /dev/null "http://$LOCAL_IP:$HOST_PORT_BOLT/health" 2>/dev/null; then
        print_success "Bolt.DIY accessible"
    else
        print_warning "Bolt.DIY pas encore prêt"
    fi

    print_step "Test User Manager..."
    if curl -f -s -o /dev/null "http://$LOCAL_IP:$HOST_PORT_UM/health.php" 2>/dev/null; then
        print_success "User Manager accessible"
    else
        print_warning "User Manager pas encore prêt"
    fi

    print_step "Test MariaDB..."
    if docker exec bolt-mariadb mysql -u bolt_um -p"$MARIADB_USER_PASSWORD" -e "SHOW DATABASES;" > /dev/null 2>&1; then
        print_success "MariaDB accessible"
    else
        print_warning "MariaDB pas encore prête"
    fi

    echo ""
}

print_installation_summary() {
    clear
    print_banner

    echo -e "${GREEN}${BOLD}════════════════════════════════════════════════════════════════════${NC}"
    echo -e "${GREEN}${BOLD}           ✓ INSTALLATION TERMINÉE AVEC SUCCÈS                     ${NC}"
    echo -e "${GREEN}${BOLD}════════════════════════════════════════════════════════════════════${NC}"
    echo ""

    echo -e "${CYAN}╔═══════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║${NC} ${WHITE}${BOLD}ACCÈS AUX SERVICES${NC}                                            ${CYAN}║${NC}"
    echo -e "${CYAN}╠═══════════════════════════════════════════════════════════════╣${NC}"
    echo -e "${CYAN}║${NC}                                                               ${CYAN}║${NC}"
    echo -e "${CYAN}║${NC}  ${YELLOW}🚀 Bolt.DIY${NC}        http://$LOCAL_IP:$HOST_PORT_BOLT           ${CYAN}║${NC}"
    echo -e "${CYAN}║${NC}  ${YELLOW}🏠 Home${NC}            http://$LOCAL_IP:$HOST_PORT_HOME           ${CYAN}║${NC}"
    echo -e "${CYAN}║${NC}  ${YELLOW}👥 User Manager${NC}    http://$LOCAL_IP:$HOST_PORT_UM             ${CYAN}║${NC}"
    echo -e "${CYAN}║${NC}                                                               ${CYAN}║${NC}"
    echo -e "${CYAN}╠═══════════════════════════════════════════════════════════════╣${NC}"
    echo -e "${CYAN}║${NC} ${WHITE}${BOLD}AUTHENTIFICATION${NC}                                           ${CYAN}║${NC}"
    echo -e "${CYAN}╠═══════════════════════════════════════════════════════════════╣${NC}"
    echo -e "${CYAN}║${NC}                                                               ${CYAN}║${NC}"
    echo -e "${CYAN}║${NC}  ${YELLOW}Utilisateur:${NC} $NGINX_USER                                    ${CYAN}║${NC}"
    echo -e "${CYAN}║${NC}  ${YELLOW}Mot de passe:${NC} ●●●●●●●●                                      ${CYAN}║${NC}"
    echo -e "${CYAN}║${NC}                                                               ${CYAN}║${NC}"
    echo -e "${CYAN}╠═══════════════════════════════════════════════════════════════╣${NC}"
    echo -e "${CYAN}║${NC} ${WHITE}${BOLD}SUPER ADMIN${NC}                                                ${CYAN}║${NC}"
    echo -e "${CYAN}╠═══════════════════════════════════════════════════════════════╣${NC}"
    echo -e "${CYAN}║${NC}                                                               ${CYAN}║${NC}"
    echo -e "${CYAN}║${NC}  ${YELLOW}Username:${NC} $ADMIN_USERNAME                                  ${CYAN}║${NC}"
    echo -e "${CYAN}║${NC}  ${YELLOW}Email:${NC} $ADMIN_EMAIL                                        ${CYAN}║${NC}"
    echo -e "${CYAN}║${NC}                                                               ${CYAN}║${NC}"
    echo -e "${CYAN}╠═══════════════════════════════════════════════════════════════╣${NC}"
    echo -e "${CYAN}║${NC} ${WHITE}${BOLD}COMMANDES UTILES${NC}                                          ${CYAN}║${NC}"
    echo -e "${CYAN}╠═══════════════════════════════════════════════════════════════╣${NC}"
    echo -e "${CYAN}║${NC}                                                               ${CYAN}║${NC}"
    echo -e "${CYAN}║${NC}  Logs: ${WHITE}docker compose logs -f${NC}                           ${CYAN}║${NC}"
    echo -e "${CYAN}║${NC}  Arrêter: ${WHITE}docker compose stop${NC}                          ${CYAN}║${NC}"
    echo -e "${CYAN}║${NC}  Redémarrer: ${WHITE}docker compose restart${NC}                    ${CYAN}║${NC}"
    echo -e "${CYAN}║${NC}  Status: ${WHITE}docker compose ps${NC}                             ${CYAN}║${NC}"
    echo -e "${CYAN}║${NC}                                                               ${CYAN}║${NC}"
    echo -e "${CYAN}╚═══════════════════════════════════════════════════════════════╝${NC}"
    echo ""

    echo -e "${GREEN}${BOLD}✓ Installation v6.6 terminée !${NC}"
    echo ""
}

# ═══════════════════════════════════════════════════════════════════════════
# SCRIPT PRINCIPAL
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

    create_sql_schema
    create_sql_seed

    create_usermanager_files
    create_htpasswd

    generate_html_pages
    fix_bolt_dockerfile

    build_and_start_containers
    run_post_install_tests

    print_installation_summary
}

main
