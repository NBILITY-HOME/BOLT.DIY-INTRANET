
# ═══════════════════════════════════════════════════════════════════════════
# FONCTION: Génération de nginx.conf
# ═══════════════════════════════════════════════════════════════════════════
generate_nginx_conf() {
    print_section "GÉNÉRATION DE NGINX.CONF"

    print_step "Création de nginx.conf..."

    cat > "$NGINX_DIR/nginx.conf" << 'NGINX_CONF_EOF'
user nginx;
worker_processes auto;
error_log /var/log/nginx/error.log warn;
pid /var/run/nginx.pid;

events {
    worker_connections 1024;
    use epoll;
    multi_accept on;
}

http {
    include /etc/nginx/mime.types;
    default_type application/octet-stream;

    log_format main '$remote_addr - $remote_user [$time_local] "$request" '
                    '$status $body_bytes_sent "$http_referer" '
                    '"$http_user_agent" "$http_x_forwarded_for"';

    access_log /var/log/nginx/access.log main;

    sendfile on;
    tcp_nopush on;
    tcp_nodelay on;
    keepalive_timeout 65;
    types_hash_max_size 2048;
    client_max_body_size 100M;

    gzip on;
    gzip_vary on;
    gzip_proxied any;
    gzip_comp_level 6;
    gzip_types text/plain text/css text/xml text/javascript 
               application/json application/javascript application/xml+rss 
               application/rss+xml font/truetype font/opentype 
               application/vnd.ms-fontobject image/svg+xml;

    upstream bolt_backend {
        server bolt-core:5173;
        keepalive 32;
    }

    upstream home_backend {
        server bolt-home:80;
        keepalive 16;
    }

    upstream usermanager_backend {
        server bolt-user-manager:80;
        keepalive 16;
    }

    # ════════════════════════════════════════════════════════════════
    # SERVER BOLT.DIY (Port 8585)
    # ════════════════════════════════════════════════════════════════
    server {
        listen 8585;
        server_name _;

        # CRITIQUE: Empêche NGINX de supprimer le port
        port_in_redirect off;
        absolute_redirect off;

        auth_basic "Bolt.DIY - Accès Restreint";
        auth_basic_user_file /etc/nginx/.htpasswd;

        location /health {
            auth_basic off;
            access_log off;
            return 200 "healthy\n";
            add_header Content-Type text/plain;
        }

        location / {
            proxy_pass http://bolt_backend;

            # Headers pour préserver le port
            proxy_set_header Host $http_host;
            proxy_set_header X-Real-IP $remote_addr;
            proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
            proxy_set_header X-Forwarded-Proto $scheme;
            proxy_set_header X-Forwarded-Host $host:$server_port;
            proxy_set_header X-Forwarded-Port $server_port;

            # WebSocket support
            proxy_http_version 1.1;
            proxy_set_header Upgrade $http_upgrade;
            proxy_set_header Connection "upgrade";

            proxy_connect_timeout 60s;
            proxy_send_timeout 60s;
            proxy_read_timeout 60s;
            proxy_buffering off;

            proxy_redirect http:// http://;
            proxy_redirect https:// https://;
        }

        location ~* \.(js|css|png|jpg|jpeg|gif|ico|svg|woff|woff2|ttf|eot)$ {
            proxy_pass http://bolt_backend;
            proxy_set_header Host $http_host;
            expires 1y;
            add_header Cache-Control "public, immutable";
        }
    }

    # ════════════════════════════════════════════════════════════════
    # SERVER BOLT HOME (Port 8686)
    # ════════════════════════════════════════════════════════════════
    server {
        listen 8686;
        server_name _;

        port_in_redirect off;
        absolute_redirect off;

        auth_basic "Bolt.DIY Home - Accès Restreint";
        auth_basic_user_file /etc/nginx/.htpasswd;

        location / {
            proxy_pass http://home_backend;
            proxy_set_header Host $http_host;
            proxy_set_header X-Real-IP $remote_addr;
            proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
            proxy_set_header X-Forwarded-Proto $scheme;
        }
    }

    # ════════════════════════════════════════════════════════════════
    # SERVER USER MANAGER (Port 8687)
    # ════════════════════════════════════════════════════════════════
    server {
        listen 8687;
        server_name _;

        port_in_redirect off;
        absolute_redirect off;

        auth_basic "User Manager - Accès Restreint";
        auth_basic_user_file /etc/nginx/.htpasswd;

        location /health.php {
            auth_basic off;
            proxy_pass http://usermanager_backend;
            access_log off;
        }

        location / {
            proxy_pass http://usermanager_backend;

            proxy_set_header Host $http_host;
            proxy_set_header X-Real-IP $remote_addr;
            proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
            proxy_set_header X-Forwarded-Proto $scheme;
            proxy_set_header X-Forwarded-Host $host:$server_port;
            proxy_set_header X-Forwarded-Port $server_port;

            proxy_connect_timeout 60s;
            proxy_send_timeout 60s;
            proxy_read_timeout 60s;
        }

        location ~* \.(css|js|jpg|jpeg|png|gif|ico|svg)$ {
            proxy_pass http://usermanager_backend;
            expires 1h;
            add_header Cache-Control "public";
        }
    }
}
NGINX_CONF_EOF

    print_success "nginx.conf créé"
    echo ""
}

