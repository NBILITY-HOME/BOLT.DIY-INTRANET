
# ═══════════════════════════════════════════════════════════════════════════
# FONCTION: Génération des HTML templates
# ═══════════════════════════════════════════════════════════════════════════
generate_html_from_templates() {
    local template_file=$1
    local output_file=$2
    local desc=$3

    print_step "Génération de $desc..."

    sed -e "s/LOCAL_IP/$LOCAL_IP/g" \
        -e "s/GATEWAY_IP/$GATEWAY_IP/g" \
        -e "s/HOST_PORT_BOLT/$HOST_PORT_BOLT/g" \
        -e "s/HOST_PORT_HOME/$HOST_PORT_HOME/g" \
        -e "s/HOST_PORT_UM/$HOST_PORT_UM/g" \
        "$template_file" > "$output_file"

    if [ -f "$output_file" ]; then
        print_success "$desc générée"
    else
        print_error "Échec de la génération de $desc"
    fi
}

generate_html_pages() {
    print_section "GÉNÉRATION DES PAGES HTML"

    if [ -d "$TEMPLATES_DIR" ]; then
        if [ -f "$TEMPLATES_DIR/home.html" ]; then
            generate_html_from_templates "$TEMPLATES_DIR/home.html" "$TEMPLATES_DIR/home_generated.html" "page d'accueil"
        else
            print_warning "Template home.html non trouvé"
        fi
    else
        print_warning "Dossier templates introuvable"
    fi

    echo ""
}

# ═══════════════════════════════════════════════════════════════════════════
# FONCTION: Fix Dockerfile Bolt
# ═══════════════════════════════════════════════════════════════════════════
fix_bolt_dockerfile() {
    print_section "APPLICATION DU FIX DOCKERFILE BOLT"

    cd "$INSTALL_DIR"

    local dockerfile_template="$TEMPLATES_DIR/bolt.diy/Dockerfile"
    local dockerfile_target="$BOLT_DIR/Dockerfile"

    if [ ! -f "$dockerfile_template" ]; then
        print_warning "Template Dockerfile non trouvé, skip du fix"
        return 0
    fi

    if [ ! -f "$dockerfile_target" ]; then
        print_warning "Dockerfile cible non trouvé dans bolt.diy/"
        return 0
    fi

    print_step "Application du fix wrangler..."
    cp "$dockerfile_template" "$dockerfile_target"
    print_success "Fix Dockerfile appliqué"

    echo ""
}

# ═══════════════════════════════════════════════════════════════════════════
# FONCTION: Build et démarrage des conteneurs
# ═══════════════════════════════════════════════════════════════════════════
build_and_start_containers() {
    print_section "BUILD ET DÉMARRAGE DES CONTENEURS"

    cd "$INSTALL_DIR"

    print_step "Vérification de la configuration docker-compose..."
    if docker compose config > /dev/null 2>&1; then
        print_success "Configuration docker-compose valide"
    else
        print_error "Configuration docker-compose invalide"
        exit 1
    fi

    print_step "Build des images Docker (cela peut prendre plusieurs minutes)..."
    echo -e "${YELLOW}Build en cours...${NC}"

    if docker compose build 2>&1 | tee /tmp/bolt-build.log; then
        print_success "Build des images réussi"
    else
        print_error "Échec du build"
        echo -e "${YELLOW}Consultez /tmp/bolt-build.log pour les détails${NC}"
        exit 1
    fi

    print_step "Démarrage des conteneurs..."
    if docker compose up -d; then
        print_success "Conteneurs démarrés"
    else
        print_error "Échec du démarrage"
        exit 1
    fi

    print_step "Attente de l'initialisation de MariaDB..."
    sleep 10
    print_success "MariaDB initialisée"

    print_step "Vérification de l'état des conteneurs..."
    docker compose ps

    echo ""
}

# ═══════════════════════════════════════════════════════════════════════════
# FONCTION: Tests post-installation
# ═══════════════════════════════════════════════════════════════════════════
run_post_install_tests() {
    print_section "TESTS POST-INSTALLATION"

    print_step "Test de connectivité Bolt.DIY..."
    if curl -f -s -o /dev/null "http://$LOCAL_IP:$HOST_PORT_BOLT/health"; then
        print_success "Bolt.DIY accessible"
    else
        print_warning "Bolt.DIY pas encore prêt (peut prendre quelques minutes)"
    fi

    print_step "Test de connectivité User Manager..."
    if curl -f -s -o /dev/null "http://$LOCAL_IP:$HOST_PORT_UM/health.php"; then
        print_success "User Manager accessible"
    else
        print_warning "User Manager pas encore prêt"
    fi

    print_step "Test de la base de données..."
    if docker exec bolt-mariadb mysql -u bolt_um -p"$MARIADB_USER_PASSWORD" -e "SHOW DATABASES;" > /dev/null 2>&1; then
        print_success "Base de données accessible"
    else
        print_warning "Base de données pas encore prête"
    fi

    echo ""
}

