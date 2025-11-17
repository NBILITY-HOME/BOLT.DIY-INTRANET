#!/bin/bash
set -e

# =========================================================================
# TITRE: Bolt.DIY - Nbility Edition - Installation v7.4
# GitHub comme source - Approche optimisée
# =========================================================================

# VARIABLES GLOBALES
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

# Variables d'installation
LOCAL_IP=""
HOST_PORT_HOME=""  # ← UN SEUL PORT MAINTENANT
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

# =========================================================================
# FONCTIONS D'AFFICHAGE
# =========================================================================

print_banner() {
    clear
    echo ""
    echo -e "${CYAN}╔════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║                                                            ║${NC}"
    echo -e "${CYAN}║           🚀 BOLT.DIY - NBILITY EDITION 🚀                ║${NC}"
    echo -e "${CYAN}║                                                            ║${NC}"
    echo -e "${CYAN}╚════════════════════════════════════════════════════════════╝${NC}"
    echo ""
    echo -e "${BLUE}   NBILITY EDITION - Installation v7.4${NC}"
    echo -e "${BLUE}   GitHub comme source - Approche optimisée${NC}"
    echo -e "${CYAN}════════════════════════════════════════════════════════════${NC}"
    echo ""
}

print_section() {
    echo ""
    echo -e "${CYAN}═══════════════════════════════════════════════════════════${NC}"
    echo -e "${CYAN}  $1${NC}"
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

# =========================================================================
# FONCTIONS DE VALIDATION
# =========================================================================

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

# =========================================================================
# VÉRIFICATION DES DÉPENDANCES
# =========================================================================

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

# =========================================================================
# COLLECTE DES INFORMATIONS UTILISATEUR
# =========================================================================

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

    # ★ UN SEUL PORT MAINTENANT ★
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

    # Admin
    echo -n "Utilisateur admin [admin]: "
    read -r ADMIN_USER
    ADMIN_USER="${ADMIN_USER:-admin}"

    echo -n "Mot de passe admin: "
    read -rs ADMIN_PASSWORD
    echo
    while [ -z "$ADMIN_PASSWORD" ]; do
        print_error "Le mot de passe ne peut pas être vide"
        echo -n "Mot de passe admin: "
        read -rs ADMIN_PASSWORD
        echo
    done

    # Hash du mot de passe admin
    ADMIN_PASSWORD_HASH=$(openssl passwd -apr1 "$ADMIN_PASSWORD")

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

# =========================================================================
# CLONAGE DEPUIS GITHUB
# =========================================================================

clone_repository() {
    print_section "CLONAGE DEPUIS GITHUB"

    # Supprimer le dossier existant si présent
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

    # Créer le dossier et cloner
    print_step "Création du dossier projet..."
    mkdir -p "$PROJECT_ROOT"
    print_success "Dossier $PROJECT_ROOT créé"

    print_step "Clonage depuis GitHub..."
    print_info "Repository: $GITHUB_REPO"
    print_info "Destination: $PROJECT_ROOT"

    if git clone "$GITHUB_REPO" "$PROJECT_ROOT"; then
        print_success "Repository cloné avec succès dans $PROJECT_ROOT"
    else
        print_error "Échec du clonage depuis GitHub"
        print_error "Vérifiez votre connexion internet et l'URL du repository"
        exit 1
    fi
}

# =========================================================================
# VÉRIFICATION DE LA STRUCTURE GITHUB
# =========================================================================

verify_github_structure() {
    print_section "VÉRIFICATION DU CONTENU GITHUB"
    local critical_ok=true

    print_step "Vérification de la structure de base..."

    # Vérifier la structure de base
    local required_dirs=(
        "$BOLTDIY_DIR"
        "$DATA_LOCAL_DIR"
        "$USERMANAGER_DIR"
    )

    for dir in "${required_dirs[@]}"; do
        if [ -d "$dir" ]; then
            print_success "Dossier $(basename "$dir") présent"
        else
            print_error "Dossier $(basename "$dir") manquant dans le repository GitHub"
            critical_ok=false
        fi
    done

    # Vérifier docker-compose.yml
    if [ -f "$PROJECT_ROOT/docker-compose.yml" ]; then
        print_success "Fichier docker-compose.yml présent"
    else
        print_error "Fichier docker-compose.yml manquant dans le repository GitHub"
        print_error "Le repository doit contenir docker-compose.yml à la racine"
        critical_ok=false
    fi

    # Vérifier .env.example Bolt.DIY
    if [ -f "$BOLTDIY_DIR/.env.example" ]; then
        print_success "Fichier bolt.diy/.env.example présent"
    else
        print_error "Fichier bolt.diy/.env.example manquant"
        critical_ok=false
    fi

    # Vérifier nginx/html/index.html
    if [ -f "$NGINX_DIR/html/index.html" ]; then
        print_success "Fichier index.html présent"
    else
        print_error "Fichier index.html manquant dans le repository GitHub"
        print_error "Le repository doit contenir DATA-LOCAL/nginx/html/index.html"
        critical_ok=false
    fi

    # Vérifier nginx.conf
    if [ -f "$NGINX_DIR/nginx.conf" ]; then
        print_success "Fichier nginx.conf présent"
    else
        print_error "Fichier nginx.conf manquant dans le repository GitHub"
        print_error "Le repository doit contenir DATA-LOCAL/nginx/nginx.conf"
        critical_ok=false
    fi

    if [ "$critical_ok" = true ]; then
        print_success "Tous les fichiers critiques sont présents"
    else
        print_error "Le clone est incomplet ou le repository est corrompu"
        print_error "Vérifiez que $GITHUB_REPO est à jour"
        exit 1
    fi

    # Vérifier User Manager
    print_step "Vérification détaillée de User Manager..."

    local um_files=(
        "$USERMANAGER_DIR/composer.json"
        "$USERMANAGER_DIR/Dockerfile"
        "$USERMANAGER_DIR/.env.example"
        "$USERMANAGER_DIR/app/database/migrations/01-schema.sql"
        "$USERMANAGER_DIR/app/database/migrations/02-seed.sql"
    )

    for file in "${um_files[@]}"; do
        if [ -f "$file" ]; then
            print_success "$(basename "$file") présent"
        else
            print_warning "$(basename "$file") manquant (optionnel)"
        fi
    done

    # Vérifier les fichiers SQL
    print_step "Vérification des fichiers SQL..."

    if [ -f "$USERMANAGER_DIR/app/database/migrations/01-schema.sql" ]; then
        print_success "01-schema.sql présent"
    else
        print_error "01-schema.sql manquant"
        critical_ok=false
    fi

    if [ -f "$USERMANAGER_DIR/app/database/migrations/02-seed.sql" ]; then
        print_success "02-seed.sql présent"
    else
        print_error "02-seed.sql manquant"
        critical_ok=false
    fi

    if [ "$critical_ok" = false ]; then
        print_error "Des fichiers SQL critiques sont manquants"
        exit 1
    fi

    print_success "Vérification complète réussie"
}

# =========================================================================
# VÉRIFICATION ET CORRECTION DE DOCKER-COMPOSE.YML
# =========================================================================

verify_docker_compose() {
    print_section "VÉRIFICATION DOCKER-COMPOSE.YML"

    print_step "Vérification du fichier docker-compose.yml..."

    local compose_file="$PROJECT_ROOT/docker-compose.yml"

    if [ ! -f "$compose_file" ]; then
        print_error "docker-compose.yml manquant dans le repository GitHub"
        exit 1
    fi

    # Supprimer "version" si présent (obsolète)
    if grep -q "version:" "$compose_file"; then
        print_warning "Suppression de 'version:' (obsolète)..."
        sed -i '/version:/d' "$compose_file"
        print_success "'version:' supprimé"
    fi

    # Vérifier que --legacy-peer-deps est présent pour npm
    if ! grep -q "legacy-peer-deps" "$compose_file"; then
        print_warning "Ajout de --legacy-peer-deps à npm install..."
        sed -i 's/npm install/npm install --legacy-peer-deps/g' "$compose_file"
        print_success "--legacy-peer-deps ajouté"
    fi

    # Vérifier le nom de la base de données
    if grep -q "boltusermanager" "$compose_file"; then
        print_warning "Correction du nom de base de données..."
        sed -i 's/boltusermanager/usermanager/g' "$compose_file"
        print_success "Nom de DB corrigé (usermanager)"
    fi

    print_success "docker-compose.yml vérifié et corrigé"
}

# =========================================================================
# CRÉATION DES DOSSIERS RUNTIME
# =========================================================================

create_directories() {
    print_section "CRÉATION DES DOSSIERS"

    print_step "Création des dossiers MariaDB..."
    mkdir -p "$MARIADB_DIR/data"
    mkdir -p "$MARIADB_DIR/init"
    print_success "Dossiers MariaDB créés"

    print_step "Création des dossiers User Manager..."
    mkdir -p "$USERMANAGER_DIR/app/logs"
    mkdir -p "$USERMANAGER_DIR/app/uploads"
    print_success "Dossiers User Manager créés"

    print_step "Vérification des permissions..."
    chmod -R 755 "$PROJECT_ROOT"
    chmod -R 777 "$USERMANAGER_DIR/app/logs" 2>/dev/null || true
    chmod -R 777 "$USERMANAGER_DIR/app/uploads" 2>/dev/null || true
    chmod -R 777 "$MARIADB_DIR/data" 2>/dev/null || true
    print_success "Permissions configurées"

    print_success "Structure de dossiers créée"
}

# =========================================================================
# GÉNÉRATION .ENV PRINCIPAL
# =========================================================================

generate_main_env() {
    print_section "GÉNÉRATION FICHIERS .ENV"

    print_step "Création du fichier .env principal..."

    cat > "$PROJECT_ROOT/.env" << ENV_MAIN_EOF
# IP et Port
LOCAL_IP=$LOCAL_IP
HOST_PORT_HOME=$HOST_PORT_HOME

# Database
DB_HOST=mariadb
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
ENV_MAIN_EOF

    print_success ".env principal créé"
}

# =========================================================================
# GÉNÉRATION .ENV BOLT.DIY
# =========================================================================

generate_boltdiy_env() {
    print_step "Création du fichier .env Bolt.DIY..."

    # Copier .env.example si disponible
    if [ -f "$BOLTDIY_DIR/.env.example" ]; then
        cp "$BOLTDIY_DIR/.env.example" "$BOLTDIY_DIR/.env"
        print_info ".env créé depuis .env.example"
    else
        touch "$BOLTDIY_DIR/.env"
        print_warning ".env.example non trouvé, création d'un .env vide"
    fi

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
        echo "GOOGLE_GENERATIVE_AI_API_KEY=$GOOGLE_API_KEY" >> "$BOLTDIY_DIR/.env"
    fi

    print_success ".env Bolt.DIY créé"
}

# =========================================================================
# GÉNÉRATION .ENV USER MANAGER
# =========================================================================

generate_usermanager_env() {
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
DB_NAME=usermanager
DB_USER=usermanager
DB_PASSWORD=$MARIADB_USER_PASSWORD

# Logs
LOG_LEVEL=info
LOG_FILE=/var/www/html/logs/app.log
ENV_UM_EOF

    print_success ".env User Manager créé"
}

# =========================================================================
# GÉNÉRATION .HTPASSWD
# =========================================================================

generate_htpasswd() {
    print_section "GÉNÉRATION .HTPASSWD"

    print_step "Création du fichier .htpasswd..."

    # Créer .htpasswd avec htpasswd (compatible nginx)
    htpasswd -cb "$NGINX_DIR/.htpasswd" "$ADMIN_USER" "$ADMIN_PASSWORD"

    print_success ".htpasswd créé avec utilisateur: $ADMIN_USER"
}

# =========================================================================
# CONFIGURATION DES PLACEHOLDERS SQL
# =========================================================================

configure_sql_placeholders() {
    print_section "CONFIGURATION DES FICHIERS SQL"

    local schema_sql="$USERMANAGER_DIR/app/database/migrations/01-schema.sql"
    local seed_sql="$USERMANAGER_DIR/app/database/migrations/02-seed.sql"

    # Vérifier et corriger le nom de la base de données
    if grep -q "boltusermanager" "$MARIADB_DIR/init/01-schema.sql"; then
        print_warning "Correction du nom de DB dans 01-schema.sql..."
        sed -i 's/boltusermanager/usermanager/g' "$MARIADB_DIR/init/01-schema.sql"
    fi

    print_step "Copie de 02-seed.sql vers mariadb/init/..."

    if [ -f "$seed_sql" ]; then
        cp "$seed_sql" "$MARIADB_DIR/init/"

        print_step "Configuration de l'utilisateur admin dans 02-seed.sql..."

        # Échapper les caractères spéciaux dans le hash pour sed
        ESCAPED_HASH=$(echo "$ADMIN_PASSWORD_HASH" | sed 's/\//\\\//g')

        # Remplacer les placeholders
        sed -i "s/ADMIN_USER/$ADMIN_USER/g" "$MARIADB_DIR/init/02-seed.sql"
        sed -i "s/ADMIN_PASSWORD_HASH/$ESCAPED_HASH/g" "$MARIADB_DIR/init/02-seed.sql"

        print_success "02-seed.sql copié et configuré"
    else
        print_error "02-seed.sql manquant dans le repository"
        exit 1
    fi
}

# =========================================================================
# VÉRIFICATION FINALE
# =========================================================================

final_verification() {
    print_section "VÉRIFICATION FINALE"

    print_step "Vérification de la structure..."

    local critical_files=(
        "$PROJECT_ROOT/docker-compose.yml"
        "$PROJECT_ROOT/.env"
        "$NGINX_DIR/nginx.conf"
        "$NGINX_DIR/.htpasswd"
        "$NGINX_DIR/html/index.html"
        "$BOLTDIY_DIR/.env"
        "$USERMANAGER_DIR/.env"
        "$USERMANAGER_DIR/Dockerfile"
        "$MARIADB_DIR/init/01-schema.sql"
        "$MARIADB_DIR/init/02-seed.sql"
    )

    local all_ok=true

    for file in "${critical_files[@]}"; do
        if [ -f "$file" ]; then
            print_success "$(basename "$file") présent"
        else
            print_error "$(basename "$file") manquant"
            all_ok=false
        fi
    done

    # Vrifier les dossiers critiques
    local critical_dirs=(
        "$BOLTDIY_DIR"
        "$NGINX_DIR"
        "$MARIADB_DIR/init"
        "$MARIADB_DIR/data"
        "$USERMANAGER_DIR/app"
    )

    for dir in "${critical_dirs[@]}"; do
        if [ -d "$dir" ]; then
            print_success "$(basename "$dir") présent"
        else
            print_error "$(basename "$dir") manquant"
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

# =========================================================================
# LANCEMENT DES CONTENEURS DOCKER
# =========================================================================

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

    print_step "Attente du démarrage complet (30 secondes)..."
    sleep 30

    print_step "Vérification de l'état des conteneurs..."
    docker compose ps

    print_success "Déploiement terminé"
}

# =========================================================================
# RÉSUMÉ DE L'INSTALLATION
# =========================================================================

print_summary() {
    echo ""
    echo -e "${GREEN}═══════════════════════════════════════════════════════════${NC}"
    echo -e "${GREEN}   Bolt.DIY v7.4 installé avec succès !${NC}"
    echo -e "${GREEN}═══════════════════════════════════════════════════════════${NC}"
    echo ""
    echo -e "${CYAN}════════════════════════════════════════════════════════════${NC}"
    echo -e "${CYAN}             INFORMATIONS D'ACCÈS${NC}"
    echo -e "${CYAN}════════════════════════════════════════════════════════════${NC}"
    echo ""
    echo -e "${YELLOW}📍 Accès unique via Nginx:${NC}"
    echo -e "   ${BLUE}http://$LOCAL_IP:$HOST_PORT_HOME${NC}"
    echo ""
    echo -e "${YELLOW}🏠 Page d'accueil:${NC}"
    echo -e "   ${BLUE}http://$LOCAL_IP:$HOST_PORT_HOME/${NC}"
    echo ""
    echo -e "${YELLOW}⚡ Bolt.DIY Application:${NC}"
    echo -e "   ${BLUE}http://$LOCAL_IP:$HOST_PORT_HOME/bolt${NC}"
    echo ""
    echo -e "${YELLOW}👥 User Manager:${NC}"
    echo -e "   ${BLUE}http://$LOCAL_IP:$HOST_PORT_HOME/user-manager${NC}"
    echo ""
    echo -e "${CYAN}════════════════════════════════════════════════════════════${NC}"
    echo ""
    echo -e "${YELLOW}🔐 Identifiants Admin:${NC}"
    echo -e "   Utilisateur: ${GREEN}$ADMIN_USER${NC}"
    echo -e "   Mot de passe: ${GREEN}[celui que vous avez défini]${NC}"
    echo ""
    echo -e "${CYAN}════════════════════════════════════════════════════════════${NC}"
    echo -e "${CYAN}             COMMANDES UTILES${NC}"
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
    echo -e "${GREEN}✨ Profitez de Bolt.DIY - Nbility Edition !${NC}"
    echo ""
}

# =========================================================================
# FONCTION PRINCIPALE
# =========================================================================

main() {
    print_banner
    check_dependencies
    collect_user_inputs
    clone_repository
    verify_github_structure
    verify_docker_compose
    create_directories
    generate_main_env
    generate_boltdiy_env
    generate_usermanager_env
    generate_htpasswd
    configure_sql_placeholders
    final_verification
    launch_docker
    print_summary
}

# Lancer l'installation
main
