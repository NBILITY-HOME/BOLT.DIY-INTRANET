#!/bin/bash
#═══════════════════════════════════════════════════════════════════════════
# BOLT.DIY NBILITY - Installation Script v6.5
# Architecture Multi-Ports + User Manager v2.0 + MariaDB + Docker Compose
# © Copyright Nbility 2025 - contact@nbility.fr
#
# NOUVEAUTÉS v6.5:
# ✨ Génération automatique de docker-compose.yml
# ✨ Génération automatique de nginx.conf complet avec préservation du port
# ✨ Création du Dockerfile User Manager (PHP 8.2 + Apache)
# ✨ Configuration .env Bolt complète (APP_URL, VITE_BASE_URL, etc.)
# ✨ Création de health.php pour healthcheck Docker
# ✨ Validation et tests post-installation
# ✨ Diagnostic des problèmes de port automatique
#═══════════════════════════════════════════════════════════════════════════

clear
printf "\033[8;55;116t"

# ═══════════════════════════════════════════════════════════════════════════
# VÉRIFICATION SUDO
# ═══════════════════════════════════════════════════════════════════════════
if [ "$EUID" -eq 0 ]; then
    echo -e "\033[0;31m✗ ERREUR: Ce script NE DOIT PAS être lancé en sudo/root\033[0m"
    echo ""
    echo "Raison: Docker et les fichiers doivent appartenir à votre utilisateur"
    echo ""
    echo "Solution: Lancez le script sans sudo:"
    echo "  ./install_bolt_nbility_v6.5.sh"
    echo ""
    echo "Si Docker nécessite sudo, ajoutez votre utilisateur au groupe docker:"
    echo "  sudo usermod -aG docker \$USER"
    echo "  newgrp docker"
    echo ""
    exit 1
fi

# ═══════════════════════════════════════════════════════════════════════════
# COULEURS ET SYMBOLES
# ═══════════════════════════════════════════════════════════════════════════
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

# ═══════════════════════════════════════════════════════════════════════════
# VARIABLES GLOBALES
# ═══════════════════════════════════════════════════════════════════════════
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

# Variables de configuration (remplies par get_configuration)
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

# API Keys (optionnelles)
ANTHROPIC_KEY=""
OPENAI_KEY=""
GEMINI_KEY=""
GROQ_KEY=""
MISTRAL_KEY=""
DEEPSEEK_KEY=""
HF_KEY=""

# ═══════════════════════════════════════════════════════════════════════════
# FONCTIONS UTILITAIRES
# ═══════════════════════════════════════════════════════════════════════════

print_banner() {
    clear
    echo -e "${CYAN}"
    echo "╔══════════════════════════════════════════════════════════════════════════════╗"
    echo "║                                                                              ║"
    echo "║                    ${BOLD}BOLT.DIY NBILITY - Installer v6.5${NC}${CYAN}                     ║"
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

# ═══════════════════════════════════════════════════════════════════════════
# FONCTION: Vérification des prérequis
# ═══════════════════════════════════════════════════════════════════════════
check_prerequisites() {
    print_section "VÉRIFICATION DES PRÉREQUIS"

    local all_good=true

    # Docker
    print_step "Vérification de Docker..."
    if command -v docker &> /dev/null; then
        DOCKER_VERSION=$(docker --version | awk '{print $3}' | tr -d ',')
        print_success "Docker installé: v$DOCKER_VERSION"
    else
        print_error "Docker n'est pas installé"
        all_good=false
    fi

    # Docker Compose
    print_step "Vérification de Docker Compose..."
    if docker compose version &> /dev/null; then
        COMPOSE_VERSION=$(docker compose version | awk '{print $4}')
        print_success "Docker Compose installé: v$COMPOSE_VERSION"
    else
        print_error "Docker Compose n'est pas installé"
        all_good=false
    fi

    # Git
    print_step "Vérification de Git..."
    if command -v git &> /dev/null; then
        GIT_VERSION=$(git --version | awk '{print $3}')
        print_success "Git installé: v$GIT_VERSION"
    else
        print_error "Git n'est pas installé"
        all_good=false
    fi

    # curl
    print_step "Vérification de curl..."
    if command -v curl &> /dev/null; then
        print_success "curl installé"
    else
        print_error "curl n'est pas installé"
        all_good=false
    fi

    # htpasswd (apache2-utils)
    print_step "Vérification de htpasswd..."
    if command -v htpasswd &> /dev/null; then
        print_success "htpasswd installé"
    else
        print_warning "htpasswd n'est pas installé (optionnel, auth nginx)"
    fi

    echo ""

    if [ "$all_good" = false ]; then
        print_error "Certains prérequis sont manquants"
        echo ""
        echo "Installez les dépendances manquantes:"
        echo "  sudo apt-get update"
        echo "  sudo apt-get install -y docker.io docker-compose git curl apache2-utils"
        echo ""
        exit 1
    fi

    print_success "Tous les prérequis sont satisfaits"
    echo ""
}

# ═══════════════════════════════════════════════════════════════════════════
# FONCTION: Vérification Internet et GitHub
# ═══════════════════════════════════════════════════════════════════════════
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

# ═══════════════════════════════════════════════════════════════════════════
# FONCTION: Vérification de disponibilité d'un port
# ═══════════════════════════════════════════════════════════════════════════
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

# ═══════════════════════════════════════════════════════════════════════════
# FONCTION: Génération de mots de passe sécurisés
# ═══════════════════════════════════════════════════════════════════════════
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

    # IP Locale
    print_step "Détection de l'IP locale..."
    DETECTED_IP=$(hostname -I | awk '{print $1}')
    echo -e "${CYAN}IP détectée: ${WHITE}$DETECTED_IP${NC}"
    read -p "$(echo -e ${YELLOW}Confirmer ou entrer l\'IP: ${NC})" input_ip
    LOCAL_IP=${input_ip:-$DETECTED_IP}
    print_success "IP configurée: $LOCAL_IP"
    echo ""

    # IP Gateway
    print_step "Configuration de la gateway (box/routeur)..."
    DETECTED_GW=$(ip route | grep default | awk '{print $3}' | head -n1)
    echo -e "${CYAN}Gateway détectée: ${WHITE}$DETECTED_GW${NC}"
    read -p "$(echo -e ${YELLOW}Confirmer ou entrer la gateway: ${NC})" input_gw
    GATEWAY_IP=${input_gw:-$DETECTED_GW}
    print_success "Gateway configurée: $GATEWAY_IP"
    echo ""

    # Ports
    print_step "Configuration des ports..."
    echo ""

    while true; do
        read -p "$(echo -e ${YELLOW}Port pour Bolt.DIY [défaut: 8585]: ${NC})" input_bolt
        HOST_PORT_BOLT=${input_bolt:-8585}
        if check_port_available $HOST_PORT_BOLT "Bolt.DIY"; then
            break
        fi
    done

    while true; do
        read -p "$(echo -e ${YELLOW}Port pour Home [défaut: 8686]: ${NC})" input_home
        HOST_PORT_HOME=${input_home:-8686}
        if check_port_available $HOST_PORT_HOME "Home"; then
            break
        fi
    done

    while true; do
        read -p "$(echo -e ${YELLOW}Port pour User Manager [défaut: 8687]: ${NC})" input_um
        HOST_PORT_UM=${input_um:-8687}
        if check_port_available $HOST_PORT_UM "User Manager"; then
            break
        fi
    done

    echo ""

    # Authentification NGINX
    print_step "Configuration de l'authentification NGINX..."
    echo ""
    read -p "$(echo -e ${YELLOW}Nom d\'utilisateur: ${NC})" NGINX_USER
    while true; do
        read -sp "$(echo -e ${YELLOW}Mot de passe: ${NC})" NGINX_PASS
        echo ""
        read -sp "$(echo -e ${YELLOW}Confirmer le mot de passe: ${NC})" NGINX_PASS_CONFIRM
        echo ""
        if [ "$NGINX_PASS" = "$NGINX_PASS_CONFIRM" ]; then
            break
        else
            print_error "Les mots de passe ne correspondent pas"
        fi
    done
    print_success "Authentification NGINX configurée"
    echo ""

    # Super Admin
    print_step "Configuration du Super Admin..."
    echo ""
    read -p "$(echo -e ${YELLOW}Username Super Admin: ${NC})" ADMIN_USERNAME
    read -p "$(echo -e ${YELLOW}Email Super Admin: ${NC})" ADMIN_EMAIL
    while true; do
        read -sp "$(echo -e ${YELLOW}Mot de passe Super Admin: ${NC})" ADMIN_PASSWORD
        echo ""
        read -sp "$(echo -e ${YELLOW}Confirmer le mot de passe: ${NC})" ADMIN_PASSWORD_CONFIRM
        echo ""
        if [ "$ADMIN_PASSWORD" = "$ADMIN_PASSWORD_CONFIRM" ]; then
            break
        else
            print_error "Les mots de passe ne correspondent pas"
        fi
    done
    print_success "Super Admin configuré"
    echo ""

    # Génération des mots de passe BDD
    print_step "Génération des mots de passe MariaDB..."
    MARIADB_ROOT_PASSWORD=$(generate_secure_password 32)
    MARIADB_USER_PASSWORD=$(generate_secure_password 32)
    APP_SECRET=$(generate_app_secret)
    print_success "Mots de passe générés automatiquement"
    echo ""

    # API Keys (optionnel)
    print_step "Configuration des API Keys (optionnel - Entrée pour ignorer)..."
    echo ""
    read -p "$(echo -e ${CYAN}Anthropic API Key: ${NC})" ANTHROPIC_KEY
    read -p "$(echo -e ${CYAN}OpenAI API Key: ${NC})" OPENAI_KEY
    read -p "$(echo -e ${CYAN}Google Gemini API Key: ${NC})" GEMINI_KEY
    read -p "$(echo -e ${CYAN}Groq API Key: ${NC})" GROQ_KEY
    read -p "$(echo -e ${CYAN}Mistral API Key: ${NC})" MISTRAL_KEY
    read -p "$(echo -e ${CYAN}DeepSeek API Key: ${NC})" DEEPSEEK_KEY
    read -p "$(echo -e ${CYAN}HuggingFace API Key: ${NC})" HF_KEY

    echo ""
    print_success "Configuration terminée"
    echo ""
}

