
#═══════════════════════════════════════════════════════════════════════════
# LANCEMENT DOCKER
#═══════════════════════════════════════════════════════════════════════════

launch_docker() {
    print_section "LANCEMENT DES CONTENEURS DOCKER"

    cd "$PROJECT_ROOT" || exit 1

    # Arrêter les conteneurs existants
    print_step "Arrêt des conteneurs existants..."
    docker compose down 2>/dev/null || true
    print_success "Conteneurs arrêtés"

    # Construire et démarrer
    print_step "Construction et démarrage des conteneurs..."
    if docker compose up -d --build; then
        print_success "Conteneurs démarrés"
    else
        print_error "Échec du démarrage des conteneurs"
        exit 1
    fi

    # Attendre que les services soient prêts
    print_step "Attente du démarrage des services (30s)..."
    sleep 30

    # Vérifier l'état des conteneurs
    print_step "Vérification de l'état des conteneurs..."
    docker compose ps

    cd "$SCRIPT_DIR"
}

#═══════════════════════════════════════════════════════════════════════════
# RÉSUMÉ FINAL
#═══════════════════════════════════════════════════════════════════════════

print_summary() {
    print_section "INSTALLATION TERMINÉE"

    printf "\033[1;32m"
    cat << 'SUCCESS_BANNER'
  _____ _   _  ____ ____ _____ ____  
 / ____| | | |/ ___/ ___| ____/ ___| 
 \\___ \| | | | |  | |   |  _| \___ \ 
  ___) | |_| | |__| |___| |___ ___) |
 |____/ \___/ \____\____|_____|____/ 

