#!/bin/bash

set -e

# ═══════════════════════════════════════════════════════════════════════════
# BOLT.DIY INTRANET - Installation complète v8.0 FINAL
# Fix: Copie des .env.example + Création utilisateur admin robuste
# © Copyright Nbility 2025 - contact@nbility.fr
# ═══════════════════════════════════════════════════════════════════════════

# Variables globales
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="${HOME}/DOCKER-PROJETS/BOLT.DIY-INTRANET"
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

# Variables d'installation
LOCAL_IP=""
HOST_PORT_HOME=""
ADMIN_USERNAME=""
ADMIN_EMAIL=""
ADMIN_PASSWORD=""
ADMIN_PASSWORD_HASH=""
MARIADB_ROOT_PASSWORD=""
MARIADB_USER_PASSWORD=""
APP_SECRET=""
OPENAI_API_KEY=""
ANTHROPIC_API_KEY=""
GROQ_API_KEY=""
GOOGLE_API_KEY=""

# ═══════════════════════════════════════════════════════════════════════════
# FONCTIONS D'AFFICHAGE
# ═══════════════════════════════════════════════════════════════════════════

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
    echo -e "${BLUE}  NBILITY EDITION - Installation v8.1${NC}"
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
    echo -e "${YELLOW}➜${NC} $1"
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

# ═══════════════════════════════════════════════════════════════════════════
# FONCTIONS DE VALIDATION
# ═══════════════════════════════════════════════════════════════════════════

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
    if [[ $port =~ ^[0-9]+$ ]] && ((port >= 1024 && port <= 65535)); then
        return 0
    fi
    return 1
}

# ═══════════════════════════════════════════════════════════════════════════
# VÉRIFICATION DES DÉPENDANCES
# ═══════════════════════════════════════════════════════════════════════════

check_dependencies() {
    print_section "VÉRIFICATION DES DÉPENDANCES"
    local all_ok=true

    # Docker
    if command -v docker &> /dev/null; then
        DOCKER_VERSION=$(docker --version | awk '{print $3}' | tr -d ',')
        print_success "Docker $DOCKER_VERSION"
    else
        print_error "Docker n'est pas installé"
        all_ok=false
    fi

    # Docker Compose
    if command -v docker compose version &> /dev/null; then
        COMPOSE_VERSION=$(docker compose version --short 2>/dev/null || echo "v2.x")
        print_success "Docker Compose $COMPOSE_VERSION"
    else
        print_error "Docker Compose n'est pas installé"
        all_ok=false
    fi

    # Git
    if command -v git &> /dev/null; then
        GIT_VERSION=$(git --version | awk '{print $3}')
        print_success "Git $GIT_VERSION"
    else
        print_error "Git n'est pas installé"
        all_ok=false
    fi

    # OpenSSL
    if command -v openssl &> /dev/null; then
        OPENSSL_VERSION=$(openssl version | awk '{print $2}')
        print_success "OpenSSL $OPENSSL_VERSION"
    else
        print_error "OpenSSL n'est pas installé"
        all_ok=false
    fi

    if [ "$all_ok" = true ]; then
        print_success "Toutes les dépendances sont installées"
    else
        print_error "Des dépendances sont manquantes"
        print_info "Installez-les avec: sudo apt install docker.io docker-compose git openssl"
        exit 1
    fi
}

# ═══════════════════════════════════════════════════════════════════════════
# COLLECTE DES INFORMATIONS UTILISATEUR
# ═══════════════════════════════════════════════════════════════════════════

