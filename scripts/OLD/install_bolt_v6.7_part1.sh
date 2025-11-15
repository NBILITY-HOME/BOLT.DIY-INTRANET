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