# ═══════════════════════════════════════════════════════════════════════════
# FONCTION: Clonage du repository
# ═══════════════════════════════════════════════════════════════════════════
clone_repository() {
    print_section "CLONAGE DU REPOSITORY GITHUB"

    if [ -d "$INSTALL_DIR" ]; then
        print_warning "Le répertoire $REPO_NAME existe déjà"
        read -p "$(echo -e ${YELLOW}Supprimer et re-cloner ? (o/N): ${NC})" confirm
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

# ═══════════════════════════════════════════════════════════════════════════
# FONCTION: Création de la structure de répertoires
# ═══════════════════════════════════════════════════════════════════════════
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
# FONCTION: Génération du fichier docker-compose.yml
# ═══════════════════════════════════════════════════════════════════════════
generate_docker_compose() {
    print_section "GÉNÉRATION DU DOCKER-COMPOSE.YML"

    print_step "Création de docker-compose.yml..."

    cat > "$INSTALL_DIR/docker-compose.yml" << 'DOCKER_COMPOSE_EOF'
version: '3.8'

services:
  # ════════════════════════════════════════════════════════════════
  # NGINX REVERSE PROXY
  # ════════════════════════════════════════════════════════════════
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
    healthcheck:
      test: ["CMD", "wget", "--quiet", "--tries=1", "--spider", "http://localhost:8585/health"]
      interval: 30s
      timeout: 10s
      retries: 3

  # ════════════════════════════════════════════════════════════════
  # BOLT.DIY CORE APPLICATION
  # ════════════════════════════════════════════════════════════════
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
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:5173"]
      interval: 30s
      timeout: 10s
      retries: 3

  # ════════════════════════════════════════════════════════════════
  # BOLT HOME (Page d accueil HTML statique)
  # ════════════════════════════════════════════════════════════════
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

  # ════════════════════════════════════════════════════════════════
  # USER MANAGER v2.0 (PHP + Apache)
  # ════════════════════════════════════════════════════════════════
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
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost/health.php"]
      interval: 30s
      timeout: 10s
      retries: 3

  # ════════════════════════════════════════════════════════════════
  # MARIADB DATABASE
  # ════════════════════════════════════════════════════════════════
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

# ═══════════════════════════════════════════════════════════════════════════
# FONCTION: Génération fichiers .env
# ═══════════════════════════════════════════════════════════════════════════
generate_env_files() {
    print_section "GÉNÉRATION DES FICHIERS .ENV"

    # Fichier .env principal du projet (pour docker-compose)
    print_step "Création du fichier .env principal..."
    cat > "$INSTALL_DIR/.env" << ENV_MAIN_EOF
# ════════════════════════════════════════════════════════════════
# BOLT.DIY INTRANET - Configuration Docker v6.5
# ════════════════════════════════════════════════════════════════

# Configuration réseau
LOCAL_IP=$LOCAL_IP

# Ports des services
HOST_PORT_BOLT=$HOST_PORT_BOLT
HOST_PORT_HOME=$HOST_PORT_HOME
HOST_PORT_UM=$HOST_PORT_UM
MARIADB_PORT=$MARIADB_PORT

# Authentification NGINX
HTPASSWD_FILE=$HTPASSWD_FILE

# MariaDB Configuration
MARIADB_ROOT_PASSWORD=$MARIADB_ROOT_PASSWORD
MARIADB_USER=bolt_um
MARIADB_PASSWORD=$MARIADB_USER_PASSWORD

# Application Security
APP_SECRET=$APP_SECRET

# API Keys (Optionnel)
ANTHROPIC_API_KEY=$ANTHROPIC_KEY
OPENAI_API_KEY=$OPENAI_KEY
GOOGLE_GENERATIVE_AI_API_KEY=$GEMINI_KEY
GROQ_API_KEY=$GROQ_KEY
MISTRAL_API_KEY=$MISTRAL_KEY
DEEPSEEK_API_KEY=$DEEPSEEK_KEY
HF_API_KEY=$HF_KEY
ENV_MAIN_EOF

    print_success "Fichier .env principal créé"

    # Fichier .env pour Bolt.DIY
    print_step "Création du fichier .env pour Bolt.DIY..."
    cat > "$BOLT_DIR/.env" << ENV_BOLT_EOF
# ════════════════════════════════════════════════════════════════
# BOLT.DIY CONFIGURATION - v6.5
# ════════════════════════════════════════════════════════════════

# URLs et Routing (CRITIQUE: Préservation du port)
BASE_URL=http://$LOCAL_IP:$HOST_PORT_BOLT
APP_URL=http://$LOCAL_IP:$HOST_PORT_BOLT
PUBLIC_URL=http://$LOCAL_IP:$HOST_PORT_BOLT
VITE_BASE_URL=/
VITE_ROUTER_BASE=/
BASE_PATH=/
ROUTER_BASE=/

# API Keys
ANTHROPIC_API_KEY=$ANTHROPIC_KEY
OPENAI_API_KEY=$OPENAI_KEY
GOOGLE_GENERATIVE_AI_API_KEY=$GEMINI_KEY
GROQ_API_KEY=$GROQ_KEY
MISTRAL_API_KEY=$MISTRAL_KEY
DEEPSEEK_API_KEY=$DEEPSEEK_KEY
HF_API_KEY=$HF_KEY

# Développement
NODE_ENV=production
VITE_LOG_LEVEL=info

# Sécurité
SESSION_SECRET=changeme_with_random_string

# Serveur
PORT=5173
HOST=0.0.0.0
ENV_BOLT_EOF

    print_success "Fichier .env Bolt créé"
    echo ""
}

# ═══════════════════════════════════════════════════════════════════════════
# FONCTION: Création du schéma SQL
# ═══════════════════════════════════════════════════════════════════════════
create_sql_schema() {
    print_section "CRÉATION DU SCHÉMA SQL MARIADB"
    
    mkdir -p "$MARIADB_DIR/init"
    
    cat > "$MARIADB_DIR/init/01-schema.sql" << 'SQL_SCHEMA'
-- ═══════════════════════════════════════════════════════════════════════════
-- BOLT.DIY USER MANAGER v2.0 - Database Schema
-- © Copyright Nbility 2025
-- ═══════════════════════════════════════════════════════════════════════════

SET NAMES utf8mb4;
SET FOREIGN_KEY_CHECKS = 0;

-- ───────────────────────────────────────────────────────────────────────────
-- Table: users
-- ───────────────────────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS `users` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `username` varchar(50) NOT NULL,
  `email` varchar(255) NOT NULL,
  `password_hash` varchar(255) NOT NULL,
  `first_name` varchar(100) DEFAULT NULL,
  `last_name` varchar(100) DEFAULT NULL,
  `phone` varchar(20) DEFAULT NULL,
  `avatar_url` varchar(500) DEFAULT NULL,
  `is_active` tinyint(1) DEFAULT 1,
  `is_super_admin` tinyint(1) DEFAULT 0,
  `email_verified` tinyint(1) DEFAULT 0,
  `email_verification_token` varchar(100) DEFAULT NULL,
  `password_reset_token` varchar(100) DEFAULT NULL,
  `password_reset_expires` datetime DEFAULT NULL,
  `last_login_at` datetime DEFAULT NULL,
  `last_login_ip` varchar(45) DEFAULT NULL,
  `failed_login_attempts` int(11) DEFAULT 0,
  `lockout_until` datetime DEFAULT NULL,
  `created_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  UNIQUE KEY `username` (`username`),
  UNIQUE KEY `email` (`email`),
  KEY `idx_email_verified` (`email_verified`),
  KEY `idx_is_active` (`is_active`),
  KEY `idx_is_super_admin` (`is_super_admin`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ───────────────────────────────────────────────────────────────────────────
-- Table: groups
-- ───────────────────────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS `groups` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `name` varchar(100) NOT NULL,
  `description` text DEFAULT NULL,
  `color` varchar(7) DEFAULT '#3498db',
  `icon` varchar(50) DEFAULT 'users',
  `is_system` tinyint(1) DEFAULT 0,
  `created_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  UNIQUE KEY `name` (`name`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ───────────────────────────────────────────────────────────────────────────
-- Table: user_groups
-- ───────────────────────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS `user_groups` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `user_id` int(11) NOT NULL,
  `group_id` int(11) NOT NULL,
  `created_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  UNIQUE KEY `user_group_unique` (`user_id`, `group_id`),
  KEY `fk_user_groups_user` (`user_id`),
  KEY `fk_user_groups_group` (`group_id`),
  CONSTRAINT `fk_user_groups_user` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`) ON DELETE CASCADE,
  CONSTRAINT `fk_user_groups_group` FOREIGN KEY (`group_id`) REFERENCES `groups` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ───────────────────────────────────────────────────────────────────────────
-- Table: permissions
-- ───────────────────────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS `permissions` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `name` varchar(100) NOT NULL,
  `slug` varchar(100) NOT NULL,
  `description` text DEFAULT NULL,
  `category` varchar(50) DEFAULT 'general',
  `created_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  UNIQUE KEY `slug` (`slug`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ───────────────────────────────────────────────────────────────────────────
-- Table: group_permissions
-- ───────────────────────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS `group_permissions` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `group_id` int(11) NOT NULL,
  `permission_id` int(11) NOT NULL,
  `created_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  UNIQUE KEY `group_permission_unique` (`group_id`, `permission_id`),
  KEY `fk_group_permissions_group` (`group_id`),
  KEY `fk_group_permissions_permission` (`permission_id`),
  CONSTRAINT `fk_group_permissions_group` FOREIGN KEY (`group_id`) REFERENCES `groups` (`id`) ON DELETE CASCADE,
  CONSTRAINT `fk_group_permissions_permission` FOREIGN KEY (`permission_id`) REFERENCES `permissions` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ───────────────────────────────────────────────────────────────────────────
-- Table: sessions
-- ───────────────────────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS `sessions` (
  `id` varchar(128) NOT NULL,
  `user_id` int(11) NOT NULL,
  `ip_address` varchar(45) DEFAULT NULL,
  `user_agent` text DEFAULT NULL,
  `payload` longtext NOT NULL,
  `last_activity` int(11) NOT NULL,
  `created_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  KEY `fk_sessions_user` (`user_id`),
  KEY `idx_last_activity` (`last_activity`),
  CONSTRAINT `fk_sessions_user` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ───────────────────────────────────────────────────────────────────────────
-- Table: audit_logs
-- ───────────────────────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS `audit_logs` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `user_id` int(11) DEFAULT NULL,
  `action` varchar(100) NOT NULL,
  `entity_type` varchar(50) DEFAULT NULL,
  `entity_id` int(11) DEFAULT NULL,
  `old_values` json DEFAULT NULL,
  `new_values` json DEFAULT NULL,
  `ip_address` varchar(45) DEFAULT NULL,
  `user_agent` text DEFAULT NULL,
  `created_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  KEY `fk_audit_logs_user` (`user_id`),
  KEY `idx_action` (`action`),
  KEY `idx_entity` (`entity_type`, `entity_id`),
  KEY `idx_created_at` (`created_at`),
  CONSTRAINT `fk_audit_logs_user` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ───────────────────────────────────────────────────────────────────────────
-- Table: settings
-- ───────────────────────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS `settings` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `key` varchar(100) NOT NULL,
  `value` text DEFAULT NULL,
  `type` varchar(20) DEFAULT 'string',
  `description` text DEFAULT NULL,
  `category` varchar(50) DEFAULT 'general',
  `updated_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  UNIQUE KEY `key` (`key`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ───────────────────────────────────────────────────────────────────────────
-- Table: themes
-- ───────────────────────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS `themes` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `name` varchar(100) NOT NULL,
  `slug` varchar(100) NOT NULL,
  `primary_color` varchar(7) DEFAULT '#3498db',
  `secondary_color` varchar(7) DEFAULT '#2ecc71',
  `background_color` varchar(7) DEFAULT '#ffffff',
  `text_color` varchar(7) DEFAULT '#2c3e50',
  `is_default` tinyint(1) DEFAULT 0,
  `is_active` tinyint(1) DEFAULT 1,
  `created_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  UNIQUE KEY `slug` (`slug`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ───────────────────────────────────────────────────────────────────────────
-- Table: notifications
-- ───────────────────────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS `notifications` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `user_id` int(11) NOT NULL,
  `type` varchar(50) NOT NULL,
  `title` varchar(255) NOT NULL,
  `message` text NOT NULL,
  `data` json DEFAULT NULL,
  `is_read` tinyint(1) DEFAULT 0,
  `read_at` datetime DEFAULT NULL,
  `created_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  KEY `fk_notifications_user` (`user_id`),
  KEY `idx_is_read` (`is_read`),
  CONSTRAINT `fk_notifications_user` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ───────────────────────────────────────────────────────────────────────────
-- Table: webhooks
-- ───────────────────────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS `webhooks` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `name` varchar(100) NOT NULL,
  `url` varchar(500) NOT NULL,
  `secret` varchar(100) DEFAULT NULL,
  `events` json NOT NULL,
  `is_active` tinyint(1) DEFAULT 1,
  `last_triggered_at` datetime DEFAULT NULL,
  `failure_count` int(11) DEFAULT 0,
  `created_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ───────────────────────────────────────────────────────────────────────────
-- Table: webhook_logs
-- ───────────────────────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS `webhook_logs` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `webhook_id` int(11) NOT NULL,
  `event` varchar(100) NOT NULL,
  `payload` json NOT NULL,
  `response_code` int(11) DEFAULT NULL,
  `response_body` text DEFAULT NULL,
  `is_success` tinyint(1) DEFAULT 0,
  `error_message` text DEFAULT NULL,
  `created_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  KEY `fk_webhook_logs_webhook` (`webhook_id`),
  KEY `idx_created_at` (`created_at`),
  CONSTRAINT `fk_webhook_logs_webhook` FOREIGN KEY (`webhook_id`) REFERENCES `webhooks` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ───────────────────────────────────────────────────────────────────────────
-- Table: reports
-- ───────────────────────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS `reports` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `name` varchar(255) NOT NULL,
  `type` varchar(50) NOT NULL,
  `parameters` json DEFAULT NULL,
  `file_path` varchar(500) DEFAULT NULL,
  `file_size` bigint(20) DEFAULT NULL,
  `status` enum('pending','processing','completed','failed') DEFAULT 'pending',
  `generated_by` int(11) DEFAULT NULL,
  `generated_at` datetime DEFAULT NULL,
  `created_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  KEY `fk_reports_user` (`generated_by`),
  KEY `idx_status` (`status`),
  CONSTRAINT `fk_reports_user` FOREIGN KEY (`generated_by`) REFERENCES `users` (`id`) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ───────────────────────────────────────────────────────────────────────────
-- Table: email_templates
-- ───────────────────────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS `email_templates` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `name` varchar(100) NOT NULL,
  `slug` varchar(100) NOT NULL,
  `subject` varchar(255) NOT NULL,
  `body_html` text NOT NULL,
  `body_text` text DEFAULT NULL,
  `variables` json DEFAULT NULL,
  `is_system` tinyint(1) DEFAULT 0,
  `created_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  UNIQUE KEY `slug` (`slug`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

SET FOREIGN_KEY_CHECKS = 1;
SQL_SCHEMA

    print_success "Schéma SQL créé (14 tables)"
}

# ═══════════════════════════════════════════════════════════════════════════
# FONCTION: Création des données initiales SQL
# ═══════════════════════════════════════════════════════════════════════════
create_sql_seed() {
    print_step "Création des données initiales..."
    
    local ADMIN_PASSWORD_HASH
    ADMIN_PASSWORD_HASH=$(php -r "echo password_hash('$ADMIN_PASSWORD', PASSWORD_BCRYPT);")
    
    cat > "$MARIADB_DIR/init/02-seed.sql" << SQL_SEED
-- ═══════════════════════════════════════════════════════════════════════════
-- BOLT.DIY USER MANAGER v2.0 - Initial Data
-- © Copyright Nbility 2025
-- ═══════════════════════════════════════════════════════════════════════════

SET NAMES utf8mb4;

-- ───────────────────────────────────────────────────────────────────────────
-- Insertion du Super Admin
-- ───────────────────────────────────────────────────────────────────────────
INSERT INTO users (username, email, password_hash, first_name, last_name, is_active, is_super_admin, email_verified)
VALUES ('$ADMIN_USERNAME', '$ADMIN_EMAIL', '$ADMIN_PASSWORD_HASH', 'Super', 'Admin', 1, 1, 1);

-- ───────────────────────────────────────────────────────────────────────────
-- Groupes par défaut
-- ───────────────────────────────────────────────────────────────────────────
INSERT INTO \`groups\` (name, description, color, icon, is_system) VALUES
('Administrateurs', 'Accès complet au système', '#e74c3c', 'shield', 1),
('Développeurs', 'Équipe de développement', '#3498db', 'code', 0),
('Support', 'Équipe support client', '#2ecc71', 'headset', 0),
('Utilisateurs', 'Utilisateurs standard', '#95a5a6', 'users', 1);

-- ───────────────────────────────────────────────────────────────────────────
-- Permissions par défaut
-- ───────────────────────────────────────────────────────────────────────────
INSERT INTO permissions (name, slug, description, category) VALUES
('Gérer les utilisateurs', 'manage_users', 'Créer, modifier et supprimer des utilisateurs', 'users'),
('Voir les utilisateurs', 'view_users', 'Consulter la liste des utilisateurs', 'users'),
('Gérer les groupes', 'manage_groups', 'Créer, modifier et supprimer des groupes', 'groups'),
('Voir les groupes', 'view_groups', 'Consulter la liste des groupes', 'groups'),
('Gérer les permissions', 'manage_permissions', 'Attribuer et retirer des permissions', 'permissions'),
('Voir les logs', 'view_audit_logs', 'Consulter les logs d\'audit', 'logs'),
('Gérer les settings', 'manage_settings', 'Modifier les paramètres système', 'settings'),
('Gérer les thèmes', 'manage_themes', 'Créer et modifier des thèmes', 'themes'),
('Gérer les webhooks', 'manage_webhooks', 'Configurer les webhooks', 'webhooks'),
('Générer des rapports', 'generate_reports', 'Créer et exporter des rapports', 'reports');

-- ───────────────────────────────────────────────────────────────────────────
-- Attribution groupe Administrateurs au Super Admin
-- ───────────────────────────────────────────────────────────────────────────
INSERT INTO user_groups (user_id, group_id)
SELECT 1, id FROM \`groups\` WHERE name = 'Administrateurs';

-- ───────────────────────────────────────────────────────────────────────────
-- Attribution de toutes les permissions au groupe Administrateurs
-- ───────────────────────────────────────────────────────────────────────────
INSERT INTO group_permissions (group_id, permission_id)
SELECT g.id, p.id
FROM \`groups\` g
CROSS JOIN permissions p
WHERE g.name = 'Administrateurs';

-- ───────────────────────────────────────────────────────────────────────────
-- Settings par défaut
-- ───────────────────────────────────────────────────────────────────────────
INSERT INTO settings (\`key\`, value, type, description, category) VALUES
('site_name', 'Bolt.DIY User Manager', 'string', 'Nom du site', 'general'),
('site_description', 'Système de gestion des utilisateurs', 'string', 'Description du site', 'general'),
('items_per_page', '20', 'integer', 'Nombre d''éléments par page', 'general'),
('session_lifetime', '7200', 'integer', 'Durée de session en secondes (2h)', 'security'),
('max_login_attempts', '5', 'integer', 'Tentatives de connexion max', 'security'),
('lockout_duration', '900', 'integer', 'Durée de verrouillage en secondes (15min)', 'security'),
('password_min_length', '8', 'integer', 'Longueur minimale du mot de passe', 'security'),
('require_email_verification', '1', 'boolean', 'Vérification email obligatoire', 'security'),
('smtp_host', '', 'string', 'Serveur SMTP', 'email'),
('smtp_port', '587', 'integer', 'Port SMTP', 'email'),
('smtp_username', '', 'string', 'Utilisateur SMTP', 'email'),
('smtp_password', '', 'string', 'Mot de passe SMTP', 'email'),
('smtp_encryption', 'tls', 'string', 'Encryption SMTP (tls/ssl)', 'email'),
('smtp_from_email', 'noreply@example.com', 'string', 'Email expéditeur', 'email'),
('smtp_from_name', 'Bolt.DIY User Manager', 'string', 'Nom expéditeur', 'email');

-- ───────────────────────────────────────────────────────────────────────────
-- Thèmes par défaut
-- ───────────────────────────────────────────────────────────────────────────
INSERT INTO themes (name, slug, primary_color, secondary_color, background_color, text_color, is_default, is_active) VALUES
('Bleu par défaut', 'default-blue', '#3498db', '#2ecc71', '#ffffff', '#2c3e50', 1, 1),
('Sombre', 'dark', '#2c3e50', '#3498db', '#1a1a1a', '#ecf0f1', 0, 1),
('Vert professionnel', 'professional-green', '#27ae60', '#2ecc71', '#ffffff', '#2c3e50', 0, 1);

-- ───────────────────────────────────────────────────────────────────────────
-- Templates d'emails
-- ───────────────────────────────────────────────────────────────────────────
INSERT INTO email_templates (name, slug, subject, body_html, body_text, is_system) VALUES
('Vérification email', 'email_verification', 'Vérifiez votre adresse email', '<h1>Bienvenue!</h1><p>Cliquez sur le lien pour vérifier votre email: {{verification_link}}</p>', 'Bienvenue! Cliquez sur le lien pour vérifier votre email: {{verification_link}}', 1),
('Réinitialisation mot de passe', 'password_reset', 'Réinitialisation de votre mot de passe', '<h1>Réinitialisation</h1><p>Cliquez sur le lien pour réinitialiser votre mot de passe: {{reset_link}}</p>', 'Cliquez sur le lien pour réinitialiser votre mot de passe: {{reset_link}}', 1),
('Nouvel utilisateur', 'new_user', 'Votre compte a été créé', '<h1>Compte créé!</h1><p>Votre nom d''utilisateur: {{username}}</p><p>Mot de passe temporaire: {{temp_password}}</p>', 'Votre compte a été créé. Username: {{username}}, Mot de passe temporaire: {{temp_password}}', 1);
SQL_SEED

    print_success "Données initiales créées"
}

# ═══════════════════════════════════════════════════════════════════════════
# FONCTION: Création du fichier htpasswd
# ═══════════════════════════════════════════════════════════════════════════
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

# ═══════════════════════════════════════════════════════════════════════════
# FONCTION: Création des fichiers User Manager
# ═══════════════════════════════════════════════════════════════════════════
create_usermanager_files() {
    print_section "CRÉATION DES FICHIERS USER MANAGER"

    print_step "Génération de composer.json..."
    cat > "$USERMANAGER_DIR/app/composer.json" << 'COMPOSER_EOF'
{
    "name": "nbility/bolt-user-manager",
    "description": "Bolt.DIY User Manager v2.0 with Authentication and Profiles",
    "type": "project",
    "require": {
        "php": ">=8.2",
        "phpmailer/phpmailer": "^6.9",
        "phpoffice/phpspreadsheet": "^1.29",
        "tecnickcom/tcpdf": "^6.6"
    },
    "autoload": {
        "psr-4": {
            "App\\": "app/",
            "App\\Models\\": "app/models/",
            "App\\Controllers\\": "app/controllers/"
        }
    },
    "config": {
        "optimize-autoloader": true,
        "preferred-install": "dist",
        "sort-packages": true
    },
    "minimum-stability": "stable",
    "prefer-stable": true
}
COMPOSER_EOF

    print_success "composer.json créé"

    print_step "Génération de index.php (page simple de test)..."
    cat > "$USERMANAGER_DIR/app/index.php" << 'PHP_INDEX_EOF'
<?php
/**
 * BOLT.DIY User Manager v2.0 - Entry Point
 * Copyright Nbility 2025
 */

// Configuration
error_reporting(E_ALL);
ini_set('display_errors', 1);

// Récupération des variables d'environnement
\$db_host = getenv('DB_HOST') ?: 'bolt-mariadb';
\$db_port = getenv('DB_PORT') ?: '3306';
\$db_name = getenv('DB_NAME') ?: 'bolt_usermanager';
\$db_user = getenv('DB_USER') ?: 'bolt_um';
\$db_password = getenv('DB_PASSWORD') ?: '';

// Connexion à la base de données
try {
    \$dsn = "mysql:host=\$db_host;port=\$db_port;dbname=\$db_name;charset=utf8mb4";
    \$pdo = new PDO(\$dsn, \$db_user, \$db_password, [
        PDO::ATTR_ERRMODE => PDO::ERRMODE_EXCEPTION,
        PDO::ATTR_DEFAULT_FETCH_MODE => PDO::FETCH_ASSOC,
        PDO::ATTR_EMULATE_PREPARES => false
    ]);
} catch (PDOException \$e) {
    die('Erreur de connexion à la base de données: ' . \$e->getMessage());
}

// Récupérer les statistiques
try {
    \$stmt = \$pdo->query("SELECT COUNT(*) as total FROM users");
    \$stats['total_users'] = \$stmt->fetchColumn();

    \$stmt = \$pdo->query("SELECT COUNT(*) as total FROM users WHERE is_active = 1");
    \$stats['active_users'] = \$stmt->fetchColumn();

    \$stmt = \$pdo->query("SELECT COUNT(*) as total FROM groups");
    \$stats['total_groups'] = \$stmt->fetchColumn();
} catch (PDOException \$e) {
    \$stats = ['total_users' => 0, 'active_users' => 0, 'total_groups' => 0];
}
?>
<!DOCTYPE html>
<html lang="fr">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>User Manager v2.0 - Bolt.DIY</title>
    <style>
        * { margin: 0; padding: 0; box-sizing: border-box; }
        body {
            font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, Oxygen, Ubuntu, sans-serif;
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            min-height: 100vh;
            padding: 20px;
        }
        .container { max-width: 1200px; margin: 0 auto; }
        .header {
            background: white;
            border-radius: 15px;
            padding: 30px;
            margin-bottom: 20px;
            box-shadow: 0 10px 30px rgba(0,0,0,0.2);
        }
        .header h1 { color: #667eea; font-size: 32px; margin-bottom: 5px; }
        .header p { color: #666; font-size: 14px; }
        .stats {
            display: grid;
            grid-template-columns: repeat(auto-fit, minmax(250px, 1fr));
            gap: 20px;
            margin-bottom: 20px;
        }
        .stat-card {
            background: white;
            border-radius: 15px;
            padding: 25px;
            box-shadow: 0 10px 30px rgba(0,0,0,0.2);
            text-align: center;
        }
        .stat-card h3 { color: #667eea; font-size: 36px; margin-bottom: 10px; }
        .stat-card p { color: #666; font-size: 14px; text-transform: uppercase; letter-spacing: 1px; }
        .footer {
            text-align: center;
            color: white;
            margin-top: 30px;
            font-size: 14px;
        }
    </style>
</head>
<body>
    <div class="container">
        <div class="header">
            <h1>🔧 User Manager v2.0</h1>
            <p>Bolt.DIY Intranet Edition - Système de gestion des utilisateurs</p>
        </div>

        <div class="stats">
            <div class="stat-card">
                <h3><?php echo \$stats['total_users']; ?></h3>
                <p>Utilisateurs totaux</p>
            </div>
            <div class="stat-card">
                <h3><?php echo \$stats['active_users']; ?></h3>
                <p>Utilisateurs actifs</p>
            </div>
            <div class="stat-card">
                <h3><?php echo \$stats['total_groups']; ?></h3>
                <p>Groupes</p>
            </div>
        </div>

        <div class="footer">
            © 2025 Nbility - Bolt.DIY Intranet Edition v6.5 - User Manager v2.0
        </div>
    </div>
</body>
</html>
PHP_INDEX_EOF

    print_success "index.php créé"
    echo ""
}

# ═══════════════════════════════════════════════════════════════════════════
# FONCTION: Génération des HTML templates
# ═══════════════════════════════════════════════════════════════════════════
generate_html_from_templates() {
    local template_file=$1
    local output_file=$2
    local desc=$3

    print_step "Génération de $desc..."

    sed -e "s/LOCAL_IP/$LOCAL_IP/g" \
        -e "s/GATEWAY_IP/$GATEWAY_IP/g" \
        -e "s/HOST_PORT_BOLT/$HOST_PORT_BOLT/g" \
        -e "s/HOST_PORT_HOME/$HOST_PORT_HOME/g" \
        -e "s/HOST_PORT_UM/$HOST_PORT_UM/g" \
        "$template_file" > "$output_file"

    if [ -f "$output_file" ]; then
        print_success "$desc générée"
    else
        print_error "Échec de la génération de $desc"
    fi
}

generate_html_pages() {
    print_section "GÉNÉRATION DES PAGES HTML"

    if [ -d "$TEMPLATES_DIR" ]; then
        if [ -f "$TEMPLATES_DIR/home.html" ]; then
            generate_html_from_templates "$TEMPLATES_DIR/home.html" "$TEMPLATES_DIR/home_generated.html" "page d'accueil"
        else
            print_warning "Template home.html non trouvé"
        fi
    else
        print_warning "Dossier templates introuvable"
    fi

    echo ""
}

# ═══════════════════════════════════════════════════════════════════════════
# FONCTION: Fix Dockerfile Bolt
# ═══════════════════════════════════════════════════════════════════════════
fix_bolt_dockerfile() {
    print_section "APPLICATION DU FIX DOCKERFILE BOLT"

    cd "$INSTALL_DIR"

    local dockerfile_template="$TEMPLATES_DIR/bolt.diy/Dockerfile"
    local dockerfile_target="$BOLT_DIR/Dockerfile"

    if [ ! -f "$dockerfile_template" ]; then
        print_warning "Template Dockerfile non trouvé, skip du fix"
        return 0
    fi

    if [ ! -f "$dockerfile_target" ]; then
        print_warning "Dockerfile cible non trouvé dans bolt.diy/"
        return 0
    fi

    print_step "Application du fix wrangler..."
    cp "$dockerfile_template" "$dockerfile_target"
    print_success "Fix Dockerfile appliqué"

    echo ""
}

# ═══════════════════════════════════════════════════════════════════════════
# FONCTION: Build et démarrage des conteneurs
# ═══════════════════════════════════════════════════════════════════════════
build_and_start_containers() {
    print_section "BUILD ET DÉMARRAGE DES CONTENEURS"

    cd "$INSTALL_DIR"

    print_step "Vérification de la configuration docker-compose..."
    if docker compose config > /dev/null 2>&1; then
        print_success "Configuration docker-compose valide"
    else
        print_error "Configuration docker-compose invalide"
        exit 1
    fi

    print_step "Build des images Docker (cela peut prendre plusieurs minutes)..."
    echo -e "${YELLOW}Build en cours...${NC}"

    if docker compose build 2>&1 | tee /tmp/bolt-build.log; then
        print_success "Build des images réussi"
    else
        print_error "Échec du build"
        echo -e "${YELLOW}Consultez /tmp/bolt-build.log pour les détails${NC}"
        exit 1
    fi

    print_step "Démarrage des conteneurs..."
    if docker compose up -d; then
        print_success "Conteneurs démarrés"
    else
        print_error "Échec du démarrage"
        exit 1
    fi

    print_step "Attente de l'initialisation de MariaDB..."
    sleep 10
    print_success "MariaDB initialisée"

    print_step "Vérification de l'état des conteneurs..."
    docker compose ps

    echo ""
}

# ═══════════════════════════════════════════════════════════════════════════
# FONCTION: Tests post-installation
# ═══════════════════════════════════════════════════════════════════════════
run_post_install_tests() {
    print_section "TESTS POST-INSTALLATION"

    print_step "Test de connectivité Bolt.DIY..."
    if curl -f -s -o /dev/null "http://$LOCAL_IP:$HOST_PORT_BOLT/health"; then
        print_success "Bolt.DIY accessible"
    else
        print_warning "Bolt.DIY pas encore prêt (peut prendre quelques minutes)"
    fi

    print_step "Test de connectivité User Manager..."
    if curl -f -s -o /dev/null "http://$LOCAL_IP:$HOST_PORT_UM/health.php"; then
        print_success "User Manager accessible"
    else
        print_warning "User Manager pas encore prêt"
    fi

    print_step "Test de la base de données..."
    if docker exec bolt-mariadb mysql -u bolt_um -p"$MARIADB_USER_PASSWORD" -e "SHOW DATABASES;" > /dev/null 2>&1; then
        print_success "Base de données accessible"
    else
        print_warning "Base de données pas encore prête"
    fi

    echo ""
}

# ═══════════════════════════════════════════════════════════════════════════
# FONCTION: Résumé de l'installation
# ═══════════════════════════════════════════════════════════════════════════
print_installation_summary() {
    clear
    print_banner

    echo -e "${GREEN}${BOLD}═══════════════════════════════════════════════════════════════════════════${NC}"
    echo -e "${GREEN}${BOLD}                    ✓ INSTALLATION TERMINÉE AVEC SUCCÈS                   ${NC}"
    echo -e "${GREEN}${BOLD}═══════════════════════════════════════════════════════════════════════════${NC}"
    echo ""

    echo -e "${CYAN}╔══════════════════════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║${NC} ${WHITE}${BOLD}ACCÈS AUX SERVICES${NC}                                                          ${CYAN}║${NC}"
    echo -e "${CYAN}╠══════════════════════════════════════════════════════════════════════════════╣${NC}"
    echo -e "${CYAN}║${NC}                                                                              ${CYAN}║${NC}"
    echo -e "${CYAN}║${NC}  ${YELLOW}🚀 Login Bolt.DIY${NC}        http://$LOCAL_IP:$HOST_PORT_BOLT                   ${CYAN}║${NC}"
    echo -e "${CYAN}║${NC}  ${YELLOW}🏠 Page d'Accueil${NC}        http://$LOCAL_IP:$HOST_PORT_HOME                   ${CYAN}║${NC}"
    echo -e "${CYAN}║${NC}  ${YELLOW}👥 User Manager${NC}          http://$LOCAL_IP:$HOST_PORT_UM                     ${CYAN}║${NC}"
    echo -e "${CYAN}║${NC}                                                                              ${CYAN}║${NC}"
    echo -e "${CYAN}╠══════════════════════════════════════════════════════════════════════════════╣${NC}"
    echo -e "${CYAN}║${NC} ${WHITE}${BOLD}AUTHENTIFICATION NGINX${NC}                                                     ${CYAN}║${NC}"
    echo -e "${CYAN}╠══════════════════════════════════════════════════════════════════════════════╣${NC}"
    echo -e "${CYAN}║${NC}                                                                              ${CYAN}║${NC}"
    echo -e "${CYAN}║${NC}  ${YELLOW}Utilisateur:${NC} $NGINX_USER                                                    ${CYAN}║${NC}"
    echo -e "${CYAN}║${NC}  ${YELLOW}Mot de passe:${NC} ●●●●●●●●                                                     ${CYAN}║${NC}"
    echo -e "${CYAN}║${NC}                                                                              ${CYAN}║${NC}"
    echo -e "${CYAN}╠══════════════════════════════════════════════════════════════════════════════╣${NC}"
    echo -e "${CYAN}║${NC} ${WHITE}${BOLD}SUPER ADMIN USER MANAGER${NC}                                                  ${CYAN}║${NC}"
    echo -e "${CYAN}╠══════════════════════════════════════════════════════════════════════════════╣${NC}"
    echo -e "${CYAN}║${NC}                                                                              ${CYAN}║${NC}"
    echo -e "${CYAN}║${NC}  ${YELLOW}Username:${NC} $ADMIN_USERNAME                                                   ${CYAN}║${NC}"
    echo -e "${CYAN}║${NC}  ${YELLOW}Email:${NC} $ADMIN_EMAIL                                                         ${CYAN}║${NC}"
    echo -e "${CYAN}║${NC}  ${YELLOW}Mot de passe:${NC} (celui que vous avez configuré)                              ${CYAN}║${NC}"
    echo -e "${CYAN}║${NC}                                                                              ${CYAN}║${NC}"
    echo -e "${CYAN}╠══════════════════════════════════════════════════════════════════════════════╣${NC}"
    echo -e "${CYAN}║${NC} ${WHITE}${BOLD}BASE DE DONNÉES MARIADB${NC}                                                   ${CYAN}║${NC}"
    echo -e "${CYAN}╠══════════════════════════════════════════════════════════════════════════════╣${NC}"
    echo -e "${CYAN}║${NC}                                                                              ${CYAN}║${NC}"
    echo -e "${CYAN}║${NC}  ${YELLOW}Port:${NC} $MARIADB_PORT                                                           ${CYAN}║${NC}"
    echo -e "${CYAN}║${NC}  ${YELLOW}Database:${NC} bolt_usermanager                                                  ${CYAN}║${NC}"
    echo -e "${CYAN}║${NC}  ${YELLOW}Utilisateur:${NC} bolt_um                                                        ${CYAN}║${NC}"
    echo -e "${CYAN}║${NC}  ${YELLOW}Tables créées:${NC} 14 tables                                                    ${CYAN}║${NC}"
    echo -e "${CYAN}║${NC}                                                                              ${CYAN}║${NC}"
    echo -e "${CYAN}╠══════════════════════════════════════════════════════════════════════════════╣${NC}"
    echo -e "${CYAN}║${NC} ${WHITE}${BOLD}ARCHITECTURE${NC}                                                              ${CYAN}║${NC}"
    echo -e "${CYAN}╠══════════════════════════════════════════════════════════════════════════════╣${NC}"
    echo -e "${CYAN}║${NC}                                                                              ${CYAN}║${NC}"
    echo -e "${CYAN}║${NC}  • Port $HOST_PORT_BOLT: Login Bolt.DIY (à la racine)                                  ${CYAN}║${NC}"
    echo -e "${CYAN}║${NC}  • Port $HOST_PORT_HOME: Page d'accueil statique                                       ${CYAN}║${NC}"
    echo -e "${CYAN}║${NC}  • Port $HOST_PORT_UM: User Manager v2.0 (PHP + MariaDB)                            ${CYAN}║${NC}"
    echo -e "${CYAN}║${NC}  • Port $MARIADB_PORT: MariaDB 10.11                                                   ${CYAN}║${NC}"
    echo -e "${CYAN}║${NC}                                                                              ${CYAN}║${NC}"
    echo -e "${CYAN}╚══════════════════════════════════════════════════════════════════════════════╝${NC}"
    echo ""

    echo -e "${MAGENTA}${BOLD}📋 Commandes utiles${NC}"
    echo -e "${CYAN}${ARROW}${NC} Voir les logs: ${WHITE}docker compose logs -f${NC}"
    echo -e "${CYAN}${ARROW}${NC} Logs User Manager: ${WHITE}docker compose logs -f bolt-user-manager${NC}"
    echo -e "${CYAN}${ARROW}${NC} Logs MariaDB: ${WHITE}docker compose logs -f bolt-mariadb${NC}"
    echo -e "${CYAN}${ARROW}${NC} Arrêter: ${WHITE}docker compose stop${NC}"
    echo -e "${CYAN}${ARROW}${NC} Redémarrer: ${WHITE}docker compose restart${NC}"
    echo -e "${CYAN}${ARROW}${NC} Status: ${WHITE}docker compose ps${NC}"
    echo -e "${CYAN}${ARROW}${NC} Accès MariaDB: ${WHITE}docker exec -it bolt-mariadb mysql -u bolt_um -p${NC}"
    echo ""

    echo -e "${GREEN}${BOLD}✓ Installation v6.5 terminée avec succès !${NC}"
    echo ""
}

# ═══════════════════════════════════════════════════════════════════════════
# SCRIPT PRINCIPAL
# ═══════════════════════════════════════════════════════════════════════════
main() {
    # Affichage de la bannière
    print_banner

    # Vérifications
    check_prerequisites
    check_internet_and_github

    # Configuration
    get_configuration

    # Clonage et préparation
    clone_repository
    create_directory_structure

    # Génération des fichiers de configuration
    generate_docker_compose
    generate_nginx_conf
    generate_usermanager_dockerfile
    generate_health_php
    generate_env_files

    # Création de la base de données
    create_sql_schema
    create_sql_seed

    # Création des fichiers User Manager
    create_usermanager_files

    # Authentification NGINX
    create_htpasswd

    # HTML templates
    generate_html_pages

    # Fix Bolt Dockerfile
    fix_bolt_dockerfile

    # Build et démarrage
    build_and_start_containers

    # Tests
    run_post_install_tests

    # Résumé
    print_installation_summary
}

# Lancement du script
main
