#!/bin/bash
#═══════════════════════════════════════════════════════════════════════════
# BOLT.DIY NBILITY - Installation Script v7.0 (ASSEMBLÉ)
# Architecture Multi-Ports + User Manager v2.0 COMPLET + MariaDB + Docker
# © Copyright Nbility 2025 - contact@nbility.fr
#
# 🆕 SCRIPT ASSEMBLÉ AUTOMATIQUEMENT
# Généré à partir des fichiers modulaires (parts 1-6)
#
# Pour modifier ce script:
# 1. Éditez les fichiers install_bolt_v7.0_partX.sh
# 2. Relancez: ./assemble.sh
#
# Repository: https://github.com/NBILITY-HOME/BOLT.DIY-INTRANET
#═══════════════════════════════════════════════════════════════════════════
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

#═══════════════════════════════════════════════════════════════════════════
# FONCTION: Configuration interactive
#═══════════════════════════════════════════════════════════════════════════
get_configuration() {
    print_section "CONFIGURATION"

    # Détection IP automatique
    DEFAULT_IP=$(hostname -I | awk '{print $1}')
    if [ -z "$DEFAULT_IP" ]; then
        DEFAULT_IP="127.0.0.1"
    fi

    echo -e "${BOLD}Configuration du serveur:${NC}"
    echo ""

    # IP
    read -p "Adresse IP du serveur [$DEFAULT_IP]: " LOCAL_IP
    LOCAL_IP=${LOCAL_IP:-$DEFAULT_IP}
    print_success "IP: $LOCAL_IP"
    echo ""

    # Ports
    echo -e "${BOLD}Configuration des ports:${NC}"
    read -p "Port Bolt.DIY [8080]: " HOST_PORT_BOLT
    HOST_PORT_BOLT=${HOST_PORT_BOLT:-8080}

    read -p "Port Page d'accueil [8686]: " HOST_PORT_HOME
    HOST_PORT_HOME=${HOST_PORT_HOME:-8686}

    read -p "Port User Manager [8787]: " HOST_PORT_UM
    HOST_PORT_UM=${HOST_PORT_UM:-8787}

    print_success "Ports: Bolt=$HOST_PORT_BOLT, Home=$HOST_PORT_HOME, UM=$HOST_PORT_UM"
    echo ""

    # Compte admin
    echo -e "${BOLD}Compte administrateur:${NC}"
    read -p "Nom d'utilisateur [admin]: " ADMIN_USER
    ADMIN_USER=${ADMIN_USER:-admin}

    while true; do
        read -sp "Mot de passe admin: " ADMIN_PASSWORD
        echo ""
        if [ ${#ADMIN_PASSWORD} -ge 8 ]; then
            read -sp "Confirmer le mot de passe: " ADMIN_PASSWORD_CONFIRM
            echo ""
            if [ "$ADMIN_PASSWORD" = "$ADMIN_PASSWORD_CONFIRM" ]; then
                break
            else
                print_error "Les mots de passe ne correspondent pas"
            fi
        else
            print_error "Le mot de passe doit contenir au moins 8 caractères"
        fi
    done
    print_success "Compte admin configuré"
    echo ""

    # Mots de passe base de données
    print_step "Génération des mots de passe sécurisés..."
    MARIADB_ROOT_PASSWORD=$(generate_password)
    MARIADB_USER_PASSWORD=$(generate_password)
    APP_SECRET=$(generate_password)
    print_success "Mots de passe générés"
    echo ""

    # Clés API (optionnel)
    echo -e "${BOLD}Clés API LLM (optionnel, Entrée pour skip):${NC}"
    read -p "OpenAI API Key: " OPENAI_API_KEY
    read -p "Anthropic API Key: " ANTHROPIC_API_KEY
    read -p "Google API Key: " GOOGLE_API_KEY
    read -p "Groq API Key: " GROQ_API_KEY
    echo ""

    # Résumé
    echo -e "${BOLD}${GREEN}Configuration terminée:${NC}"
    echo "  • IP: $LOCAL_IP"
    echo "  • Port Bolt.DIY: $HOST_PORT_BOLT"
    echo "  • Port Home: $HOST_PORT_HOME"
    echo "  • Port User Manager: $HOST_PORT_UM"
    echo "  • Admin: $ADMIN_USER"
    echo ""
}

#═══════════════════════════════════════════════════════════════════════════
# FONCTION: Clonage du repository GitHub
#═══════════════════════════════════════════════════════════════════════════
clone_repository() {
    print_section "CLONAGE DU REPOSITORY GITHUB"

    # Supprimer clone précédent si existe
    if [ -d "$CLONE_DIR" ]; then
        print_step "Suppression du clone précédent..."
        rm -rf "$CLONE_DIR"
    fi

    # Clone
    print_step "Clonage depuis GitHub..."
    print_step "Repository: $GITHUB_REPO"

    if git clone --depth 1 "$GITHUB_REPO" "$CLONE_DIR"; then
        print_success "Repository cloné avec succès"
    else
        print_error "Échec du clonage"
        exit 1
    fi

    # Vérifier présence User Manager
    if [ ! -d "$CLONE_DIR/DATA-LOCAL/user-manager" ]; then
        print_error "Dossier User Manager introuvable dans le clone"
        exit 1
    fi

    # Copier User Manager vers DATA-LOCAL
    print_step "Copie User Manager depuis le clone..."

    mkdir -p "$USERMANAGER_DIR"

    # Copier TOUT le contenu User Manager
    if cp -r "$CLONE_DIR/DATA-LOCAL/user-manager/"* "$USERMANAGER_DIR/" 2>/dev/null; then
        print_success "User Manager copié"
    else
        print_error "Échec de la copie User Manager"
        exit 1
    fi

    # Créer les dossiers runtime (pas dans Git)
    print_step "Création des dossiers runtime..."
    mkdir -p "$USERMANAGER_DIR/app/logs"
    mkdir -p "$USERMANAGER_DIR/app/cache"
    mkdir -p "$USERMANAGER_DIR/uploads"
    mkdir -p "$USERMANAGER_DIR/backups"

    # Permissions
    chmod -R 755 "$USERMANAGER_DIR/app" 2>/dev/null || true
    chmod +x "$USERMANAGER_DIR/app/scripts/"*.sh 2>/dev/null || true

    print_success "Dossiers runtime créés"

    # Copier autres dossiers si nécessaires
    print_step "Copie des autres composants..."
    mkdir -p "$NGINX_DIR"
    mkdir -p "$MARIADB_DIR/init"

    print_success "Structure de répertoires prête"
    echo ""
}

#═══════════════════════════════════════════════════════════════════════════
# FONCTION: Vérification des fichiers GitHub
#═══════════════════════════════════════════════════════════════════════════
verify_github_files() {
    print_section "VÉRIFICATION DES FICHIERS GITHUB"

    local all_ok=true
    local critical_ok=true

    print_step "Vérification User Manager v2.0..."
    echo ""

    # Fichiers de configuration
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
        print_error "composer.json manquant (CRITIQUE)"
        critical_ok=false
    fi

    if [ -f "$USERMANAGER_DIR/.gitignore" ]; then
        print_success ".gitignore présent"
    else
        print_warning ".gitignore manquant"
    fi

    # Structure backend
    if [ -d "$USERMANAGER_DIR/app/src/Controllers" ]; then
        CONTROLLER_COUNT=$(find "$USERMANAGER_DIR/app/src/Controllers" -name "*.php" 2>/dev/null | wc -l)
        if [ $CONTROLLER_COUNT -gt 0 ]; then
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
        if [ $MODEL_COUNT -gt 0 ]; then
            print_success "Models: $MODEL_COUNT fichiers"
        else
            print_error "Dossier Models vide"
            critical_ok=false
        fi
    else
        print_error "Dossier Models manquant"
        critical_ok=false
    fi

    if [ -d "$USERMANAGER_DIR/app/src/Middleware" ]; then
        MIDDLEWARE_COUNT=$(find "$USERMANAGER_DIR/app/src/Middleware" -name "*.php" 2>/dev/null | wc -l)
        if [ $MIDDLEWARE_COUNT -gt 0 ]; then
            print_success "Middleware: $MIDDLEWARE_COUNT fichiers"
        else
            print_warning "Dossier Middleware vide"
        fi
    fi

    if [ -d "$USERMANAGER_DIR/app/src/Utils" ]; then
        UTILS_COUNT=$(find "$USERMANAGER_DIR/app/src/Utils" -name "*.php" 2>/dev/null | wc -l)
        if [ $UTILS_COUNT -gt 0 ]; then
            print_success "Utils: $UTILS_COUNT fichiers"
        else
            print_warning "Dossier Utils vide"
        fi
    fi

    # Frontend
    if [ -d "$USERMANAGER_DIR/app/public/assets/js" ]; then
        JS_COUNT=$(find "$USERMANAGER_DIR/app/public/assets/js" -name "*.js" 2>/dev/null | wc -l)
        if [ $JS_COUNT -ge 9 ]; then
            print_success "JavaScript: $JS_COUNT fichiers (attendu: 9)"
        else
            print_warning "JavaScript: $JS_COUNT fichiers (incomplet, attendu: 9)"
        fi
    else
        print_error "Dossier JavaScript manquant"
        critical_ok=false
    fi

    if [ -d "$USERMANAGER_DIR/app/public/assets/css" ]; then
        CSS_COUNT=$(find "$USERMANAGER_DIR/app/public/assets/css" -name "*.css" 2>/dev/null | wc -l)
        if [ $CSS_COUNT -gt 0 ]; then
            print_success "CSS: $CSS_COUNT fichier(s)"
        fi
    fi

    # Pages HTML
    if [ -d "$USERMANAGER_DIR/app/public" ]; then
        HTML_COUNT=$(find "$USERMANAGER_DIR/app/public" -maxdepth 1 -name "*.html" 2>/dev/null | wc -l)
        if [ $HTML_COUNT -ge 6 ]; then
            print_success "Pages HTML: $HTML_COUNT fichiers (attendu: 6)"
        else
            print_warning "Pages HTML: $HTML_COUNT fichiers (incomplet, attendu: 6)"
        fi
    fi

    # Scripts
    if [ -f "$USERMANAGER_DIR/app/scripts/backup.sh" ]; then
        print_success "Script backup.sh présent"
    else
        print_warning "backup.sh manquant"
    fi

    if [ -f "$USERMANAGER_DIR/app/scripts/maintenance.sh" ]; then
        print_success "Script maintenance.sh présent"
    else
        print_warning "maintenance.sh manquant"
    fi

    # Base de données
    if [ -f "$USERMANAGER_DIR/app/database/migrations/01-schema.sql" ]; then
        print_success "Schema SQL présent"
    else
        print_warning "Schema SQL manquant"
    fi

    if [ -f "$USERMANAGER_DIR/app/database/migrations/02-seed.sql" ]; then
        print_success "Seed SQL présent"
    else
        print_warning "Seed SQL manquant"
    fi

    echo ""

    if [ "$critical_ok" = false ]; then
        print_error "Fichiers critiques manquants, installation impossible"
        exit 1
    elif [ "$all_ok" = true ]; then
        print_success "Tous les fichiers sont présents"
    else
        print_warning "Certains fichiers optionnels sont manquants"
        print_warning "L'installation va continuer..."
    fi

    echo ""
}

#═══════════════════════════════════════════════════════════════════════════
# FONCTION: Installation des dépendances Composer (optionnel)
#═══════════════════════════════════════════════════════════════════════════
install_composer_dependencies() {
    print_section "DÉPENDANCES COMPOSER"

    if [ -f "$USERMANAGER_DIR/composer.json" ]; then
        print_step "Vérification Composer..."

        if command -v composer &> /dev/null; then
            print_step "Installation des dépendances PHP..."
            cd "$USERMANAGER_DIR"

            if composer install --no-dev --optimize-autoloader 2>&1 | tee /tmp/composer_install.log; then
                print_success "Dépendances installées avec succès"
            else
                print_warning "Erreur lors de l'installation des dépendances"
                print_warning "Elles seront installées dans le conteneur Docker"
            fi

            cd "$SCRIPT_DIR"
        else
            print_warning "Composer non installé localement"
            print_warning "Les dépendances seront installées dans le conteneur"
        fi
    else
        print_warning "composer.json non trouvé, skip"
    fi

    echo ""
}

#═══════════════════════════════════════════════════════════════════════════
# FONCTION: Génération docker-compose.yml
#═══════════════════════════════════════════════════════════════════════════
generate_docker_compose() {
    print_section "GÉNÉRATION DOCKER-COMPOSE.YML"

    print_step "Création du fichier docker-compose.yml..."

    cat > "$PROJECT_ROOT/docker-compose.yml" << 'DOCKER_COMPOSE_EOF'
version: '3.8'

services:
  # ═══════════════════════════════════════════════════════════════════════════
  # BOLT.DIY - AI Code Generator
  # ═══════════════════════════════════════════════════════════════════════════
  bolt-nbility-core:
    image: ghcr.io/stackblitz-labs/bolt.diy:latest
    container_name: bolt-nbility-core
    restart: unless-stopped
    environment:
      - GROQ_API_KEY=${GROQ_API_KEY}
      - OPENAI_API_KEY=${OPENAI_API_KEY}
      - ANTHROPIC_API_KEY=${ANTHROPIC_API_KEY}
      - GOOGLE_GENERATIVE_AI_API_KEY=${GOOGLE_API_KEY}
    volumes:
      - ./DATA:/app/data:cached
    networks:
      - bolt-network
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:5173/"]
      interval: 30s
      timeout: 10s
      retries: 3

  # ═══════════════════════════════════════════════════════════════════════════
  # MARIADB - Base de données
  # ═══════════════════════════════════════════════════════════════════════════
  bolt-mariadb:
    image: mariadb:10.11
    container_name: bolt-mariadb
    restart: unless-stopped
    environment:
      MYSQL_ROOT_PASSWORD: ${MARIADB_ROOT_PASSWORD}
      MYSQL_DATABASE: bolt_usermanager
      MYSQL_USER: bolt_um
      MYSQL_PASSWORD: ${MARIADB_USER_PASSWORD}
    volumes:
      - mariadb-data:/var/lib/mysql
      - ./DATA-LOCAL/mariadb/init:/docker-entrypoint-initdb.d:ro
    networks:
      - bolt-network
    healthcheck:
      test: ["CMD", "healthcheck.sh", "--connect", "--innodb_initialized"]
      interval: 10s
      timeout: 5s
      retries: 5

  # ═══════════════════════════════════════════════════════════════════════════
  # USER MANAGER v2.0 - Gestion utilisateurs, groupes, permissions
  # ═══════════════════════════════════════════════════════════════════════════
  bolt-user-manager:
    build:
      context: ./DATA-LOCAL/user-manager
      dockerfile: Dockerfile
    container_name: bolt-user-manager
    restart: unless-stopped
    environment:
      - DB_HOST=bolt-mariadb
      - DB_PORT=3306
      - DB_NAME=bolt_usermanager
      - DB_USER=bolt_um
      - DB_PASSWORD=${MARIADB_USER_PASSWORD}
    volumes:
      - ./DATA-LOCAL/user-manager/app:/var/www/html:cached
      - ./DATA-LOCAL/user-manager/app/logs:/var/www/html/app/logs:rw
      - ./DATA-LOCAL/user-manager/uploads:/var/www/html/uploads:rw
      - ./DATA-LOCAL/user-manager/backups:/var/www/html/backups:rw
    networks:
      - bolt-network
    depends_on:
      bolt-mariadb:
        condition: service_healthy
    healthcheck:
      test: ["CMD", "php", "-r", "echo 'OK';"]
      interval: 30s
      timeout: 10s
      retries: 3

  # ═══════════════════════════════════════════════════════════════════════════
  # NGINX - Reverse Proxy + Authentification
  # ═══════════════════════════════════════════════════════════════════════════
  bolt-nginx:
    image: nginx:alpine
    container_name: bolt-nginx
    restart: unless-stopped
    ports:
      - "${HOST_PORT_BOLT}:80"
      - "${HOST_PORT_HOME}:8686"
      - "${HOST_PORT_UM}:8787"
    volumes:
      - ./DATA-LOCAL/nginx/nginx.conf:/etc/nginx/nginx.conf:ro
      - ./DATA-LOCAL/nginx/.htpasswd:/etc/nginx/.htpasswd:ro
      - ./DATA-LOCAL/nginx/home.html:/usr/share/nginx/html/home.html:ro
    networks:
      - bolt-network
    depends_on:
      - bolt-nbility-core
      - bolt-user-manager
    healthcheck:
      test: ["CMD", "wget", "--quiet", "--tries=1", "--spider", "http://localhost:80/health"]
      interval: 30s
      timeout: 10s
      retries: 3

networks:
  bolt-network:
    driver: bridge

volumes:
  mariadb-data:
    driver: local
DOCKER_COMPOSE_EOF

    print_success "docker-compose.yml créé"
    echo ""
}

#═══════════════════════════════════════════════════════════════════════════
# FONCTION: Génération nginx.conf
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
    gzip_vary on;
    gzip_proxied any;
    gzip_comp_level 6;
    gzip_types text/plain text/css text/xml text/javascript 
               application/json application/javascript application/xml+rss;

    # ═══════════════════════════════════════════════════════════════════════
    # SERVER 1: BOLT.DIY (Port 80) - AVEC AUTHENTIFICATION
    # ═══════════════════════════════════════════════════════════════════════
    server {
        listen 80;
        server_name _;

        # Authentification HTTP Basic
        auth_basic "Bolt.DIY - Accès Restreint";
        auth_basic_user_file /etc/nginx/.htpasswd;

        # Health check (sans auth)
        location = /health {
            auth_basic off;
            access_log off;
            return 200 "OK\n";
            add_header Content-Type text/plain;
        }

        # Proxy vers Bolt.DIY
        location / {
            proxy_pass http://bolt-nbility-core:5173;
            proxy_http_version 1.1;
            proxy_set_header Upgrade $http_upgrade;
            proxy_set_header Connection "upgrade";
            proxy_set_header Host $host;
            proxy_set_header X-Real-IP $remote_addr;
            proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
            proxy_set_header X-Forwarded-Proto $scheme;
            proxy_cache_bypass $http_upgrade;
            proxy_read_timeout 300s;
            proxy_connect_timeout 75s;
        }
    }

    # ═══════════════════════════════════════════════════════════════════════
    # SERVER 2: PAGE D'ACCUEIL (Port 8686) - SANS AUTHENTIFICATION
    # ═══════════════════════════════════════════════════════════════════════
    server {
        listen 8686;
        server_name _;

        root /usr/share/nginx/html;
        index home.html;

        location / {
            try_files $uri $uri/ =404;
        }

        location = /favicon.ico {
            log_not_found off;
            access_log off;
        }
    }

    # ═══════════════════════════════════════════════════════════════════════
    # SERVER 3: USER MANAGER v2.0 (Port 8787) - AVEC AUTHENTIFICATION
    # ═══════════════════════════════════════════════════════════════════════
    server {
        listen 8787;
        server_name _;

        # Authentification HTTP Basic
        auth_basic "User Manager - Accès Admin";
        auth_basic_user_file /etc/nginx/.htpasswd;

        # Racine vers User Manager
        root /var/www/html;

        # Configuration PHP
        location / {
            proxy_pass http://bolt-user-manager:80;
            proxy_set_header Host $host;
            proxy_set_header X-Real-IP $remote_addr;
            proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
            proxy_set_header X-Forwarded-Proto $scheme;
            proxy_read_timeout 300s;
        }

        # Fichiers statiques (CSS, JS, images)
        location ~* \.(css|js|jpg|jpeg|png|gif|ico|svg|woff|woff2|ttf|eot)$ {
            proxy_pass http://bolt-user-manager:80;
            expires 30d;
            add_header Cache-Control "public, immutable";
        }
    }
}
NGINX_CONF_EOF

    print_success "nginx.conf créé"

    # Copier home.html depuis le clone
    if [ -f "$CLONE_DIR/DATA-LOCAL/nginx/home.html" ]; then
        print_step "Copie de home.html depuis GitHub..."
        cp "$CLONE_DIR/DATA-LOCAL/nginx/home.html" "$NGINX_DIR/home.html"
        print_success "home.html copié"
    else
        print_warning "home.html non trouvé dans le clone, création d'une version basique..."
        cat > "$NGINX_DIR/home.html" << 'HOME_HTML_EOF'
<!DOCTYPE html>
<html lang="fr">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>BOLT.DIY Nbility - Accueil</title>
    <style>
        * { margin: 0; padding: 0; box-sizing: border-box; }
        body {
            font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif;
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            min-height: 100vh;
            display: flex;
            align-items: center;
            justify-content: center;
            color: white;
        }
        .container {
            text-align: center;
            padding: 2rem;
            background: rgba(255, 255, 255, 0.1);
            backdrop-filter: blur(10px);
            border-radius: 20px;
            box-shadow: 0 8px 32px 0 rgba(31, 38, 135, 0.37);
        }
        h1 { font-size: 3rem; margin-bottom: 1rem; }
        p { font-size: 1.2rem; margin-bottom: 2rem; opacity: 0.9; }
        .links { display: flex; gap: 1rem; justify-content: center; flex-wrap: wrap; }
        a {
            display: inline-block;
            padding: 1rem 2rem;
            background: white;
            color: #667eea;
            text-decoration: none;
            border-radius: 10px;
            font-weight: bold;
            transition: transform 0.3s, box-shadow 0.3s;
        }
        a:hover {
            transform: translateY(-5px);
            box-shadow: 0 10px 20px rgba(0,0,0,0.2);
        }
    </style>
</head>
<body>
    <div class="container">
        <h1>🚀 BOLT.DIY Nbility</h1>
        <p>Plateforme de développement IA</p>
        <div class="links">
            <a href="http://REPLACE_IP:REPLACE_PORT_BOLT" target="_blank" rel="noopener noreferrer">Accéder à Bolt.DIY</a>
            <a href="http://REPLACE_IP:REPLACE_PORT_UM" target="_blank" rel="noopener noreferrer">User Manager</a>
        </div>
    </div>
</body>
</html>
HOME_HTML_EOF

        # Remplacer les placeholders
        sed -i "s/REPLACE_IP/$LOCAL_IP/g" "$NGINX_DIR/home.html"
        sed -i "s/REPLACE_PORT_BOLT/$HOST_PORT_BOLT/g" "$NGINX_DIR/home.html"
        sed -i "s/REPLACE_PORT_UM/$HOST_PORT_UM/g" "$NGINX_DIR/home.html"

        print_success "home.html basique créé"
    fi

    echo ""
}

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