# ═══════════════════════════════════════════════════════════════════════════
# FONCTION: Génération du Dockerfile User Manager
# ═══════════════════════════════════════════════════════════════════════════
generate_usermanager_dockerfile() {
    print_section "GÉNÉRATION DU DOCKERFILE USER MANAGER"

    print_step "Création du Dockerfile User Manager..."

    cat > "$USERMANAGER_DIR/Dockerfile" << 'DOCKERFILE_UM_EOF'
FROM php:8.2-apache

LABEL maintainer="contact@nbility.fr"
LABEL description="Bolt.DIY User Manager v2.0 with PHP 8.2 and Apache"
LABEL version="2.0"

# Installation des dépendances système
RUN apt-get update && apt-get install -y \
    git \
    curl \
    libpng-dev \
    libonig-dev \
    libxml2-dev \
    libzip-dev \
    zip \
    unzip \
    default-mysql-client \
    && rm -rf /var/lib/apt/lists/*

# Installation des extensions PHP
RUN docker-php-ext-install \
    pdo_mysql \
    mysqli \
    mbstring \
    exif \
    pcntl \
    bcmath \
    gd \
    zip

# Installation de Composer
COPY --from=composer:latest /usr/bin/composer /usr/bin/composer

# Configuration Apache
RUN a2enmod rewrite headers expires && \
    sed -i 's/AllowOverride None/AllowOverride All/' /etc/apache2/apache2.conf

# Configuration PHP
RUN echo "memory_limit = 256M" > /usr/local/etc/php/conf.d/memory.ini && \
    echo "upload_max_filesize = 20M" >> /usr/local/etc/php/conf.d/memory.ini && \
    echo "post_max_size = 20M" >> /usr/local/etc/php/conf.d/memory.ini && \
    echo "max_execution_time = 60" >> /usr/local/etc/php/conf.d/memory.ini

WORKDIR /var/www/html

# Copie du composer.json si présent
COPY app/composer.json* /var/www/html/ 2>/dev/null || true

# Installation des dépendances PHP
RUN if [ -f composer.json ]; then \
        composer install --no-dev --optimize-autoloader --no-interaction; \
    fi

# Copie du code source
COPY app/ /var/www/html/

# Fichier health check
RUN echo "<?php http_response_code(200); echo 'healthy'; ?>" > /var/www/html/health.php

# Permissions
RUN chown -R www-data:www-data /var/www/html && \
    chmod -R 755 /var/www/html

EXPOSE 80

CMD ["apache2-foreground"]
DOCKERFILE_UM_EOF

    print_success "Dockerfile User Manager créé"
    echo ""
}

# ═══════════════════════════════════════════════════════════════════════════
# FONCTION: Génération de health.php
# ═══════════════════════════════════════════════════════════════════════════
generate_health_php() {
    print_section "GÉNÉRATION DE HEALTH.PHP"

    print_step "Création de health.php..."

    cat > "$USERMANAGER_DIR/app/health.php" << 'HEALTH_PHP_EOF'
<?php
/**
 * Health Check Endpoint
 * Vérifie que PHP et la base de données sont fonctionnels
 */

header('Content-Type: application/json');

$health = [
    'status' => 'healthy',
    'timestamp' => time(),
    'checks' => []
];

// Test PHP
$health['checks']['php'] = [
    'status' => 'ok',
    'version' => PHP_VERSION
];

// Test connexion base de données
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

    $health['checks']['database'] = [
        'status' => 'ok',
        'host' => $host,
        'database' => $dbname
    ];
} catch (PDOException $e) {
    $health['status'] = 'degraded';
    $health['checks']['database'] = [
        'status' => 'error',
        'message' => 'Database connection failed'
    ];
}

http_response_code($health['status'] === 'healthy' ? 200 : 503);
echo json_encode($health, JSON_PRETTY_PRINT);
HEALTH_PHP_EOF

    print_success "health.php créé"
    echo ""
}
