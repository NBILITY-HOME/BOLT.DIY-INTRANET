#!/bin/bash

#═══════════════════════════════════════════════════════════════════════════
# BOLT.DIY NBILITY - Installation Script v7.3
# Architecture Multi-Ports + User Manager v2.0 + MariaDB + Docker
# © Copyright Nbility 2025 - contact@nbility.fr
#
# 🆕 NOUVEAUTÉS v7.3:
#   ✅ Suppression des générateurs de fichiers source (home.html, SQL)
#   ✅ Utilisation exclusive des fichiers GitHub (plus maintenable)
#   ✅ home.html → index.html (standard web)
#   ✅ Vérifications strictes avec arrêt si fichier manquant
#   ✅ Script réduit de ~170 lignes (-11%)
#   ✅ Messages d'erreur clairs et informatifs
#
# Repository: https://github.com/NBILITY-HOME/BOLT.DIY-INTRANET
#═══════════════════════════════════════════════════════════════════════════

# Protection sudo
if [ "$EUID" -eq 0 ]; then
    echo -e "\033[0;31m✗ ERREUR: Ce script NE DOIT PAS être lancé en sudo/root\033[0m"
    echo ""
    echo "Raison: Docker et les fichiers doivent appartenir à votre utilisateur"
    echo ""
    echo "Solution: Lancez le script sans sudo:"
    echo "  ./install_bolt_v7.3.sh"
    echo ""
    exit 1
fi

#═══════════════════════════════════════════════════════════════════════════
# VARIABLES GLOBALES
#═══════════════════════════════════════════════════════════════════════════

# Chemins
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$SCRIPT_DIR/BOLT.DIY-INTRANET"
DATA_LOCAL_DIR="$PROJECT_ROOT/DATA-LOCAL"
NGINX_DIR="$DATA_LOCAL_DIR/nginx"
MARIADB_DIR="$DATA_LOCAL_DIR/mariadb"
USERMANAGER_DIR="$DATA_LOCAL_DIR/user-manager"
BOLTDIY_DIR="$PROJECT_ROOT/bolt.diy"

# GitHub
GITHUB_REPO="https://github.com/NBILITY-HOME/BOLT.DIY-INTRANET.git"
CLONE_DIR="$PROJECT_ROOT"

# Versions
BOLT_VERSION="v7.3"
USERMANAGER_VERSION="2.0"

# Variables utilisateur (seront demandées)
LOCAL_IP=""
HOST_PORT_BOLT=""
HOST_PORT_HOME=""
HOST_PORT_UM=""
ADMIN_USER=""
ADMIN_PASSWORD=""
ADMIN_PASSWORD_HASH=""
MARIADB_ROOT_PASSWORD=""
MARIADB_USER_PASSWORD=""
APP_SECRET=""
OPENAI_API_KEY=""
ANTHROPIC_API_KEY=""
GROQ_API_KEY=""
GOOGLE_API_KEY=""

#═══════════════════════════════════════════════════════════════════════════
# FONCTIONS D'AFFICHAGE
#═══════════════════════════════════════════════════════════════════════════

print_banner() {
    clear
    printf "\033[38;5;51;1m"
    cat << 'BANNER'
═══════════════════════════════════════════════════════════════════════════
   ____   ____  _   _____     ____ _____   __  
  | __ ) / __ \| | |_   _|   |  _ \_   _\ / /  
  |  _ \| |  | | |   | |     | | | || |  | |   
  | |_) | |__| | |___| |  _  | |_| || |  | |   
  |____/ \____/|_____|_| (_) |____/___/   \_\  

  NBILITY EDITION - Installation v7.3
  User Manager v2.0 + Multi-Ports Architecture
═══════════════════════════════════════════════════════════════════════════
BANNER
    printf "\033[0m\n"
}

print_section() {
    printf "\n\033[38;5;51;1m"
    printf "═%.0s" {1..75}
    printf "\n  %s\n" "$1"
    printf "═%.0s" {1..75}
    printf "\033[0m\n\n"
}

print_step() {
    printf "\033[1;36m▶\033[0m %s\n" "$1"
}

print_success() {
    printf "\033[1;32m✓\033[0m %s\n" "$1"
}

print_error() {
    printf "\033[1;31m✗\033[0m %s\n" "$1"
}

print_warning() {
    printf "\033[1;33m⚠\033[0m %s\n" "$1"
}

