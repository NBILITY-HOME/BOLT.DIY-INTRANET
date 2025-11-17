#═══════════════════════════════════════════════════════════════════════════
# GÉNÉRATION .HTPASSWD
#═══════════════════════════════════════════════════════════════════════════

generate_htpasswd() {
    print_section "GÉNÉRATION .HTPASSWD"

    print_step "Création du fichier .htpasswd..."

    # Créer .htpasswd avec htpasswd (compatible nginx)
    htpasswd -cb "$NGINX_DIR/.htpasswd" "$ADMIN_USER" "$ADMIN_PASSWORD"

    print_success ".htpasswd créé avec utilisateur: $ADMIN_USER"
}

#═══════════════════════════════════════════════════════════════════════════
# CONFIGURATION DES PLACEHOLDERS SQL
#═══════════════════════════════════════════════════════════════════════════

configure_sql_placeholders() {
    print_section "CONFIGURATION DES FICHIERS SQL"

    local schema_sql="$USERMANAGER_DIR/app/database/migrations/01-schema.sql"
    local seed_sql="$USERMANAGER_DIR/app/database/migrations/02-seed.sql"

    # Copier les fichiers SQL dans mariadb/init
    print_step "Copie de 01-schema.sql vers mariadb/init..."

    if [ -f "$schema_sql" ]; then
        cp "$schema_sql" "$MARIADB_DIR/init/"
        print_success "01-schema.sql copié"

        # Vérifier et corriger le nom de la base de données
        if grep -q "bolt_usermanager" "$MARIADB_DIR/init/01-schema.sql"; then
            print_warning "Correction du nom de DB dans 01-schema.sql..."
            sed -i 's/bolt_usermanager/usermanager/g' "$MARIADB_DIR/init/01-schema.sql"
        fi

        # Supprimer les lignes "USE ..." si présentes (Docker crée automatiquement la DB)
        if grep -q "^USE " "$MARIADB_DIR/init/01-schema.sql"; then
            print_warning "Suppression de 'USE ...' dans 01-schema.sql..."
            sed -i '/^USE /d' "$MARIADB_DIR/init/01-schema.sql"
        fi
    else
        print_error "01-schema.sql manquant dans le repository"
        exit 1
    fi

    # Copier et configurer 02-seed.sql
    print_step "Copie de 02-seed.sql vers mariadb/init..."

    if [ -f "$seed_sql" ]; then
        cp "$seed_sql" "$MARIADB_DIR/init/"

        print_step "Configuration de l'utilisateur admin dans 02-seed.sql..."

        # Échapper les caractères spéciaux dans le hash pour sed
        ESCAPED_HASH=$(echo "$ADMIN_PASSWORD_HASH" | sed 's/[\\/&]/\\&/g')

        # Remplacer les placeholders
        sed -i "s/{{ADMIN_USER}}/$ADMIN_USER/g" "$MARIADB_DIR/init/02-seed.sql"
        sed -i "s/{{ADMIN_PASSWORD_HASH}}/$ESCAPED_HASH/g" "$MARIADB_DIR/init/02-seed.sql"

        print_success "02-seed.sql copié et configuré"
    else
        print_error "02-seed.sql manquant dans le repository"
        exit 1
    fi
}

#═══════════════════════════════════════════════════════════════════════════
# VÉRIFICATION FINALE
#═══════════════════════════════════════════════════════════════════════════

final_verification() {
    print_section "VÉRIFICATION FINALE"

    print_step "Vérification de la structure..."

    local critical_files=(
        "$PROJECT_ROOT/docker-compose.yml"
        "$PROJECT_ROOT/.env"
        "$NGINX_DIR/nginx.conf"
        "$NGINX_DIR/.htpasswd"
        "$NGINX_DIR/html/index.html"
        "$BOLTDIY_DIR/.env"
        "$USERMANAGER_DIR/.env"
        "$USERMANAGER_DIR/Dockerfile"
        "$MARIADB_DIR/init/01-schema.sql"
        "$MARIADB_DIR/init/02-seed.sql"
    )

    local all_ok=true

    for file in "${critical_files[@]}"; do
        if [ -f "$file" ]; then
            print_success "$(basename $file) présent"
        else
            print_error "$(basename $file) manquant"
            all_ok=false
        fi
    done

    # Vérifier les dossiers critiques
    local critical_dirs=(
        "$BOLTDIY_DIR"
        "$NGINX_DIR"
        "$MARIADB_DIR/init"
        "$MARIADB_DIR/data"
        "$USERMANAGER_DIR/app"
    )

    for dir in "${critical_dirs[@]}"; do
        if [ -d "$dir" ]; then
            print_success "$(basename $dir)/ présent"
        else
            print_error "$(basename $dir)/ manquant"
            all_ok=false
        fi
    done

    if [ "$all_ok" = true ]; then
        print_success "Vérification finale réussie"
    else
        print_error "Des fichiers ou dossiers critiques sont manquants"
        exit 1
    fi
}
