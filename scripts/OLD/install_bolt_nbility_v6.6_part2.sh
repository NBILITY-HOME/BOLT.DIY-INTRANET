
# ═══════════════════════════════════════════════════════════════════════════
# FONCTION: Configuration interactive (SYNTAXE CORRIGÉE)
# ═══════════════════════════════════════════════════════════════════════════
get_configuration() {
    print_section "CONFIGURATION DU SYSTÈME"

    # IP Locale
    print_step "Détection de l'IP locale..."
    DETECTED_IP=$(hostname -I | awk '{print $1}')
    echo -e "${CYAN}IP détectée: ${WHITE}$DETECTED_IP${NC}"
    echo -ne "${YELLOW}Confirmer ou entrer l'IP: ${NC}"
    read input_ip
    LOCAL_IP=${input_ip:-$DETECTED_IP}
    print_success "IP configurée: $LOCAL_IP"
    echo ""

    # IP Gateway
    print_step "Configuration de la gateway (box/routeur)..."
    DETECTED_GW=$(ip route | grep default | awk '{print $3}' | head -n1)
    echo -e "${CYAN}Gateway détectée: ${WHITE}$DETECTED_GW${NC}"
    echo -ne "${YELLOW}Confirmer ou entrer la gateway: ${NC}"
    read input_gw
    GATEWAY_IP=${input_gw:-$DETECTED_GW}
    print_success "Gateway configurée: $GATEWAY_IP"
    echo ""

    # Ports
    print_step "Configuration des ports..."
    echo ""

    while true; do
        echo -ne "${YELLOW}Port pour Bolt.DIY [défaut: 8585]: ${NC}"
        read input_bolt
        HOST_PORT_BOLT=${input_bolt:-8585}
        if check_port_available $HOST_PORT_BOLT "Bolt.DIY"; then
            break
        fi
    done

    while true; do
        echo -ne "${YELLOW}Port pour Home [défaut: 8686]: ${NC}"
        read input_home
        HOST_PORT_HOME=${input_home:-8686}
        if check_port_available $HOST_PORT_HOME "Home"; then
            break
        fi
    done

    while true; do
        echo -ne "${YELLOW}Port pour User Manager [défaut: 8687]: ${NC}"
        read input_um
        HOST_PORT_UM=${input_um:-8687}
        if check_port_available $HOST_PORT_UM "User Manager"; then
            break
        fi
    done

    echo ""

    # Authentification NGINX
    print_step "Configuration de l'authentification NGINX..."
    echo ""
    echo -ne "${YELLOW}Nom d'utilisateur: ${NC}"
    read NGINX_USER
    while true; do
        echo -ne "${YELLOW}Mot de passe: ${NC}"
        read -s NGINX_PASS
        echo ""
        echo -ne "${YELLOW}Confirmer le mot de passe: ${NC}"
        read -s NGINX_PASS_CONFIRM
        echo ""
        if [ "$NGINX_PASS" = "$NGINX_PASS_CONFIRM" ]; then
            break
        else
            print_error "Les mots de passe ne correspondent pas"
        fi
    done
    print_success "Authentification NGINX configurée"
    echo ""

    # Super Admin
    print_step "Configuration du Super Admin..."
    echo ""
    echo -ne "${YELLOW}Username Super Admin: ${NC}"
    read ADMIN_USERNAME
    echo -ne "${YELLOW}Email Super Admin: ${NC}"
    read ADMIN_EMAIL
    while true; do
        echo -ne "${YELLOW}Mot de passe Super Admin: ${NC}"
        read -s ADMIN_PASSWORD
        echo ""
        echo -ne "${YELLOW}Confirmer le mot de passe: ${NC}"
        read -s ADMIN_PASSWORD_CONFIRM
        echo ""
        if [ "$ADMIN_PASSWORD" = "$ADMIN_PASSWORD_CONFIRM" ]; then
            break
        else
            print_error "Les mots de passe ne correspondent pas"
        fi
    done
    print_success "Super Admin configuré"
    echo ""

    # Génération des mots de passe BDD
    print_step "Génération des mots de passe MariaDB..."
    MARIADB_ROOT_PASSWORD=$(generate_secure_password 32)
    MARIADB_USER_PASSWORD=$(generate_secure_password 32)
    APP_SECRET=$(generate_app_secret)
    print_success "Mots de passe générés automatiquement"
    echo ""

    # API Keys (optionnel)
    print_step "Configuration des API Keys (optionnel - Entrée pour ignorer)..."
    echo ""
    echo -ne "${CYAN}Anthropic API Key: ${NC}"
    read ANTHROPIC_KEY
    echo -ne "${CYAN}OpenAI API Key: ${NC}"
    read OPENAI_KEY
    echo -ne "${CYAN}Google Gemini API Key: ${NC}"
    read GEMINI_KEY
    echo -ne "${CYAN}Groq API Key: ${NC}"
    read GROQ_KEY
    echo -ne "${CYAN}Mistral API Key: ${NC}"
    read MISTRAL_KEY
    echo -ne "${CYAN}DeepSeek API Key: ${NC}"
    read DEEPSEEK_KEY
    echo -ne "${CYAN}HuggingFace API Key: ${NC}"
    read HF_KEY

    echo ""
    print_success "Configuration terminée"
    echo ""
}

clone_repository() {
    print_section "CLONAGE DU REPOSITORY GITHUB"

    if [ -d "$INSTALL_DIR" ]; then
        print_warning "Le répertoire $REPO_NAME existe déjà"
        echo -ne "${YELLOW}Supprimer et re-cloner ? (o/N): ${NC}"
        read confirm
        if [[ "$confirm" =~ ^[Oo]$ ]]; then
            print_step "Suppression de l'ancien répertoire..."
            rm -rf "$INSTALL_DIR"
            print_success "Répertoire supprimé"
        else
            print_info "Utilisation du répertoire existant"
            return 0
        fi
    fi

    print_step "Clonage depuis $REPO_URL..."
    if git clone "$REPO_URL" "$INSTALL_DIR"; then
        print_success "Repository cloné avec succès"
    else
        print_error "Échec du clonage"
        exit 1
    fi

    echo ""
}

create_directory_structure() {
    print_section "CRÉATION DE LA STRUCTURE DE RÉPERTOIRES"

    print_step "Création des répertoires..."

    mkdir -p "$NGINX_DIR"
    mkdir -p "$MARIADB_DIR/init"
    mkdir -p "$USERMANAGER_DIR/app"
    mkdir -p "$USERMANAGER_DIR/app/config"
    mkdir -p "$USERMANAGER_DIR/app/includes"
    mkdir -p "$USERMANAGER_DIR/app/models"
    mkdir -p "$USERMANAGER_DIR/app/controllers"
    mkdir -p "$USERMANAGER_DIR/app/views"
    mkdir -p "$USERMANAGER_DIR/app/assets"
    mkdir -p "$USERMANAGER_DIR/uploads"
    mkdir -p "$USERMANAGER_DIR/backups"

    print_success "Structure créée"
    echo ""
}
