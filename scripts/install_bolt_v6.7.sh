#!/bin/bash
#═══════════════════════════════════════════════════════════════════════════
# BOLT.DIY NBILITY - Installation Script v6.7
# Architecture Multi-Ports + User Manager v2.0 + MariaDB + Docker Compose  
# © Copyright Nbility 2025 - contact@nbility.fr
#
# CORRECTIONS v6.7 (basé sur v6.6):
# ✅ nginx.conf: Pas d'authentification sur port 8686 (home public)
# ✅ home.html: rel="noopener noreferrer" sur les liens externes
# ✅ index.php User Manager: Bouton déconnexion + affichage utilisateur
# ✅ logout.php: NOUVEAU - Page de déconnexion professionnelle
# ✅ Toutes corrections v6.6 conservées (read -p, Dockerfile, etc.)
#═══════════════════════════════════════════════════════════════════════════

clear
printf "\033[8;55;116t"

if [ "$EUID" -eq 0 ]; then
    echo -e "\033[0;31m✗ ERREUR: Ce script NE DOIT PAS être lancé en sudo/root\033[0m"
    echo ""
    echo "Raison: Docker et les fichiers doivent appartenir à votre utilisateur"
    echo ""
    echo "Solution: Lancez le script sans sudo:"
    echo "  ./install_bolt_nbility_v6.7.sh"
    echo ""
    exit 1
fi

RED="\033[0;31m"
GREEN="\033[0;32m"
YELLOW="\033[1;33m"
BLUE="\033[0;34m"
CYAN="\033[0;36m"
MAGENTA="\033[0;35m"
WHITE="\033[1;37m"
NC="\033[0m"
BOLD="\033[1m"

CHECK="✓"
CROSS="✗"
ARROW="→"
STAR="★"

SCRIPT_DIR=$(pwd)
REPO_URL="https://github.com/NBILITY-HOME/BOLT.DIY-INTRANET.git"
REPO_NAME="BOLT.DIY-INTRANET"
INSTALL_DIR="$SCRIPT_DIR/$REPO_NAME"
DATA_DIR="$INSTALL_DIR/DATA-LOCAL"
NGINX_DIR="$DATA_DIR/nginx"
MARIADB_DIR="$DATA_DIR/mariadb"
USERMANAGER_DIR="$DATA_DIR/user-manager"
TEMPLATES_DIR="$DATA_DIR/templates"
HTPASSWD_FILE="$NGINX_DIR/.htpasswd"
BOLT_DIR="$INSTALL_DIR/bolt.diy"

NETWORK_NAME="bolt-network-app"
VOLUME_DATA="bolt-nbility-data"
VOLUME_MARIADB="mariadb-data"

LOCAL_IP=""
GATEWAY_IP=""
HOST_PORT_BOLT=""
HOST_PORT_HOME=""
HOST_PORT_UM=""
MARIADB_PORT=3306
NGINX_USER=""
NGINX_PASS=""
ADMIN_USERNAME=""
ADMIN_EMAIL=""
ADMIN_PASSWORD=""
MARIADB_ROOT_PASSWORD=""
MARIADB_USER_PASSWORD=""
APP_SECRET=""

ANTHROPIC_KEY=""
OPENAI_KEY=""
GEMINI_KEY=""
GROQ_KEY=""
MISTRAL_KEY=""
DEEPSEEK_KEY=""
HF_KEY=""

print_banner() {
    clear
    echo -e "${CYAN}"
    echo "╔══════════════════════════════════════════════════════════════════════════════╗"
    echo "║                                                                              ║"
    echo "║                    ${BOLD}BOLT.DIY NBILITY - Installer v6.7${NC}${CYAN}                     ║"
    echo "║                                                                              ║"
    echo "║              ${WHITE}Architecture Multi-Ports + User Manager v2.0${NC}${CYAN}               ║"
    echo "║                                                                              ║"
    echo "║                      ${YELLOW}© Copyright Nbility 2025${NC}${CYAN}                          ║"
    echo "║                      contact@nbility.fr                                      ║"
    echo "║                                                                              ║"
    echo "╚══════════════════════════════════════════════════════════════════════════════╝"
    echo -e "${NC}"
    echo ""
}

print_section() {
    echo -e "${BOLD}${CYAN}═══════════════════════════════════════════════════════════════════════════${NC}"
    echo -e "${BOLD}${WHITE}$1${NC}"
    echo -e "${BOLD}${CYAN}═══════════════════════════════════════════════════════════════════════════${NC}"
    echo ""
}

print_step() {
    echo -e "${BLUE}${ARROW}${NC} ${WHITE}$1${NC}"
}

print_success() {
    echo -e "${GREEN}${CHECK}${NC} ${GREEN}$1${NC}"
}

print_error() {
    echo -e "${RED}${CROSS}${NC} ${RED}$1${NC}"
}

print_warning() {
    echo -e "${YELLOW}${STAR}${NC} ${YELLOW}$1${NC}"
}

print_info() {
    echo -e "${CYAN}ℹ${NC} ${CYAN}$1${NC}"
}