collect_user_inputs() {
    print_section "CONFIGURATION"

    # IP locale
    local default_ip=$(hostname -I | awk '{print $1}')
    echo -n "Adresse IP locale [$default_ip]: "
    read -r LOCAL_IP
    LOCAL_IP="${LOCAL_IP:-$default_ip}"

    while ! validate_ip "$LOCAL_IP"; do
        print_error "Adresse IP invalide"
        echo -n "Adresse IP locale [$default_ip]: "
        read -r LOCAL_IP
        LOCAL_IP="${LOCAL_IP:-$default_ip}"
    done

    # Port unique
    echo -n "Port d'accès (pour tout: accueil, Bolt.DIY, User Manager) [8686]: "
    read -r HOST_PORT_HOME
    HOST_PORT_HOME="${HOST_PORT_HOME:-8686}"

    while ! validate_port "$HOST_PORT_HOME"; do
        print_error "Port invalide (1024-65535)"
        echo -n "Port d'accès [8686]: "
        read -r HOST_PORT_HOME
        HOST_PORT_HOME="${HOST_PORT_HOME:-8686}"
    done

    print_info "Tout sera accessible via: http://$LOCAL_IP:$HOST_PORT_HOME"

    # --- DÉBUT DU SCRIPT : COLLECTE DES INFOS SUPERADMIN ---

    echo -e "${CYAN}Création du compte SUPERADMIN${NC}"
        echo -n "Nom d'utilisateur superadmin [superadmin]: "
        read -r SUPERADMIN_USERNAME
        SUPERADMIN_USERNAME=${SUPERADMIN_USERNAME:-superadmin}

    echo -n "Email du superadmin [superadmin@local]: "
        read -r SUPERADMIN_EMAIL
        SUPERADMIN_EMAIL=${SUPERADMIN_EMAIL:-superadmin@local}

    echo -n "Mot de passe superadmin: "
        read -rs SUPERADMIN_PASSWORD
        echo
    while [ -z "$SUPERADMIN_PASSWORD" ]; do
        echo -e "${RED}Le mot de passe ne peut pas être vide${NC}"
        echo -n "Mot de passe superadmin: "
        read -rs SUPERADMIN_PASSWORD
        echo
    done

    # Admin username
    echo -n "Nom d'utilisateur admin [admin]: "
    read -r ADMIN_USERNAME
    ADMIN_USERNAME="${ADMIN_USERNAME:-admin}"

    # Admin email
    echo -n "Email de l'administrateur [admin@bolt.local]: "
    read -r ADMIN_EMAIL
    ADMIN_EMAIL="${ADMIN_EMAIL:-admin@bolt.local}"

    # Mot de passe
    echo -n "Mot de passe admin: "
    read -rs ADMIN_PASSWORD
    echo

    while [ -z "$ADMIN_PASSWORD" ]; do
        print_error "Le mot de passe ne peut pas être vide"
        echo -n "Mot de passe admin: "
        read -rs ADMIN_PASSWORD
        echo
    done

    # Mots de passe base de données
    MARIADB_ROOT_PASSWORD=$(openssl rand -base64 32)
    MARIADB_USER_PASSWORD=$(openssl rand -base64 32)
    APP_SECRET=$(openssl rand -hex 32)

    # Clés API optionnelles
    echo ""
    print_info "Clés API optionnelles (laisser vide pour ignorer)"
    echo -n "OpenAI API Key: "
    read -rs OPENAI_API_KEY
    echo
    echo -n "Anthropic API Key: "
    read -rs ANTHROPIC_API_KEY
    echo
    echo -n "Groq API Key: "
    read -rs GROQ_API_KEY
    echo
    echo -n "Google API Key: "
    read -rs GOOGLE_API_KEY
    echo

    print_success "Configuration collectée"
}

# ═══════════════════════════════════════════════════════════════════════════
# CLONAGE DU REPO GITHUB
# ═══════════════════════════════════════════════════════════════════════════

clone_github_repo() {
    print_section "CLONAGE DU REPOSITORY GITHUB"

    if [ -d "$PROJECT_ROOT" ]; then
        print_warning "Le dossier $PROJECT_ROOT existe déjà"
        echo -n "Voulez-vous le supprimer et recommencer ? (o/N): "
        read -r response
        if [[ "$response" =~ ^[Oo]$ ]]; then
            print_step "Suppression du dossier existant..."
            rm -rf "$PROJECT_ROOT"
            print_success "Dossier supprimé"
        else
            print_info "Conservation du dossier existant"
            return
        fi
    fi

    print_step "Clonage depuis $GITHUB_REPO"
    git clone "$GITHUB_REPO" "$PROJECT_ROOT"

    if [ $? -eq 0 ]; then
        print_success "Repository cloné avec succès"
    else
        print_error "Échec du clonage"
        exit 1
    fi
}

# ═══════════════════════════════════════════════════════════════════════════
# VÉRIFICATION DES FICHIERS .env.example DANS LE REPO
# ═══════════════════════════════════════════════════════════════════════════

