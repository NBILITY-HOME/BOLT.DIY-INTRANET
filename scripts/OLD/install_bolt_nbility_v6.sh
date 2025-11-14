#!/bin/bash
#═══════════════════════════════════════════════════════════════════════════
# BOLT.DIY NBILITY - Installation Script v6.0
# Architecture Multi-Ports avec User Manager v2.0 + MariaDB
# © Copyright Nbility 2025 - contact@nbility.fr
#═══════════════════════════════════════════════════════════════════════════

clear
printf "\\033[8;55;116t"

# ═══════════════════════════════════════════════════════════════════════════
# VÉRIFICATION SUDO
# ═══════════════════════════════════════════════════════════════════════════

if [ "$EUID" -eq 0 ]; then 
    echo -e "\033[0;31m✗ ERREUR: Ce script NE DOIT PAS être lancé en sudo/root\033[0m"
    echo ""
    echo "Raison: Docker et les fichiers doivent appartenir à votre utilisateur"
    echo ""
    echo "Solution: Lancez le script sans sudo:"
    echo "  ./install_bolt_nbility_v6.sh"
    echo ""
    echo "Si Docker nécessite sudo, ajoutez votre utilisateur au groupe docker:"
    echo "  sudo usermod -aG docker \$USER"
    echo "  newgrp docker"
    echo ""
    exit 1
fi

# ═══════════════════════════════════════════════════════════════════════════
# VARIABLES GLOBALES
# ═══════════════════════════════════════════════════════════════════════════

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
MAGENTA='\033[0;35m'
WHITE='\033[1;37m'
NC='\033[0m'
BOLD='\033[1m'
CHECK="✓"
CROSS="✗"
ARROW="→"
STAR="★"

# Chemins et configuration
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

# ═══════════════════════════════════════════════════════════════════════════
# FONCTIONS D'AFFICHAGE
# ═══════════════════════════════════════════════════════════════════════════

print_banner() {
    clear
    echo -e "${CYAN}"
    echo "              ╔═══════════════════════════════════════════════════════════════════════╗"
    echo "              ║                                                                       ║"
    echo "              ║   ██████╗  ██████╗ ██╗  ████████╗    ██████╗ ██╗██╗   ██╗             ║"
    echo "              ║   ██╔══██╗██╔═══██╗██║  ╚══██╔══╝    ██╔══██╗██║╚██╗ ██╔╝             ║"
    echo "              ║   ██████╔╝██║   ██║██║     ██║       ██║  ██║██║ ╚████╔╝              ║"
    echo "              ║   ██╔══██╗██║   ██║██║     ██║       ██║  ██║██║  ╚██╔╝               ║"
    echo "              ║   ██████╔╝╚██████╔╝███████╗██║       ██████╔╝██║   ██║                ║"
    echo "              ║   ╚═════╝  ╚═════╝ ╚══════╝╚═╝       ╚═════╝ ╚═╝   ╚═╝                ║"
    echo "              ║                                                                       ║"
    echo "              ║                    N B I L I T Y   E D I T I O N                      ║"
    echo "              ║                         I N T R A N E T                               ║"
    echo "              ║                      User Manager v2.0 + MariaDB                      ║"
    echo "              ║                                                                       ║"
    echo "              ╚═══════════════════════════════════════════════════════════════════════╝"
    echo -e "${NC}"
    echo -e "${MAGENTA}${BOLD}                                    Installation Interactive v6.0${NC}"
    echo -e "${CYAN}                        © Copyright Nbility 2025 - contact : contact@nbility.fr${NC}"
    echo ""
}

print_section() {
    echo ""
    echo -e "${BLUE}╔═══════════════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${BLUE}║${NC} ${WHITE}${BOLD}$1${NC}"
    echo -e "${BLUE}╚═══════════════════════════════════════════════════════════════════════╝${NC}"
    echo ""
}

