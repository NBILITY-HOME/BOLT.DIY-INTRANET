#!/bin/bash

#═══════════════════════════════════════════════════════════════════════════
# Script d'installation Bolt.DIY v7.4 - NBILITY EDITION
# © Copyright Nbility 2025 - contact@nbility.fr
# GitHub comme source - Approche optimisée
#═══════════════════════════════════════════════════════════════════════════

set -e

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

# Couleurs
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
MAGENTA='\033[0;35m'
NC='\033[0m'

# Variables d'installation (seront remplies par l'utilisateur)
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
    echo ""
    echo -e "${CYAN}═══════════════════════════════════════════════════════════════════════════${NC}"
    echo -e "${CYAN}   ____   ____  _   _____     ____ _____   __  ${NC}"
    echo -e "${CYAN}  | __ ) / __ \| | |_   _|   |  _ \_   _\ / /  ${NC}"
    echo -e "${CYAN}  |  _ \| |  | | |   | |     | | | || |  | |   ${NC}"
    echo -e "${CYAN}  | |_) | |__| | |___| |  _  | |_| || |  | |   ${NC}"
    echo -e "${CYAN}  |____/ \____/|_____|_| (_) |____/___/   \_\  ${NC}"
    echo ""
    echo -e "${BLUE}  NBILITY EDITION - Installation v7.4${NC}"
    echo -e "${BLUE}  GitHub comme source - Approche optimisée${NC}"
    echo -e "${CYAN}═══════════════════════════════════════════════════════════════════════════${NC}"
    echo ""
}

print_section() {
    echo ""
    echo -e "${CYAN}═══════════════════════════════════════════════════════════════════════════${NC}"
    echo -e "${CYAN}  $1${NC}"
    echo -e "${CYAN}═══════════════════════════════════════════════════════════════════════════${NC}"
    echo ""
}

print_step() {
    echo -e "${YELLOW}▶${NC} $1"
}

print_success() {
    echo -e "${GREEN}✓${NC} $1"
}

print_error() {
    echo -e "${RED}✗${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}⚠${NC} $1"
}

print_info() {
    echo -e "${BLUE}ℹ${NC} $1"
}

#═══════════════════════════════════════════════════════════════════════════
# FONCTIONS DE VALIDATION
#═══════════════════════════════════════════════════════════════════════════

validate_ip() {
    local ip=$1
    if [[ $ip =~ ^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}$ ]]; then
        IFS='.' read -r -a octets <<< "$ip"
        for octet in "${octets[@]}"; do
            if ((octet > 255)); then
                return 1
            fi
        done
        return 0
    fi
    return 1
}

validate_port() {
    local port=$1
    if [[ $port =~ ^[0-9]+$ ]] && [ "$port" -ge 1024 ] && [ "$port" -le 65535 ]; then
        return 0
    fi
    return 1
}

#═══════════════════════════════════════════════════════════════════════════
# VÉRIFICATION DES DÉPENDANCES
#═══════════════════════════════════════════════════════════════════════════

check_dependencies() {
    print_section "VÉRIFICATION DES DÉPENDANCES"

    local all_ok=true

    # Docker
    if command -v docker &> /dev/null; then
        DOCKER_VERSION=$(docker --version | awk '{print $3}' | tr -d ',')
        print_success "Docker: $DOCKER_VERSION"
    else
        print_error "Docker n'est pas installé"
        all_ok=false
    fi

    # Docker Compose
    if command -v docker compose version &> /dev/null; then
        COMPOSE_VERSION=$(docker compose version --short 2>/dev/null || echo "v2.x")
        print_success "Docker Compose: $COMPOSE_VERSION"
    else
        print_error "Docker Compose n'est pas installé"
        all_ok=false
    fi

    # Git
    if command -v git &> /dev/null; then
        GIT_VERSION=$(git --version | awk '{print $3}')
        print_success "Git: $GIT_VERSION"
    else
        print_error "Git n'est pas installé"
        all_ok=false
    fi

    # OpenSSL
    if command -v openssl &> /dev/null; then
        OPENSSL_VERSION=$(openssl version | awk '{print $2}')
        print_success "OpenSSL: $OPENSSL_VERSION"
    else
        print_error "OpenSSL n'est pas installé"
        all_ok=false
    fi

    # htpasswd
    if command -v htpasswd &> /dev/null; then
        print_success "htpasswd: disponible"
    else
        print_error "htpasswd n'est pas installé (paquet apache2-utils)"
        all_ok=false
    fi

    if [ "$all_ok" = true ]; then
        print_success "Toutes les dépendances sont installées"
    else
        print_error "Des dépendances sont manquantes"
        print_info "Installez-les avec: sudo apt install docker.io docker-compose git openssl apache2-utils"
        exit 1
    fi
}

#═══════════════════════════════════════════════════════════════════════════
# COLLECTE DES INFORMATIONS UTILISATEUR
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

    # Hash du mot de passe admin (APR1 - compatible htpasswd)
    ADMIN_PASSWORD_HASH=$(openssl passwd -apr1 "$ADMIN_PASSWORD")

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
