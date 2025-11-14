
# ═══════════════════════════════════════════════════════════════════════════
# FONCTION: Génération du Dockerfile User Manager
# ═══════════════════════════════════════════════════════════════════════════
generate_usermanager_dockerfile() {
    print_section "GÉNÉRATION DU DOCKERFILE USER MANAGER"

    print_step "Création du Dockerfile..."

    cat > "$USERMANAGER_DIR/Dockerfile" << 'DOCKERFILE_EOF'
FROM php:8.2-apache

LABEL maintainer="contact@nbility.fr"
LABEL version="2.0"

RUN apt-get update && apt-get install -y \
    git curl libpng-dev libonig-dev libxml2-dev libzip-dev \
    zip unzip default-mysql-client \
    && rm -rf /var/lib/apt/lists/*

RUN docker-php-ext-install pdo_mysql mysqli mbstring exif pcntl bcmath gd zip

COPY --from=composer:latest /usr/bin/composer /usr/bin/composer

RUN a2enmod rewrite headers expires && \
    sed -i 's/AllowOverride None/AllowOverride All/' /etc/apache2/apache2.conf

RUN echo "memory_limit = 256M" > /usr/local/etc/php/conf.d/memory.ini && \
    echo "upload_max_filesize = 20M" >> /usr/local/etc/php/conf.d/memory.ini && \
    echo "post_max_size = 20M" >> /usr/local/etc/php/conf.d/memory.ini && \
    echo "max_execution_time = 60" >> /usr/local/etc/php/conf.d/memory.ini

WORKDIR /var/www/html

COPY app/ /var/www/html/

RUN if [ -f composer.json ]; then \
        composer install --no-dev --optimize-autoloader --no-interaction; \
    fi

RUN echo "<?php http_response_code(200); echo 'healthy'; ?>" > /var/www/html/health.php

RUN chown -R www-data:www-data /var/www/html && \
    chmod -R 755 /var/www/html

EXPOSE 80

CMD ["apache2-foreground"]
DOCKERFILE_EOF

    print_success "Dockerfile User Manager créé"
    echo ""
}

generate_health_php() {
    print_section "GÉNÉRATION DE HEALTH.PHP"

    print_step "Création de health.php..."

    cat > "$USERMANAGER_DIR/app/health.php" << 'HEALTH_PHP_EOF'
<?php
header('Content-Type: application/json');

$health = ['status' => 'healthy', 'timestamp' => time(), 'checks' => []];

$health['checks']['php'] = ['status' => 'ok', 'version' => PHP_VERSION];

try {
    $host = getenv('DB_HOST') ?: 'bolt-mariadb';
    $port = getenv('DB_PORT') ?: '3306';
    $dbname = getenv('DB_NAME') ?: 'bolt_usermanager';
    $user = getenv('DB_USER') ?: 'bolt_um';
    $pass = getenv('DB_PASSWORD') ?: '';

    $dsn = "mysql:host=$host;port=$port;dbname=$dbname;charset=utf8mb4";
    $pdo = new PDO($dsn, $user, $pass, [
        PDO::ATTR_ERRMODE => PDO::ERRMODE_EXCEPTION,
        PDO::ATTR_TIMEOUT => 2
    ]);

    $health['checks']['database'] = ['status' => 'ok', 'host' => $host];
} catch (PDOException $e) {
    $health['status'] = 'degraded';
    $health['checks']['database'] = ['status' => 'error'];
}

http_response_code($health['status'] === 'healthy' ? 200 : 503);
echo json_encode($health, JSON_PRETTY_PRINT);
HEALTH_PHP_EOF

    print_success "health.php créé"
    echo ""
}

generate_env_files() {
    print_section "GÉNÉRATION DES FICHIERS .ENV"

    print_step "Création du fichier .env principal..."
    cat > "$INSTALL_DIR/.env" << ENV_MAIN_EOF
LOCAL_IP=$LOCAL_IP
HOST_PORT_BOLT=$HOST_PORT_BOLT
HOST_PORT_HOME=$HOST_PORT_HOME
HOST_PORT_UM=$HOST_PORT_UM
MARIADB_PORT=$MARIADB_PORT
HTPASSWD_FILE=$HTPASSWD_FILE
MARIADB_ROOT_PASSWORD=$MARIADB_ROOT_PASSWORD
MARIADB_USER=bolt_um
MARIADB_PASSWORD=$MARIADB_USER_PASSWORD
APP_SECRET=$APP_SECRET
ANTHROPIC_API_KEY=$ANTHROPIC_KEY
OPENAI_API_KEY=$OPENAI_KEY
GOOGLE_GENERATIVE_AI_API_KEY=$GEMINI_KEY
GROQ_API_KEY=$GROQ_KEY
MISTRAL_API_KEY=$MISTRAL_KEY
DEEPSEEK_API_KEY=$DEEPSEEK_KEY
HF_API_KEY=$HF_KEY
ENV_MAIN_EOF

    print_success "Fichier .env principal créé"

    print_step "Création du fichier .env pour Bolt.DIY..."
    cat > "$BOLT_DIR/.env" << ENV_BOLT_EOF
BASE_URL=http://$LOCAL_IP:$HOST_PORT_BOLT
APP_URL=http://$LOCAL_IP:$HOST_PORT_BOLT
PUBLIC_URL=http://$LOCAL_IP:$HOST_PORT_BOLT
VITE_BASE_URL=/
VITE_ROUTER_BASE=/
BASE_PATH=/
ROUTER_BASE=/
ANTHROPIC_API_KEY=$ANTHROPIC_KEY
OPENAI_API_KEY=$OPENAI_KEY
GOOGLE_GENERATIVE_AI_API_KEY=$GEMINI_KEY
GROQ_API_KEY=$GROQ_KEY
MISTRAL_API_KEY=$MISTRAL_KEY
DEEPSEEK_API_KEY=$DEEPSEEK_KEY
HF_API_KEY=$HF_KEY
NODE_ENV=production
VITE_LOG_LEVEL=info
SESSION_SECRET=changeme_with_random_string
PORT=5173
HOST=0.0.0.0
ENV_BOLT_EOF

    print_success "Fichier .env Bolt créé"
    echo ""
}
