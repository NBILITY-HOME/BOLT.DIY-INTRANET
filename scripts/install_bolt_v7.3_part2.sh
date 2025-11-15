
#═══════════════════════════════════════════════════════════════════════════
# CLONAGE DEPUIS GITHUB
#═══════════════════════════════════════════════════════════════════════════

clone_repository() {
    print_section "CLONAGE DEPUIS GITHUB"

    # Vérifier si le dossier existe déjà
    if [ -d "$PROJECT_ROOT" ]; then
        print_warning "Le dossier $PROJECT_ROOT existe déjà"
        echo -n "Voulez-vous le supprimer et recloner ? (o/N): "
        read -r response
        if [[ "$response" =~ ^[Oo]$ ]]; then
            print_step "Suppression du dossier existant..."
            rm -rf "$PROJECT_ROOT"
            print_success "Dossier supprimé"
        else
            print_error "Installation annulée"
            exit 1
        fi
    fi

    # Créer le dossier projet
    print_step "Création du dossier projet..."
    mkdir -p "$PROJECT_ROOT"
    print_success "Dossier $PROJECT_ROOT créé"

    # Cloner le repository
    print_step "Clonage depuis GitHub..."
    print_step "Repository: $GITHUB_REPO"
    print_step "Destination: $PROJECT_ROOT"

    cd "$PROJECT_ROOT" || exit 1

    if git clone --depth 1 "$GITHUB_REPO" .; then
        print_success "Repository cloné avec succès dans $PROJECT_ROOT"
        cd "$SCRIPT_DIR"
    else
        print_error "Échec du clonage"
        cd "$SCRIPT_DIR"
        exit 1
    fi
}

#═══════════════════════════════════════════════════════════════════════════
# VÉRIFICATION DU CONTENU CLONÉ
#═══════════════════════════════════════════════════════════════════════════

verify_cloned_content() {
    print_section "VÉRIFICATION DU CONTENU CLONÉ"

    local critical_ok=true
    local all_ok=true

    # Vérifier bolt.diy/
    if [ -d "$BOLTDIY_DIR" ]; then
        print_success "Dossier bolt.diy/ présent"
    else
        print_error "Dossier bolt.diy/ manquant dans le clone"
        critical_ok=false
    fi

    # Vérifier DATA-LOCAL/
    if [ -d "$DATA_LOCAL_DIR" ]; then
        print_success "Dossier DATA-LOCAL/ présent"
    else
        print_error "Dossier DATA-LOCAL/ manquant dans le clone"
        critical_ok=false
    fi

    # Vérifier user-manager/
    if [ -d "$USERMANAGER_DIR" ]; then
        print_success "Dossier user-manager/ présent"
    else
        print_error "Dossier user-manager/ manquant dans le clone"
        critical_ok=false
    fi

    # Vérifier .env.example de Bolt.DIY
    if [ -f "$BOLTDIY_DIR/.env.example" ]; then
        print_success "Fichier bolt.diy/.env.example présent"
    else
        print_error "Fichier bolt.diy/.env.example manquant"
        critical_ok=false
    fi

    # Vérifier index.html (PAS home.html)
    if [ -f "$NGINX_DIR/index.html" ]; then
        print_success "Fichier index.html présent"
    else
        print_error "Fichier index.html manquant dans le repository GitHub"
        print_error "Le repository doit contenir: DATA-LOCAL/nginx/index.html"
        critical_ok=false
    fi

    if [ "$critical_ok" = false ]; then
        print_error "Le clone est incomplet ou le repository est corrompu"
        exit 1
    fi

    print_success "Tous les dossiers critiques sont présents"

    # Vérification détaillée User Manager
    print_step "Vérification détaillée de User Manager..."

    # Fichiers essentiels
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
        print_error "composer.json manquant CRITIQUE"
        critical_ok=false
    fi

    if [ -f "$USERMANAGER_DIR/.gitignore" ]; then
        print_success ".gitignore présent"
    else
        print_warning ".gitignore manquant"
    fi

    # Fichiers de configuration
    print_step "Vérification des fichiers de configuration..."

    if [ -d "$USERMANAGER_DIR/app/src/Controllers" ]; then
        CONTROLLER_COUNT=$(find "$USERMANAGER_DIR/app/src/Controllers" -name "*.php" 2>/dev/null | wc -l)
        if [ "$CONTROLLER_COUNT" -gt 0 ]; then
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
        if [ "$MODEL_COUNT" -gt 0 ]; then
            print_success "Models: $MODEL_COUNT fichiers"
        else
            print_error "Dossier Models vide"
            critical_ok=false
        fi
    else
        print_error "Dossier Models manquant"
        critical_ok=false
    fi

    if [ -d "$USERMANAGER_DIR/app/public" ]; then
        HTML_COUNT=$(find "$USERMANAGER_DIR/app/public" -name "*.html" 2>/dev/null | wc -l)
        if [ "$HTML_COUNT" -gt 0 ]; then
            print_success "Fichiers HTML: $HTML_COUNT fichiers"
        else
            print_warning "Aucun fichier HTML dans public/"
        fi
    else
        print_warning "Dossier public/ manquant"
    fi

    # Vérifier les fichiers SQL
    print_step "Vérification des fichiers SQL..."

    if [ -f "$USERMANAGER_DIR/app/database/migrations/01-schema.sql" ]; then
        print_success "01-schema.sql présent"
    else
        print_error "01-schema.sql manquant dans le repository"
        print_error "Chemin attendu: DATA-LOCAL/user-manager/app/database/migrations/01-schema.sql"
        critical_ok=false
    fi

    if [ -f "$USERMANAGER_DIR/app/database/migrations/02-seed.sql" ]; then
        print_success "02-seed.sql présent"
    else
        print_error "02-seed.sql manquant dans le repository"
        print_error "Chemin attendu: DATA-LOCAL/user-manager/app/database/migrations/02-seed.sql"
        critical_ok=false
    fi

    if [ "$critical_ok" = false ]; then
        print_error "Fichiers critiques manquants - Installation impossible"
        print_error "Vérifiez le repository GitHub ou contactez le support"
        exit 1
    fi

    if [ "$all_ok" = true ]; then
        print_success "Vérification complète réussie"
    else
        print_warning "Vérification réussie avec quelques avertissements"
    fi
}

#═══════════════════════════════════════════════════════════════════════════
# CRÉATION DES DOSSIERS
#═══════════════════════════════════════════════════════════════════════════

create_directories() {
    print_section "CRÉATION DES DOSSIERS"

    # Créer dossier MariaDB
    print_step "Création des dossiers MariaDB..."
    mkdir -p "$MARIADB_DIR/init"
    mkdir -p "$MARIADB_DIR/data"
    print_success "Dossiers MariaDB créés"

    # Créer dossiers User Manager supplémentaires
    print_step "Création des dossiers User Manager..."
    mkdir -p "$USERMANAGER_DIR/app/logs"
    mkdir -p "$USERMANAGER_DIR/app/uploads"
    print_success "Dossiers User Manager créés"

    # Vérifier les permissions
    print_step "Vérification des permissions..."
    chmod -R 755 "$PROJECT_ROOT"
    chmod -R 777 "$USERMANAGER_DIR/app/logs"
    chmod -R 777 "$USERMANAGER_DIR/app/uploads"
    chmod -R 777 "$MARIADB_DIR/data"
    print_success "Permissions configurées"

    print_success "Structure de dossiers créée"
}
