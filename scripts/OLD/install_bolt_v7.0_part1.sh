#!/bin/bash
#═══════════════════════════════════════════════════════════════════════════
# BOLT.DIY NBILITY - Installation Script v7.0
# Architecture Multi-Ports + User Manager v2.0 COMPLET + MariaDB + Docker
# © Copyright Nbility 2025 - contact@nbility.fr
#
# 🆕 NOUVEAUTÉS v7.0 (User Manager v2.0 COMPLET):
# ✅ Clonage intelligent depuis GitHub avec copie automatique
# ✅ Suppression génération locale de fichiers PHP (désormais sur GitHub)
# ✅ Architecture MVC v2.0 complète (Controllers, Models, Middleware, Utils)
# ✅ Backend PHP complet (20 fichiers) avec autoload PSR-4
# ✅ Frontend JS moderne (9 modules: api, auth, utils, users, groups, etc.)
# ✅ Vérification intégrité des fichiers clonés (45 fichiers)
# ✅ Configuration .env User Manager automatique
# ✅ Volumes Docker pour logs/, cache/, uploads/, backups/
# ✅ Dockerfile PHP 8.1 (au lieu de 8.2)
# ✅ Installation optionnelle des dépendances Composer
# ✅ Scripts de maintenance (backup.sh, maintenance.sh) depuis GitHub
# ✅ Réduction de ~30% du code (-780 lignes)
#
# 🔧 AMÉLIORATIONS MAJEURES:
# • Pas de génération locale de index.php, logout.php, composer.json
# • Tout le code User Manager v2.0 provient de GitHub
# • Vérification complète des 45 fichiers du projet
# • Structure de répertoires conforme à l'architecture MVC
#
# 📦 REPOSITORY: https://github.com/NBILITY-HOME/BOLT.DIY-INTRANET
#═══════════════════════════════════════════════════════════════════════════

clear
printf "\033[8;55;116t"

# Vérification sudo/root
if [ "$EUID" -eq 0 ]; then
    echo -e "\033[0;31m✗ ERREUR: Ce script NE DOIT PAS être lancé en sudo/root\033[0m"
    echo ""
    echo "Raison: Docker et les fichiers doivent appartenir à votre utilisateur"
    echo ""
    echo "Solution: Lancez le script sans sudo:"
    echo "  ./install_bolt_v7.0.sh"
    echo ""
    exit 1
fi

#═══════════════════════════════════════════════════════════════════════════
# VARIABLES GLOBALES
#═══════════════════════════════════════════════════════════════════════════

# Chemins
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$SCRIPT_DIR"
DATA_LOCAL_DIR="$PROJECT_ROOT/DATA-LOCAL"
NGINX_DIR="$DATA_LOCAL_DIR/nginx"
MARIADB_DIR="$DATA_LOCAL_DIR/mariadb"
USERMANAGER_DIR="$DATA_LOCAL_DIR/user-manager"

# GitHub
GITHUB_REPO="https://github.com/NBILITY-HOME/BOLT.DIY-INTRANET.git"
CLONE_DIR="$PROJECT_ROOT/PROJET-SOURCE"

# Versions
BOLT_VERSION="v7.0"
USER_MANAGER_VERSION="2.0"

# Configuration utilisateur (sera demandée)
LOCAL_IP=""
HOST_PORT_BOLT=""
HOST_PORT_HOME=""
HOST_PORT_UM=""
ADMIN_USER=""
ADMIN_PASSWORD=""
MARIADB_ROOT_PASSWORD=""
MARIADB_USER_PASSWORD=""
APP_SECRET=""
OPENAI_API_KEY=""
ANTHROPIC_API_KEY=""
GOOGLE_API_KEY=""
GROQ_API_KEY=""

# Couleurs
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'
BOLD='\033[1m'

#═══════════════════════════════════════════════════════════════════════════
# FONCTIONS UTILITAIRES
#═══════════════════════════════════════════════════════════════════════════

print_banner() {
    clear
    echo -e "${CYAN}"
    echo "╔════════════════════════════════════════════════════════════════════════╗"
    echo "║                                                                        ║"
    echo "║ ${BOLD}BOLT.DIY NBILITY - Installer v7.0${NC}${CYAN}                                   ║"
    echo "║                                                                        ║"
    echo "║ Installation Docker complète:                                          ║"
    echo "║ • Bolt.DIY (AI Code Generator)                                         ║"
    echo "║ • User Manager v2.0 COMPLET (MVC + 45 fichiers)                       ║"
    echo "║ • MariaDB 10.11                                                        ║"
    echo "║ • Nginx Reverse Proxy                                                  ║"
    echo "║                                                                        ║"
    echo "║ © 2025 Nbility - Seysses, France                                       ║"
    echo "║                                                                        ║"
    echo "╚════════════════════════════════════════════════════════════════════════╝"
    echo -e "${NC}"
    echo ""
}