SUCCESS_BANNER
    printf "\033[0m\n"

    echo ""
    printf "\033[1;36m═══════════════════════════════════════════════════════════════════════════\033[0m\n"
    printf "\033[1;37m  INFORMATIONS D'ACCÈS\033[0m\n"
    printf "\033[1;36m═══════════════════════════════════════════════════════════════════════════\033[0m\n"
    echo ""

    printf "\033[1;33m🏠 Page d'accueil:\033[0m\n"
    printf "   http://%s:%s\n" "$LOCAL_IP" "$HOST_PORT_HOME"
    echo ""

    printf "\033[1;33m⚡ Bolt.DIY (via proxy):\033[0m\n"
    printf "   http://%s:%s/bolt\n" "$LOCAL_IP" "$HOST_PORT_HOME"
    echo ""

    printf "\033[1;33m⚡ Bolt.DIY (direct):\033[0m\n"
    printf "   http://%s:%s\n" "$LOCAL_IP" "$HOST_PORT_BOLT"
    echo ""

    printf "\033[1;33m👥 User Manager (via proxy):\033[0m\n"
    printf "   http://%s:%s/user-manager\n" "$LOCAL_IP" "$HOST_PORT_HOME"
    echo ""

    printf "\033[1;33m👥 User Manager (direct):\033[0m\n"
    printf "   http://%s:%s\n" "$LOCAL_IP" "$HOST_PORT_UM"
    echo ""

    printf "\033[1;36m═══════════════════════════════════════════════════════════════════════════\033[0m\n"
    printf "\033[1;37m  IDENTIFIANTS\033[0m\n"
    printf "\033[1;36m═══════════════════════════════════════════════════════════════════════════\033[0m\n"
    echo ""

    printf "\033[1;33m👤 Utilisateur:\033[0m %s\n" "$ADMIN_USER"
    printf "\033[1;33m🔑 Mot de passe:\033[0m %s\n" "$ADMIN_PASSWORD"
    echo ""

    printf "\033[1;36m═══════════════════════════════════════════════════════════════════════════\033[0m\n"
    printf "\033[1;37m  COMMANDES UTILES\033[0m\n"
    printf "\033[1;36m═══════════════════════════════════════════════════════════════════════════\033[0m\n"
    echo ""

    printf "\033[1;32mVoir les logs:\033[0m\n"
    printf "  docker compose -f %s/docker-compose.yml logs -f\n" "$PROJECT_ROOT"
    echo ""

    printf "\033[1;32mArrêter les services:\033[0m\n"
    printf "  docker compose -f %s/docker-compose.yml down\n" "$PROJECT_ROOT"
    echo ""

    printf "\033[1;32mRedémarrer les services:\033[0m\n"
    printf "  docker compose -f %s/docker-compose.yml restart\n" "$PROJECT_ROOT"
    echo ""

    printf "\033[1;32mVoir l'état des conteneurs:\033[0m\n"
    printf "  docker compose -f %s/docker-compose.yml ps\n" "$PROJECT_ROOT"
    echo ""

    printf "\033[1;36m═══════════════════════════════════════════════════════════════════════════\033[0m\n"
    printf "\033[1;37m  SANTÉ DES SERVICES\033[0m\n"
    printf "\033[1;36m═══════════════════════════════════════════════════════════════════════════\033[0m\n"
    echo ""

    printf "\033[1;32mNginx health:\033[0m\n"
    printf "  curl http://%s:%s/health\n" "$LOCAL_IP" "$HOST_PORT_HOME"
    echo ""

    printf "\033[1;32mUser Manager health:\033[0m\n"
    printf "  curl http://%s:%s/health.php\n" "$LOCAL_IP" "$HOST_PORT_UM"
    echo ""

    printf "\033[1;36m═══════════════════════════════════════════════════════════════════════════\033[0m\n"
    printf "\033[1;37m  FICHIERS IMPORTANTS\033[0m\n"
    printf "\033[1;36m═══════════════════════════════════════════════════════════════════════════\033[0m\n"
    echo ""

    printf "\033[1;33m📁 Projet:\033[0m %s\n" "$PROJECT_ROOT"
    printf "\033[1;33m⚙️  Docker Compose:\033[0m %s/docker-compose.yml\n" "$PROJECT_ROOT"
    printf "\033[1;33m🔧 Nginx Config:\033[0m %s/nginx.conf\n" "$NGINX_DIR"
    printf "\033[1;33m📊 Logs MariaDB:\033[0m %s/data\n" "$MARIADB_DIR"
    echo ""

    printf "\033[1;36m═══════════════════════════════════════════════════════════════════════════\033[0m\n"
    printf "\033[1;37m  NOUVEAUTÉS V7.3\033[0m\n"
    printf "\033[1;36m═══════════════════════════════════════════════════════════════════════════\033[0m\n"
    echo ""

    printf "\033[1;32m✅ Suppression des générateurs de fichiers source\033[0m\n"
    printf "\033[1;32m✅ Utilisation exclusive des fichiers GitHub\033[0m\n"
    printf "\033[1;32m✅ home.html → index.html (standard web)\033[0m\n"
    printf "\033[1;32m✅ Vérifications strictes avec arrêt si fichier manquant\033[0m\n"
    printf "\033[1;32m✅ Support de 4 clés API (Groq, OpenAI, Anthropic, Google)\033[0m\n"
    printf "\033[1;32m✅ Script réduit de ~170 lignes (-11%%)\033[0m\n"
    echo ""

    printf "\033[1;36m═══════════════════════════════════════════════════════════════════════════\033[0m\n"
    echo ""

    printf "\033[1;32m🎉 Installation réussie !\033[0m\n"
    printf "\033[1;37mVersion: %s | User Manager: %s\033[0m\n" "$BOLT_VERSION" "$USERMANAGER_VERSION"
    echo ""
}

#═══════════════════════════════════════════════════════════════════════════
# FONCTION PRINCIPALE
#═══════════════════════════════════════════════════════════════════════════

main() {
    # Bannière
    print_banner

    # Vérifications préalables
    check_dependencies

    # Collecte des informations
    collect_user_inputs

    # Clonage et vérifications
    clone_repository
    verify_cloned_content

    # Création structure
    create_directories

    # Génération des fichiers de configuration
    generate_nginx_conf
    generate_docker_compose
    generate_env_files
    generate_dockerfile
    generate_htpasswd

    # Copie des fichiers source
    copy_sql_files
    generate_health_php

    # Vérification finale
    final_verification

    # Lancement
    launch_docker

    # Résumé
    print_summary
}

#═══════════════════════════════════════════════════════════════════════════
# POINT D'ENTRÉE
#═══════════════════════════════════════════════════════════════════════════

main "$@"
