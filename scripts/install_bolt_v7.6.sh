#!/bin/bash
set -e

# ═══════════════════════════════════════════════════════════════════════════
# BOLT.DIY INTRANET - Installation complète v7.6
# Basé sur v7.5 avec support username au lieu d'email
# © Copyright Nbility 2025 - contact@nbility.fr
# ═══════════════════════════════════════════════════════════════════════════

# Variables globales
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="${HOME}/DOCKER-PROJETS/BOLT.DIY-INTRANET"
DATA_LOCAL_DIR="$PROJECT_ROOT/DATA-LOCAL"
NGINX_DIR="$DATA_LOCAL_DIR/nginx"
MARIADB_DIR="$DATA_LOCAL_DIR/mariadb"
USERMANAGER_DIR="$DATA_LOCAL_DIR/user-manager"
BOLTDIY_DIR="$DATA_LOCAL_DIR/bolt.diy"

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
ADMIN_USERNAME=""  # ← CHANGEMENT: username au lieu de ADMIN_USER
ADMIN_EMAIL=""     # ← AJOUT: email en plus
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
    echo -e "${CYAN}╔════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║                                                            ║${NC}"
    echo -e "${CYAN}║          🚀 BOLT.DIY - NBILITY EDITION 🚀                 ║${NC}"
    echo -e "${CYAN}║                                                            ║${NC}"
    echo -e "${CYAN}╚════════════════════════════════════════════════════════════╝${NC}"
    echo ""
    echo -e "${BLUE}       NBILITY EDITION - Installation v7.6${NC}"
    echo -e "${BLUE}       Support username + email${NC}"
    echo -e "${CYAN}════════════════════════════════════════════════════════════${NC}"
    echo ""
}