print_section() {
    echo ""
    echo -e "${BOLD}${BLUE}═══════════════════════════════════════════════════════════════════════════${NC}"
    echo -e "${BOLD}${BLUE}  $1${NC}"
    echo -e "${BOLD}${BLUE}═══════════════════════════════════════════════════════════════════════════${NC}"
    echo ""
}

print_step() {
    echo -e "${CYAN}▶ $1${NC}"
}

print_success() {
    echo -e "${GREEN}✓ $1${NC}"
}

print_error() {
    echo -e "${RED}✗ ERREUR: $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠ ATTENTION: $1${NC}"
}

generate_password() {
    openssl rand -base64 32 | tr -dc 'a-zA-Z0-9' | head -c 32
}

#═══════════════════════════════════════════════════════════════════════════
# FONCTION: Vérification des prérequis
#═══════════════════════════════════════════════════════════════════════════
check_prerequisites() {
    print_section "VÉRIFICATION DES PRÉREQUIS"

    local all_ok=true

    # Docker
    print_step "Vérification Docker..."
    if command -v docker &> /dev/null; then
        DOCKER_VERSION=$(docker --version | awk '{print $3}' | tr -d ',')
        print_success "Docker $DOCKER_VERSION installé"
    else
        print_error "Docker n'est pas installé"
        all_ok=false
    fi

    # Docker Compose
    print_step "Vérification Docker Compose..."
    if command -v docker-compose &> /dev/null || docker compose version &> /dev/null; then
        print_success "Docker Compose installé"
    else
        print_error "Docker Compose n'est pas installé"
        all_ok=false
    fi

    # Git
    print_step "Vérification Git..."
    if command -v git &> /dev/null; then
        GIT_VERSION=$(git --version | awk '{print $3}')
        print_success "Git $GIT_VERSION installé"
    else
        print_error "Git n'est pas installé"
        all_ok=false
    fi

    # curl
    print_step "Vérification curl..."
    if command -v curl &> /dev/null; then
        print_success "curl installé"
    else
        print_error "curl n'est pas installé"
        all_ok=false
    fi

    # htpasswd
    print_step "Vérification htpasswd..."
    if command -v htpasswd &> /dev/null; then
        print_success "htpasswd installé"
    else
        print_warning "htpasswd non installé (optionnel)"
        print_warning "Installation: sudo apt install apache2-utils"
    fi

    # Composer (optionnel)
    print_step "Vérification Composer (optionnel)..."
    if command -v composer &> /dev/null; then
        COMPOSER_VERSION=$(composer --version | awk '{print $3}')
        print_success "Composer $COMPOSER_VERSION installé"
    else
        print_warning "Composer non installé (optionnel)"
        print_warning "Les dépendances PHP seront installées dans le conteneur"
    fi

    if [ "$all_ok" = false ]; then
        echo ""
        print_error "Certains prérequis manquent. Installation impossible."
        echo ""
        echo "Pour installer les prérequis sur Debian/Ubuntu:"
        echo "  sudo apt update"
        echo "  sudo apt install docker.io docker-compose git curl apache2-utils"
        echo ""
        exit 1
    fi

    print_success "Tous les prérequis sont satisfaits"
    echo ""
}

#═══════════════════════════════════════════════════════════════════════════
# FONCTION: Vérification Internet et GitHub
#═══════════════════════════════════════════════════════════════════════════
check_internet_and_github() {
    print_section "VÉRIFICATION CONNECTIVITÉ"

    print_step "Test de connexion Internet..."
    if curl -s --head --max-time 5 https://www.google.com | head -n 1 | grep "HTTP/" > /dev/null; then
        print_success "Connexion Internet OK"
    else
        print_error "Pas de connexion Internet"
        exit 1
    fi

    print_step "Test d'accès à GitHub..."
    if curl -s --head --max-time 5 https://github.com | head -n 1 | grep "HTTP/" > /dev/null; then
        print_success "Accès GitHub OK"
    else
        print_error "Impossible d'accéder à GitHub"
        exit 1
    fi

    print_step "Test d'accès au repository..."
    if git ls-remote "$GITHUB_REPO" HEAD &> /dev/null; then
        print_success "Repository accessible"
    else
        print_error "Repository inaccessible: $GITHUB_REPO"
        exit 1
    fi

    echo ""
}