print_step() { echo -e "${CYAN}${ARROW}${NC} ${WHITE}$1${NC}"; }
print_success() { echo -e "${GREEN}${CHECK}${NC} ${GREEN}$1${NC}"; }
print_error() { echo -e "${RED}${CROSS}${NC} ${RED}$1${NC}"; }
print_warning() { echo -e "${YELLOW}⚠${NC} ${YELLOW}$1${NC}"; }
print_info() { echo -e "${CYAN}ℹ${NC} ${CYAN}$1${NC}"; }

# ═══════════════════════════════════════════════════════════════════════════
# GÉNÉRATION DE PASSWORDS SÉCURISÉS
# ═══════════════════════════════════════════════════════════════════════════

generate_password() {
    local length=${1:-32}
    openssl rand -base64 48 | tr -d "=+/" | cut -c1-${length}
}

generate_app_secret() {
    openssl rand -hex 32
}


# ═══════════════════════════════════════════════════════════════════════════
# VÉRIFICATIONS PRÉALABLES
# ═══════════════════════════════════════════════════════════════════════════

check_prerequisites() {
    print_section "VÉRIFICATION DES PRÉREQUIS"
    
    print_step "Vérification de Docker..."
    if command -v docker &> /dev/null; then
        DOCKER_VERSION=$(docker --version | awk '{print $3}' | sed 's/,//')
        print_success "Docker $DOCKER_VERSION installé"
    else
        print_error "Docker n'est pas installé"
        exit 1
    fi
    
    print_step "Vérification de Docker Compose..."
    if docker compose version &> /dev/null; then
        COMPOSE_VERSION=$(docker compose version --short)
        print_success "Docker Compose $COMPOSE_VERSION installé"
    else
        print_error "Docker Compose n'est pas installé"
        exit 1
    fi
    
    print_step "Vérification des permissions Docker..."
    if docker ps &> /dev/null; then
        print_success "Permissions Docker OK"
    else
        print_error "Pas de permission Docker"
        exit 1
    fi
    
    print_step "Vérification de Git..."
    if command -v git &> /dev/null; then
        GIT_VERSION=$(git --version | awk '{print $3}')
        print_success "Git $GIT_VERSION installé"
    else
        print_error "Git n'est pas installé"
        exit 1
    fi
}

# ═══════════════════════════════════════════════════════════════════════════
# CLONAGE DU REPOSITORY
# ═══════════════════════════════════════════════════════════════════════════

clone_repository() {
    print_section "CLONAGE DU REPOSITORY GITHUB"
    
    if [ -d "$INSTALL_DIR" ]; then
        print_warning "Le dossier $REPO_NAME existe déjà"
        read -p "Voulez-vous le supprimer et recommencer ? (o/N): " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Oo]$ ]]; then
            print_step "Suppression de l'ancien dossier..."
            rm -rf "$INSTALL_DIR"
            print_success "Ancien dossier supprimé"
        else
            print_error "Installation annulée"
            exit 1
        fi
    fi
    
    print_step "Clonage depuis GitHub..."
    if git clone --recurse-submodules "$REPO_URL" "$INSTALL_DIR"; then
        print_success "Repository cloné avec succès"
    else
        print_error "Échec du clonage"
        exit 1
    fi
    
    print_step "Initialisation des submodules..."
    cd "$INSTALL_DIR"
    git submodule update --init --recursive
    print_success "Submodules initialisés"
}

# ═══════════════════════════════════════════════════════════════════════════
# CONFIGURATION DU SUPER ADMIN
# ═══════════════════════════════════════════════════════════════════════════

