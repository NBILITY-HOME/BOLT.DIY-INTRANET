#═══════════════════════════════════════════════════════════════════════════
# LANCEMENT DES CONTENEURS DOCKER
#═══════════════════════════════════════════════════════════════════════════

launch_docker() {
    print_section "LANCEMENT DES CONTENEURS DOCKER"

    cd "$PROJECT_ROOT" || exit 1

    print_step "Arrêt des conteneurs existants..."
    docker compose down 2>/dev/null || true
    print_success "Conteneurs arrêtés"

    print_step "Construction et démarrage des conteneurs..."
    if docker compose up -d --build; then
        print_success "Conteneurs démarrés avec succès"
    else
        print_error "Échec du démarrage des conteneurs"
        print_info "Consultez les logs avec: docker compose logs -f"
        exit 1
    fi

    print_step "Attente du démarrage complet (30 secondes)..."
    sleep 30

    print_step "Vérification de l'état des conteneurs..."
    docker compose ps

    print_success "Déploiement terminé"
}

#═══════════════════════════════════════════════════════════════════════════
# RÉSUMÉ DE L'INSTALLATION
#═══════════════════════════════════════════════════════════════════════════

print_summary() {
    print_section "INSTALLATION TERMINÉE"

    echo -e "${GREEN}✓ Bolt.DIY v7.4 installé avec succès !${NC}"
    echo ""
    echo -e "${CYAN}═══════════════════════════════════════════════════════════════════════════${NC}"
    echo -e "${CYAN}  INFORMATIONS D'ACCÈS${NC}"
    echo -e "${CYAN}═══════════════════════════════════════════════════════════════════════════${NC}"
    echo ""
    echo -e "${YELLOW}📱 Page d'accueil:${NC}"
    echo -e "   ${BLUE}http://$LOCAL_IP:$HOST_PORT_HOME${NC}"
    echo ""
    echo -e "${YELLOW}🤖 Bolt.DIY (Application):${NC}"
    echo -e "   ${BLUE}http://$LOCAL_IP:$HOST_PORT_BOLT${NC}"
    echo ""
    echo -e "${YELLOW}👥 User Manager:${NC}"
    echo -e "   ${BLUE}http://$LOCAL_IP:$HOST_PORT_UM${NC}"
    echo ""
    echo -e "${CYAN}───────────────────────────────────────────────────────────────────────────${NC}"
    echo ""
    echo -e "${YELLOW}🔐 Identifiants Admin:${NC}"
    echo -e "   Utilisateur: ${GREEN}$ADMIN_USER${NC}"
    echo -e "   Mot de passe: ${GREEN}****** (celui que vous avez défini)${NC}"
    echo ""
    echo -e "${CYAN}═══════════════════════════════════════════════════════════════════════════${NC}"
    echo -e "${CYAN}  COMMANDES UTILES${NC}"
    echo -e "${CYAN}═══════════════════════════════════════════════════════════════════════════${NC}"
    echo ""
    echo -e "${YELLOW}Voir les logs:${NC}"
    echo -e "   ${BLUE}cd $PROJECT_ROOT && docker compose logs -f${NC}"
    echo ""
    echo -e "${YELLOW}Redémarrer:${NC}"
    echo -e "   ${BLUE}cd $PROJECT_ROOT && docker compose restart${NC}"
    echo ""
    echo -e "${YELLOW}Arrêter:${NC}"
    echo -e "   ${BLUE}cd $PROJECT_ROOT && docker compose down${NC}"
    echo ""
    echo -e "${YELLOW}Mettre à jour depuis GitHub:${NC}"
    echo -e "   ${BLUE}cd $PROJECT_ROOT && git pull${NC}"
    echo ""
    echo -e "${CYAN}═══════════════════════════════════════════════════════════════════════════${NC}"
    echo ""
    echo -e "${GREEN}✨ Profitez de Bolt.DIY - Nbility Edition !${NC}"
    echo ""
}

#═══════════════════════════════════════════════════════════════════════════
# FONCTION PRINCIPALE
#═══════════════════════════════════════════════════════════════════════════

main() {
    print_banner
    check_dependencies
    collect_user_inputs
    clone_repository
    verify_github_structure
    verify_docker_compose
    create_directories
    generate_main_env
    generate_boltdiy_env
    generate_usermanager_env
    generate_htpasswd
    configure_sql_placeholders
    final_verification
    launch_docker
    print_summary
}

# Lancer l'installation
main
