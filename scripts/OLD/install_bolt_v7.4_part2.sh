#═══════════════════════════════════════════════════════════════════════════
# CLONAGE DEPUIS GITHUB
#═══════════════════════════════════════════════════════════════════════════

clone_repository() {
    print_section "CLONAGE DEPUIS GITHUB"

    # Supprimer le dossier existant si présent
    if [ -d "$PROJECT_ROOT" ]; then
        print_warning "Le dossier $PROJECT_ROOT existe déjà"
        echo -n "Voulez-vous le supprimer et recommencer? (o/N): "
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

    # Créer le dossier et cloner
    print_step "Création du dossier projet..."
    mkdir -p "$PROJECT_ROOT"
    print_success "Dossier $PROJECT_ROOT créé"

    print_step "Clonage depuis GitHub..."
    print_info "Repository: $GITHUB_REPO"
    print_info "Destination: $PROJECT_ROOT"

    if git clone "$GITHUB_REPO" "$PROJECT_ROOT"; then
        print_success "Repository cloné avec succès dans $PROJECT_ROOT"
    else
        print_error "Échec du clonage depuis GitHub"
        print_error "Vérifiez votre connexion internet et l'URL du repository"
        exit 1
    fi
}

#═══════════════════════════════════════════════════════════════════════════
# VÉRIFICATION DE LA STRUCTURE GITHUB
#═══════════════════════════════════════════════════════════════════════════

verify_github_structure() {
    print_section "VÉRIFICATION DU CONTENU GITHUB"

    local critical_ok=true

    # Vérifier la structure de base
    print_step "Vérification de la structure de base..."

    local required_dirs=(
        "$BOLTDIY_DIR"
        "$DATA_LOCAL_DIR"
        "$USERMANAGER_DIR"
    )

    for dir in "${required_dirs[@]}"; do
        if [ -d "$dir" ]; then
            print_success "Dossier $(basename $dir)/ présent"
        else
            print_error "Dossier $(basename $dir)/ manquant dans le repository GitHub"
            critical_ok=false
        fi
    done

    # Vérifier docker-compose.yml
    if [ -f "$PROJECT_ROOT/docker-compose.yml" ]; then
        print_success "Fichier docker-compose.yml présent"
    else
        print_error "Fichier docker-compose.yml manquant dans le repository GitHub"
        print_error "Le repository doit contenir: docker-compose.yml à la racine"
        critical_ok=false
    fi

    # Vérifier .env.example Bolt.DIY
    if [ -f "$BOLTDIY_DIR/.env.example" ]; then
        print_success "Fichier bolt.diy/.env.example présent"
    else
        print_error "Fichier bolt.diy/.env.example manquant"
        critical_ok=false
    fi

    # Vérifier nginx/html/index.html
    if [ -f "$NGINX_DIR/html/index.html" ]; then
        print_success "Fichier index.html présent"
    else
        print_error "Fichier index.html manquant dans le repository GitHub"
        print_error "Le repository doit contenir: DATA-LOCAL/nginx/html/index.html"
        critical_ok=false
    fi

    # Vérifier nginx.conf
    if [ -f "$NGINX_DIR/nginx.conf" ]; then
        print_success "Fichier nginx.conf présent"
    else
        print_error "Fichier nginx.conf manquant dans le repository GitHub"
        print_error "Le repository doit contenir: DATA-LOCAL/nginx/nginx.conf"
        critical_ok=false
    fi

    if [ "$critical_ok" = true ]; then
        print_success "Tous les fichiers critiques sont présents"
    else
        print_error "Le clone est incomplet ou le repository est corrompu"
        print_error "Vérifiez que $GITHUB_REPO est à jour"
        exit 1
    fi

    # Vérifier User Manager
    print_step "Vérification détaillée de User Manager..."

    local um_files=(
        "$USERMANAGER_DIR/composer.json"
        "$USERMANAGER_DIR/Dockerfile"
        "$USERMANAGER_DIR/.env.example"
        "$USERMANAGER_DIR/app/database/migrations/01-schema.sql"
        "$USERMANAGER_DIR/app/database/migrations/02-seed.sql"
    )

    for file in "${um_files[@]}"; do
        if [ -f "$file" ]; then
            print_success "$(basename $file) présent"
        else
            print_warning "$(basename $file) manquant (optionnel)"
        fi
    done

    # Vérifier les fichiers SQL
    print_step "Vérification des fichiers SQL..."

    if [ -f "$USERMANAGER_DIR/app/database/migrations/01-schema.sql" ]; then
        print_success "01-schema.sql présent"
    else
        print_error "01-schema.sql manquant"
        critical_ok=false
    fi

    if [ -f "$USERMANAGER_DIR/app/database/migrations/02-seed.sql" ]; then
        print_success "02-seed.sql présent"
    else
        print_error "02-seed.sql manquant"
        critical_ok=false
    fi

    if [ "$critical_ok" = false ]; then
        print_error "Des fichiers SQL critiques sont manquants"
        exit 1
    fi

    print_success "Vérification complète réussie"
}

