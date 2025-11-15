#═══════════════════════════════════════════════════════════════════════════
# GÉNÉRATION .ENV PRINCIPAL
#═══════════════════════════════════════════════════════════════════════════

generate_main_env() {
    print_section "GÉNÉRATION FICHIERS .ENV"

    print_step "Création du fichier .env principal..."

    cat > "$PROJECT_ROOT/.env" << ENV_MAIN_EOF
# =========================================================================
# Configuration principale - Bolt.DIY v7.4
# Généré automatiquement le $(date)
# =========================================================================

# IP et Ports
LOCAL_IP=$LOCAL_IP
HOST_PORT_BOLT=$HOST_PORT_BOLT
HOST_PORT_HOME=$HOST_PORT_HOME
HOST_PORT_UM=$HOST_PORT_UM

# Chemins
NGINX_DIR=./DATA-LOCAL/nginx
BOLTDIY_DIR=./bolt.diy
MARIADB_DIR=./DATA-LOCAL/mariadb
USERMANAGER_DIR=./DATA-LOCAL/user-manager

# Base de données
MARIADB_ROOT_PASSWORD=$MARIADB_ROOT_PASSWORD
MARIADB_USER_PASSWORD=$MARIADB_USER_PASSWORD

# Application
APP_SECRET=$APP_SECRET
ENV_MAIN_EOF

    print_success ".env principal créé"
}

#═══════════════════════════════════════════════════════════════════════════
# GÉNÉRATION .ENV BOLT.DIY
#═══════════════════════════════════════════════════════════════════════════

generate_boltdiy_env() {
    print_step "Création du fichier .env Bolt.DIY..."

    # Copier .env.example si disponible
    if [ -f "$BOLTDIY_DIR/.env.example" ]; then
        cp "$BOLTDIY_DIR/.env.example" "$BOLTDIY_DIR/.env"
        print_info ".env créé depuis .env.example"
    else
        touch "$BOLTDIY_DIR/.env"
        print_warning ".env.example non trouvé, création d'un .env vide"
    fi

    # Ajouter les clés API (si fournies)
    if [ -n "$OPENAI_API_KEY" ]; then
        echo "OPENAI_API_KEY=$OPENAI_API_KEY" >> "$BOLTDIY_DIR/.env"
    fi

    if [ -n "$ANTHROPIC_API_KEY" ]; then
        echo "ANTHROPIC_API_KEY=$ANTHROPIC_API_KEY" >> "$BOLTDIY_DIR/.env"
    fi

    if [ -n "$GROQ_API_KEY" ]; then
        echo "GROQ_API_KEY=$GROQ_API_KEY" >> "$BOLTDIY_DIR/.env"
    fi

    if [ -n "$GOOGLE_API_KEY" ]; then
        echo "GOOGLE_GENERATIVE_AI_API_KEY=$GOOGLE_API_KEY" >> "$BOLTDIY_DIR/.env"
    fi

    print_success ".env Bolt.DIY créé"
}

#═══════════════════════════════════════════════════════════════════════════
# GÉNÉRATION .ENV USER MANAGER
#═══════════════════════════════════════════════════════════════════════════

generate_usermanager_env() {
    print_step "Création du fichier .env User Manager..."

    cat > "$USERMANAGER_DIR/.env" << ENV_UM_EOF
# =========================================================================
# User Manager v2.0 - Configuration
# Généré automatiquement le $(date)
# =========================================================================

# Database
DB_HOST=mariadb
DB_PORT=3306
DB_NAME=usermanager
DB_USER=usermanager
DB_PASSWORD=$MARIADB_USER_PASSWORD

# Application
APP_NAME=Bolt.DIY User Manager
APP_ENV=production
APP_DEBUG=false
APP_URL=http://$LOCAL_IP:$HOST_PORT_UM

# Security
APP_SECRET=$APP_SECRET
SESSION_LIFETIME=120

# Logs
LOG_LEVEL=info
LOG_FILE=/var/www/html/logs/app.log
ENV_UM_EOF

    print_success ".env User Manager créé"
}