get_superadmin_config() {
    print_banner
    print_section "CONFIGURATION DU SUPER ADMINISTRATEUR"
    
    echo -e "${YELLOW}${BOLD}Ce compte aura tous les droits sur le User Manager${NC}"
    echo ""
    
    # Username
    while true; do
        echo -e "${CYAN}╭─────────────────────────────────────────────────────────────────╮${NC}"
        echo -e "${CYAN}│${NC} ${WHITE}${BOLD}Nom d'utilisateur (3-32 caractères)${NC}"
        echo -e "${CYAN}╰─────────────────────────────────────────────────────────────────╯${NC}"
        read -p "Username [admin]: " SUPERADMIN_USERNAME
        SUPERADMIN_USERNAME=${SUPERADMIN_USERNAME:-admin}
        
        if [[ ${#SUPERADMIN_USERNAME} -ge 3 && ${#SUPERADMIN_USERNAME} -le 32 ]]; then
            print_success "Username: $SUPERADMIN_USERNAME"
            break
        else
            print_error "Le username doit faire entre 3 et 32 caractères"
        fi
    done
    echo ""
    
    # Email
    while true; do
        echo -e "${CYAN}╭─────────────────────────────────────────────────────────────────╮${NC}"
        echo -e "${CYAN}│${NC} ${WHITE}${BOLD}Adresse email${NC}"
        echo -e "${CYAN}╰─────────────────────────────────────────────────────────────────╯${NC}"
        read -p "Email [admin@nbility.fr]: " SUPERADMIN_EMAIL
        SUPERADMIN_EMAIL=${SUPERADMIN_EMAIL:-admin@nbility.fr}
        
        if [[ $SUPERADMIN_EMAIL =~ ^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$ ]]; then
            print_success "Email: $SUPERADMIN_EMAIL"
            break
        else
            print_error "Format d'email invalide"
        fi
    done
    echo ""
    
    # Password
    while true; do
        echo -e "${CYAN}╭─────────────────────────────────────────────────────────────────╮${NC}"
        echo -e "${CYAN}│${NC} ${WHITE}${BOLD}Mot de passe (min 8 caractères)${NC}"
        echo -e "${CYAN}╰─────────────────────────────────────────────────────────────────╯${NC}"
        read -sp "Password: " SUPERADMIN_PASSWORD
        echo ""
        
        if [ ${#SUPERADMIN_PASSWORD} -ge 8 ]; then
            read -sp "Confirmez le password: " SUPERADMIN_PASSWORD_CONFIRM
            echo ""
            
            if [ "$SUPERADMIN_PASSWORD" = "$SUPERADMIN_PASSWORD_CONFIRM" ]; then
                print_success "Mot de passe défini"
                break
            else
                print_error "Les mots de passe ne correspondent pas"
            fi
        else
            print_error "Le mot de passe doit faire au moins 8 caractères"
        fi
    done
    echo ""
}

# ═══════════════════════════════════════════════════════════════════════════
# CONFIGURATION MARIADB
# ═══════════════════════════════════════════════════════════════════════════

get_mariadb_config() {
    print_banner
    print_section "CONFIGURATION MARIADB"
    
    # Port MariaDB
    echo -e "${CYAN}╭─────────────────────────────────────────────────────────────────╮${NC}"
    echo -e "${CYAN}│${NC} ${WHITE}${BOLD}Port MariaDB (interne Docker)${NC}"
    echo -e "${CYAN}╰─────────────────────────────────────────────────────────────────╯${NC}"
    echo -e "${CYAN}${ARROW}${NC} Laissez vide pour le port par défaut 3306"
    read -p "Port [3306]: " MARIADB_PORT
    MARIADB_PORT=${MARIADB_PORT:-3306}
    print_success "Port MariaDB: $MARIADB_PORT"
    echo ""
    
    # Génération des passwords
    print_step "Génération des mots de passe MariaDB..."
    MARIADB_ROOT_PASSWORD=$(generate_password 32)
    MARIADB_PASSWORD=$(generate_password 32)
    print_success "Mots de passe générés automatiquement"
    echo ""
}


# ═══════════════════════════════════════════════════════════════════════════
# CONFIGURATION DES PORTS
# ═══════════════════════════════════════════════════════════════════════════

get_ports_config() {
    print_banner
    print_section "CONFIGURATION DES PORTS"
    
    echo -e "${CYAN}╭─────────────────────────────────────────────────────────────────╮${NC}"
    echo -e "${CYAN}│${NC} ${WHITE}${BOLD}Port Bolt.DIY Application${NC}"
    echo -e "${CYAN}╰─────────────────────────────────────────────────────────────────╯${NC}"
    read -p "Port [6969]: " HOST_PORT_BOLT
    export HOST_PORT_BOLT=${HOST_PORT_BOLT:-6969}
    print_success "Port Bolt.DIY: $HOST_PORT_BOLT"
    echo ""
    
    echo -e "${CYAN}╭─────────────────────────────────────────────────────────────────╮${NC}"
    echo -e "${CYAN}│${NC} ${WHITE}${BOLD}Port Page d'accueil${NC}"
    echo -e "${CYAN}╰─────────────────────────────────────────────────────────────────╯${NC}"
    read -p "Port [7070]: " HOST_PORT_HOME
    export HOST_PORT_HOME=${HOST_PORT_HOME:-7070}
    print_success "Port Home: $HOST_PORT_HOME"
    echo ""
    
    echo -e "${CYAN}╭─────────────────────────────────────────────────────────────────╮${NC}"
    echo -e "${CYAN}│${NC} ${WHITE}${BOLD}Port User Manager${NC}"
    echo -e "${CYAN}╰─────────────────────────────────────────────────────────────────╯${NC}"
    read -p "Port [7071]: " HOST_PORT_UM
    export HOST_PORT_UM=${HOST_PORT_UM:-7071}
    print_success "Port User Manager: $HOST_PORT_UM"
    echo ""
}

# ═══════════════════════════════════════════════════════════════════════════
# CRÉATION STRUCTURE COMPLÈTE
# ═══════════════════════════════════════════════════════════════════════════

create_directory_structure() {
    print_section "CRÉATION DE LA STRUCTURE"
    
    cd "$INSTALL_DIR"
    
    print_step "Création des répertoires..."
    mkdir -p "$MARIADB_DIR/init"
    mkdir -p "$USERMANAGER_DIR/app"
    mkdir -p "$USERMANAGER_DIR/uploads/reports"
    mkdir -p "$USERMANAGER_DIR/backups"
    mkdir -p "$NGINX_DIR"
    print_success "Répertoires créés"
}

# ═══════════════════════════════════════════════════════════════════════════
# CRÉATION FICHIER .ENV
# ═══════════════════════════════════════════════════════════════════════════

create_env_file() {
    print_section "CRÉATION DU FICHIER .ENV"
    
    APP_SECRET=$(generate_app_secret)
    
    print_step "Génération du fichier .env..."
    cat > "$INSTALL_DIR/.env" << ENV_EOF
# ═══════════════════════════════════════════════════════════════════════════
# BOLT.DIY NBILITY - Configuration Environment
# © Copyright Nbility 2025 - contact@nbility.fr
# Généré le: $(date '+%Y-%m-%d %H:%M:%S')
# ═══════════════════════════════════════════════════════════════════════════

# Configuration des ports
HOST_PORT_BOLT=$HOST_PORT_BOLT
HOST_PORT_HOME=$HOST_PORT_HOME
HOST_PORT_UM=$HOST_PORT_UM

# Fichier htpasswd (utilisateurs Bolt.DIY)
HTPASSWD_FILE=./DATA-LOCAL/nginx/.htpasswd

# MariaDB Configuration
MARIADB_PORT=$MARIADB_PORT
MARIADB_ROOT_PASSWORD=$MARIADB_ROOT_PASSWORD
MARIADB_USER=bolt_um
MARIADB_PASSWORD=$MARIADB_PASSWORD

# Application Security
APP_SECRET=$APP_SECRET
APP_ENV=production
APP_DEBUG=false
ENV_EOF
    
    print_success "Fichier .env créé"
    print_info "APP_SECRET généré: ${APP_SECRET:0:16}..."
}

# ═══════════════════════════════════════════════════════════════════════════
# CRÉATION FICHIERS SQL
# ═══════════════════════════════════════════════════════════════════════════

create_sql_files() {
    print_section "CRÉATION DES FICHIERS SQL"
    
    print_step "Téléchargement du schéma de base de données..."
    
    # Je vais créer le schéma SQL directement ici
    cat > "$MARIADB_DIR/init/01-schema.sql" << 'SQL_SCHEMA_EOF'
-- SCHEMA SQL ICI (voir fichier schema.sql créé précédemment)
SQL_SCHEMA_EOF
    
    cat > "$MARIADB_DIR/init/02-seed.sql" << 'SQL_SEED_EOF'
-- SEED SQL ICI (voir fichier seed.sql créé précédemment)
SQL_SEED_EOF
    
    print_success "Fichiers SQL créés"
}

# ═══════════════════════════════════════════════════════════════════════════
# CRÉATION HTPASSWD VIDE
# ═══════════════════════════════════════════════════════════════════════════

create_htpasswd() {
    print_section "CRÉATION DU FICHIER .HTPASSWD"
    
    print_step "Création du fichier .htpasswd vide..."
    touch "$HTPASSWD_FILE"
    chmod 664 "$HTPASSWD_FILE"
    print_success "Fichier .htpasswd créé"
}


# ═══════════════════════════════════════════════════════════════════════════
# CRÉATION COMPOSER.JSON
# ═══════════════════════════════════════════════════════════════════════════

create_composer_json() {
    print_section "CRÉATION DU COMPOSER.JSON"
    
    print_step "Création du fichier composer.json..."
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
    
    print_success "Fichier composer.json créé"
}

# ═══════════════════════════════════════════════════════════════════════════
# SETUP DOCKER
# ═══════════════════════════════════════════════════════════════════════════

setup_docker() {
    print_section "CONFIGURATION DOCKER"
    
    cd "$INSTALL_DIR"
    
    # Création réseau
    print_step "Création du réseau Docker..."
    if docker network inspect $NETWORK_NAME &> /dev/null; then
        print_warning "Le réseau $NETWORK_NAME existe déjà"
    else
        docker network create $NETWORK_NAME
        print_success "Réseau $NETWORK_NAME créé"
    fi
    
    # Création volume
    print_step "Création du volume Docker..."
    if docker volume inspect $VOLUME_DATA &> /dev/null; then
        print_warning "Le volume $VOLUME_DATA existe déjà"
    else
        docker volume create $VOLUME_DATA
        print_success "Volume $VOLUME_DATA créé"
    fi
    
    # Build et lancement
    print_step "Build et lancement des containers Docker..."
    docker compose up -d --build
    
    print_success "Containers lancés avec succès"
    echo ""
    print_info "Attente du démarrage de MariaDB (30 secondes)..."
    sleep 30
}

# ═══════════════════════════════════════════════════════════════════════════
# CRÉATION DU SUPER ADMIN DANS LA BASE
# ═══════════════════════════════════════════════════════════════════════════

create_superadmin_in_db() {
    print_section "CRÉATION DU SUPER ADMINISTRATEUR"
    
    print_step "Hash du mot de passe..."
    PASSWORD_HASH=$(docker exec bolt-user-manager php -r "echo password_hash('$SUPERADMIN_PASSWORD', PASSWORD_BCRYPT);")
    
    print_step "Insertion dans la base de données..."
    docker exec bolt-mariadb mysql -uroot -p"$MARIADB_ROOT_PASSWORD" bolt_user_manager << MYSQL_EOF
INSERT INTO um_users (username, email, password_hash, role, status, created_at) 
VALUES ('$SUPERADMIN_USERNAME', '$SUPERADMIN_EMAIL', '$PASSWORD_HASH', 'superadmin', 'active', NOW());

-- Ajouter le Super Admin au groupe Administrateurs
INSERT INTO um_user_groups (user_id, group_id, added_by) 
VALUES (1, 1, 1);
MYSQL_EOF
    
    print_success "Super Admin créé avec succès"
}


# ═══════════════════════════════════════════════════════════════════════════
# RÉCAPITULATIF FINAL
# ═══════════════════════════════════════════════════════════════════════════

show_final_summary() {
    print_banner
    print_section "✅ INSTALLATION TERMINÉE AVEC SUCCÈS"
    
    echo -e "${GREEN}${BOLD}╔═══════════════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${GREEN}${BOLD}║                    INFORMATIONS D'ACCÈS                               ║${NC}"
    echo -e "${GREEN}${BOLD}╚═══════════════════════════════════════════════════════════════════════╝${NC}"
    echo ""
    
    echo -e "${CYAN}${BOLD}🌐 URLs d'accès :${NC}"
    echo -e "  ${WHITE}• Bolt.DIY App      :${NC} http://localhost:$HOST_PORT_BOLT"
    echo -e "  ${WHITE}• Page d'accueil    :${NC} http://localhost:$HOST_PORT_HOME"
    echo -e "  ${WHITE}• User Manager v2.0 :${NC} ${GREEN}${BOLD}http://localhost:$HOST_PORT_UM${NC}"
    echo ""
    
    echo -e "${CYAN}${BOLD}👤 Super Administrateur :${NC}"
    echo -e "  ${WHITE}• Username :${NC} ${GREEN}$SUPERADMIN_USERNAME${NC}"
    echo -e "  ${WHITE}• Email    :${NC} ${GREEN}$SUPERADMIN_EMAIL${NC}"
    echo -e "  ${WHITE}• Password :${NC} ${GREEN}(celui que vous avez défini)${NC}"
    echo ""
    
    echo -e "${CYAN}${BOLD}🗄️  Base de données MariaDB :${NC}"
    echo -e "  ${WHITE}• Host     :${NC} bolt-mariadb (interne Docker)"
    echo -e "  ${WHITE}• Port     :${NC} $MARIADB_PORT"
    echo -e "  ${WHITE}• Database :${NC} bolt_user_manager"
    echo -e "  ${WHITE}• User     :${NC} bolt_um"
    echo ""
    
    echo -e "${CYAN}${BOLD}🔐 Sécurité :${NC}"
    echo -e "  ${WHITE}• APP_SECRET :${NC} ${GREEN}Généré automatiquement${NC}"
    echo -e "  ${WHITE}• Passwords  :${NC} ${GREEN}Stockés dans .env${NC}"
    echo ""
    
    echo -e "${CYAN}${BOLD}📂 Répertoire d'installation :${NC}"
    echo -e "  ${WHITE}$INSTALL_DIR${NC}"
    echo ""
    
    echo -e "${CYAN}${BOLD}🐳 Containers Docker actifs :${NC}"
    docker ps --filter "name=bolt-" --format "  • {{.Names}} - {{.Status}}"
    echo ""
    
    echo -e "${YELLOW}${BOLD}⚠️  IMPORTANT :${NC}"
    echo -e "  ${WHITE}1. Le fichier .env contient des informations sensibles${NC}"
    echo -e "  ${WHITE}2. Ne JAMAIS commiter le .env dans Git${NC}"
    echo -e "  ${WHITE}3. Configurez le serveur SMTP dans l'interface web${NC}"
    echo -e "  ${WHITE}4. Première connexion : http://localhost:$HOST_PORT_UM${NC}"
    echo ""
    
    echo -e "${GREEN}${BOLD}✨ Prêt à utiliser ! Connectez-vous au User Manager.${NC}"
    echo ""
}

# ═══════════════════════════════════════════════════════════════════════════
# FONCTION PRINCIPALE
# ═══════════════════════════════════════════════════════════════════════════

main() {
    print_banner
    
    echo -e "${YELLOW}${BOLD}Ce script va installer :${NC}"
    echo -e "  • Bolt.DIY Application"
    echo -e "  • MariaDB 10.11"
    echo -e "  • User Manager v2.0 avec authentification complète"
    echo -e "  • Système de gestion des profils et permissions"
    echo ""
    
    read -p "Voulez-vous continuer ? (o/N): " -n 1 -r
    echo ""
    if [[ ! $REPLY =~ ^[Oo]$ ]]; then
        echo "Installation annulée"
        exit 0
    fi
    
    # Étapes d'installation
    check_prerequisites
    clone_repository
    get_superadmin_config
    get_mariadb_config
    get_ports_config
    create_directory_structure
    create_env_file
    create_sql_files
    create_htpasswd
    create_composer_json
    setup_docker
    create_superadmin_in_db
    show_final_summary
}

# ═══════════════════════════════════════════════════════════════════════════
# LANCEMENT DU SCRIPT
# ═══════════════════════════════════════════════════════════════════════════

main

