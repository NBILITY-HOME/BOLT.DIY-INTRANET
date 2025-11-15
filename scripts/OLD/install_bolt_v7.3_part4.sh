
#═══════════════════════════════════════════════════════════════════════════
# GÉNÉRATION FICHIERS .ENV
#═══════════════════════════════════════════════════════════════════════════

generate_env_files() {
    print_section "GÉNÉRATION FICHIERS .ENV"

    # .env principal (pour docker-compose)
    print_step "Création du fichier .env principal..."
    cat > "$PROJECT_ROOT/.env" << ENV_MAIN_EOF
# Configuration principale Docker Compose
HOST_PORT_BOLT=${HOST_PORT_BOLT}
HOST_PORT_HOME=${HOST_PORT_HOME}
HOST_PORT_UM=${HOST_PORT_UM}

# Chemins
NGINX_DIR=${NGINX_DIR}
BOLTDIY_DIR=${BOLTDIY_DIR}
MARIADB_DIR=${MARIADB_DIR}
USERMANAGER_DIR=${USERMANAGER_DIR}

# Base de données
MARIADB_ROOT_PASSWORD=${MARIADB_ROOT_PASSWORD}
MARIADB_USER_PASSWORD=${MARIADB_USER_PASSWORD}
ENV_MAIN_EOF
    print_success ".env principal créé"

    # .env Bolt.DIY (depuis .env.example)
    print_step "Création du fichier .env Bolt.DIY..."

    # Vérifier que .env.example existe
    if [ -f "$BOLTDIY_DIR/.env.example" ]; then
        # Copier .env.example vers .env
        cp "$BOLTDIY_DIR/.env.example" "$BOLTDIY_DIR/.env"

        # Remplacer les clés API si fournies
        if [ -n "$GROQ_API_KEY" ]; then
            sed -i "s|GROQ_API_KEY=.*|GROQ_API_KEY=${GROQ_API_KEY}|" "$BOLTDIY_DIR/.env"
        fi

        if [ -n "$OPENAI_API_KEY" ]; then
            sed -i "s|OPENAI_API_KEY=.*|OPENAI_API_KEY=${OPENAI_API_KEY}|" "$BOLTDIY_DIR/.env"
        fi

        if [ -n "$ANTHROPIC_API_KEY" ]; then
            sed -i "s|ANTHROPIC_API_KEY=.*|ANTHROPIC_API_KEY=${ANTHROPIC_API_KEY}|" "$BOLTDIY_DIR/.env"
        fi

        if [ -n "$GOOGLE_API_KEY" ]; then
            sed -i "s|GOOGLE_GENERATIVE_AI_API_KEY=.*|GOOGLE_GENERATIVE_AI_API_KEY=${GOOGLE_API_KEY}|" "$BOLTDIY_DIR/.env"
        fi

        print_success ".env Bolt.DIY créé depuis .env.example"
    else
        print_error ".env.example manquant dans bolt.diy/"
        print_error "Impossible de créer .env pour Bolt.DIY"
        exit 1
    fi

    # .env User Manager
    print_step "Création du fichier .env User Manager..."
    cat > "$USERMANAGER_DIR/.env" << ENV_UM_EOF
# Configuration User Manager
APP_ENV=production
APP_DEBUG=false
APP_SECRET=${APP_SECRET}
APP_TIMEZONE=Europe/Paris

# Base de données
DB_HOST=mariadb
DB_PORT=3306
DB_DATABASE=usermanager
DB_USERNAME=usermanager
DB_PASSWORD=${MARIADB_USER_PASSWORD}

# Serveur
SERVER_HOST=0.0.0.0
SERVER_PORT=8080

# Logs
LOG_LEVEL=info
LOG_FILE=/var/www/html/logs/app.log

# Uploads
UPLOAD_MAX_SIZE=52428800
UPLOAD_ALLOWED_EXTENSIONS=jpg,jpeg,png,gif,pdf,doc,docx

# Session
SESSION_LIFETIME=7200
SESSION_NAME=USERMANAGER_SESSION
ENV_UM_EOF
    print_success ".env User Manager créé"
}

#═══════════════════════════════════════════════════════════════════════════
# GÉNÉRATION DOCKERFILE USER MANAGER
#═══════════════════════════════════════════════════════════════════════════

generate_dockerfile() {
    print_section "GÉNÉRATION DOCKERFILE USER MANAGER"

    print_step "Création du Dockerfile..."

    cat > "$USERMANAGER_DIR/Dockerfile" << 'DOCKERFILE_EOF'
FROM php:8.2-apache

# Installation des dépendances
RUN apt-get update && apt-get install -y \
    libpng-dev \
    libjpeg-dev \
    libfreetype6-dev \
    libzip-dev \
    libonig-dev \
    zip \
    unzip \
    git \
    curl \
    && docker-php-ext-configure gd --with-freetype --with-jpeg \
    && docker-php-ext-install -j$(nproc) gd \
    && docker-php-ext-install pdo pdo_mysql mysqli zip mbstring exif \
    && a2enmod rewrite headers \
    && apt-get clean && rm -rf /var/lib/apt/lists/*

# Configuration PHP
RUN { \
    echo 'memory_limit = 256M'; \
    echo 'upload_max_filesize = 50M'; \
    echo 'post_max_size = 50M'; \
    echo 'max_execution_time = 300'; \
    echo 'date.timezone = Europe/Paris'; \
} > /usr/local/etc/php/conf.d/custom.ini

# Installation de Composer
COPY --from=composer:latest /usr/bin/composer /usr/bin/composer

# Configuration Apache
RUN sed -i 's!/var/www/html!/var/www/html/public!g' /etc/apache2/sites-available/000-default.conf \
    && sed -i 's!/var/www/html!/var/www/html/public!g' /etc/apache2/apache2.conf

# Création des dossiers nécessaires
RUN mkdir -p /var/www/html/logs /var/www/html/uploads \
    && chown -R www-data:www-data /var/www/html \
    && chmod -R 755 /var/www/html

# Configuration du DocumentRoot
ENV APACHE_DOCUMENT_ROOT=/var/www/html/public

# Définir le répertoire de travail
WORKDIR /var/www/html

# Copier composer.json et composer.lock
COPY composer.json composer.lock* ./

# Installer les dépendances PHP
RUN composer install --no-dev --optimize-autoloader --no-interaction

# Copier le reste de l'application
COPY . .

# Permissions finales
RUN chown -R www-data:www-data /var/www/html \
    && chmod -R 755 /var/www/html \
    && chmod -R 777 /var/www/html/logs \
    && chmod -R 777 /var/www/html/uploads

# Exposer le port
EXPOSE 8080

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=40s --retries=3 \
    CMD php -v || exit 1

# Démarrer Apache
CMD ["apache2-foreground"]
DOCKERFILE_EOF

    print_success "Dockerfile User Manager créé"
}

#═══════════════════════════════════════════════════════════════════════════
# GÉNÉRATION .HTPASSWD
#═══════════════════════════════════════════════════════════════════════════

generate_htpasswd() {
    print_section "GÉNÉRATION .HTPASSWD"

    print_step "Création du fichier .htpasswd..."

    # Créer .htpasswd avec htpasswd
    htpasswd -cb "$NGINX_DIR/.htpasswd" "$ADMIN_USER" "$ADMIN_PASSWORD"

    print_success ".htpasswd créé avec utilisateur: $ADMIN_USER"
}
