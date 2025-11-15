
#═══════════════════════════════════════════════════════════════════════════
# FONCTION: Génération Dockerfile User Manager
#═══════════════════════════════════════════════════════════════════════════
generate_usermanager_dockerfile() {
    print_section "GÉNÉRATION DOCKERFILE USER MANAGER"

    print_step "Création du Dockerfile..."

    cat > "$USERMANAGER_DIR/Dockerfile" << 'DOCKERFILE_EOF'
FROM php:8.1-apache

# Métadonnées
LABEL maintainer="Nbility <contact@nbility.fr>"
LABEL version="2.0"
LABEL description="User Manager v2.0 - MVC Architecture"

# Installation des extensions PHP requises
RUN apt-get update && apt-get install -y \
    libzip-dev \
    zip \
    unzip \
    git \
    && docker-php-ext-install \
    pdo \
    pdo_mysql \
    mysqli \
    zip \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# Installer Composer
COPY --from=composer:latest /usr/bin/composer /usr/bin/composer

# Configuration Apache
RUN a2enmod rewrite headers

# Copier les fichiers de l'application
COPY ./app /var/www/html

# Créer les dossiers nécessaires
RUN mkdir -p /var/www/html/app/logs \
    && mkdir -p /var/www/html/app/cache \
    && mkdir -p /var/www/html/uploads \
    && mkdir -p /var/www/html/backups \
    && chown -R www-data:www-data /var/www/html \
    && chmod -R 755 /var/www/html/app/logs \
    && chmod -R 755 /var/www/html/app/cache

# Installer les dépendances Composer si composer.json existe
RUN if [ -f /var/www/html/composer.json ]; then \
        cd /var/www/html && composer install --no-dev --optimize-autoloader; \
    fi

# Configuration Apache pour User Manager
RUN echo '<VirtualHost *:80>' > /etc/apache2/sites-available/000-default.conf \
    && echo '    ServerAdmin webmaster@localhost' >> /etc/apache2/sites-available/000-default.conf \
    && echo '    DocumentRoot /var/www/html/public' >> /etc/apache2/sites-available/000-default.conf \
    && echo '    <Directory /var/www/html/public>' >> /etc/apache2/sites-available/000-default.conf \
    && echo '        Options Indexes FollowSymLinks' >> /etc/apache2/sites-available/000-default.conf \
    && echo '        AllowOverride All' >> /etc/apache2/sites-available/000-default.conf \
    && echo '        Require all granted' >> /etc/apache2/sites-available/000-default.conf \
    && echo '    </Directory>' >> /etc/apache2/sites-available/000-default.conf \
    && echo '    ErrorLog ${APACHE_LOG_DIR}/error.log' >> /etc/apache2/sites-available/000-default.conf \
    && echo '    CustomLog ${APACHE_LOG_DIR}/access.log combined' >> /etc/apache2/sites-available/000-default.conf \
    && echo '</VirtualHost>' >> /etc/apache2/sites-available/000-default.conf

# Permissions finales
RUN chown -R www-data:www-data /var/www/html \
    && chmod -R 755 /var/www/html

EXPOSE 80

CMD ["apache2-foreground"]
DOCKERFILE_EOF

    print_success "Dockerfile créé (PHP 8.1 + Apache)"
    echo ""
}

#═══════════════════════════════════════════════════════════════════════════
# FONCTION: Génération health.php
#═══════════════════════════════════════════════════════════════════════════
generate_health_php() {
    print_section "GÉNÉRATION HEALTH.PHP"

    print_step "Création du fichier health.php..."

    cat > "$USERMANAGER_DIR/app/public/health.php" << 'HEALTH_PHP_EOF'
<?php
/**
 * Health Check Endpoint
 * User Manager v2.0
 */

header('Content-Type: application/json');

$health = [
    'status' => 'OK',
    'timestamp' => date('Y-m-d H:i:s'),
    'version' => '2.0',
    'php_version' => PHP_VERSION
];

// Vérifier connexion base de données si .env existe
if (file_exists(__DIR__ . '/../../.env')) {
    try {
        // Charger .env
        $env = parse_ini_file(__DIR__ . '/../../.env');

        $dsn = sprintf(
            "mysql:host=%s;port=%s;dbname=%s",
            $env['DB_HOST'] ?? 'bolt-mariadb',
            $env['DB_PORT'] ?? '3306',
            $env['DB_NAME'] ?? 'bolt_usermanager'
        );

        $pdo = new PDO(
            $dsn,
            $env['DB_USER'] ?? 'bolt_um',
            $env['DB_PASSWORD'] ?? '',
            [PDO::ATTR_ERRMODE => PDO::ERRMODE_EXCEPTION]
        );

        $health['database'] = 'connected';
    } catch (Exception $e) {
        $health['database'] = 'error';
        $health['database_message'] = $e->getMessage();
        $health['status'] = 'WARNING';
    }
} else {
    $health['database'] = 'not_configured';
}

http_response_code(200);
echo json_encode($health, JSON_PRETTY_PRINT);
HEALTH_PHP_EOF

    print_success "health.php créé"
    echo ""
}

