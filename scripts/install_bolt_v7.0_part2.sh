
#═══════════════════════════════════════════════════════════════════════════
# FONCTION: Configuration interactive
#═══════════════════════════════════════════════════════════════════════════
get_configuration() {
    print_section "CONFIGURATION"

    # Détection IP automatique
    DEFAULT_IP=$(hostname -I | awk '{print $1}')
    if [ -z "$DEFAULT_IP" ]; then
        DEFAULT_IP="127.0.0.1"
    fi

    echo -e "${BOLD}Configuration du serveur:${NC}"
    echo ""

    # IP
    read -p "Adresse IP du serveur [$DEFAULT_IP]: " LOCAL_IP
    LOCAL_IP=${LOCAL_IP:-$DEFAULT_IP}
    print_success "IP: $LOCAL_IP"
    echo ""

    # Ports
    echo -e "${BOLD}Configuration des ports:${NC}"
    read -p "Port Bolt.DIY [8080]: " HOST_PORT_BOLT
    HOST_PORT_BOLT=${HOST_PORT_BOLT:-8080}

    read -p "Port Page d'accueil [8686]: " HOST_PORT_HOME
    HOST_PORT_HOME=${HOST_PORT_HOME:-8686}

    read -p "Port User Manager [8787]: " HOST_PORT_UM
    HOST_PORT_UM=${HOST_PORT_UM:-8787}

    print_success "Ports: Bolt=$HOST_PORT_BOLT, Home=$HOST_PORT_HOME, UM=$HOST_PORT_UM"
    echo ""

    # Compte admin
    echo -e "${BOLD}Compte administrateur:${NC}"
    read -p "Nom d'utilisateur [admin]: " ADMIN_USER
    ADMIN_USER=${ADMIN_USER:-admin}

    while true; do
        read -sp "Mot de passe admin: " ADMIN_PASSWORD
        echo ""
        if [ ${#ADMIN_PASSWORD} -ge 8 ]; then
            read -sp "Confirmer le mot de passe: " ADMIN_PASSWORD_CONFIRM
            echo ""
            if [ "$ADMIN_PASSWORD" = "$ADMIN_PASSWORD_CONFIRM" ]; then
                break
            else
                print_error "Les mots de passe ne correspondent pas"
            fi
        else
            print_error "Le mot de passe doit contenir au moins 8 caractères"
        fi
    done
    print_success "Compte admin configuré"
    echo ""

    # Mots de passe base de données
    print_step "Génération des mots de passe sécurisés..."
    MARIADB_ROOT_PASSWORD=$(generate_password)
    MARIADB_USER_PASSWORD=$(generate_password)
    APP_SECRET=$(generate_password)
    print_success "Mots de passe générés"
    echo ""

    # Clés API (optionnel)
    echo -e "${BOLD}Clés API LLM (optionnel, Entrée pour skip):${NC}"
    read -p "OpenAI API Key: " OPENAI_API_KEY
    read -p "Anthropic API Key: " ANTHROPIC_API_KEY
    read -p "Google API Key: " GOOGLE_API_KEY
    read -p "Groq API Key: " GROQ_API_KEY
    echo ""

    # Résumé
    echo -e "${BOLD}${GREEN}Configuration terminée:${NC}"
    echo "  • IP: $LOCAL_IP"
    echo "  • Port Bolt.DIY: $HOST_PORT_BOLT"
    echo "  • Port Home: $HOST_PORT_HOME"
    echo "  • Port User Manager: $HOST_PORT_UM"
    echo "  • Admin: $ADMIN_USER"
    echo ""
}

#═══════════════════════════════════════════════════════════════════════════
# FONCTION: Clonage du repository GitHub
#═══════════════════════════════════════════════════════════════════════════
clone_repository() {
    print_section "CLONAGE DU REPOSITORY GITHUB"

    # Supprimer clone précédent si existe
    if [ -d "$CLONE_DIR" ]; then
        print_step "Suppression du clone précédent..."
        rm -rf "$CLONE_DIR"
    fi

    # Clone
    print_step "Clonage depuis GitHub..."
    print_step "Repository: $GITHUB_REPO"

    if git clone --depth 1 "$GITHUB_REPO" "$CLONE_DIR"; then
        print_success "Repository cloné avec succès"
    else
        print_error "Échec du clonage"
        exit 1
    fi

    # Vérifier présence User Manager
    if [ ! -d "$CLONE_DIR/DATA-LOCAL/user-manager" ]; then
        print_error "Dossier User Manager introuvable dans le clone"
        exit 1
    fi

    # Copier User Manager vers DATA-LOCAL
    print_step "Copie User Manager depuis le clone..."

    mkdir -p "$USERMANAGER_DIR"

    # Copier TOUT le contenu User Manager
    if cp -r "$CLONE_DIR/DATA-LOCAL/user-manager/"* "$USERMANAGER_DIR/" 2>/dev/null; then
        print_success "User Manager copié"
    else
        print_error "Échec de la copie User Manager"
        exit 1
    fi

    # Créer les dossiers runtime (pas dans Git)
    print_step "Création des dossiers runtime..."
    mkdir -p "$USERMANAGER_DIR/app/logs"
    mkdir -p "$USERMANAGER_DIR/app/cache"
    mkdir -p "$USERMANAGER_DIR/uploads"
    mkdir -p "$USERMANAGER_DIR/backups"

    # Permissions
    chmod -R 755 "$USERMANAGER_DIR/app" 2>/dev/null || true
    chmod +x "$USERMANAGER_DIR/app/scripts/"*.sh 2>/dev/null || true

    print_success "Dossiers runtime créés"

    # Copier autres dossiers si nécessaires
    print_step "Copie des autres composants..."
    mkdir -p "$NGINX_DIR"
    mkdir -p "$MARIADB_DIR/init"

    print_success "Structure de répertoires prête"
    echo ""
}

#═══════════════════════════════════════════════════════════════════════════
# FONCTION: Vérification des fichiers GitHub
#═══════════════════════════════════════════════════════════════════════════
verify_github_files() {
    print_section "VÉRIFICATION DES FICHIERS GITHUB"

    local all_ok=true
    local critical_ok=true

    print_step "Vérification User Manager v2.0..."
    echo ""

    # Fichiers de configuration
    if [ -f "$USERMANAGER_DIR/README.md" ]; then
        print_success "README.md présent"
    else
        print_warning "README.md manquant"
        all_ok=false
    fi

    if [ -f "$USERMANAGER_DIR/.env.example" ]; then
        print_success ".env.example présent"
    else
        print_warning ".env.example manquant"
        all_ok=false
    fi

    if [ -f "$USERMANAGER_DIR/composer.json" ]; then
        print_success "composer.json présent"
    else
        print_error "composer.json manquant (CRITIQUE)"
        critical_ok=false
    fi

    if [ -f "$USERMANAGER_DIR/.gitignore" ]; then
        print_success ".gitignore présent"
    else
        print_warning ".gitignore manquant"
    fi

    # Structure backend
    if [ -d "$USERMANAGER_DIR/app/src/Controllers" ]; then
        CONTROLLER_COUNT=$(find "$USERMANAGER_DIR/app/src/Controllers" -name "*.php" 2>/dev/null | wc -l)
        if [ $CONTROLLER_COUNT -gt 0 ]; then
            print_success "Controllers: $CONTROLLER_COUNT fichiers"
        else
            print_error "Dossier Controllers vide"
            critical_ok=false
        fi
    else
        print_error "Dossier Controllers manquant"
        critical_ok=false
    fi

    if [ -d "$USERMANAGER_DIR/app/src/Models" ]; then
        MODEL_COUNT=$(find "$USERMANAGER_DIR/app/src/Models" -name "*.php" 2>/dev/null | wc -l)
        if [ $MODEL_COUNT -gt 0 ]; then
            print_success "Models: $MODEL_COUNT fichiers"
        else
            print_error "Dossier Models vide"
            critical_ok=false
        fi
    else
        print_error "Dossier Models manquant"
        critical_ok=false
    fi

    if [ -d "$USERMANAGER_DIR/app/src/Middleware" ]; then
        MIDDLEWARE_COUNT=$(find "$USERMANAGER_DIR/app/src/Middleware" -name "*.php" 2>/dev/null | wc -l)
        if [ $MIDDLEWARE_COUNT -gt 0 ]; then
            print_success "Middleware: $MIDDLEWARE_COUNT fichiers"
        else
            print_warning "Dossier Middleware vide"
        fi
    fi

    if [ -d "$USERMANAGER_DIR/app/src/Utils" ]; then
        UTILS_COUNT=$(find "$USERMANAGER_DIR/app/src/Utils" -name "*.php" 2>/dev/null | wc -l)
        if [ $UTILS_COUNT -gt 0 ]; then
            print_success "Utils: $UTILS_COUNT fichiers"
        else
            print_warning "Dossier Utils vide"
        fi
    fi

    # Frontend
    if [ -d "$USERMANAGER_DIR/app/public/assets/js" ]; then
        JS_COUNT=$(find "$USERMANAGER_DIR/app/public/assets/js" -name "*.js" 2>/dev/null | wc -l)
        if [ $JS_COUNT -ge 9 ]; then
            print_success "JavaScript: $JS_COUNT fichiers (attendu: 9)"
        else
            print_warning "JavaScript: $JS_COUNT fichiers (incomplet, attendu: 9)"
        fi
    else
        print_error "Dossier JavaScript manquant"
        critical_ok=false
    fi

    if [ -d "$USERMANAGER_DIR/app/public/assets/css" ]; then
        CSS_COUNT=$(find "$USERMANAGER_DIR/app/public/assets/css" -name "*.css" 2>/dev/null | wc -l)
        if [ $CSS_COUNT -gt 0 ]; then
            print_success "CSS: $CSS_COUNT fichier(s)"
        fi
    fi

    # Pages HTML
    if [ -d "$USERMANAGER_DIR/app/public" ]; then
        HTML_COUNT=$(find "$USERMANAGER_DIR/app/public" -maxdepth 1 -name "*.html" 2>/dev/null | wc -l)
        if [ $HTML_COUNT -ge 6 ]; then
            print_success "Pages HTML: $HTML_COUNT fichiers (attendu: 6)"
        else
            print_warning "Pages HTML: $HTML_COUNT fichiers (incomplet, attendu: 6)"
        fi
    fi

    # Scripts
    if [ -f "$USERMANAGER_DIR/app/scripts/backup.sh" ]; then
        print_success "Script backup.sh présent"
    else
        print_warning "backup.sh manquant"
    fi

    if [ -f "$USERMANAGER_DIR/app/scripts/maintenance.sh" ]; then
        print_success "Script maintenance.sh présent"
    else
        print_warning "maintenance.sh manquant"
    fi

    # Base de données
    if [ -f "$USERMANAGER_DIR/app/database/migrations/01-schema.sql" ]; then
        print_success "Schema SQL présent"
    else
        print_warning "Schema SQL manquant"
    fi

    if [ -f "$USERMANAGER_DIR/app/database/migrations/02-seed.sql" ]; then
        print_success "Seed SQL présent"
    else
        print_warning "Seed SQL manquant"
    fi

    echo ""

    if [ "$critical_ok" = false ]; then
        print_error "Fichiers critiques manquants, installation impossible"
        exit 1
    elif [ "$all_ok" = true ]; then
        print_success "Tous les fichiers sont présents"
    else
        print_warning "Certains fichiers optionnels sont manquants"
        print_warning "L'installation va continuer..."
    fi

    echo ""
}

#═══════════════════════════════════════════════════════════════════════════
# FONCTION: Installation des dépendances Composer (optionnel)
#═══════════════════════════════════════════════════════════════════════════
install_composer_dependencies() {
    print_section "DÉPENDANCES COMPOSER"

    if [ -f "$USERMANAGER_DIR/composer.json" ]; then
        print_step "Vérification Composer..."

        if command -v composer &> /dev/null; then
            print_step "Installation des dépendances PHP..."
            cd "$USERMANAGER_DIR"

            if composer install --no-dev --optimize-autoloader 2>&1 | tee /tmp/composer_install.log; then
                print_success "Dépendances installées avec succès"
            else
                print_warning "Erreur lors de l'installation des dépendances"
                print_warning "Elles seront installées dans le conteneur Docker"
            fi

            cd "$SCRIPT_DIR"
        else
            print_warning "Composer non installé localement"
            print_warning "Les dépendances seront installées dans le conteneur"
        fi
    else
        print_warning "composer.json non trouvé, skip"
    fi

    echo ""
}
