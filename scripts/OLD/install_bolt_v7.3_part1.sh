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