check_prerequisites() {
    print_section "VÉRIFICATION DES PRÉREQUIS"
    local all_good=true

    print_step "Vérification de Docker..."
    if command -v docker &> /dev/null; then
        DOCKER_VERSION=$(docker --version | awk '{print $3}' | tr -d ',')
        print_success "Docker installé: v$DOCKER_VERSION"
    else
        print_error "Docker n'est pas installé"
        all_good=false
    fi

    print_step "Vérification de Docker Compose..."
    if docker compose version &> /dev/null; then
        COMPOSE_VERSION=$(docker compose version | awk '{print $4}')
        print_success "Docker Compose installé: v$COMPOSE_VERSION"
    else
        print_error "Docker Compose n'est pas installé"
        all_good=false
    fi

    print_step "Vérification de Git..."
    if command -v git &> /dev/null; then
        GIT_VERSION=$(git --version | awk '{print $3}')
        print_success "Git installé: v$GIT_VERSION"
    else
        print_error "Git n'est pas installé"
        all_good=false
    fi

    print_step "Vérification de curl..."
    if command -v curl &> /dev/null; then
        print_success "curl installé"
    else
        print_error "curl n'est pas installé"
        all_good=false
    fi

    print_step "Vérification de htpasswd..."
    if command -v htpasswd &> /dev/null; then
        print_success "htpasswd installé"
    else
        print_warning "htpasswd n'est pas installé (sera installé si nécessaire)"
    fi

    echo ""

    if [ "$all_good" = false ]; then
        print_error "Certains prérequis sont manquants"
        echo ""
        echo "Installez les dépendances:"
        echo "  sudo apt-get update"
        echo "  sudo apt-get install -y docker.io docker-compose git curl apache2-utils"
        echo ""
        exit 1
    fi

    print_success "Tous les prérequis sont satisfaits"
    echo ""
}

check_internet_and_github() {
    print_section "VÉRIFICATION DE LA CONNECTIVITÉ"

    print_step "Test de connexion Internet..."
    if ping -c 1 8.8.8.8 &> /dev/null; then
        print_success "Connexion Internet OK"
    else
        print_error "Pas de connexion Internet"
        exit 1
    fi

    print_step "Test de connexion GitHub..."
    if ping -c 1 github.com &> /dev/null; then
        print_success "GitHub accessible"
    else
        print_error "GitHub inaccessible"
        exit 1
    fi

    echo ""
}

check_port_available() {
    local port=$1
    local service_name=$2

    if netstat -tuln 2>/dev/null | grep -q ":$port "; then
        print_error "Port $port ($service_name) déjà utilisé"
        return 1
    elif ss -tuln 2>/dev/null | grep -q ":$port "; then
        print_error "Port $port ($service_name) déjà utilisé"
        return 1
    else
        print_success "Port $port ($service_name) disponible"
        return 0
    fi
}

generate_secure_password() {
    local length=${1:-32}
    openssl rand -base64 $length | tr -d "=+/" | cut -c1-$length
}

generate_app_secret() {
    openssl rand -hex 32
}