#═══════════════════════════════════════════════════════════════════════════
# FONCTION: Génération fichiers .env
#═══════════════════════════════════════════════════════════════════════════
generate_env_files() {
    print_section "GÉNÉRATION FICHIERS .ENV"

    # .env principal
    print_step "Création du fichier .env principal..."
    cat > "$PROJECT_ROOT/.env" << ENV_MAIN_EOF
# ═══════════════════════════════════════════════════════════════════════════
# BOLT.DIY NBILITY - Configuration Environnement v7.0
# © Copyright Nbility 2025
# ═══════════════════════════════════════════════════════════════════════════

# Ports
HOST_PORT_BOLT=$HOST_PORT_BOLT
HOST_PORT_HOME=$HOST_PORT_HOME
HOST_PORT_UM=$HOST_PORT_UM

# MariaDB
MARIADB_ROOT_PASSWORD=$MARIADB_ROOT_PASSWORD
MARIADB_USER_PASSWORD=$MARIADB_USER_PASSWORD

# Clés API LLM
GROQ_API_KEY=$GROQ_API_KEY
OPENAI_API_KEY=$OPENAI_API_KEY
ANTHROPIC_API_KEY=$ANTHROPIC_API_KEY
GOOGLE_API_KEY=$GOOGLE_API_KEY
ENV_MAIN_EOF
    print_success ".env principal créé"

    # .env Bolt
    print_step "Création du fichier .env Bolt..."
    cat > "$PROJECT_ROOT/DATA/.env" << ENV_BOLT_EOF
# ═══════════════════════════════════════════════════════════════════════════
# BOLT.DIY - Configuration
# ═══════════════════════════════════════════════════════════════════════════

GROQ_API_KEY=$GROQ_API_KEY
OPENAI_API_KEY=$OPENAI_API_KEY
ANTHROPIC_API_KEY=$ANTHROPIC_API_KEY
GOOGLE_GENERATIVE_AI_API_KEY=$GOOGLE_API_KEY
ENV_BOLT_EOF
    print_success ".env Bolt créé"

    # .env User Manager
    print_step "Création du fichier .env User Manager..."
    cat > "$USERMANAGER_DIR/.env" << ENV_UM_EOF
# ═══════════════════════════════════════════════════════════════════════════
# USER MANAGER v2.0 - Configuration
# © Copyright Nbility 2025
# ═══════════════════════════════════════════════════════════════════════════

# Database
DB_HOST=bolt-mariadb
DB_PORT=3306
DB_NAME=bolt_usermanager
DB_USER=bolt_um
DB_PASSWORD=$MARIADB_USER_PASSWORD

# Security
JWT_SECRET=$APP_SECRET
SESSION_LIFETIME=3600
CSRF_TOKEN_LIFETIME=3600
PASSWORD_MIN_LENGTH=8

# Rate Limiting
RATE_LIMIT_REQUESTS=100
RATE_LIMIT_WINDOW=60
MAX_LOGIN_ATTEMPTS=5
LOCKOUT_DURATION=900

# Logging
LOG_LEVEL=info
LOG_FILE=/var/www/html/app/logs/app.log
AUDIT_ENABLED=true
AUDIT_RETENTION_DAYS=90

# Application
APP_NAME="User Manager"
APP_VERSION=2.0
APP_ENV=production
APP_DEBUG=false
APP_TIMEZONE=Europe/Paris
APP_LANGUAGE=fr
APP_URL=http://$LOCAL_IP:$HOST_PORT_UM

# Performance
CACHE_ENABLED=true
CACHE_LIFETIME=3600
MAX_PER_PAGE=100
DEFAULT_PER_PAGE=25
ENV_UM_EOF
    print_success ".env User Manager créé"

    echo ""
}