print_info() {
    printf "\033[1;34mℹ\033[0m %s\n" "$1"
}

#═══════════════════════════════════════════════════════════════════════════
# FONCTION VALIDATION
#═══════════════════════════════════════════════════════════════════════════

validate_port() {
    local port=$1
    if [[ ! "$port" =~ ^[0-9]+$ ]] || [ "$port" -lt 1024 ] || [ "$port" -gt 65535 ]; then
        return 1
    fi
    return 0
}

validate_ip() {
    local ip=$1
    if [[ "$ip" =~ ^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}$ ]]; then
        return 0
    fi
    return 1
}

#═══════════════════════════════════════════════════════════════════════════
# VÉRIFICATIONS PRÉALABLES
#═══════════════════════════════════════════════════════════════════════════

check_dependencies() {
    print_section "VÉRIFICATION DES DÉPENDANCES"

    local missing_deps=()

    # Docker
    if ! command -v docker &> /dev/null; then
        missing_deps+=("docker")
        print_error "Docker n'est pas installé"
    else
        print_success "Docker: $(docker --version | cut -d' ' -f3 | tr -d ',')"
    fi

    # Docker Compose
    if ! docker compose version &> /dev/null; then
        missing_deps+=("docker-compose")
        print_error "Docker Compose n'est pas installé"
    else
        print_success "Docker Compose: $(docker compose version | cut -d' ' -f4)"
    fi

    # Git
    if ! command -v git &> /dev/null; then
        missing_deps+=("git")
        print_error "Git n'est pas installé"
    else
        print_success "Git: $(git --version | cut -d' ' -f3)"
    fi

    # OpenSSL
    if ! command -v openssl &> /dev/null; then
        missing_deps+=("openssl")
        print_error "OpenSSL n'est pas installé"
    else
        print_success "OpenSSL: $(openssl version | cut -d' ' -f2)"
    fi

    # Htpasswd
    if ! command -v htpasswd &> /dev/null; then
        missing_deps+=("apache2-utils")
        print_error "htpasswd n'est pas installé (paquet apache2-utils)"
    else
        print_success "htpasswd: disponible"
    fi

    if [ ${#missing_deps[@]} -gt 0 ]; then
        echo ""
        print_error "Dépendances manquantes: ${missing_deps[*]}"
        echo ""
        echo "Installation sur Debian/Ubuntu:"
        echo "  sudo apt update"
        echo "  sudo apt install -y ${missing_deps[*]}"
        echo ""
        exit 1
    fi

    print_success "Toutes les dépendances sont installées"
}

#═══════════════════════════════════════════════════════════════════════════
# COLLECTE DES INFORMATIONS
#═══════════════════════════════════════════════════════════════════════════

collect_user_inputs() {
    print_section "CONFIGURATION"

    # IP locale
    local default_ip=$(hostname -I | awk '{print $1}')
    echo -n "Adresse IP locale [$default_ip]: "
    read -r LOCAL_IP
    LOCAL_IP=${LOCAL_IP:-$default_ip}

    while ! validate_ip "$LOCAL_IP"; do
        print_error "Adresse IP invalide"
        echo -n "Adresse IP locale [$default_ip]: "
        read -r LOCAL_IP
        LOCAL_IP=${LOCAL_IP:-$default_ip}
    done

    # Ports
    echo -n "Port Bolt.DIY [8100]: "
    read -r HOST_PORT_BOLT
    HOST_PORT_BOLT=${HOST_PORT_BOLT:-8100}
    while ! validate_port "$HOST_PORT_BOLT"; do
        print_error "Port invalide (1024-65535)"
        echo -n "Port Bolt.DIY [8100]: "
        read -r HOST_PORT_BOLT
        HOST_PORT_BOLT=${HOST_PORT_BOLT:-8100}
    done

    echo -n "Port Home [8080]: "
    read -r HOST_PORT_HOME
    HOST_PORT_HOME=${HOST_PORT_HOME:-8080}
    while ! validate_port "$HOST_PORT_HOME"; do
        print_error "Port invalide (1024-65535)"
        echo -n "Port Home [8080]: "
        read -r HOST_PORT_HOME
        HOST_PORT_HOME=${HOST_PORT_HOME:-8080}
    done

    echo -n "Port User Manager [8200]: "
    read -r HOST_PORT_UM
    HOST_PORT_UM=${HOST_PORT_UM:-8200}
    while ! validate_port "$HOST_PORT_UM"; do
        print_error "Port invalide (1024-65535)"
        echo -n "Port User Manager [8200]: "
        read -r HOST_PORT_UM
        HOST_PORT_UM=${HOST_PORT_UM:-8200}
    done

    # Admin
    echo -n "Utilisateur admin [admin]: "
    read -r ADMIN_USER
    ADMIN_USER=${ADMIN_USER:-admin}

    echo -n "Mot de passe admin: "
    read -rs ADMIN_PASSWORD
    echo ""
    while [ -z "$ADMIN_PASSWORD" ]; do
        print_error "Le mot de passe ne peut pas être vide"
        echo -n "Mot de passe admin: "
        read -rs ADMIN_PASSWORD
        echo ""
    done

    # Hash du mot de passe admin
    ADMIN_PASSWORD_HASH=$(php -r "echo password_hash('$ADMIN_PASSWORD', PASSWORD_BCRYPT);")

    # Mots de passe base de données
    MARIADB_ROOT_PASSWORD=$(openssl rand -base64 32)
    MARIADB_USER_PASSWORD=$(openssl rand -base64 32)
    APP_SECRET=$(openssl rand -hex 32)

    # Clés API (optionnelles)
    echo ""
    print_info "Clés API (optionnelles, laisser vide pour ignorer):"
    echo -n "OpenAI API Key: "
    read -rs OPENAI_API_KEY
    echo ""

    echo -n "Anthropic API Key: "
    read -rs ANTHROPIC_API_KEY
    echo ""

    echo -n "Groq API Key: "
    read -rs GROQ_API_KEY
    echo ""

    echo -n "Google API Key: "
    read -rs GOOGLE_API_KEY
    echo ""

    print_success "Configuration collectée"
}


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


#═══════════════════════════════════════════════════════════════════════════
# GÉNÉRATION NGINX.CONF
#═══════════════════════════════════════════════════════════════════════════

generate_nginx_conf() {
    print_section "GÉNÉRATION NGINX.CONF"

    print_step "Création du fichier nginx.conf..."

    cat > "$NGINX_DIR/nginx.conf" << 'NGINX_CONF_EOF'
user nginx;
worker_processes auto;
error_log /var/log/nginx/error.log warn;
pid /var/run/nginx.pid;

events {
    worker_connections 1024;
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
    gzip_disable "msie6";

    # Configuration du serveur
    server {
        listen 80;
        server_name _;

        # Page d'accueil
        location / {
            root /usr/share/nginx/html;
            index index.html;
            try_files $uri $uri/ =404;
        }

        # Proxy vers Bolt.DIY
        location /bolt {
            auth_basic "Bolt.DIY - Accès Restreint";
            auth_basic_user_file /etc/nginx/.htpasswd;

            proxy_pass http://bolt:5173;
            proxy_http_version 1.1;
            proxy_set_header Upgrade $http_upgrade;
            proxy_set_header Connection 'upgrade';
            proxy_set_header Host $host;
            proxy_cache_bypass $http_upgrade;
            proxy_set_header X-Real-IP $remote_addr;
            proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
            proxy_set_header X-Forwarded-Proto $scheme;

            proxy_read_timeout 300s;
            proxy_connect_timeout 75s;
        }

        # Proxy vers User Manager
        location /user-manager {
            auth_basic "User Manager - Accès Admin";
            auth_basic_user_file /etc/nginx/.htpasswd;

            rewrite ^/user-manager(/.*)$ $1 break;

            proxy_pass http://user-manager:8080;
            proxy_http_version 1.1;
            proxy_set_header Host $host;
            proxy_set_header X-Real-IP $remote_addr;
            proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
            proxy_set_header X-Forwarded-Proto $scheme;

            proxy_read_timeout 300s;
            proxy_connect_timeout 75s;
        }

        # Page d'erreur personnalisée
        error_page 404 /404.html;
        location = /404.html {
            root /usr/share/nginx/html;
            internal;
        }

        error_page 500 502 503 504 /50x.html;
        location = /50x.html {
            root /usr/share/nginx/html;
        }

        # Health check
        location /health {
            access_log off;
            return 200 "healthy\n";
            add_header Content-Type text/plain;
        }
    }
}
NGINX_CONF_EOF

    print_success "nginx.conf créé"
}

#═══════════════════════════════════════════════════════════════════════════
# GÉNÉRATION DOCKER-COMPOSE.YML
#═══════════════════════════════════════════════════════════════════════════

generate_docker_compose() {
    print_section "GÉNÉRATION DOCKER-COMPOSE.YML"

    print_step "Création du fichier docker-compose.yml..."

    cat > "$PROJECT_ROOT/docker-compose.yml" << COMPOSE_EOF
version: '3.8'

services:
  # =========================================================================
  # NGINX - Reverse Proxy
  # =========================================================================
  nginx:
    image: nginx:alpine
    container_name: bolt-nginx
    restart: unless-stopped
    ports:
      - "${HOST_PORT_HOME}:80"
    volumes:
      - ${NGINX_DIR}/nginx.conf:/etc/nginx/nginx.conf:ro
      - ${NGINX_DIR}:/usr/share/nginx/html:ro
      - ${NGINX_DIR}/.htpasswd:/etc/nginx/.htpasswd:ro
    depends_on:
      - bolt
      - user-manager
    networks:
      - bolt-network
    healthcheck:
      test: ["CMD", "wget", "--quiet", "--tries=1", "--spider", "http://localhost/health"]
      interval: 30s
      timeout: 10s
      retries: 3

  # =========================================================================
  # BOLT.DIY - Application principale
  # =========================================================================
  bolt:
    image: node:20-slim
    container_name: bolt-app
    restart: unless-stopped
    working_dir: /app
    command: sh -c "npm install && npm run dev -- --host 0.0.0.0"
    ports:
      - "${HOST_PORT_BOLT}:5173"
    volumes:
      - ${BOLTDIY_DIR}:/app
    environment:
      - NODE_ENV=development
    env_file:
      - ${BOLTDIY_DIR}/.env
    networks:
      - bolt-network
    healthcheck:
      test: ["CMD", "node", "--version"]
      interval: 30s
      timeout: 10s
      retries: 3

  # =========================================================================
  # MARIADB - Base de données
  # =========================================================================
  mariadb:
    image: mariadb:latest
    container_name: bolt-mariadb
    restart: unless-stopped
    environment:
      MARIADB_ROOT_PASSWORD: \${MARIADB_ROOT_PASSWORD}
      MARIADB_DATABASE: usermanager
      MARIADB_USER: usermanager
      MARIADB_PASSWORD: \${MARIADB_USER_PASSWORD}
    volumes:
      - ${MARIADB_DIR}/data:/var/lib/mysql
      - ${MARIADB_DIR}/init:/docker-entrypoint-initdb.d:ro
    networks:
      - bolt-network
    healthcheck:
      test: ["CMD", "healthcheck.sh", "--connect", "--innodb_initialized"]
      interval: 30s
      timeout: 10s
      retries: 3

  # =========================================================================
  # USER MANAGER - Gestion utilisateurs
  # =========================================================================
  user-manager:
    build:
      context: ${USERMANAGER_DIR}
      dockerfile: Dockerfile
    container_name: bolt-user-manager
    restart: unless-stopped
    ports:
      - "${HOST_PORT_UM}:8080"
    volumes:
      - ${USERMANAGER_DIR}/app:/var/www/html
    environment:
      - PHP_MEMORY_LIMIT=256M
      - PHP_UPLOAD_MAX_FILESIZE=50M
      - PHP_POST_MAX_SIZE=50M
    env_file:
      - ${USERMANAGER_DIR}/.env
    depends_on:
      - mariadb
    networks:
      - bolt-network
    healthcheck:
      test: ["CMD", "php", "-v"]
      interval: 30s
      timeout: 10s
      retries: 3

# =========================================================================
# NETWORKS
# =========================================================================
networks:
  bolt-network:
    driver: bridge
    ipam:
      config:
        - subnet: 172.20.0.0/16
COMPOSE_EOF

    print_success "docker-compose.yml créé"
}


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


#═══════════════════════════════════════════════════════════════════════════
# COPIE DES FICHIERS SQL
#═══════════════════════════════════════════════════════════════════════════

copy_sql_files() {
    print_section "COPIE DES FICHIERS SQL"

    # Copier 01-schema.sql
    print_step "Copie de 01-schema.sql vers mariadb/init..."

    if [ -f "$USERMANAGER_DIR/app/database/migrations/01-schema.sql" ]; then
        cp "$USERMANAGER_DIR/app/database/migrations/01-schema.sql" "$MARIADB_DIR/init/"
        print_success "01-schema.sql copié"
    else
        print_error "01-schema.sql manquant dans le repository"
        print_error "Chemin attendu: $USERMANAGER_DIR/app/database/migrations/01-schema.sql"
        exit 1
    fi

    # Copier 02-seed.sql et remplacer les variables
    print_step "Copie de 02-seed.sql vers mariadb/init..."

    if [ -f "$USERMANAGER_DIR/app/database/migrations/02-seed.sql" ]; then
        cp "$USERMANAGER_DIR/app/database/migrations/02-seed.sql" "$MARIADB_DIR/init/"

        # Remplacer les variables dans seed.sql
        print_step "Configuration de l'utilisateur admin dans 02-seed.sql..."
        sed -i "s/{{ADMIN_USER}}/$ADMIN_USER/g" "$MARIADB_DIR/init/02-seed.sql"
        sed -i "s/{{ADMIN_PASSWORD_HASH}}/$ADMIN_PASSWORD_HASH/g" "$MARIADB_DIR/init/02-seed.sql"

        print_success "02-seed.sql copié et configuré"
    else
        print_error "02-seed.sql manquant dans le repository"
        print_error "Chemin attendu: $USERMANAGER_DIR/app/database/migrations/02-seed.sql"
        exit 1
    fi
}

#═══════════════════════════════════════════════════════════════════════════
# GÉNÉRATION HEALTH.PHP
#═══════════════════════════════════════════════════════════════════════════

generate_health_php() {
    print_section "GÉNÉRATION HEALTH.PHP"

    print_step "Création du fichier health.php..."

    cat > "$USERMANAGER_DIR/app/public/health.php" << 'HEALTH_PHP_EOF'
<?php
/**
 * Health Check Endpoint
 * Vérifie l'état de santé de l'application User Manager
 */

header('Content-Type: application/json');

$health = [
    'status' => 'healthy',
    'timestamp' => date('Y-m-d H:i:s'),
    'checks' => []
];

// Vérifier PHP
$health['checks']['php'] = [
    'status' => 'ok',
    'version' => PHP_VERSION
];

// Vérifier la connexion à la base de données
try {
    $host = getenv('DB_HOST') ?: 'mariadb';
    $db = getenv('DB_DATABASE') ?: 'usermanager';
    $user = getenv('DB_USERNAME') ?: 'usermanager';
    $pass = getenv('DB_PASSWORD') ?: '';

    $dsn = "mysql:host=$host;dbname=$db;charset=utf8mb4";
    $pdo = new PDO($dsn, $user, $pass, [
        PDO::ATTR_ERRMODE => PDO::ERRMODE_EXCEPTION,
        PDO::ATTR_TIMEOUT => 5
    ]);

    $health['checks']['database'] = [
        'status' => 'ok',
        'host' => $host,
        'database' => $db
    ];
} catch (PDOException $e) {
    $health['status'] = 'unhealthy';
    $health['checks']['database'] = [
        'status' => 'error',
        'message' => 'Database connection failed'
    ];
}

// Vérifier les dossiers d'écriture
$writableDirs = [
    '/var/www/html/logs',
    '/var/www/html/uploads'
];

foreach ($writableDirs as $dir) {
    $isWritable = is_dir($dir) && is_writable($dir);
    $health['checks']['filesystem'][$dir] = [
        'status' => $isWritable ? 'ok' : 'error',
        'writable' => $isWritable
    ];

    if (!$isWritable) {
        $health['status'] = 'unhealthy';
    }
}

// Définir le code HTTP approprié
http_response_code($health['status'] === 'healthy' ? 200 : 503);

echo json_encode($health, JSON_PRETTY_PRINT);
HEALTH_PHP_EOF

    print_success "health.php créé"
}

#═══════════════════════════════════════════════════════════════════════════
# VÉRIFICATION FINALE
#═══════════════════════════════════════════════════════════════════════════

final_verification() {
    print_section "VÉRIFICATION FINALE"

    local all_ok=true

    print_step "Vérification de la structure..."

    # Vérifier les fichiers critiques
    local critical_files=(
        "$PROJECT_ROOT/docker-compose.yml"
        "$PROJECT_ROOT/.env"
        "$NGINX_DIR/nginx.conf"
        "$NGINX_DIR/.htpasswd"
        "$NGINX_DIR/index.html"
        "$BOLTDIY_DIR/.env"
        "$USERMANAGER_DIR/.env"
        "$USERMANAGER_DIR/Dockerfile"
        "$MARIADB_DIR/init/01-schema.sql"
        "$MARIADB_DIR/init/02-seed.sql"
    )

    for file in "${critical_files[@]}"; do
        if [ -f "$file" ]; then
            print_success "$(basename "$file") présent"
        else
            print_error "$(basename "$file") manquant"
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
            print_success "$(basename "$dir")/ présent"
        else
            print_error "$(basename "$dir")/ manquant"
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


#═══════════════════════════════════════════════════════════════════════════
# LANCEMENT DOCKER
#═══════════════════════════════════════════════════════════════════════════

launch_docker() {
    print_section "LANCEMENT DES CONTENEURS DOCKER"

    cd "$PROJECT_ROOT" || exit 1

    # Arrêter les conteneurs existants
    print_step "Arrêt des conteneurs existants..."
    docker compose down 2>/dev/null || true
    print_success "Conteneurs arrêtés"

    # Construire et démarrer
    print_step "Construction et démarrage des conteneurs..."
    if docker compose up -d --build; then
        print_success "Conteneurs démarrés"
    else
        print_error "Échec du démarrage des conteneurs"
        exit 1
    fi

    # Attendre que les services soient prêts
    print_step "Attente du démarrage des services (30s)..."
    sleep 30

    # Vérifier l'état des conteneurs
    print_step "Vérification de l'état des conteneurs..."
    docker compose ps

    cd "$SCRIPT_DIR"
}

#═══════════════════════════════════════════════════════════════════════════
# RÉSUMÉ FINAL
#═══════════════════════════════════════════════════════════════════════════

print_summary() {
    print_section "INSTALLATION TERMINÉE"

    printf "\033[1;32m"
    cat << 'SUCCESS_BANNER'
  _____ _   _  ____ ____ _____ ____  
 / ____| | | |/ ___/ ___| ____/ ___| 
 \\___ \| | | | |  | |   |  _| \___ \ 
  ___) | |_| | |__| |___| |___ ___) |
 |____/ \___/ \____\____|_____|____/ 

SUCCESS_BANNER
    printf "\033[0m\n"

    echo ""
    printf "\033[1;36m═══════════════════════════════════════════════════════════════════════════\033[0m\n"
    printf "\033[1;37m  INFORMATIONS D'ACCÈS\033[0m\n"
    printf "\033[1;36m═══════════════════════════════════════════════════════════════════════════\033[0m\n"
    echo ""

    printf "\033[1;33m🏠 Page d'accueil:\033[0m\n"
    printf "   http://%s:%s\n" "$LOCAL_IP" "$HOST_PORT_HOME"
    echo ""

    printf "\033[1;33m⚡ Bolt.DIY (via proxy):\033[0m\n"
    printf "   http://%s:%s/bolt\n" "$LOCAL_IP" "$HOST_PORT_HOME"
    echo ""

    printf "\033[1;33m⚡ Bolt.DIY (direct):\033[0m\n"
    printf "   http://%s:%s\n" "$LOCAL_IP" "$HOST_PORT_BOLT"
    echo ""

    printf "\033[1;33m👥 User Manager (via proxy):\033[0m\n"
    printf "   http://%s:%s/user-manager\n" "$LOCAL_IP" "$HOST_PORT_HOME"
    echo ""

    printf "\033[1;33m👥 User Manager (direct):\033[0m\n"
    printf "   http://%s:%s\n" "$LOCAL_IP" "$HOST_PORT_UM"
    echo ""

    printf "\033[1;36m═══════════════════════════════════════════════════════════════════════════\033[0m\n"
    printf "\033[1;37m  IDENTIFIANTS\033[0m\n"
    printf "\033[1;36m═══════════════════════════════════════════════════════════════════════════\033[0m\n"
    echo ""

    printf "\033[1;33m👤 Utilisateur:\033[0m %s\n" "$ADMIN_USER"
    printf "\033[1;33m🔑 Mot de passe:\033[0m %s\n" "$ADMIN_PASSWORD"
    echo ""

    printf "\033[1;36m═══════════════════════════════════════════════════════════════════════════\033[0m\n"
    printf "\033[1;37m  COMMANDES UTILES\033[0m\n"
    printf "\033[1;36m═══════════════════════════════════════════════════════════════════════════\033[0m\n"
    echo ""

    printf "\033[1;32mVoir les logs:\033[0m\n"
    printf "  docker compose -f %s/docker-compose.yml logs -f\n" "$PROJECT_ROOT"
    echo ""

    printf "\033[1;32mArrêter les services:\033[0m\n"
    printf "  docker compose -f %s/docker-compose.yml down\n" "$PROJECT_ROOT"
    echo ""

    printf "\033[1;32mRedémarrer les services:\033[0m\n"
    printf "  docker compose -f %s/docker-compose.yml restart\n" "$PROJECT_ROOT"
    echo ""

    printf "\033[1;32mVoir l'état des conteneurs:\033[0m\n"
    printf "  docker compose -f %s/docker-compose.yml ps\n" "$PROJECT_ROOT"
    echo ""

    printf "\033[1;36m═══════════════════════════════════════════════════════════════════════════\033[0m\n"
    printf "\033[1;37m  SANTÉ DES SERVICES\033[0m\n"
    printf "\033[1;36m═══════════════════════════════════════════════════════════════════════════\033[0m\n"
    echo ""

    printf "\033[1;32mNginx health:\033[0m\n"
    printf "  curl http://%s:%s/health\n" "$LOCAL_IP" "$HOST_PORT_HOME"
    echo ""

    printf "\033[1;32mUser Manager health:\033[0m\n"
    printf "  curl http://%s:%s/health.php\n" "$LOCAL_IP" "$HOST_PORT_UM"
    echo ""

    printf "\033[1;36m═══════════════════════════════════════════════════════════════════════════\033[0m\n"
    printf "\033[1;37m  FICHIERS IMPORTANTS\033[0m\n"
    printf "\033[1;36m═══════════════════════════════════════════════════════════════════════════\033[0m\n"
    echo ""

    printf "\033[1;33m📁 Projet:\033[0m %s\n" "$PROJECT_ROOT"
    printf "\033[1;33m⚙️  Docker Compose:\033[0m %s/docker-compose.yml\n" "$PROJECT_ROOT"
    printf "\033[1;33m🔧 Nginx Config:\033[0m %s/nginx.conf\n" "$NGINX_DIR"
    printf "\033[1;33m📊 Logs MariaDB:\033[0m %s/data\n" "$MARIADB_DIR"
    echo ""

    printf "\033[1;36m═══════════════════════════════════════════════════════════════════════════\033[0m\n"
    printf "\033[1;37m  NOUVEAUTÉS V7.3\033[0m\n"
    printf "\033[1;36m═══════════════════════════════════════════════════════════════════════════\033[0m\n"
    echo ""

    printf "\033[1;32m✅ Suppression des générateurs de fichiers source\033[0m\n"
    printf "\033[1;32m✅ Utilisation exclusive des fichiers GitHub\033[0m\n"
    printf "\033[1;32m✅ home.html → index.html (standard web)\033[0m\n"
    printf "\033[1;32m✅ Vérifications strictes avec arrêt si fichier manquant\033[0m\n"
    printf "\033[1;32m✅ Support de 4 clés API (Groq, OpenAI, Anthropic, Google)\033[0m\n"
    printf "\033[1;32m✅ Script réduit de ~170 lignes (-11%%)\033[0m\n"
    echo ""

    printf "\033[1;36m═══════════════════════════════════════════════════════════════════════════\033[0m\n"
    echo ""

    printf "\033[1;32m🎉 Installation réussie !\033[0m\n"
    printf "\033[1;37mVersion: %s | User Manager: %s\033[0m\n" "$BOLT_VERSION" "$USERMANAGER_VERSION"
    echo ""
}

#═══════════════════════════════════════════════════════════════════════════
# FONCTION PRINCIPALE
#═══════════════════════════════════════════════════════════════════════════

main() {
    # Bannière
    print_banner

    # Vérifications préalables
    check_dependencies

    # Collecte des informations
    collect_user_inputs

    # Clonage et vérifications
    clone_repository
    verify_cloned_content

    # Création structure
    create_directories

    # Génération des fichiers de configuration
    generate_nginx_conf
    generate_docker_compose
    generate_env_files
    generate_dockerfile
    generate_htpasswd

    # Copie des fichiers source
    copy_sql_files
    generate_health_php

    # Vérification finale
    final_verification

    # Lancement
    launch_docker

    # Résumé
    print_summary
}

#═══════════════════════════════════════════════════════════════════════════
# POINT D'ENTRÉE
#═══════════════════════════════════════════════════════════════════════════

main "$@"