# ═══════════════════════════════════════════════════════════════════════════
# FONCTION: Configuration interactive
# ═══════════════════════════════════════════════════════════════════════════
get_configuration() {
    print_section "CONFIGURATION DU SYSTÈME"

    print_step "Détection de l'IP locale..."
    DETECTED_IP=$(hostname -I | awk '{print $1}')
    echo -e "${CYAN}IP détectée: ${WHITE}$DETECTED_IP${NC}"
    echo -ne "${YELLOW}Confirmer ou entrer l'IP: ${NC}"
    read input_ip
    LOCAL_IP=${input_ip:-$DETECTED_IP}
    print_success "IP configurée: $LOCAL_IP"
    echo ""

    print_step "Configuration de la gateway (box/routeur)..."
    DETECTED_GW=$(ip route | grep default | awk '{print $3}' | head -n1)
    echo -e "${CYAN}Gateway détectée: ${WHITE}$DETECTED_GW${NC}"
    echo -ne "${YELLOW}Confirmer ou entrer la gateway: ${NC}"
    read input_gw
    GATEWAY_IP=${input_gw:-$DETECTED_GW}
    print_success "Gateway configurée: $GATEWAY_IP"
    echo ""

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

    print_step "Génération des mots de passe MariaDB..."
    MARIADB_ROOT_PASSWORD=$(generate_secure_password 32)
    MARIADB_USER_PASSWORD=$(generate_secure_password 32)
    APP_SECRET=$(generate_app_secret)
    print_success "Mots de passe générés automatiquement"
    echo ""

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

# ═══════════════════════════════════════════════════════════════════════════
# FONCTION: Génération du docker-compose.yml
# ═══════════════════════════════════════════════════════════════════════════
generate_docker_compose() {
    print_section "GÉNÉRATION DU DOCKER-COMPOSE.YML"

    print_step "Création de docker-compose.yml..."

    cat > "$INSTALL_DIR/docker-compose.yml" << 'DOCKER_COMPOSE_EOF'
version: '3.8'

services:
  nginx:
    image: nginx:alpine
    container_name: bolt-nginx
    restart: unless-stopped
    ports:
      - "${HOST_PORT_BOLT}:8585"
      - "${HOST_PORT_HOME}:8686"
      - "${HOST_PORT_UM}:8687"
    volumes:
      - ./DATA-LOCAL/nginx/nginx.conf:/etc/nginx/nginx.conf:ro
      - ./DATA-LOCAL/nginx/.htpasswd:/etc/nginx/.htpasswd:ro
      - ./DATA-LOCAL/templates:/usr/share/nginx/html:ro
    networks:
      - bolt-network-app
    depends_on:
      - bolt-core
      - bolt-user-manager

  bolt-core:
    build:
      context: ./bolt.diy
      dockerfile: Dockerfile
    container_name: bolt-core
    restart: unless-stopped
    expose:
      - "5173"
    environment:
      - BASE_URL=http://${LOCAL_IP}:${HOST_PORT_BOLT}
      - APP_URL=http://${LOCAL_IP}:${HOST_PORT_BOLT}
      - VITE_BASE_URL=/
      - PUBLIC_URL=http://${LOCAL_IP}:${HOST_PORT_BOLT}
      - BASE_PATH=/
      - VITE_ROUTER_BASE=/
      - ANTHROPIC_API_KEY=${ANTHROPIC_API_KEY:-}
      - OPENAI_API_KEY=${OPENAI_API_KEY:-}
      - GOOGLE_GENERATIVE_AI_API_KEY=${GOOGLE_GENERATIVE_AI_API_KEY:-}
      - GROQ_API_KEY=${GROQ_API_KEY:-}
      - MISTRAL_API_KEY=${MISTRAL_API_KEY:-}
      - DEEPSEEK_API_KEY=${DEEPSEEK_API_KEY:-}
      - HF_API_KEY=${HF_API_KEY:-}
    volumes:
      - bolt-nbility-data:/app/data
      - ./bolt.diy:/app:cached
    networks:
      - bolt-network-app

  bolt-home:
    image: nginx:alpine
    container_name: bolt-home
    restart: unless-stopped
    expose:
      - "80"
    volumes:
      - ./DATA-LOCAL/templates/home.html:/usr/share/nginx/html/index.html:ro
    networks:
      - bolt-network-app

  bolt-user-manager:
    build:
      context: ./DATA-LOCAL/user-manager
      dockerfile: Dockerfile
    container_name: bolt-user-manager
    restart: unless-stopped
    expose:
      - "80"
    environment:
      - DB_HOST=bolt-mariadb
      - DB_PORT=3306
      - DB_NAME=bolt_usermanager
      - DB_USER=bolt_um
      - DB_PASSWORD=${MARIADB_PASSWORD}
      - APP_SECRET=${APP_SECRET}
      - APP_URL=http://${LOCAL_IP}:${HOST_PORT_UM}
      - PHP_MEMORY_LIMIT=256M
      - PHP_UPLOAD_MAX_FILESIZE=20M
      - PHP_POST_MAX_SIZE=20M
    volumes:
      - ./DATA-LOCAL/user-manager/app:/var/www/html:cached
    networks:
      - bolt-network-app
    depends_on:
      bolt-mariadb:
        condition: service_healthy

  bolt-mariadb:
    image: mariadb:10.11
    container_name: bolt-mariadb
    restart: unless-stopped
    expose:
      - "3306"
    environment:
      - MARIADB_ROOT_PASSWORD=${MARIADB_ROOT_PASSWORD}
      - MARIADB_DATABASE=bolt_usermanager
      - MARIADB_USER=bolt_um
      - MARIADB_PASSWORD=${MARIADB_PASSWORD}
      - MARIADB_AUTO_UPGRADE=1
    volumes:
      - mariadb-data:/var/lib/mysql
      - ./DATA-LOCAL/mariadb/init:/docker-entrypoint-initdb.d:ro
    networks:
      - bolt-network-app
    command: 
      - --character-set-server=utf8mb4
      - --collation-server=utf8mb4_unicode_ci
      - --max-connections=200
      - --innodb-buffer-pool-size=256M
    healthcheck:
      test: ["CMD", "healthcheck.sh", "--connect", "--innodb_initialized"]
      interval: 10s
      timeout: 5s
      retries: 5

networks:
  bolt-network-app:
    name: bolt-network-app
    driver: bridge

volumes:
  bolt-nbility-data:
    name: bolt-nbility-data
    driver: local
  mariadb-data:
    name: mariadb-data
    driver: local
DOCKER_COMPOSE_EOF

    print_success "docker-compose.yml créé"
    echo ""
}

# ═══════════════════════════════════════════════════════════════════════════
# FONCTION: Génération de nginx.conf (v6.7 - HOME PUBLIC)
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

    # ═════════════════════════════════════════════════════════════════════
    # SERVER BOLT.DIY (Port 8585) - AVEC AUTHENTIFICATION
    # ═════════════════════════════════════════════════════════════════════
    server {
        listen 8585;
        server_name _;

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

            proxy_set_header Host $http_host;
            proxy_set_header X-Real-IP $remote_addr;
            proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
            proxy_set_header X-Forwarded-Proto $scheme;
            proxy_set_header X-Forwarded-Host $host:$server_port;
            proxy_set_header X-Forwarded-Port $server_port;

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

    # ═════════════════════════════════════════════════════════════════════
    # SERVER HOME (Port 8686) - SANS AUTHENTIFICATION (PUBLIC) ✨ v6.7
    # ═════════════════════════════════════════════════════════════════════
    server {
        listen 8686;
        server_name _;

        port_in_redirect off;
        absolute_redirect off;

        # PAS D'AUTHENTIFICATION - Page d'accueil publique

        location / {
            proxy_pass http://home_backend;
            proxy_set_header Host $http_host;
            proxy_set_header X-Real-IP $remote_addr;
            proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
            proxy_set_header X-Forwarded-Proto $scheme;
        }
    }

    # ═════════════════════════════════════════════════════════════════════
    # SERVER USER MANAGER (Port 8687) - AVEC AUTHENTIFICATION
    # ═════════════════════════════════════════════════════════════════════
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

    print_success "nginx.conf créé (v6.7 - Home public)"
    echo ""
}

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

# ═══════════════════════════════════════════════════════════════════════════
# FONCTION: Création du schéma SQL et données
# ═══════════════════════════════════════════════════════════════════════════
create_sql_files() {
    print_section "CRÉATION DU SCHÉMA SQL MARIADB"

    cat > "$MARIADB_DIR/init/01_schema.sql" << 'SQL_SCHEMA_EOF'
CREATE DATABASE IF NOT EXISTS bolt_usermanager CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
USE bolt_usermanager;

CREATE TABLE IF NOT EXISTS users (
    id INT AUTO_INCREMENT PRIMARY KEY,
    username VARCHAR(50) UNIQUE NOT NULL,
    email VARCHAR(100) UNIQUE NOT NULL,
    password_hash VARCHAR(255) NOT NULL,
    first_name VARCHAR(50),
    last_name VARCHAR(50),
    is_active BOOLEAN DEFAULT 1,
    is_superadmin BOOLEAN DEFAULT 0,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    last_login TIMESTAMP NULL,
    INDEX idx_username (username),
    INDEX idx_email (email),
    INDEX idx_active (is_active)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS groups (
    id INT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(100) UNIQUE NOT NULL,
    description TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    INDEX idx_name (name)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS user_groups (
    id INT AUTO_INCREMENT PRIMARY KEY,
    user_id INT NOT NULL,
    group_id INT NOT NULL,
    assigned_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
    FOREIGN KEY (group_id) REFERENCES groups(id) ON DELETE CASCADE,
    UNIQUE KEY unique_user_group (user_id, group_id),
    INDEX idx_user_id (user_id),
    INDEX idx_group_id (group_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS permissions (
    id INT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(100) UNIQUE NOT NULL,
    description TEXT,
    resource VARCHAR(50),
    action VARCHAR(50),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    INDEX idx_name (name),
    INDEX idx_resource_action (resource, action)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS group_permissions (
    id INT AUTO_INCREMENT PRIMARY KEY,
    group_id INT NOT NULL,
    permission_id INT NOT NULL,
    assigned_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (group_id) REFERENCES groups(id) ON DELETE CASCADE,
    FOREIGN KEY (permission_id) REFERENCES permissions(id) ON DELETE CASCADE,
    UNIQUE KEY unique_group_permission (group_id, permission_id),
    INDEX idx_group_id (group_id),
    INDEX idx_permission_id (permission_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS user_sessions (
    id INT AUTO_INCREMENT PRIMARY KEY,
    user_id INT NOT NULL,
    session_token VARCHAR(255) UNIQUE NOT NULL,
    ip_address VARCHAR(45),
    user_agent TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    expires_at TIMESTAMP NOT NULL,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
    INDEX idx_session_token (session_token),
    INDEX idx_user_id (user_id),
    INDEX idx_expires_at (expires_at)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS audit_logs (
    id INT AUTO_INCREMENT PRIMARY KEY,
    user_id INT,
    action VARCHAR(100) NOT NULL,
    resource_type VARCHAR(50),
    resource_id INT,
    details TEXT,
    ip_address VARCHAR(45),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE SET NULL,
    INDEX idx_user_id (user_id),
    INDEX idx_action (action),
    INDEX idx_created_at (created_at)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
SQL_SCHEMA_EOF

    print_success "Schéma SQL créé (7 tables principales)"

    print_step "Création des données initiales..."

    HASHED_PASSWORD=$(php -r "echo password_hash('$ADMIN_PASSWORD', PASSWORD_BCRYPT);")

cat > "$MARIADB_DIR/init/02_seed.sql" << SQL_SEED_EOF
USE bolt_usermanager;

-- 1. CRÉER L'UTILISATEUR EN PREMIER (important pour les FK)
INSERT INTO users (username, email, password_hash, first_name, last_name, is_active, is_superadmin)
VALUES ('$ADMIN_USERNAME', '$ADMIN_EMAIL', '$HASHED_PASSWORD', 'Super', 'Admin', 1, 1)
ON DUPLICATE KEY UPDATE email=VALUES(email);

-- 2. PUIS CRÉER LES GROUPES
INSERT INTO groups (name, description) VALUES

INSERT INTO groups (name, description) VALUES 
('Administrateurs', 'Groupe des administrateurs système'),
('Développeurs', 'Équipe de développement'),
('Utilisateurs', 'Utilisateurs standards'),
('Invités', 'Accès lecture seule')
ON DUPLICATE KEY UPDATE description=VALUES(description);

INSERT INTO permissions (name, description, resource, action) VALUES
('user.create', 'Créer un utilisateur', 'user', 'create'),
('user.read', 'Lire un utilisateur', 'user', 'read'),
('user.update', 'Modifier un utilisateur', 'user', 'update'),
('user.delete', 'Supprimer un utilisateur', 'user', 'delete'),
('group.manage', 'Gérer les groupes', 'group', 'manage'),
('permission.manage', 'Gérer les permissions', 'permission', 'manage'),
('system.admin', 'Administration système', 'system', 'admin')
ON DUPLICATE KEY UPDATE description=VALUES(description);

INSERT INTO user_groups (user_id, group_id) 
SELECT u.id, g.id FROM users u, groups g 
WHERE u.username = '$ADMIN_USERNAME' AND g.name = 'Administrateurs'
ON DUPLICATE KEY UPDATE user_id=VALUES(user_id);

INSERT INTO group_permissions (group_id, permission_id)
SELECT g.id, p.id FROM groups g, permissions p
WHERE g.name = 'Administrateurs'
ON DUPLICATE KEY UPDATE group_id=VALUES(group_id);
SQL_SEED_EOF

    print_success "Données initiales créées"
    echo ""
}

# ═══════════════════════════════════════════════════════════════════════════
# FONCTION: Création des fichiers User Manager v6.7
# ═══════════════════════════════════════════════════════════════════════════
create_usermanager_files() {
    print_section "CRÉATION DES FICHIERS USER MANAGER v6.7"

    print_step "Génération de composer.json..."
    cat > "$USERMANAGER_DIR/app/composer.json" << 'COMPOSER_EOF'
{
    "name": "nbility/bolt-user-manager",
    "description": "Bolt.DIY User Manager v2.0",
    "type": "project",
    "require": {
        "php": ">=8.2",
        "phpmailer/phpmailer": "^6.9",
        "phpoffice/phpspreadsheet": "^1.29",
        "tecnickcom/tcpdf": "^6.6"
    },
    "autoload": {
        "psr-4": {
            "App\\": "app/"
        }
    },
    "config": {
        "optimize-autoloader": true
    }
}
COMPOSER_EOF
    print_success "composer.json créé"

    print_step "Génération de index.php avec bouton déconnexion (v6.7)..."
    cat > "$USERMANAGER_DIR/app/index.php" << 'PHP_INDEX_EOF'
<?php
error_reporting(E_ALL);
ini_set('display_errors', 1);

$db_host = getenv('DB_HOST') ?: 'bolt-mariadb';
$db_port = getenv('DB_PORT') ?: '3306';
$db_name = getenv('DB_NAME') ?: 'bolt_usermanager';
$db_user = getenv('DB_USER') ?: 'bolt_um';
$db_password = getenv('DB_PASSWORD') ?: '';

try {
    $dsn = "mysql:host=$db_host;port=$db_port;dbname=$db_name;charset=utf8mb4";
    $pdo = new PDO($dsn, $db_user, $db_password, [
        PDO::ATTR_ERRMODE => PDO::ERRMODE_EXCEPTION,
        PDO::ATTR_DEFAULT_FETCH_MODE => PDO::FETCH_ASSOC
    ]);
    $stmt = $pdo->query("SELECT COUNT(*) FROM users");
    $total_users = $stmt->fetchColumn();
    $stmt = $pdo->query("SELECT COUNT(*) FROM users WHERE is_active = 1");
    $active_users = $stmt->fetchColumn();
    $stmt = $pdo->query("SELECT COUNT(*) FROM groups");
    $total_groups = $stmt->fetchColumn();
} catch (PDOException $e) {
    $total_users = $active_users = $total_groups = 0;
    $db_error = $e->getMessage();
}
?>
<!DOCTYPE html>
<html lang="fr">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>User Manager v2.0</title>
    <style>
        *{margin:0;padding:0;box-sizing:border-box}
        body{font-family:-apple-system,BlinkMacSystemFont,'Segoe UI',Roboto,sans-serif;background:linear-gradient(135deg,#667eea 0%,#764ba2 100%);min-height:100vh;padding:20px}
        .container{max-width:1200px;margin:0 auto}
        .header{background:white;border-radius:15px;padding:30px;margin-bottom:20px;box-shadow:0 10px 30px rgba(0,0,0,0.2);display:flex;justify-content:space-between;align-items:center;flex-wrap:wrap;gap:20px}
        .header-left h1{color:#667eea;font-size:32px;margin-bottom:5px}
        .header-left p{color:#666;font-size:14px}
        .header-right{display:flex;gap:10px;align-items:center}
        .user-info{display:flex;align-items:center;gap:10px;padding:10px 15px;background:#f3f4f6;border-radius:10px;font-size:14px;color:#374151}
        .user-icon{width:35px;height:35px;background:linear-gradient(135deg,#667eea,#764ba2);border-radius:50%;display:flex;align-items:center;justify-content:center;color:white;font-weight:bold}
        .btn-logout{padding:12px 24px;background:linear-gradient(135deg,#ef4444,#dc2626);color:white;border:none;border-radius:10px;font-weight:600;cursor:pointer;transition:all 0.3s ease;text-decoration:none;display:inline-flex;align-items:center;gap:8px;font-size:15px}
        .btn-logout:hover{transform:translateY(-2px);box-shadow:0 8px 20px rgba(239,68,68,0.4)}
        .stats{display:grid;grid-template-columns:repeat(auto-fit,minmax(250px,1fr));gap:20px}
        .stat-card{background:white;border-radius:15px;padding:25px;box-shadow:0 10px 30px rgba(0,0,0,0.2);text-align:center}
        .stat-card h3{color:#667eea;font-size:36px;margin-bottom:10px}
        .stat-card p{color:#666;font-size:14px;text-transform:uppercase;letter-spacing:1px}
        .footer{text-align:center;color:white;margin-top:30px;font-size:14px;opacity:0.9}
        @media(max-width:768px){.header{flex-direction:column;text-align:center}.header-right{flex-direction:column;width:100%}.btn-logout{width:100%;justify-content:center}}
    </style>
</head>
<body>
    <div class="container">
        <div class="header">
            <div class="header-left">
                <h1>🔧 User Manager v2.0</h1>
                <p>Bolt.DIY Intranet Edition v6.7</p>
            </div>
            <div class="header-right">
                <div class="user-info">
                    <div class="user-icon"><?php echo strtoupper(substr($_SERVER['PHP_AUTH_USER']??'A',0,1));?></div>
                    <span><strong><?php echo htmlspecialchars($_SERVER['PHP_AUTH_USER']??'Admin');?></strong></span>
                </div>
                <a href="/logout.php" class="btn-logout">🚪 Déconnexion</a>
            </div>
        </div>
        <div class="stats">
            <div class="stat-card"><h3><?php echo $total_users;?></h3><p>Utilisateurs totaux</p></div>
            <div class="stat-card"><h3><?php echo $active_users;?></h3><p>Utilisateurs actifs</p></div>
            <div class="stat-card"><h3><?php echo $total_groups;?></h3><p>Groupes</p></div>
        </div>
        <?php if(isset($db_error)):?>
        <div style="background:#fef2f2;border:2px solid #ef4444;border-radius:15px;padding:20px;margin-top:20px">
            <h3 style="color:#dc2626;margin-bottom:10px">⚠️ Erreur de connexion</h3>
            <p style="color:#7f1d1d;font-size:14px"><?php echo htmlspecialchars($db_error);?></p>
        </div>
        <?php endif;?>
        <div class="footer">© 2025 Nbility - Bolt.DIY v6.7 - User Manager v2.0</div>
    </div>
</body>
</html>
PHP_INDEX_EOF
    print_success "index.php créé avec bouton déconnexion"

    print_step "Génération de logout.php (NOUVEAU v6.7)..."
    cat > "$USERMANAGER_DIR/app/logout.php" << 'PHP_LOGOUT_EOF'
<?php
header('WWW-Authenticate: Basic realm="Déconnexion"');
header('HTTP/1.0 401 Unauthorized');
?>
<!DOCTYPE html>
<html lang="fr">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Déconnexion - User Manager</title>
    <style>
        *{margin:0;padding:0;box-sizing:border-box}
        body{font-family:-apple-system,BlinkMacSystemFont,'Segoe UI',Roboto,sans-serif;background:linear-gradient(135deg,#667eea 0%,#764ba2 100%);min-height:100vh;display:flex;align-items:center;justify-content:center;padding:20px}
        .container{background:white;border-radius:20px;padding:60px 40px;box-shadow:0 20px 60px rgba(0,0,0,0.3);text-align:center;max-width:500px;width:100%;animation:slideUp 0.5s ease-out}
        @keyframes slideUp{from{opacity:0;transform:translateY(30px)}to{opacity:1;transform:translateY(0)}}
        .icon{font-size:80px;margin-bottom:20px;animation:bounce 1s ease infinite}
        @keyframes bounce{0%,100%{transform:translateY(0)}50%{transform:translateY(-10px)}}
        h1{color:#667eea;font-size:32px;margin-bottom:15px;font-weight:700}
        p{color:#666;font-size:16px;line-height:1.6;margin-bottom:30px}
        .success-message{background:#10b981;color:white;padding:15px 20px;border-radius:10px;margin-bottom:30px;font-weight:600}
        .buttons{display:flex;gap:15px;justify-content:center;flex-wrap:wrap}
        .btn{display:inline-block;padding:14px 32px;border-radius:12px;font-weight:600;font-size:16px;text-decoration:none;transition:all 0.3s ease;cursor:pointer;border:none}
        .btn-primary{background:linear-gradient(135deg,#667eea,#764ba2);color:white;box-shadow:0 4px 15px rgba(102,126,234,0.4)}
        .btn-primary:hover{transform:translateY(-2px);box-shadow:0 8px 25px rgba(102,126,234,0.6)}
        .btn-secondary{background:#f3f4f6;color:#667eea}
        .btn-secondary:hover{background:#e5e7eb;transform:translateY(-2px)}
        .info-box{background:#f0f9ff;border:2px solid #bfdbfe;border-radius:10px;padding:15px;margin-top:30px;font-size:14px;color:#1e40af;text-align:left}
        .info-box strong{display:block;margin-bottom:8px;font-size:15px}
        @media(max-width:600px){.container{padding:40px 30px}h1{font-size:26px}.buttons{flex-direction:column}.btn{width:100%}}
    </style>
</head>
<body>
    <div class="container">
        <div class="icon">👋</div>
        <h1>Déconnexion réussie</h1>
        <div class="success-message">✓ Vous avez été déconnecté avec succès</div>
        <p>Votre session a été fermée. Pour des raisons de sécurité, nous vous recommandons de fermer complètement votre navigateur.</p>
        <div class="buttons">
            <a href="http://LOCAL_IP:HOST_PORT_UM" class="btn btn-primary">🔐 Se reconnecter</a>
            <a href="http://LOCAL_IP:HOST_PORT_HOME" class="btn btn-secondary">🏠 Page d'accueil</a>
        </div>
        <div class="info-box">
            <strong>ℹ️ Note importante :</strong>
            L'authentification HTTP Basic est stockée par votre navigateur. Pour une déconnexion complète, fermez tous les onglets et redémarrez votre navigateur.
        </div>
    </div>
</body>
</html>
PHP_LOGOUT_EOF
    print_success "logout.php créé (NOUVEAU v6.7)"

    echo ""
}

create_htpasswd() {
    print_section "CRÉATION DU FICHIER HTPASSWD"

    print_step "Génération du fichier htpasswd pour NGINX..."

    if [ -f "$HTPASSWD_FILE" ]; then
        rm -f "$HTPASSWD_FILE"
        print_info "Ancien fichier htpasswd supprimé"
    fi

    if command -v htpasswd &> /dev/null; then
        if htpasswd -cbB "$HTPASSWD_FILE" "$NGINX_USER" "$NGINX_PASS"; then
            print_success "Fichier htpasswd créé avec bcrypt"
        else
            print_error "Échec de la création du fichier htpasswd"
            exit 1
        fi
    else
        print_error "La commande htpasswd n'est pas disponible"
        echo "Installation de apache2-utils..."
        if command -v apt-get &> /dev/null; then
            sudo apt-get update
            sudo apt-get install -y apache2-utils
            htpasswd -cbB "$HTPASSWD_FILE" "$NGINX_USER" "$NGINX_PASS"
        else
            print_error "Impossible d'installer htpasswd automatiquement"
            exit 1
        fi
    fi

    chmod 644 "$HTPASSWD_FILE"

    if [ -s "$HTPASSWD_FILE" ]; then
        print_success "Fichier htpasswd valide"
    else
        print_error "Fichier htpasswd VIDE"
        exit 1
    fi

    echo ""
}

generate_html_pages() {
    print_section "GÉNÉRATION DE home.html (v6.7 - avec rel)"

    print_step "Génération de la page d'accueil avec corrections..."

    if [ -f "$TEMPLATES_DIR/home.html" ]; then
        sed -i "s/LOCAL_IP/$LOCAL_IP/g" "$TEMPLATES_DIR/home.html"
        sed -i "s/HOST_PORT_BOLT/$HOST_PORT_BOLT/g" "$TEMPLATES_DIR/home.html"
        sed -i "s/HOST_PORT_HOME/$HOST_PORT_HOME/g" "$TEMPLATES_DIR/home.html"
        sed -i "s/HOST_PORT_UM/$HOST_PORT_UM/g" "$TEMPLATES_DIR/home.html"
        print_success "Variables remplacées dans home.html"
    else
        print_warning "home.html non trouvé, création par défaut..."
        echo "<!DOCTYPE html><html><head><title>Bolt.DIY v6.7</title></head><body><h1>Welcome to Bolt.DIY</h1></body></html>" > "$TEMPLATES_DIR/home.html"
    fi

    if [ -f "$USERMANAGER_DIR/app/logout.php" ]; then
        sed -i "s/LOCAL_IP/$LOCAL_IP/g" "$USERMANAGER_DIR/app/logout.php"
        sed -i "s/HOST_PORT_UM/$HOST_PORT_UM/g" "$USERMANAGER_DIR/app/logout.php"
        sed -i "s/HOST_PORT_HOME/$HOST_PORT_HOME/g" "$USERMANAGER_DIR/app/logout.php"
        print_success "Variables remplacées dans logout.php"
    fi

    echo ""
}

fix_bolt_dockerfile() {
    print_section "FIX DOCKERFILE BOLT"

    cd "$INSTALL_DIR"

    local dockerfile_template="$TEMPLATES_DIR/bolt.diy/Dockerfile"
    local dockerfile_target="$BOLT_DIR/Dockerfile"

    if [ -f "$dockerfile_template" ] && [ -f "$dockerfile_target" ]; then
        print_step "Application du fix wrangler..."
        cp "$dockerfile_template" "$dockerfile_target"
        print_success "Fix Dockerfile appliqué"
    else
        print_warning "Templates Dockerfile non trouvés, skip"
    fi

    echo ""
}

# ═══════════════════════════════════════════════════════════════════════════
# FONCTION: Build et démarrage des conteneurs
# ═══════════════════════════════════════════════════════════════════════════
build_and_start() {
    print_section "BUILD ET DÉMARRAGE DES CONTENEURS"

    cd "$INSTALL_DIR"

    print_step "Vérification de la configuration docker-compose..."
    if docker compose config &> /dev/null; then
        print_success "Configuration valide"
    else
        print_error "Configuration docker-compose invalide"
        docker compose config
        exit 1
    fi

    print_step "Build des images Docker (plusieurs minutes)..."
    echo -e "${YELLOW}Build en cours...${NC}"

    if docker compose build --no-cache 2>&1 | tee /tmp/docker_build.log; then
        print_success "Build réussi"
    else
        print_error "Échec du build"
        echo ""
        echo "Logs d'erreur:"
        tail -n 20 /tmp/docker_build.log
        exit 1
    fi

    print_step "Démarrage des conteneurs..."
    if docker compose up -d; then
        print_success "Conteneurs démarrés"
    else
        print_error "Échec du démarrage"
        exit 1
    fi

    echo ""
}

test_services() {
    print_section "TESTS POST-INSTALLATION"

    print_step "Attente du démarrage des services (30s)..."
    sleep 30

    print_step "Test du container bolt-nginx..."
    if docker ps | grep -q "bolt-nginx"; then
        print_success "bolt-nginx: Running"
    else
        print_error "bolt-nginx: Not running"
    fi

    print_step "Test du container bolt-core..."
    if docker ps | grep -q "bolt-core"; then
        print_success "bolt-core: Running"
    else
        print_error "bolt-core: Not running"
    fi

    print_step "Test du container bolt-home..."
    if docker ps | grep -q "bolt-home"; then
        print_success "bolt-home: Running"
    else
        print_error "bolt-home: Not running"
    fi

    print_step "Test du container bolt-user-manager..."
    if docker ps | grep -q "bolt-user-manager"; then
        print_success "bolt-user-manager: Running"
    else
        print_error "bolt-user-manager: Not running"
    fi

    print_step "Test du container bolt-mariadb..."
    if docker ps | grep -q "bolt-mariadb"; then
        print_success "bolt-mariadb: Running"
    else
        print_error "bolt-mariadb: Not running"
    fi

    print_step "Test de connectivité port $HOST_PORT_BOLT..."
    if nc -z -w5 $LOCAL_IP $HOST_PORT_BOLT 2>/dev/null || timeout 5 bash -c "cat < /dev/null > /dev/tcp/$LOCAL_IP/$HOST_PORT_BOLT" 2>/dev/null; then
        print_success "Port $HOST_PORT_BOLT accessible"
    else
        print_warning "Port $HOST_PORT_BOLT non accessible (attendre quelques secondes)"
    fi

    print_step "Test de connectivité port $HOST_PORT_HOME..."
    if nc -z -w5 $LOCAL_IP $HOST_PORT_HOME 2>/dev/null || timeout 5 bash -c "cat < /dev/null > /dev/tcp/$LOCAL_IP/$HOST_PORT_HOME" 2>/dev/null; then
        print_success "Port $HOST_PORT_HOME accessible"
    else
        print_warning "Port $HOST_PORT_HOME non accessible (attendre quelques secondes)"
    fi

    print_step "Test de connectivité port $HOST_PORT_UM..."
    if nc -z -w5 $LOCAL_IP $HOST_PORT_UM 2>/dev/null || timeout 5 bash -c "cat < /dev/null > /dev/tcp/$LOCAL_IP/$HOST_PORT_UM" 2>/dev/null; then
        print_success "Port $HOST_PORT_UM accessible"
    else
        print_warning "Port $HOST_PORT_UM non accessible (attendre quelques secondes)"
    fi

    echo ""
}

print_final_summary() {
    clear
    print_banner

    echo -e "${BOLD}${GREEN}╔══════════════════════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${BOLD}${GREEN}║                                                                              ║${NC}"
    echo -e "${BOLD}${GREEN}║                    ✓ INSTALLATION TERMINÉE AVEC SUCCÈS                       ║${NC}"
    echo -e "${BOLD}${GREEN}║                                                                              ║${NC}"
    echo -e "${BOLD}${GREEN}╚══════════════════════════════════════════════════════════════════════════════╝${NC}"
    echo ""

    echo -e "${BOLD}${CYAN}═══════════════════════════════════════════════════════════════════════════${NC}"
    echo -e "${BOLD}${WHITE}INFORMATIONS D'ACCÈS${NC}"
    echo -e "${BOLD}${CYAN}═══════════════════════════════════════════════════════════════════════════${NC}"
    echo ""

    echo -e "${BOLD}${YELLOW}🏠 Page d'Accueil (PUBLIC - SANS AUTHENTIFICATION):${NC}"
    echo -e "   ${CYAN}http://$LOCAL_IP:$HOST_PORT_HOME${NC}"
    echo ""

    echo -e "${BOLD}${YELLOW}⚡ Bolt.DIY (avec authentification):${NC}"
    echo -e "   ${CYAN}http://$LOCAL_IP:$HOST_PORT_BOLT${NC}"
    echo -e "   ${WHITE}User: ${GREEN}$NGINX_USER${NC}"
    echo -e "   ${WHITE}Pass: ${GREEN}[votre mot de passe]${NC}"
    echo ""

    echo -e "${BOLD}${YELLOW}👥 User Manager (avec authentification):${NC}"
    echo -e "   ${CYAN}http://$LOCAL_IP:$HOST_PORT_UM${NC}"
    echo -e "   ${WHITE}User: ${GREEN}$NGINX_USER${NC}"
    echo -e "   ${WHITE}Pass: ${GREEN}[votre mot de passe]${NC}"
    echo ""

    echo -e "${BOLD}${YELLOW}🚪 Déconnexion User Manager:${NC}"
    echo -e "   ${CYAN}http://$LOCAL_IP:$HOST_PORT_UM/logout.php${NC}"
    echo ""

    echo -e "${BOLD}${CYAN}═══════════════════════════════════════════════════════════════════════════${NC}"
    echo -e "${BOLD}${WHITE}INFORMATIONS SUPER ADMIN${NC}"
    echo -e "${BOLD}${CYAN}═══════════════════════════════════════════════════════════════════════════${NC}"
    echo ""
    echo -e "   ${WHITE}Username: ${GREEN}$ADMIN_USERNAME${NC}"
    echo -e "   ${WHITE}Email:    ${GREEN}$ADMIN_EMAIL${NC}"
    echo ""

    echo -e "${BOLD}${CYAN}═══════════════════════════════════════════════════════════════════════════${NC}"
    echo -e "${BOLD}${WHITE}COMMANDES UTILES${NC}"
    echo -e "${BOLD}${CYAN}═══════════════════════════════════════════════════════════════════════════${NC}"
    echo ""
    echo -e "   ${YELLOW}Voir les logs:${NC}"
    echo -e "   ${CYAN}docker compose logs -f${NC}"
    echo ""
    echo -e "   ${YELLOW}Arrêter les services:${NC}"
    echo -e "   ${CYAN}docker compose down${NC}"
    echo ""
    echo -e "   ${YELLOW}Redémarrer les services:${NC}"
    echo -e "   ${CYAN}docker compose restart${NC}"
    echo ""
    echo -e "   ${YELLOW}Reconstruire après modification:${NC}"
    echo -e "   ${CYAN}docker compose up -d --build${NC}"
    echo ""

    echo -e "${BOLD}${CYAN}═══════════════════════════════════════════════════════════════════════════${NC}"
    echo -e "${BOLD}${WHITE}NOUVEAUTÉS v6.7${NC}"
    echo -e "${BOLD}${CYAN}═══════════════════════════════════════════════════════════════════════════${NC}"
    echo ""
    echo -e "   ${GREEN}✓${NC} Page d'accueil accessible SANS authentification (port $HOST_PORT_HOME)"
    echo -e "   ${GREEN}✓${NC} Bouton de déconnexion dans User Manager"
    echo -e "   ${GREEN}✓${NC} Page de déconnexion dédiée (/logout.php)"
    echo -e "   ${GREEN}✓${NC} Affichage de l'utilisateur connecté"
    echo -e "   ${GREEN}✓${NC} Liens externes avec rel='noopener noreferrer'"
    echo ""

    echo -e "${BOLD}${MAGENTA}Support: contact@nbility.fr${NC}"
    echo -e "${BOLD}${MAGENTA}Documentation: https://github.com/NBILITY-HOME/BOLT.DIY-INTRANET${NC}"
    echo ""
}

# ═══════════════════════════════════════════════════════════════════════════
# MAIN - Fonction principale
# ═══════════════════════════════════════════════════════════════════════════
main() {
    print_banner

    check_prerequisites
    check_internet_and_github
    get_configuration
    clone_repository
    create_directory_structure
    generate_docker_compose
    generate_nginx_conf
    generate_usermanager_dockerfile
    generate_health_php
    generate_env_files
    create_sql_files
    create_usermanager_files
    create_htpasswd
    generate_html_pages
    fix_bolt_dockerfile
    build_and_start
    test_services
    print_final_summary
}

main "$@"