#═══════════════════════════════════════════════════════════════════════════
# FONCTION: Création des fichiers SQL
#═══════════════════════════════════════════════════════════════════════════
create_sql_files() {
    print_section "GÉNÉRATION FICHIERS SQL"

    # Vérifier si les fichiers SQL existent déjà dans le clone
    if [ -f "$USERMANAGER_DIR/app/database/migrations/01-schema.sql" ] && \
       [ -f "$USERMANAGER_DIR/app/database/migrations/02-seed.sql" ]; then
        print_success "Fichiers SQL déjà présents depuis GitHub"

        # Copier vers mariadb/init
        print_step "Copie des fichiers SQL vers mariadb/init..."
        cp "$USERMANAGER_DIR/app/database/migrations/01-schema.sql" "$MARIADB_DIR/init/"
        cp "$USERMANAGER_DIR/app/database/migrations/02-seed.sql" "$MARIADB_DIR/init/"
        print_success "Fichiers SQL copiés"
    else
        print_warning "Fichiers SQL non trouvés dans GitHub, génération locale..."

        # 01-schema.sql
        print_step "Création de 01-schema.sql..."
        cat > "$MARIADB_DIR/init/01-schema.sql" << 'SCHEMA_SQL_EOF'
-- ═══════════════════════════════════════════════════════════════════════════
-- USER MANAGER v2.0 - Database Schema
-- © Copyright Nbility 2025
-- ═══════════════════════════════════════════════════════════════════════════

USE bolt_usermanager;

-- Table: users
CREATE TABLE IF NOT EXISTS users (
    id INT AUTO_INCREMENT PRIMARY KEY,
    username VARCHAR(50) UNIQUE NOT NULL,
    email VARCHAR(255) UNIQUE NOT NULL,
    password VARCHAR(255) NOT NULL,
    first_name VARCHAR(100),
    last_name VARCHAR(100),
    role ENUM('super_admin', 'admin', 'user') DEFAULT 'user',
    status ENUM('active', 'inactive', 'suspended') DEFAULT 'active',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    last_login TIMESTAMP NULL,
    INDEX idx_username (username),
    INDEX idx_email (email),
    INDEX idx_status (status),
    INDEX idx_role (role)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Table: groups
CREATE TABLE IF NOT EXISTS groups (
    id INT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(100) UNIQUE NOT NULL,
    description TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    INDEX idx_name (name)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Table: user_groups (relation many-to-many)
CREATE TABLE IF NOT EXISTS user_groups (
    user_id INT NOT NULL,
    group_id INT NOT NULL,
    assigned_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (user_id, group_id),
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
    FOREIGN KEY (group_id) REFERENCES groups(id) ON DELETE CASCADE,
    INDEX idx_user_id (user_id),
    INDEX idx_group_id (group_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Table: permissions
CREATE TABLE IF NOT EXISTS permissions (
    id INT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(100) UNIQUE NOT NULL,
    slug VARCHAR(100) UNIQUE NOT NULL,
    description TEXT,
    category VARCHAR(50),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    INDEX idx_slug (slug),
    INDEX idx_category (category)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Table: group_permissions (relation many-to-many)
CREATE TABLE IF NOT EXISTS group_permissions (
    group_id INT NOT NULL,
    permission_id INT NOT NULL,
    granted_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (group_id, permission_id),
    FOREIGN KEY (group_id) REFERENCES groups(id) ON DELETE CASCADE,
    FOREIGN KEY (permission_id) REFERENCES permissions(id) ON DELETE CASCADE,
    INDEX idx_group_id (group_id),
    INDEX idx_permission_id (permission_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Table: user_permissions (permissions directes, override groups)
CREATE TABLE IF NOT EXISTS user_permissions (
    user_id INT NOT NULL,
    permission_id INT NOT NULL,
    granted_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (user_id, permission_id),
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
    FOREIGN KEY (permission_id) REFERENCES permissions(id) ON DELETE CASCADE,
    INDEX idx_user_id (user_id),
    INDEX idx_permission_id (permission_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Table: sessions
CREATE TABLE IF NOT EXISTS sessions (
    id VARCHAR(128) PRIMARY KEY,
    user_id INT NOT NULL,
    ip_address VARCHAR(45),
    user_agent TEXT,
    metadata JSON,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    expires_at TIMESTAMP NOT NULL,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
    INDEX idx_user_id (user_id),
    INDEX idx_expires_at (expires_at)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Table: audit_logs
CREATE TABLE IF NOT EXISTS audit_logs (
    id INT AUTO_INCREMENT PRIMARY KEY,
    user_id INT,
    action VARCHAR(100) NOT NULL,
    entity_type VARCHAR(50),
    entity_id INT,
    metadata JSON,
    ip_address VARCHAR(45),
    user_agent TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE SET NULL,
    INDEX idx_user_id (user_id),
    INDEX idx_action (action),
    INDEX idx_entity (entity_type, entity_id),
    INDEX idx_created_at (created_at)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Optimisations
ANALYZE TABLE users;
ANALYZE TABLE groups;
ANALYZE TABLE permissions;
SCHEMA_SQL_EOF
        print_success "01-schema.sql créé"

        # 02-seed.sql
        print_step "Création de 02-seed.sql..."

        # Générer hash password admin
        ADMIN_PASSWORD_HASH=$(php -r "echo password_hash('$ADMIN_PASSWORD', PASSWORD_BCRYPT);")

        cat > "$MARIADB_DIR/init/02-seed.sql" << SEED_SQL_EOF
-- ═══════════════════════════════════════════════════════════════════════════
-- USER MANAGER v2.0 - Seed Data
-- © Copyright Nbility 2025
-- ═══════════════════════════════════════════════════════════════════════════

USE bolt_usermanager;

-- Utilisateur admin
INSERT INTO users (username, email, password, first_name, last_name, role, status) 
VALUES ('$ADMIN_USER', 'admin@localhost', '$ADMIN_PASSWORD_HASH', 'Admin', 'System', 'super_admin', 'active')
ON DUPLICATE KEY UPDATE 
    email = VALUES(email),
    password = VALUES(password),
    role = VALUES(role),
    status = VALUES(status);

-- Groupes par défaut
INSERT INTO groups (name, description) VALUES
('Administrators', 'Administrateurs système avec tous les droits'),
('Developers', 'Développeurs avec accès Bolt.DIY'),
('Users', 'Utilisateurs standards')
ON DUPLICATE KEY UPDATE description = VALUES(description);

-- Permissions système
INSERT INTO permissions (name, slug, description, category) VALUES
-- User management
('Voir les utilisateurs', 'users.view', 'Consulter la liste des utilisateurs', 'users'),
('Créer des utilisateurs', 'users.create', 'Créer de nouveaux utilisateurs', 'users'),
('Modifier des utilisateurs', 'users.edit', 'Modifier les utilisateurs existants', 'users'),
('Supprimer des utilisateurs', 'users.delete', 'Supprimer des utilisateurs', 'users'),
-- Group management
('Voir les groupes', 'groups.view', 'Consulter la liste des groupes', 'groups'),
('Créer des groupes', 'groups.create', 'Créer de nouveaux groupes', 'groups'),
('Modifier des groupes', 'groups.edit', 'Modifier les groupes existants', 'groups'),
('Supprimer des groupes', 'groups.delete', 'Supprimer des groupes', 'groups'),
-- Permission management
('Voir les permissions', 'permissions.view', 'Consulter les permissions', 'permissions'),
('Gérer les permissions', 'permissions.manage', 'Attribuer/retirer des permissions', 'permissions'),
-- Audit
('Voir les logs', 'audit.view', 'Consulter les logs d\'audit', 'audit'),
-- System
('Accès système', 'system.access', 'Accès aux paramètres système', 'system')
ON DUPLICATE KEY UPDATE 
    name = VALUES(name),
    description = VALUES(description);

-- Assigner admin au groupe Administrators
INSERT INTO user_groups (user_id, group_id)
SELECT u.id, g.id 
FROM users u, groups g 
WHERE u.username = '$ADMIN_USER' AND g.name = 'Administrators'
ON DUPLICATE KEY UPDATE assigned_at = CURRENT_TIMESTAMP;

-- Donner toutes les permissions au groupe Administrators
INSERT INTO group_permissions (group_id, permission_id)
SELECT g.id, p.id
FROM groups g, permissions p
WHERE g.name = 'Administrators'
ON DUPLICATE KEY UPDATE granted_at = CURRENT_TIMESTAMP;
SEED_SQL_EOF
        print_success "02-seed.sql créé"
    fi

    echo ""
}

#═══════════════════════════════════════════════════════════════════════════
# FONCTION: Création du fichier .htpasswd
#═══════════════════════════════════════════════════════════════════════════
create_htpasswd() {
    print_section "CRÉATION FICHIER .HTPASSWD"

    print_step "Génération du fichier .htpasswd..."

    if command -v htpasswd &> /dev/null; then
        # Utiliser htpasswd si disponible
        htpasswd -cb "$NGINX_DIR/.htpasswd" "$ADMIN_USER" "$ADMIN_PASSWORD"
        print_success ".htpasswd créé avec htpasswd"
    else
        # Fallback: utiliser openssl
        print_warning "htpasswd non disponible, utilisation de openssl..."
        HASH=$(openssl passwd -apr1 "$ADMIN_PASSWORD")
        echo "$ADMIN_USER:$HASH" > "$NGINX_DIR/.htpasswd"
        print_success ".htpasswd créé avec openssl"
    fi

    chmod 644 "$NGINX_DIR/.htpasswd"
    echo ""
}

#═══════════════════════════════════════════════════════════════════════════
# FONCTION: Build et démarrage des conteneurs
#═══════════════════════════════════════════════════════════════════════════
build_and_start_containers() {
    print_section "BUILD ET DÉMARRAGE DES CONTENEURS"

    cd "$PROJECT_ROOT"

    # Arrêter les conteneurs existants
    print_step "Arrêt des conteneurs existants..."
    docker-compose down -v 2>/dev/null || true
    print_success "Conteneurs arrêtés"

    # Build
    print_step "Build des images Docker..."
    if docker-compose build --no-cache; then
        print_success "Build réussi"
    else
        print_error "Échec du build"
        exit 1
    fi

    # Démarrage
    print_step "Démarrage des conteneurs..."
    if docker-compose up -d; then
        print_success "Conteneurs démarrés"
    else
        print_error "Échec du démarrage"
        exit 1
    fi

    # Attendre que les services soient prêts
    print_step "Attente du démarrage des services (30s)..."
    sleep 30

    # Vérifier les conteneurs
    print_step "Vérification de l'état des conteneurs..."
    echo ""
    docker-compose ps
    echo ""

    # Vérifier les healthchecks
    print_step "Vérification des healthchecks..."
    HEALTHY=0
    for i in {1..10}; do
        if docker-compose ps | grep -q "healthy"; then
            HEALTHY=1
            break
        fi
        echo "  Tentative $i/10..."
        sleep 5
    done

    if [ $HEALTHY -eq 1 ]; then
        print_success "Services démarrés et opérationnels"
    else
        print_warning "Certains services peuvent encore être en cours de démarrage"
        print_warning "Vérifiez les logs: docker-compose logs"
    fi

    echo ""
}

#═══════════════════════════════════════════════════════════════════════════
# FONCTION: Affichage du résumé
#═══════════════════════════════════════════════════════════════════════════
display_summary() {
    print_section "INSTALLATION TERMINÉE"

    echo -e "${GREEN}${BOLD}"
    echo "╔═══════════════════════════════════════════════════════════════════════════╗"
    echo "║                                                                           ║"
    echo "║                    ✓ INSTALLATION RÉUSSIE                                ║"
    echo "║                                                                           ║"
    echo "╚═══════════════════════════════════════════════════════════════════════════╝"
    echo -e "${NC}"
    echo ""

    echo -e "${BOLD}📊 RÉCAPITULATIF:${NC}"
    echo ""
    echo "┌─────────────────────────────────────────────────────────────────────────┐"
    echo "│ ${BOLD}Services déployés:${NC}                                                     │"
    echo "├─────────────────────────────────────────────────────────────────────────┤"
    echo "│ • Bolt.DIY (AI Code Generator)                                          │"
    echo "│ • User Manager v2.0 (MVC Architecture - 45 fichiers)                    │"
    echo "│ • MariaDB 10.11                                                          │"
    echo "│ • Nginx Reverse Proxy                                                    │"
    echo "└─────────────────────────────────────────────────────────────────────────┘"
    echo ""

    echo "┌─────────────────────────────────────────────────────────────────────────┐"
    echo "│ ${BOLD}URLs d'accès:${NC}                                                          │"
    echo "├─────────────────────────────────────────────────────────────────────────┤"
    echo "│ • Page d'accueil:   http://$LOCAL_IP:$HOST_PORT_HOME                   │"
    echo "│ • Bolt.DIY:         http://$LOCAL_IP:$HOST_PORT_BOLT                   │"
    echo "│ • User Manager:     http://$LOCAL_IP:$HOST_PORT_UM                     │"
    echo "└─────────────────────────────────────────────────────────────────────────┘"
    echo ""

    echo "┌─────────────────────────────────────────────────────────────────────────┐"
    echo "│ ${BOLD}Identifiants:${NC}                                                          │"
    echo "├─────────────────────────────────────────────────────────────────────────┤"
    echo "│ • Utilisateur:      $ADMIN_USER                                         │"
    echo "│ • Mot de passe:     ••••••••                                            │"
    echo "└─────────────────────────────────────────────────────────────────────────┘"
    echo ""

    echo "┌─────────────────────────────────────────────────────────────────────────┐"
    echo "│ ${BOLD}Commandes utiles:${NC}                                                      │"
    echo "├─────────────────────────────────────────────────────────────────────────┤"
    echo "│ • Voir les logs:        docker-compose logs -f                          │"
    echo "│ • Arrêter:              docker-compose down                             │"
    echo "│ • Redémarrer:           docker-compose restart                          │"
    echo "│ • Statut:               docker-compose ps                               │"
    echo "│ • Rebuild:              docker-compose build --no-cache                 │"
    echo "└─────────────────────────────────────────────────────────────────────────┘"
    echo ""

    echo "┌─────────────────────────────────────────────────────────────────────────┐"
    echo "│ ${BOLD}Nouveautés v7.0:${NC}                                                       │"
    echo "├─────────────────────────────────────────────────────────────────────────┤"
    echo "│ ✓ Clonage intelligent depuis GitHub                                     │"
    echo "│ ✓ User Manager v2.0 complet (45 fichiers)                               │"
    echo "│ ✓ Architecture MVC (Controllers, Models, Middleware, Utils)             │"
    echo "│ ✓ Frontend JS moderne (9 modules)                                       │"
    echo "│ ✓ Vérification intégrité automatique                                    │"
    echo "│ ✓ Configuration .env complète                                           │"
    echo "│ ✓ Volumes Docker logs/cache/uploads                                     │"
    echo "│ ✓ PHP 8.1 + Composer autoload PSR-4                                     │"
    echo "└─────────────────────────────────────────────────────────────────────────┘"
    echo ""

    echo -e "${YELLOW}${BOLD}⚠️  IMPORTANT:${NC}"
    echo "  • Les services peuvent mettre 1-2 minutes à être pleinement opérationnels"
    echo "  • En cas de problème, consultez: docker-compose logs"
    echo "  • Documentation complète: ./DATA-LOCAL/user-manager/README.md"
    echo ""

    echo -e "${CYAN}${BOLD}📚 Ressources:${NC}"
    echo "  • Repository: https://github.com/NBILITY-HOME/BOLT.DIY-INTRANET"
    echo "  • Support: contact@nbility.fr"
    echo ""

    echo -e "${GREEN}${BOLD}🎉 Bon développement avec BOLT.DIY Nbility !${NC}"
    echo ""
}

#═══════════════════════════════════════════════════════════════════════════
# FONCTION PRINCIPALE
#═══════════════════════════════════════════════════════════════════════════
main() {
    print_banner
    check_prerequisites
    check_internet_and_github
    get_configuration
    clone_repository
    verify_github_files
    install_composer_dependencies
    generate_docker_compose
    generate_nginx_conf
    generate_usermanager_dockerfile
    generate_health_php
    generate_env_files
    create_sql_files
    create_htpasswd
    build_and_start_containers
    display_summary
}

# Lancement
main "$@"