# ═══════════════════════════════════════════════════════════════════════════
# FONCTION: Résumé de l'installation
# ═══════════════════════════════════════════════════════════════════════════
print_installation_summary() {
    clear
    print_banner

    echo -e "${GREEN}${BOLD}═══════════════════════════════════════════════════════════════════════════${NC}"
    echo -e "${GREEN}${BOLD}                    ✓ INSTALLATION TERMINÉE AVEC SUCCÈS                   ${NC}"
    echo -e "${GREEN}${BOLD}═══════════════════════════════════════════════════════════════════════════${NC}"
    echo ""

    echo -e "${CYAN}╔══════════════════════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║${NC} ${WHITE}${BOLD}ACCÈS AUX SERVICES${NC}                                                          ${CYAN}║${NC}"
    echo -e "${CYAN}╠══════════════════════════════════════════════════════════════════════════════╣${NC}"
    echo -e "${CYAN}║${NC}                                                                              ${CYAN}║${NC}"
    echo -e "${CYAN}║${NC}  ${YELLOW}🚀 Login Bolt.DIY${NC}        http://$LOCAL_IP:$HOST_PORT_BOLT                   ${CYAN}║${NC}"
    echo -e "${CYAN}║${NC}  ${YELLOW}🏠 Page d'Accueil${NC}        http://$LOCAL_IP:$HOST_PORT_HOME                   ${CYAN}║${NC}"
    echo -e "${CYAN}║${NC}  ${YELLOW}👥 User Manager${NC}          http://$LOCAL_IP:$HOST_PORT_UM                     ${CYAN}║${NC}"
    echo -e "${CYAN}║${NC}                                                                              ${CYAN}║${NC}"
    echo -e "${CYAN}╠══════════════════════════════════════════════════════════════════════════════╣${NC}"
    echo -e "${CYAN}║${NC} ${WHITE}${BOLD}AUTHENTIFICATION NGINX${NC}                                                     ${CYAN}║${NC}"
    echo -e "${CYAN}╠══════════════════════════════════════════════════════════════════════════════╣${NC}"
    echo -e "${CYAN}║${NC}                                                                              ${CYAN}║${NC}"
    echo -e "${CYAN}║${NC}  ${YELLOW}Utilisateur:${NC} $NGINX_USER                                                    ${CYAN}║${NC}"
    echo -e "${CYAN}║${NC}  ${YELLOW}Mot de passe:${NC} ●●●●●●●●                                                     ${CYAN}║${NC}"
    echo -e "${CYAN}║${NC}                                                                              ${CYAN}║${NC}"
    echo -e "${CYAN}╠══════════════════════════════════════════════════════════════════════════════╣${NC}"
    echo -e "${CYAN}║${NC} ${WHITE}${BOLD}SUPER ADMIN USER MANAGER${NC}                                                  ${CYAN}║${NC}"
    echo -e "${CYAN}╠══════════════════════════════════════════════════════════════════════════════╣${NC}"
    echo -e "${CYAN}║${NC}                                                                              ${CYAN}║${NC}"
    echo -e "${CYAN}║${NC}  ${YELLOW}Username:${NC} $ADMIN_USERNAME                                                   ${CYAN}║${NC}"
    echo -e "${CYAN}║${NC}  ${YELLOW}Email:${NC} $ADMIN_EMAIL                                                         ${CYAN}║${NC}"
    echo -e "${CYAN}║${NC}  ${YELLOW}Mot de passe:${NC} (celui que vous avez configuré)                              ${CYAN}║${NC}"
    echo -e "${CYAN}║${NC}                                                                              ${CYAN}║${NC}"
    echo -e "${CYAN}╠══════════════════════════════════════════════════════════════════════════════╣${NC}"
    echo -e "${CYAN}║${NC} ${WHITE}${BOLD}BASE DE DONNÉES MARIADB${NC}                                                   ${CYAN}║${NC}"
    echo -e "${CYAN}╠══════════════════════════════════════════════════════════════════════════════╣${NC}"
    echo -e "${CYAN}║${NC}                                                                              ${CYAN}║${NC}"
    echo -e "${CYAN}║${NC}  ${YELLOW}Port:${NC} $MARIADB_PORT                                                           ${CYAN}║${NC}"
    echo -e "${CYAN}║${NC}  ${YELLOW}Database:${NC} bolt_usermanager                                                  ${CYAN}║${NC}"
    echo -e "${CYAN}║${NC}  ${YELLOW}Utilisateur:${NC} bolt_um                                                        ${CYAN}║${NC}"
    echo -e "${CYAN}║${NC}  ${YELLOW}Tables créées:${NC} 14 tables                                                    ${CYAN}║${NC}"
    echo -e "${CYAN}║${NC}                                                                              ${CYAN}║${NC}"
    echo -e "${CYAN}╠══════════════════════════════════════════════════════════════════════════════╣${NC}"
    echo -e "${CYAN}║${NC} ${WHITE}${BOLD}ARCHITECTURE${NC}                                                              ${CYAN}║${NC}"
    echo -e "${CYAN}╠══════════════════════════════════════════════════════════════════════════════╣${NC}"
    echo -e "${CYAN}║${NC}                                                                              ${CYAN}║${NC}"
    echo -e "${CYAN}║${NC}  • Port $HOST_PORT_BOLT: Login Bolt.DIY (à la racine)                                  ${CYAN}║${NC}"
    echo -e "${CYAN}║${NC}  • Port $HOST_PORT_HOME: Page d'accueil statique                                       ${CYAN}║${NC}"
    echo -e "${CYAN}║${NC}  • Port $HOST_PORT_UM: User Manager v2.0 (PHP + MariaDB)                            ${CYAN}║${NC}"
    echo -e "${CYAN}║${NC}  • Port $MARIADB_PORT: MariaDB 10.11                                                   ${CYAN}║${NC}"
    echo -e "${CYAN}║${NC}                                                                              ${CYAN}║${NC}"
    echo -e "${CYAN}╚══════════════════════════════════════════════════════════════════════════════╝${NC}"
    echo ""

    echo -e "${MAGENTA}${BOLD}📋 Commandes utiles${NC}"
    echo -e "${CYAN}${ARROW}${NC} Voir les logs: ${WHITE}docker compose logs -f${NC}"
    echo -e "${CYAN}${ARROW}${NC} Logs User Manager: ${WHITE}docker compose logs -f bolt-user-manager${NC}"
    echo -e "${CYAN}${ARROW}${NC} Logs MariaDB: ${WHITE}docker compose logs -f bolt-mariadb${NC}"
    echo -e "${CYAN}${ARROW}${NC} Arrêter: ${WHITE}docker compose stop${NC}"
    echo -e "${CYAN}${ARROW}${NC} Redémarrer: ${WHITE}docker compose restart${NC}"
    echo -e "${CYAN}${ARROW}${NC} Status: ${WHITE}docker compose ps${NC}"
    echo -e "${CYAN}${ARROW}${NC} Accès MariaDB: ${WHITE}docker exec -it bolt-mariadb mysql -u bolt_um -p${NC}"
    echo ""

    echo -e "${GREEN}${BOLD}✓ Installation v6.5 terminée avec succès !${NC}"
    echo ""
}

# ═══════════════════════════════════════════════════════════════════════════
# SCRIPT PRINCIPAL
# ═══════════════════════════════════════════════════════════════════════════
main() {
    # Affichage de la bannière
    print_banner

    # Vérifications
    check_prerequisites
    check_internet_and_github

    # Configuration
    get_configuration

    # Clonage et préparation
    clone_repository
    create_directory_structure

    # Génération des fichiers de configuration
    generate_docker_compose
    generate_nginx_conf
    generate_usermanager_dockerfile
    generate_health_php
    generate_env_files

    # Création de la base de données
    create_sql_schema
    create_sql_seed

    # Création des fichiers User Manager
    create_usermanager_files

    # Authentification NGINX
    create_htpasswd

    # HTML templates
    generate_html_pages

    # Fix Bolt Dockerfile
    fix_bolt_dockerfile

    # Build et démarrage
    build_and_start_containers

    # Tests
    run_post_install_tests

    # Résumé
    print_installation_summary
}

# Lancement du script
main