verify_env_templates() {
    print_section "VÉRIFICATION DES TEMPLATES .ENV"

    local all_ok=true

    # Vérifier bolt.diy/.env.example
    if [ -f "$BOLTDIY_DIR/.env.example" ]; then
        print_success "Trouvé: bolt.diy/.env.example"
    else
        print_error "Manquant: bolt.diy/.env.example"
        all_ok=false
    fi

    # Vérifier DATA-LOCAL/user-manager/.env.example
    if [ -f "$USERMANAGER_DIR/.env.example" ]; then
        print_success "Trouvé: DATA-LOCAL/user-manager/.env.example"
    else
        print_error "Manquant: DATA-LOCAL/user-manager/.env.example"
        all_ok=false
    fi

    if [ "$all_ok" = false ]; then
        print_error "Templates .env.example manquants dans le repository"
        print_info "Vérifiez le repository: $GITHUB_REPO"
        exit 1
    fi

    print_success "Tous les templates .env.example sont présents"
}

# ═══════════════════════════════════════════════════════════════════════════
# VÉRIFICATION DES SCRIPTS SQL D'INITIALISATION
# ═══════════════════════════════════════════════════════════════════════════

verify_sql_init_scripts() {
    print_section "VÉRIFICATION DES SCRIPTS SQL D'INITIALISATION"

    local sql_init_dir="$MARIADB_DIR/init"

    # Vérifier que le dossier init existe
    if [ ! -d "$sql_init_dir" ]; then
        print_error "Dossier manquant: $sql_init_dir"
        print_info "Ce dossier doit contenir les scripts SQL d'initialisation MariaDB"
        exit 1
    fi

    # Compter les fichiers .sql
    local sql_count=$(find "$sql_init_dir" -maxdepth 1 -name "*.sql" 2>/dev/null | wc -l)

    if [ "$sql_count" -eq 0 ]; then
        print_error "Aucun fichier .sql trouvé dans $sql_init_dir"
        print_warning "Les tables ne seront pas créées"
        exit 1
    fi

    print_success "Trouvé $sql_count fichier(s) SQL d'initialisation"

    # Lister les fichiers trouvés
    for sql_file in "$sql_init_dir"/*.sql; do
        if [ -f "$sql_file" ]; then
            print_info "  - $(basename "$sql_file")"
        fi
    done
}

# ═══════════════════════════════════════════════════════════════════════════
# CRÉATION DES DOSSIERS
# ═══════════════════════════════════════════════════════════════════════════

create_directories() {
    print_section "CRÉATION DE L'ARBORESCENCE"

    local dirs=(
        "$DATA_LOCAL_DIR"
        "$NGINX_DIR"
        "$MARIADB_DIR"
        "$USERMANAGER_DIR"
        "$USERMANAGER_DIR/logs"
        "$USERMANAGER_DIR/uploads"
    )

    for dir in "${dirs[@]}"; do
        if [ ! -d "$dir" ]; then
            mkdir -p "$dir"
            print_success "Créé: $dir"
        else
            print_info "Existe déjà: $dir"
        fi
    done

    # Permissions spécifiques
    chmod 777 "$USERMANAGER_DIR/logs" 2>/dev/null || true
    chmod 777 "$USERMANAGER_DIR/uploads" 2>/dev/null || true

    print_success "Arborescence prête"
}

# ═══════════════════════════════════════════════════════════════════════════
# CRÉATION DU FICHIER .ENV RACINE
# ═══════════════════════════════════════════════════════════════════════════

create_root_env() {
    print_section "CRÉATION DU FICHIER .ENV (RACINE)"

    cat > "$PROJECT_ROOT/.env" <<EOF
# IP et Port
LOCAL_IP=$LOCAL_IP
HOST_PORT_HOME=$HOST_PORT_HOME

# Database
DB_HOST=bolt-mariadb
DB_PORT=3306
DB_NAME=usermanager
DB_USER=usermanager
DB_PASSWORD=$MARIADB_USER_PASSWORD

# MariaDB
MARIADB_ROOT_PASSWORD=$MARIADB_ROOT_PASSWORD
MARIADB_USER_PASSWORD=$MARIADB_USER_PASSWORD

# Chemins
NGINX_DIR=./DATA-LOCAL/nginx
BOLTDIY_DIR=./bolt.diy
MARIADB_DIR=./DATA-LOCAL/mariadb
USERMANAGER_DIR=./DATA-LOCAL/user-manager
EOF

    print_success "Fichier .env racine créé"
}

# ═══════════════════════════════════════════════════════════════════════════
# CONFIGURATION DES FICHIERS .ENV DEPUIS LES TEMPLATES
# ═══════════════════════════════════════════════════════════════════════════

setup_env_files() {
    print_section "CONFIGURATION DES FICHIERS .ENV DES SERVICES"

    # 1. bolt.diy/.env (copie du template + ajout des clés API)
    print_step "Configuration de bolt.diy/.env..."

    if [ ! -f "$BOLTDIY_DIR/.env.example" ]; then
        print_error "Template manquant: $BOLTDIY_DIR/.env.example"
        exit 1
    fi

    cp "$BOLTDIY_DIR/.env.example" "$BOLTDIY_DIR/.env"

    # Ajouter les clés API si fournies
    if [ -n "$OPENAI_API_KEY" ]; then
        echo "OPENAI_API_KEY=$OPENAI_API_KEY" >> "$BOLTDIY_DIR/.env"
    fi
    if [ -n "$ANTHROPIC_API_KEY" ]; then
        echo "ANTHROPIC_API_KEY=$ANTHROPIC_API_KEY" >> "$BOLTDIY_DIR/.env"
    fi
    if [ -n "$GROQ_API_KEY" ]; then
        echo "GROQ_API_KEY=$GROQ_API_KEY" >> "$BOLTDIY_DIR/.env"
    fi
    if [ -n "$GOOGLE_API_KEY" ]; then
        echo "GOOGLE_API_KEY=$GOOGLE_API_KEY" >> "$BOLTDIY_DIR/.env"
    fi

    print_success "Fichier bolt.diy/.env configuré"

    # 2. DATA-LOCAL/user-manager/.env (copie du template + remplacement des variables)
    print_step "Configuration de DATA-LOCAL/user-manager/.env..."

    if [ ! -f "$USERMANAGER_DIR/.env.example" ]; then
        print_error "Template manquant: $USERMANAGER_DIR/.env.example"
        exit 1
    fi

    # Copier le template
    cp "$USERMANAGER_DIR/.env.example" "$USERMANAGER_DIR/.env"

    # Remplacer les variables dynamiques
    sed -i "s|DB_HOST=.*|DB_HOST=bolt-mariadb|g" "$USERMANAGER_DIR/.env"
    sed -i "s|DB_PORT=.*|DB_PORT=3306|g" "$USERMANAGER_DIR/.env"
    sed -i "s|DB_NAME=.*|DB_NAME=usermanager|g" "$USERMANAGER_DIR/.env"
    sed -i "s|DB_USER=.*|DB_USER=usermanager|g" "$USERMANAGER_DIR/.env"
    sed -i "s|DB_PASSWORD=.*|DB_PASSWORD=$MARIADB_USER_PASSWORD|g" "$USERMANAGER_DIR/.env"
    sed -i "s|APP_SECRET=.*|APP_SECRET=$APP_SECRET|g" "$USERMANAGER_DIR/.env"

    print_success "Fichier DATA-LOCAL/user-manager/.env configuré"
}

# ═══════════════════════════════════════════════════════════════════════════
# DÉMARRAGE DES CONTENEURS
# ═══════════════════════════════════════════════════════════════════════════

start_containers() {
    print_section "DÉMARRAGE DES CONTENEURS DOCKER"

    cd "$PROJECT_ROOT" || exit 1

    print_step "Arrêt des conteneurs existants..."
    docker compose down -v 2>/dev/null || true  # -v pour supprimer les volumes

    print_step "Suppression des données MariaDB existantes..."
    if [ -d "$MARIADB_DIR/data" ]; then
        sudo rm -rf "$MARIADB_DIR/data"
        print_success "Données MariaDB supprimées"
    fi

    print_step "Reconstruction et démarrage..."
    docker compose up -d --build

    if [ $? -eq 0 ]; then
        print_success "Conteneurs démarrés"
    else
        print_error "Échec du démarrage"
        exit 1
    fi

    print_step "Attente de l'initialisation des services (30s)..."
    sleep 30
}

# ═══════════════════════════════════════════════════════════════════════════
# VÉRIFICATION DE MARIADB
# ═══════════════════════════════════════════════════════════════════════════

wait_for_mariadb() {
    print_section "VÉRIFICATION DE MARIADB"

    local max_retries=30
    local retry=0

    # Charger les variables depuis .env
    source "$PROJECT_ROOT/.env"

    print_step "Attente de MariaDB..."

    while [ $retry -lt $max_retries ]; do
        if docker compose exec -T mariadb mariadb -uroot -p"${MARIADB_ROOT_PASSWORD}" -e "SELECT 1" &>/dev/null; then
            print_success "MariaDB est prêt"
            return 0
        fi

        retry=$((retry + 1))
        echo -n "."
        sleep 2
    done

    print_error "MariaDB n'a pas démarré dans les temps"
    exit 1
}

# ═══════════════════════════════════════════════════════════════════════════
# VÉRIFICATION DE LA BASE DE DONNÉES
# ═══════════════════════════════════════════════════════════════════════════

check_database() {
    print_section "VÉRIFICATION DE LA BASE DE DONNÉES"

    # Charger les variables depuis .env
    source "$PROJECT_ROOT/.env"

    print_step "Vérification de la base 'usermanager'..."

    DB_EXISTS=$(docker compose exec -T mariadb mariadb -uroot -p"${MARIADB_ROOT_PASSWORD}" -N -s \
        -e "SELECT COUNT(*) FROM information_schema.SCHEMATA WHERE SCHEMA_NAME='usermanager';" \
        2>/dev/null | tr -d '\n\r\t ' || echo "0")

    if [ "$DB_EXISTS" -gt 0 ]; then
        print_success "Base de données 'usermanager' existe"
    else
        print_error "Base de données 'usermanager' introuvable"
        exit 1
    fi

    print_step "Vérification de la table 'um_users'..."

    # FIX: Chercher "um_users" au lieu de "users"
    TABLE_EXISTS=$(docker compose exec -T mariadb mariadb -uroot -p"${MARIADB_ROOT_PASSWORD}" -N -s \
        -e "SELECT COUNT(*) FROM information_schema.TABLES WHERE TABLE_SCHEMA='usermanager' AND TABLE_NAME='um_users';" \
        2>/dev/null | tr -d '\n\r\t ' || echo "0")

    if [ "$TABLE_EXISTS" -gt 0 ]; then
        print_success "Table 'um_users' existe"
    else
        print_error "Table 'um_users' introuvable"
        print_info "Vérifiez les logs: docker compose logs mariadb | grep -i init"
        exit 1
    fi
}


# ═══════════════════════════════════════════════════════════════════════════
# CRÉATION DE L'UTILISATEUR SUPERADMIN
# ═══════════════════════════════════════════════════════════════════════════

create_superadmin_user() {
    print_section "CRÉATION DE L'UTILISATEUR SUPERADMIN"

    # Charger les variables depuis .env ou demander à l'utilisateur
    source "$PROJECT_ROOT/.env"

    if [ -z "$SUPERADMIN_USERNAME" ]; then
        echo -n "Nom d'utilisateur superadmin [superadmin]: "
        read -r SUPERADMIN_USERNAME
        SUPERADMIN_USERNAME=${SUPERADMIN_USERNAME:-superadmin}
    fi

    if [ -z "$SUPERADMIN_EMAIL" ]; then
        echo -n "Email superadmin [superadmin@local]: "
        read -r SUPERADMIN_EMAIL
        SUPERADMIN_EMAIL=${SUPERADMIN_EMAIL:-superadmin@local}
    fi

    if [ -z "$SUPERADMIN_PASSWORD" ]; then
        echo -n "Mot de passe superadmin: "
        read -rs SUPERADMIN_PASSWORD
        echo
        while [ -z "$SUPERADMIN_PASSWORD" ]; do
            echo -e "${RED}Le mot de passe ne peut pas être vide${NC}"
            echo -n "Mot de passe superadmin: "
            read -rs SUPERADMIN_PASSWORD
            echo
        done
    fi

    print_step "Vérification de l'utilisateur '$SUPERADMIN_USERNAME'..."

    # Vérifier si le superadmin existe déjà
    USER_COUNT=$(docker compose exec -T mariadb mariadb -uroot -p"${MARIADB_ROOT_PASSWORD}" -N -s \
        -e "SELECT COUNT(*) FROM usermanager.um_users WHERE username='$SUPERADMIN_USERNAME';" \
        2>/dev/null | tr -d '\n\r\t ' || echo "0")

    if [ "$USER_COUNT" -gt 0 ]; then
        print_warning "Le superadmin '$SUPERADMIN_USERNAME' existe déjà"
        echo -n "Voulez-vous le supprimer et le recréer ? (o/N): "
        read -r response

        if [[ "$response" =~ ^[Oo]$ ]]; then
            print_step "Suppression du superadmin existant..."
            docker compose exec -T mariadb mariadb -uroot -p"${MARIADB_ROOT_PASSWORD}" \
                -e "DELETE FROM usermanager.um_users WHERE username='$SUPERADMIN_USERNAME';" 2>/dev/null
            print_success "Superadmin supprimé"
        else
            print_info "Conservation du superadmin existant"
            return 0
        fi
    fi

    print_step "Génération du hash du mot de passe..."

    SUPERADMIN_PASSWORD_HASH=$(docker compose exec -T user-manager php -r "echo password_hash('$SUPERADMIN_PASSWORD', PASSWORD_BCRYPT);")

    if [ -z "$SUPERADMIN_PASSWORD_HASH" ]; then
        print_error "Échec de la génération du hash"
        exit 1
    fi

    print_success "Hash généré"

    print_step "Création du superadmin dans la base..."

    docker compose exec -T mariadb mariadb -uroot -p"${MARIADB_ROOT_PASSWORD}" <<SQL_SUPERADMIN
USE usermanager;
INSERT INTO um_users (
    username,
    email,
    password_hash,
    role,
    status,
    quota_bolt_users,
    failed_attempts,
    theme,
    locale,
    timezone,
    two_factor_enabled,
    created_at,
    updated_at
) VALUES (
    '$SUPERADMIN_USERNAME',
    '$SUPERADMIN_EMAIL',
    '$SUPERADMIN_PASSWORD_HASH',
    'superadmin',
    'active',
    100,
    0,
    'dark',
    'fr_FR',
    'Europe/Paris',
    0,
    NOW(),
    NOW()
);
SQL_SUPERADMIN

    if [ $? -eq 0 ]; then
        print_success "Superadmin créé avec succès"
        echo ""
        docker compose exec -T mariadb mariadb -uroot -p"${MARIADB_ROOT_PASSWORD}" \
            -e "SELECT id, username, email, role, status, quota_bolt_users, DATE_FORMAT(created_at, '%Y-%m-%d %H:%i:%s') AS created FROM usermanager.um_users WHERE username='$SUPERADMIN_USERNAME';" \
            2>/dev/null
    else
        print_error "Échec de la création du superadmin"
        exit 1
    fi
}


# ═══════════════════════════════════════════════════════════════════════════
# CRÉATION DE L'UTILISATEUR ADMIN
# ═══════════════════════════════════════════════════════════════════════════

create_admin_user() {
    print_section "CRÉATION DE L'UTILISATEUR ADMIN"

    # Charger les variables depuis .env
    source "$PROJECT_ROOT/.env"

    print_step "Vérification de l'utilisateur '$ADMIN_USERNAME'..."

    # Vérifier si l'utilisateur existe déjà
    USER_COUNT=$(docker compose exec -T mariadb mariadb -uroot -p"${MARIADB_ROOT_PASSWORD}" -N -s \
        -e "SELECT COUNT(*) FROM usermanager.um_users WHERE username='$ADMIN_USERNAME';" \
        2>/dev/null | tr -d '\n\r\t ' || echo "0")

    if [ "$USER_COUNT" -gt 0 ]; then
        print_warning "L'utilisateur '$ADMIN_USERNAME' existe déjà"
        echo -n "Voulez-vous le supprimer et le recréer ? (o/N): "
        read -r response

        if [[ "$response" =~ ^[Oo]$ ]]; then
            print_step "Suppression de l'utilisateur existant..."
            docker compose exec -T mariadb mariadb -uroot -p"${MARIADB_ROOT_PASSWORD}" \
                -e "DELETE FROM usermanager.um_users WHERE username='$ADMIN_USERNAME';" 2>/dev/null
            print_success "Utilisateur supprimé"
        else
            print_info "Conservation de l'utilisateur existant"
            return 0
        fi
    fi

    print_step "Génération du hash du mot de passe..."

    ADMIN_PASSWORD_HASH=$(docker compose exec -T user-manager php -r "echo password_hash('$ADMIN_PASSWORD', PASSWORD_BCRYPT);")

    if [ -z "$ADMIN_PASSWORD_HASH" ]; then
        print_error "Échec de la génération du hash"
        exit 1
    fi

    print_success "Hash généré"

    print_step "Création de l'utilisateur admin dans la base..."

    # FIX FINAL: Utiliser les BONS champs selon le schéma réel
    docker compose exec -T mariadb mariadb -uroot -p"${MARIADB_ROOT_PASSWORD}" <<SQL_ADMIN
USE usermanager;
INSERT INTO um_users (
    username,
    email,
    password_hash,
    role,
    status,
    quota_bolt_users,
    failed_attempts,
    theme,
    locale,
    timezone,
    two_factor_enabled,
    created_at,
    updated_at
) VALUES (
    '$ADMIN_USERNAME',
    '$ADMIN_EMAIL',
    '$ADMIN_PASSWORD_HASH',
    'admin',
    'active',
    100,
    0,
    'dark',
    'fr_FR',
    'Europe/Paris',
    0,
    NOW(),
    NOW()
);
SQL_ADMIN

    if [ $? -eq 0 ]; then
        print_success "Utilisateur admin créé avec succès"

        # Afficher l'utilisateur créé
        echo ""
        docker compose exec -T mariadb mariadb -uroot -p"${MARIADB_ROOT_PASSWORD}" \
            -e "SELECT id, username, email, role, status, quota_bolt_users, DATE_FORMAT(created_at, '%Y-%m-%d %H:%i:%s') AS created FROM usermanager.um_users WHERE username='$ADMIN_USERNAME';" \
            2>/dev/null
    else
        print_error "Échec de la création de l'utilisateur"
        exit 1
    fi
}


# ═══════════════════════════════════════════════════════════════════════════
# DIAGNOSTIC FINAL
# ═══════════════════════════════════════════════════════════════════════════

run_final_diagnostic() {
    print_section "DIAGNOSTIC FINAL"

    # Charger les variables depuis .env
    source "$PROJECT_ROOT/.env"

    echo ""
    echo -e "${CYAN}┌─────────────────────────────────────────────────────────┐${NC}"
    echo -e "${CYAN}│                 ÉTAT DE L'INSTALLATION                  │${NC}"
    echo -e "${CYAN}└─────────────────────────────────────────────────────────┘${NC}"
    echo ""

    # État des conteneurs
    print_step "État des conteneurs:"
    docker compose ps

    echo ""

    # Test de connexion MariaDB
    print_step "Test de connexion MariaDB:"
    if docker compose exec -T mariadb mariadb -uroot -p"${MARIADB_ROOT_PASSWORD}" -e "SELECT VERSION();" &>/dev/null; then
        print_success "MariaDB accessible"
    else
        print_error "MariaDB non accessible"
    fi

    # Vérification utilisateur admin
    print_step "Vérification utilisateur admin:"
    USER_COUNT=$(docker compose exec -T mariadb mariadb -uroot -p"${MARIADB_ROOT_PASSWORD}" -N -s \
        -e "SELECT COUNT(*) FROM usermanager.um_users WHERE username='$ADMIN_USERNAME';" \
        2>/dev/null | tr -d '\n\r\t ' || echo "0")

    if [ "$USER_COUNT" -gt 0 ]; then
        print_success "Utilisateur '$ADMIN_USERNAME' présent en base"

        # Afficher les détails
        echo ""
        docker compose exec -T mariadb mariadb -uroot -p"${MARIADB_ROOT_PASSWORD}" \
            -e "SELECT id, username, email, role, is_active, DATE_FORMAT(created_at, '%Y-%m-%d %H:%i:%s') AS created FROM usermanager.um_users WHERE username='$ADMIN_USERNAME';" \
            2>/dev/null
    else
        print_error "Utilisateur '$ADMIN_USERNAME' non trouvé"
    fi

    echo ""
}

# ═══════════════════════════════════════════════════════════════════════════
# AFFICHAGE DU RÉSUMÉ FINAL
# ═══════════════════════════════════════════════════════════════════════════

print_final_summary() {
    print_section "INSTALLATION TERMINÉE"

    echo ""
    echo -e "${GREEN}╔═══════════════════════════════════════════════════════════╗${NC}"
    echo -e "${GREEN}║                                                           ║${NC}"
    echo -e "${GREEN}║          ✓ BOLT.DIY INTRANET INSTALLÉ AVEC SUCCÈS        ║${NC}"
    echo -e "${GREEN}║                                                           ║${NC}"
    echo -e "${GREEN}╚═══════════════════════════════════════════════════════════╝${NC}"
    echo ""

    echo -e "${CYAN}📍 URLs D'ACCÈS :${NC}"
    echo ""
    echo -e "   ${YELLOW}Page d'accueil :${NC}"
    echo -e "   ${BLUE}http://${LOCAL_IP}:${HOST_PORT_HOME}/accueil/${NC}"
    echo ""
    echo -e "   ${YELLOW}Bolt.DIY (IDE) :${NC}"
    echo -e "   ${BLUE}http://${LOCAL_IP}:${HOST_PORT_HOME}/${NC}"
    echo ""
    echo -e "   ${YELLOW}User Manager (Gestion utilisateurs) :${NC}"
    echo -e "   ${BLUE}http://${LOCAL_IP}:${HOST_PORT_HOME}/user-manager/${NC}"
    echo ""

    echo -e "${CYAN}🔐 IDENTIFIANTS ADMIN :${NC}"
    echo ""
    echo -e "   ${YELLOW}Utilisateur :${NC} ${GREEN}${ADMIN_USERNAME}${NC}"
    echo -e "   ${YELLOW}Email :${NC}       ${GREEN}${ADMIN_EMAIL}${NC}"
    echo -e "   ${YELLOW}Mot de passe :${NC} ${GREEN}${ADMIN_PASSWORD}${NC}"
    echo ""

    echo -e "${CYAN}📂 DOSSIER DU PROJET :${NC}"
    echo -e "   ${BLUE}${PROJECT_ROOT}${NC}"
    echo ""

    echo -e "${CYAN}📄 FICHIERS .ENV :${NC}"
    echo -e "   ${BLUE}${PROJECT_ROOT}/.env${NC}"
    echo -e "   ${BLUE}${BOLTDIY_DIR}/.env${NC}"
    echo -e "   ${BLUE}${USERMANAGER_DIR}/.env${NC}"
    echo ""

    echo -e "${YELLOW}⚠️  IMPORTANT :${NC}"
    echo -e "   • Changez le mot de passe admin après la première connexion"
    echo -e "   • Sauvegardez les fichiers .env (contiennent les mots de passe)"
    echo -e "   • Configurez vos clés API dans User Manager si nécessaire"
    echo ""

    echo -e "${CYAN}🔧 COMMANDES UTILES :${NC}"
    echo ""
    echo -e "   ${YELLOW}Voir les logs :${NC}"
    echo -e "   ${BLUE}cd ${PROJECT_ROOT} && docker compose logs -f${NC}"
    echo ""
    echo -e "   ${YELLOW}Arrêter les conteneurs :${NC}"
    echo -e "   ${BLUE}cd ${PROJECT_ROOT} && docker compose down${NC}"
    echo ""
    echo -e "   ${YELLOW}Redémarrer les conteneurs :${NC}"
    echo -e "   ${BLUE}cd ${PROJECT_ROOT} && docker compose up -d${NC}"
    echo ""
    echo -e "   ${YELLOW}Diagnostic :${NC}"
    echo -e "   ${BLUE}cd ${PROJECT_ROOT} && ./Diagnostics_nginx.sh${NC}"
    echo ""

    # --- TABLEAU DES COMPTES CREER DANS MARIABD ---
    echo -e "   ${YELLOW}TABLEAU DES COMPTES CREER DANS MARIABD :${NC}"
    echo ""
    set -o allexport
    source .env
    set +o allexport
    docker compose exec mariadb mariadb -u$DB_USER -p$DB_PASSWORD -h$DB_HOST -D $DB_NAME -e "SELECT id, username, email, role, status FROM um_users;"


    echo -e "${GREEN}═══════════════════════════════════════════════════════════${NC}"
    echo ""
}

# ═══════════════════════════════════════════════════════════════════════════
# FONCTION PRINCIPALE
# ═══════════════════════════════════════════════════════════════════════════

main() {
    print_banner

    # Vérifications préalables
    check_dependencies

    # Collecte des informations
    collect_user_inputs

    # Clonage du repo
    clone_github_repo

    # Vérification des templates .env.example
    verify_env_templates

    # Vérification des scripts SQL
    verify_sql_init_scripts

    # Création des dossiers
    create_directories

    # Création du fichier .env racine
    create_root_env

    # Configuration des fichiers .env des services
    setup_env_files

    # Démarrage des conteneurs
    start_containers

    # Attente et vérification de MariaDB
    wait_for_mariadb

    # Vérification de la base de données
    check_database

    # Création du superadmin (manquant actuellement)
    create_superadmin_user

    # Création de l'utilisateur admin
    create_admin_user

    # Diagnostic final
    run_final_diagnostic

    # Résumé final
    print_final_summary
}

# ═══════════════════════════════════════════════════════════════════════════
# EXÉCUTION
# ═══════════════════════════════════════════════════════════════════════════

# Gestion des erreurs
trap 'print_error "Une erreur est survenue. Installation interrompue."; exit 1' ERR

# Lancement
main

exit 0