#═══════════════════════════════════════════════════════════════════════════
# VÉRIFICATION ET CORRECTION DE DOCKER-COMPOSE.YML
#═══════════════════════════════════════════════════════════════════════════

verify_docker_compose() {
    print_section "VÉRIFICATION DOCKER-COMPOSE.YML"

    print_step "Vérification du fichier docker-compose.yml..."

    local compose_file="$PROJECT_ROOT/docker-compose.yml"

    if [ ! -f "$compose_file" ]; then
        print_error "docker-compose.yml manquant dans le repository GitHub"
        exit 1
    fi

    # Supprimer 'version:' si présent (obsolète)
    if grep -q "^version:" "$compose_file"; then
        print_warning "Suppression de 'version:' (obsolète)..."
        sed -i '/^version:/d' "$compose_file"
        print_success "'version:' supprimé"
    fi

    # Vérifier que --legacy-peer-deps est présent pour npm
    if ! grep -q "legacy-peer-deps" "$compose_file"; then
        print_warning "Ajout de --legacy-peer-deps à npm install..."
        sed -i 's/npm install &&/npm install --legacy-peer-deps \&\&/' "$compose_file"
        print_success "--legacy-peer-deps ajouté"
    fi

    # Vérifier le nom de la base de données
    if grep -q "bolt_usermanager" "$compose_file"; then
        print_warning "Correction du nom de base de données..."
        sed -i 's/bolt_usermanager/usermanager/g' "$compose_file"
        print_success "Nom de DB corrigé: usermanager"
    fi

    print_success "docker-compose.yml vérifié et corrigé"
}

#═══════════════════════════════════════════════════════════════════════════
# CRÉATION DES DOSSIERS RUNTIME
#═══════════════════════════════════════════════════════════════════════════

create_directories() {
    print_section "CRÉATION DES DOSSIERS"

    print_step "Création des dossiers MariaDB..."
    mkdir -p "$MARIADB_DIR/data"
    mkdir -p "$MARIADB_DIR/init"
    print_success "Dossiers MariaDB créés"

    print_step "Création des dossiers User Manager..."
    mkdir -p "$USERMANAGER_DIR/app/logs"
    mkdir -p "$USERMANAGER_DIR/app/uploads"
    print_success "Dossiers User Manager créés"

    print_step "Vérification des permissions..."
    chmod -R 755 "$PROJECT_ROOT"
    chmod -R 777 "$USERMANAGER_DIR/app/logs" 2>/dev/null || true
    chmod -R 777 "$USERMANAGER_DIR/app/uploads" 2>/dev/null || true
    chmod -R 777 "$MARIADB_DIR/data" 2>/dev/null || true
    print_success "Permissions configurées"

    print_success "Structure de dossiers créée"
}