print_section() {
    echo ""
    echo -e "${CYAN}═══════════════════════════════════════════════════════════${NC}"
    echo -e "${CYAN} $1${NC}"
    echo -e "${CYAN}═══════════════════════════════════════════════════════════${NC}"
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

    # htpasswd
    if command -v htpasswd &> /dev/null; then
        print_success "htpasswd disponible"
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

    # Admin username
    echo -n "Nom d'utilisateur admin [admin]: "
    read -r ADMIN_USERNAME
    ADMIN_USERNAME="${ADMIN_USERNAME:-admin}"

    # Admin email
    echo -n "Email de l'administrateur [admin@example.com]: "
    read -r ADMIN_EMAIL
    ADMIN_EMAIL="${ADMIN_EMAIL:-admin@example.com}"

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

    # Hash du mot de passe (pour MariaDB avec password_hash PHP)
    ADMIN_PASSWORD_HASH=$(docker run --rm php:8.2-cli php -r "echo password_hash('${ADMIN_PASSWORD}', PASSWORD_ARGON2ID);")

    # Mots de passe base de données
    MARIADB_ROOT_PASSWORD=$(openssl rand -base64 32)
    MARIADB_USER_PASSWORD=$(openssl rand -base64 32)
    APP_SECRET=$(openssl rand -hex 32)

    # Clés API optionnelles
    echo ""
    print_info "Clés API optionnelles, laisser vide pour ignorer"
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
# CLONAGE DEPUIS GITHUB
# ═══════════════════════════════════════════════════════════════════════════

clone_repository() {
    print_section "CLONAGE DEPUIS GITHUB"

    if [ -d "$PROJECT_ROOT" ]; then
        print_warning "Le dossier $PROJECT_ROOT existe déjà"
        echo -n "Voulez-vous le supprimer et recommencer? (o/N): "
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

    print_step "Clonage depuis GitHub..."
    print_info "Repository: $GITHUB_REPO"
    print_info "Destination: $PROJECT_ROOT"

    if git clone "$GITHUB_REPO" "$PROJECT_ROOT"; then
        print_success "Repository cloné avec succès"
    else
        print_error "Échec du clonage depuis GitHub"
        exit 1
    fi
}

# ═══════════════════════════════════════════════════════════════════════════
# CRÉATION DES DOSSIERS
# ═══════════════════════════════════════════════════════════════════════════

create_directories() {
    print_section "CRÉATION DES DOSSIERS"

    print_step "Création des dossiers MariaDB..."
    mkdir -p "$MARIADB_DIR/data"
    mkdir -p "$MARIADB_DIR/init"
    print_success "Dossiers MariaDB créés"

    print_step "Création des dossiers User Manager..."
    mkdir -p "$USERMANAGER_DIR/app/public"
    mkdir -p "$USERMANAGER_DIR/app/logs"
    mkdir -p "$USERMANAGER_DIR/app/uploads"
    print_success "Dossiers User Manager créés"

    print_step "Vérification des permissions..."
    chmod -R 755 "$PROJECT_ROOT"
    chmod -R 777 "$USERMANAGER_DIR/app/logs" 2>/dev/null || true
    chmod -R 777 "$USERMANAGER_DIR/app/uploads" 2>/dev/null || true
    chmod -R 777 "$MARIADB_DIR/data" 2>/dev/null || true
    print_success "Permissions configurées"
}

# ═══════════════════════════════════════════════════════════════════════════
# GÉNÉRATION DES FICHIERS .ENV
# ═══════════════════════════════════════════════════════════════════════════

generate_env_files() {
    print_section "GÉNÉRATION FICHIERS .ENV"

    # .env principal
    print_step "Création du fichier .env principal..."
    cat > "$PROJECT_ROOT/.env" << ENV_MAIN_EOF
# IP et Port
LOCAL_IP=$LOCAL_IP
HOST_PORT_HOME=$HOST_PORT_HOME

# Database
DB_HOST=mariadb
DB_PORT=3306
DB_NAME=user_manager
DB_USER=user_manager
DB_PASSWORD=$MARIADB_USER_PASSWORD

# MariaDB
MARIADB_ROOT_PASSWORD=$MARIADB_ROOT_PASSWORD
MARIADB_USER_PASSWORD=$MARIADB_USER_PASSWORD

# Chemins
NGINX_DIR=./DATA-LOCAL/nginx
BOLTDIY_DIR=./DATA-LOCAL/bolt.diy
MARIADB_DIR=./DATA-LOCAL/mariadb
USERMANAGER_DIR=./DATA-LOCAL/user-manager
ENV_MAIN_EOF
    print_success ".env principal créé"

    # .env Bolt.DIY
    print_step "Création du fichier .env Bolt.DIY..."
    if [ -f "$BOLTDIY_DIR/.env.example" ]; then
        cp "$BOLTDIY_DIR/.env.example" "$BOLTDIY_DIR/.env"
    else
        touch "$BOLTDIY_DIR/.env"
    fi

    [ -n "$OPENAI_API_KEY" ] && echo "OPENAI_API_KEY=$OPENAI_API_KEY" >> "$BOLTDIY_DIR/.env"
    [ -n "$ANTHROPIC_API_KEY" ] && echo "ANTHROPIC_API_KEY=$ANTHROPIC_API_KEY" >> "$BOLTDIY_DIR/.env"
    [ -n "$GROQ_API_KEY" ] && echo "GROQ_API_KEY=$GROQ_API_KEY" >> "$BOLTDIY_DIR/.env"
    [ -n "$GOOGLE_API_KEY" ] && echo "GOOGLE_GENERATIVE_AI_API_KEY=$GOOGLE_API_KEY" >> "$BOLTDIY_DIR/.env"

    print_success ".env Bolt.DIY créé"

    # .env User Manager
    print_step "Création du fichier .env User Manager..."
    cat > "$USERMANAGER_DIR/.env" << ENV_UM_EOF
# Application
APP_NAME=Bolt.DIY User Manager
APP_ENV=production
APP_DEBUG=false
APP_URL=http://$LOCAL_IP:$HOST_PORT_HOME
APP_SECRET=$APP_SECRET

# Database
DB_HOST=mariadb
DB_PORT=3306
DB_NAME=user_manager
DB_USER=user_manager
DB_PASSWORD=$MARIADB_USER_PASSWORD

# Logs
LOG_LEVEL=info
LOG_FILE=/var/www/html/logs/app.log
ENV_UM_EOF
    print_success ".env User Manager créé"
}

# ═══════════════════════════════════════════════════════════════════════════
# GÉNÉRATION .HTPASSWD
# ═══════════════════════════════════════════════════════════════════════════

generate_htpasswd() {
    print_section "GÉNÉRATION .HTPASSWD"
    print_step "Création du fichier .htpasswd..."
    htpasswd -cb "$NGINX_DIR/.htpasswd" "$ADMIN_USERNAME" "$ADMIN_PASSWORD"
    print_success ".htpasswd créé avec utilisateur: $ADMIN_USERNAME"
}

# ═══════════════════════════════════════════════════════════════════════════
# CONFIGURATION SQL
# ═══════════════════════════════════════════════════════════════════════════

configure_sql() {
    print_section "CONFIGURATION BASE DE DONNÉES"

    print_step "Création du script SQL d'initialisation..."
    cat > "$MARIADB_DIR/init/01_init_user_manager.sql" <<'SQL_EOF'
-- ═══════════════════════════════════════════════════════════════════════════
-- BOLT.DIY USER MANAGER - Schéma de base de données v7.6
-- © Copyright Nbility 2025 - contact@nbility.fr
-- ═══════════════════════════════════════════════════════════════════════════

CREATE DATABASE IF NOT EXISTS user_manager CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
USE user_manager;

-- Table des utilisateurs
CREATE TABLE IF NOT EXISTS users (
    id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    username VARCHAR(50) NOT NULL UNIQUE,
    email VARCHAR(255) NOT NULL UNIQUE,
    password_hash VARCHAR(255) NOT NULL,
    is_active BOOLEAN DEFAULT TRUE,
    is_super_admin BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    last_login_at TIMESTAMP NULL,
    INDEX idx_username (username),
    INDEX idx_email (email),
    INDEX idx_is_active (is_active)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Table des groupes
CREATE TABLE IF NOT EXISTS user_groups (
    id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(100) NOT NULL UNIQUE,
    description TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    INDEX idx_name (name)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Table de liaison users <-> groups
CREATE TABLE IF NOT EXISTS user_group_members (
    user_id INT UNSIGNED NOT NULL,
    group_id INT UNSIGNED NOT NULL,
    assigned_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (user_id, group_id),
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
    FOREIGN KEY (group_id) REFERENCES user_groups(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Table des permissions
CREATE TABLE IF NOT EXISTS permissions (
    id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    code VARCHAR(100) NOT NULL UNIQUE,
    description TEXT,
    INDEX idx_code (code)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Table de liaison groups <-> permissions
CREATE TABLE IF NOT EXISTS group_permissions (
    group_id INT UNSIGNED NOT NULL,
    permission_id INT UNSIGNED NOT NULL,
    PRIMARY KEY (group_id, permission_id),
    FOREIGN KEY (group_id) REFERENCES user_groups(id) ON DELETE CASCADE,
    FOREIGN KEY (permission_id) REFERENCES permissions(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Table d'audit
CREATE TABLE IF NOT EXISTS audit_logs (
    id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    user_id INT UNSIGNED NULL,
    action VARCHAR(100) NOT NULL,
    entity_type VARCHAR(50),
    entity_id INT UNSIGNED NULL,
    details JSON,
    ip_address VARCHAR(45),
    user_agent TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE SET NULL,
    INDEX idx_user_id (user_id),
    INDEX idx_action (action),
    INDEX idx_created_at (created_at)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Permissions par défaut
INSERT IGNORE INTO permissions (code, description) VALUES
('user.view', 'Voir les utilisateurs'),
('user.create', 'Créer des utilisateurs'),
('user.edit', 'Modifier des utilisateurs'),
('user.delete', 'Supprimer des utilisateurs'),
('group.view', 'Voir les groupes'),
('group.create', 'Créer des groupes'),
('group.edit', 'Modifier des groupes'),
('group.delete', 'Supprimer des groupes'),
('permission.manage', 'Gérer les permissions'),
('audit.view', 'Consulter les logs d\'audit'),
('system.admin', 'Administration système complète');

-- Groupe administrateurs
INSERT IGNORE INTO user_groups (name, description) VALUES
('Administrateurs', 'Groupe avec tous les droits d\'administration');

-- Associer toutes les permissions au groupe Administrateurs
INSERT IGNORE INTO group_permissions (group_id, permission_id)
SELECT 1, id FROM permissions;
SQL_EOF

    print_success "Script SQL créé"

    print_step "Insertion de l'utilisateur admin dans le script SQL..."
    cat >> "$MARIADB_DIR/init/01_init_user_manager.sql" <<SQL_ADMIN_EOF

-- Création de l'utilisateur administrateur
INSERT INTO users (username, email, password_hash, is_active, is_super_admin)
VALUES ('$ADMIN_USERNAME', '$ADMIN_EMAIL', '$ADMIN_PASSWORD_HASH', TRUE, TRUE)
ON DUPLICATE KEY UPDATE
    email = '$ADMIN_EMAIL',
    password_hash = '$ADMIN_PASSWORD_HASH',
    is_super_admin = TRUE;

-- Associer l'admin au groupe Administrateurs
INSERT INTO user_group_members (user_id, group_id)
SELECT u.id, 1
FROM users u
WHERE u.username = '$ADMIN_USERNAME'
ON DUPLICATE KEY UPDATE user_id = user_id;
SQL_ADMIN_EOF

    print_success "Utilisateur admin ajouté au script SQL"
}

# ═══════════════════════════════════════════════════════════════════════════
# LANCEMENT DES CONTENEURS
# ═══════════════════════════════════════════════════════════════════════════

launch_docker() {
    print_section "LANCEMENT DES CONTENEURS DOCKER"

    cd "$PROJECT_ROOT" || exit 1

    print_step "Arrêt des conteneurs existants..."
    docker compose down 2>/dev/null || true
    print_success "Conteneurs arrêtés"

    print_step "Construction et démarrage des conteneurs..."
    if docker compose up -d --build; then
        print_success "Conteneurs démarrés avec succès"
    else
        print_error "Échec du démarrage des conteneurs"
        print_info "Consultez les logs avec: docker compose logs -f"
        exit 1
    fi

    print_step "Attente du démarrage complet de MariaDB (30 secondes)..."
    sleep 30

    print_step "Vérification de l'état des conteneurs..."
    docker compose ps

    print_success "Déploiement terminé"
}

# ═══════════════════════════════════════════════════════════════════════════
# RÉSUMÉ
# ═══════════════════════════════════════════════════════════════════════════

print_summary() {
    echo ""
    echo -e "${GREEN}═══════════════════════════════════════════════════════════${NC}"
    echo -e "${GREEN}       Bolt.DIY v7.6 installé avec succès !${NC}"
    echo -e "${GREEN}═══════════════════════════════════════════════════════════${NC}"
    echo ""
    echo -e "${CYAN}════════════════════════════════════════════════════════════${NC}"
    echo -e "${CYAN}  INFORMATIONS D'ACCÈS${NC}"
    echo -e "${CYAN}════════════════════════════════════════════════════════════${NC}"
    echo ""
    echo -e "${YELLOW}📍 Accès unique via Nginx:${NC}"
    echo -e "   ${BLUE}http://$LOCAL_IP:$HOST_PORT_HOME${NC}"
    echo ""
    echo -e "${YELLOW}🏠 Page d'accueil:${NC}"
    echo -e "   ${BLUE}http://$LOCAL_IP:$HOST_PORT_HOME/accueil${NC}"
    echo ""
    echo -e "${YELLOW}⚡ Bolt.DIY Application:${NC}"
    echo -e "   ${BLUE}http://$LOCAL_IP:$HOST_PORT_HOME${NC}"
    echo ""
    echo -e "${YELLOW}👥 User Manager:${NC}"
    echo -e "   ${BLUE}http://$LOCAL_IP:$HOST_PORT_HOME/user-manager/public/login.php${NC}"
    echo ""
    echo -e "${CYAN}════════════════════════════════════════════════════════════${NC}"
    echo ""
    echo -e "${YELLOW}🔐 Identifiants Admin:${NC}"
    echo -e "   Username    : ${GREEN}$ADMIN_USERNAME${NC}"
    echo -e "   Email       : ${GREEN}$ADMIN_EMAIL${NC}"
    echo -e "   Mot de passe: ${GREEN}[celui que vous avez défini]${NC}"
    echo ""
    echo -e "${CYAN}════════════════════════════════════════════════════════════${NC}"
    echo -e "${CYAN}  COMMANDES UTILES${NC}"
    echo -e "${CYAN}════════════════════════════════════════════════════════════${NC}"
    echo ""
    echo -e "${YELLOW}📋 Voir les logs:${NC}"
    echo -e "   ${BLUE}cd $PROJECT_ROOT && docker compose logs -f${NC}"
    echo ""
    echo -e "${YELLOW}🔄 Redémarrer:${NC}"
    echo -e "   ${BLUE}cd $PROJECT_ROOT && docker compose restart${NC}"
    echo ""
    echo -e "${YELLOW}🛑 Arrêter:${NC}"
    echo -e "   ${BLUE}cd $PROJECT_ROOT && docker compose down${NC}"
    echo ""
    echo -e "${YELLOW}📥 Mettre à jour depuis GitHub:${NC}"
    echo -e "   ${BLUE}cd $PROJECT_ROOT && git pull${NC}"
    echo ""
    echo -e "${CYAN}════════════════════════════════════════════════════════════${NC}"
    echo ""
    echo -e "${GREEN}✨ Profitez de Bolt.DIY - Nbility Edition v7.6 !${NC}"
    echo ""
}

# ═══════════════════════════════════════════════════════════════════════════
# FONCTION PRINCIPALE
# ═══════════════════════════════════════════════════════════════════════════

main() {
    print_banner
    check_dependencies
    collect_user_inputs
    clone_repository
    create_directories
    generate_env_files
    generate_htpasswd
    configure_sql
    launch_docker
    print_summary
}

# Lancer l'installation
main

