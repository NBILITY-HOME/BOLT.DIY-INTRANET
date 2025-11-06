#!/bin/bash
#═══════════════════════════════════════════════════════════════════════════
# BOLT.DIY NBILITY - Installation Script v3.0
# Script d'installation avec authentification GitHub
# © Copyright Nbility 2025 - contact@nbility.fr
#═══════════════════════════════════════════════════════════════════════════

clear
printf "\\033[8;55;116t"
set -e

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
LOCK="🔐"

# Chemins et configuration
SCRIPT_DIR=$(pwd)
CREDENTIALS_FILE="$SCRIPT_DIR/.github_credentials"
REPO_URL="https://github.com/NBILITY-HOME/BOLT.DIY-DOCKER-LOCAL.git"
REPO_NAME="BOLT.DIY-DOCKER-LOCAL"
REPO_DIR="$SCRIPT_DIR/$REPO_NAME"
DATA_SOURCE="$REPO_DIR/DATA-LOCAL"
DATA_DEST="$SCRIPT_DIR/DATA"

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
    echo "              ║                                                                       ║"
    echo "              ╚═══════════════════════════════════════════════════════════════════════╝"
    echo -e "${NC}"
    echo -e "${MAGENTA}${BOLD}                                    Installation Interactive v3.0${NC}"
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
# GESTION DE L'AUTHENTIFICATION GITHUB
# ═══════════════════════════════════════════════════════════════════════════

# Chiffrer une chaîne en SHA-256
hash_sha256() {
    echo -n "$1" | sha256sum | awk '{print $1}'
}

# Encoder en Base64
encode_base64() {
    echo -n "$1" | base64 -w 0
}

# Décoder depuis Base64
decode_base64() {
    echo -n "$1" | base64 -d
}

# Sauvegarder les credentials
save_credentials() {
    local username="$1"
    local token="$2"
    
    local user_hash=$(hash_sha256 "$username")
    local token_hash=$(hash_sha256 "$token")
    local user_encoded=$(encode_base64 "$username")
    local token_encoded=$(encode_base64 "$token")
    
    cat > "$CREDENTIALS_FILE" << EOF
# Credentials GitHub pour BOLT.DIY-DOCKER-LOCAL
# Généré le $(date)
GITHUB_USER_HASH=$user_hash
GITHUB_TOKEN_HASH=$token_hash
GITHUB_USER_ENCRYPTED=$user_encoded
GITHUB_TOKEN_ENCRYPTED=$token_encoded
EOF
    
    chmod 600 "$CREDENTIALS_FILE"
    print_success "Credentials sauvegardés de manière sécurisée"
}

# Charger les credentials
load_credentials() {
    if [ ! -f "$CREDENTIALS_FILE" ]; then
        return 1
    fi
    
    source "$CREDENTIALS_FILE"
    
    GITHUB_USER=$(decode_base64 "$GITHUB_USER_ENCRYPTED")
    GITHUB_TOKEN=$(decode_base64 "$GITHUB_TOKEN_ENCRYPTED")
    
    # Vérification de l'intégrité
    local user_check=$(hash_sha256 "$GITHUB_USER")
    local token_check=$(hash_sha256 "$GITHUB_TOKEN")
    
    if [ "$user_check" != "$GITHUB_USER_HASH" ] || [ "$token_check" != "$GITHUB_TOKEN_HASH" ]; then
        print_error "Intégrité des credentials compromise"
        rm -f "$CREDENTIALS_FILE"
        return 1
    fi
    
    return 0
}

# Tester la connexion au repository
test_github_connection() {
    local username="$1"
    local token="$2"
    
    # Test avec git ls-remote
    if git ls-remote "https://${username}:${token}@github.com/NBILITY-HOME/BOLT.DIY-DOCKER-LOCAL.git" &>/dev/null; then
        return 0
    else
        return 1
    fi
}

# Demander les credentials
prompt_credentials() {
    print_section "AUTHENTIFICATION GITHUB"
    echo -e "${CYAN}╭─────────────────────────────────────────────────────────────────╮${NC}"
    echo -e "${CYAN}│${NC} ${WHITE}${BOLD}Connexion au repository privé BOLT.DIY-DOCKER-LOCAL${NC}"
    echo -e "${CYAN}╰─────────────────────────────────────────────────────────────────╯${NC}"
    echo ""
    echo -e "${YELLOW}Le repository est privé et nécessite une authentification.${NC}"
    echo -e "${YELLOW}Vous pouvez utiliser :${NC}"
    echo -e "${CYAN}  1.${NC} Votre username GitHub + Personal Access Token (recommandé)"
    echo -e "${CYAN}  2.${NC} Votre username GitHub + Password (si 2FA désactivé)"
    echo ""
    echo -e "${CYAN}${ARROW}${NC} Pour créer un Personal Access Token :"
    echo -e "    https://github.com/settings/tokens"
    echo -e "    ${YELLOW}(Permissions requises: repo)${NC}"
    echo ""
    
    read -p "Nom d'utilisateur GitHub: " GITHUB_USER
    read -sp "Token ou Mot de passe: " GITHUB_TOKEN
    echo ""
    
    if [ -z "$GITHUB_USER" ] || [ -z "$GITHUB_TOKEN" ]; then
        print_error "Les credentials ne peuvent pas être vides"
        exit 1
    fi
}

# Gérer l'authentification GitHub
handle_github_authentication() {
    print_banner
    print_section "${LOCK} AUTHENTIFICATION GITHUB"
    
    # Essayer de charger les credentials existants
    print_step "Recherche de credentials sauvegardés..."
    if load_credentials; then
        print_success "Credentials trouvés"
        print_step "Test de la connexion au repository..."
        
        if test_github_connection "$GITHUB_USER" "$GITHUB_TOKEN"; then
            print_success "Connexion au repository réussie"
            return 0
        else
            print_warning "Les credentials sauvegardés ne fonctionnent plus"
            rm -f "$CREDENTIALS_FILE"
        fi
    else
        print_info "Aucun credentials sauvegardé trouvé"
    fi
    
    # Demander de nouveaux credentials
    echo ""
    prompt_credentials
    
    print_step "Test de la connexion..."
    if test_github_connection "$GITHUB_USER" "$GITHUB_TOKEN"; then
        print_success "Authentification réussie"
        save_credentials "$GITHUB_USER" "$GITHUB_TOKEN"
        return 0
    else
        print_error "Échec de l'authentification"
        print_error "Vérifiez vos identifiants et réessayez"
        exit 1
    fi
}

# ═══════════════════════════════════════════════════════════════════════════
# RÉCUPÉRATION DU REPOSITORY
# ═══════════════════════════════════════════════════════════════════════════

clone_or_update_repository() {
    print_section "RÉCUPÉRATION DES FICHIERS DE CONFIGURATION"
    
    local auth_url="https://${GITHUB_USER}:${GITHUB_TOKEN}@github.com/NBILITY-HOME/BOLT.DIY-DOCKER-LOCAL.git"
    
    if [ -d "$REPO_DIR/.git" ]; then
        print_step "Repository existant trouvé - Mise à jour..."
        cd "$REPO_DIR"
        git remote set-url origin "$auth_url" &>/dev/null
        git fetch --all &>/dev/null
        git reset --hard origin/main &>/dev/null
        git pull origin main &>/dev/null
        print_success "Repository mis à jour"
    else
        print_step "Clonage du repository..."
        git clone "$auth_url" "$REPO_DIR" &>/dev/null
        print_success "Repository cloné"
    fi
    
    cd "$SCRIPT_DIR"
    
    # Vérifier que DATA-LOCAL existe
    if [ ! -d "$DATA_SOURCE" ]; then
        print_error "Le dossier DATA-LOCAL est introuvable dans le repository"
        print_error "Chemin attendu: $DATA_SOURCE"
        exit 1
    fi
    
    print_success "Fichiers de configuration récupérés"
}

# Copier les fichiers depuis le repository
copy_configuration_files() {
    print_section "COPIE DES FICHIERS DE CONFIGURATION"
    
    print_step "Création de la structure locale..."
    mkdir -p "$DATA_DEST/nginx/html"
    mkdir -p "$DATA_DEST/templates"
    mkdir -p "$DATA_DEST/user-manager/app"
    mkdir -p "$DATA_DEST/htpasswd-manager"
    print_success "Structure créée"
    
    print_step "Copie des fichiers..."
    
    # Copier docker-compose.yml
    if [ -f "$DATA_SOURCE/docker-compose.yml" ]; then
        cp "$DATA_SOURCE/docker-compose.yml" "$SCRIPT_DIR/docker-compose.yml"
        print_info "  ✓ docker-compose.yml"
    else
        print_error "Fichier manquant: docker-compose.yml"
        exit 1
    fi
    
    # Copier Dockerfile
    if [ -f "$DATA_SOURCE/Dockerfile" ]; then
        cp "$DATA_SOURCE/Dockerfile" "$DATA_DEST/Dockerfile"
        print_info "  ✓ Dockerfile"
    else
        print_error "Fichier manquant: Dockerfile"
        exit 1
    fi
    
    # Copier nginx.conf
    if [ -f "$DATA_SOURCE/nginx/nginx.conf" ]; then
        cp "$DATA_SOURCE/nginx/nginx.conf" "$DATA_DEST/nginx/nginx.conf"
        print_info "  ✓ nginx/nginx.conf"
    else
        print_error "Fichier manquant: nginx/nginx.conf"
        exit 1
    fi
    
    # Copier les templates
    if [ -d "$DATA_SOURCE/templates" ]; then
        cp -r "$DATA_SOURCE/templates"/* "$DATA_DEST/templates/"
        print_info "  ✓ templates/*"
    else
        print_error "Dossier manquant: templates"
        exit 1
    fi
    
    # Copier user-manager
    if [ -f "$DATA_SOURCE/user-manager/app/index.php" ]; then
        cp "$DATA_SOURCE/user-manager/app/index.php" "$DATA_DEST/user-manager/app/index.php"
        print_info "  ✓ user-manager/app/index.php"
    else
        print_error "Fichier manquant: user-manager/app/index.php"
        exit 1
    fi
    
    print_success "Tous les fichiers copiés avec succès"
}

# ═══════════════════════════════════════════════════════════════════════════
# VÉRIFICATION DES PRÉ-REQUIS
# ═══════════════════════════════════════════════════════════════════════════

check_prerequisites() {
    print_banner
    print_section "VÉRIFICATION DES PRÉ-REQUIS SYSTÈME"
    local all_ok=true
    
    print_step "Vérification de Docker..."
    if command -v docker &> /dev/null; then
        DOCKER_VERSION=$(docker --version | cut -d ' ' -f3 | cut -d ',' -f1)
        print_success "Docker $DOCKER_VERSION installé"
    else
        print_error "Docker n'est pas installé"
        all_ok=false
    fi
    
    print_step "Vérification de Docker Compose..."
    if command -v docker compose &> /dev/null || command -v docker-compose &> /dev/null; then
        print_success "Docker Compose disponible"
    else
        print_error "Docker Compose n'est pas installé"
        all_ok=false
    fi
    
    print_step "Vérification de Git..."
    if command -v git &> /dev/null; then
        GIT_VERSION=$(git --version | cut -d ' ' -f3)
        print_success "Git $GIT_VERSION installé"
    else
        print_error "Git n'est pas installé"
        all_ok=false
    fi
    
    print_step "Vérification de htpasswd..."
    if command -v htpasswd &> /dev/null; then
        print_success "htpasswd disponible"
    else
        print_warning "htpasswd non trouvé - Installation automatique..."
        sudo apt-get update -qq && sudo apt-get install -y apache2-utils -qq
        if command -v htpasswd &> /dev/null; then
            print_success "htpasswd installé avec succès"
        else
            print_error "Impossible d'installer htpasswd"
            all_ok=false
        fi
    fi
    
    print_step "Vérification de la connectivité réseau..."
    if ping -c 1 -w 5 github.com &> /dev/null; then
        print_success "Connexion Internet OK"
    else
        print_error "Impossible de joindre GitHub"
        all_ok=false
    fi
    
    print_step "Vérification de l'espace disque..."
    AVAILABLE_SPACE=$(df -BG . | tail -1 | awk '{print $4}' | sed 's/G//')
    if [ "$AVAILABLE_SPACE" -gt 5 ]; then
        print_success "Espace disque suffisant - ${AVAILABLE_SPACE}GB disponible"
    else
        print_warning "Espace disque limité - ${AVAILABLE_SPACE}GB disponible"
    fi
    
    echo ""
    if [ "$all_ok" = false ]; then
        print_error "Certains pré-requis ne sont pas satisfaits"
        echo ""
        read -p "Voulez-vous continuer malgré tout ? (o/N) " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Oo]$ ]]; then
            exit 1
        fi
    else
        print_success "Tous les pré-requis sont satisfaits"
    fi
    
    echo ""
    echo -e "${GREEN}${BOLD}Appuyez sur ENTRÉE pour continuer...${NC}"
    read
}

# ═══════════════════════════════════════════════════════════════════════════
# CONFIGURATION UTILISATEUR
# ═══════════════════════════════════════════════════════════════════════════

get_configuration() {
    print_banner
    print_section "CONFIGURATION RÉSEAU"
    
    echo -e "${CYAN}╭─────────────────────────────────────────────────────────────────╮${NC}"
    echo -e "${CYAN}│${NC} ${WHITE}${BOLD}Adresse IP locale du serveur${NC}"
    echo -e "${CYAN}╰─────────────────────────────────────────────────────────────────╯${NC}"
    echo -e "${CYAN}${ARROW}${NC} Exemple: 192.168.1.200"
    read -p "IP locale [192.168.1.200]: " LOCAL_IP
    LOCAL_IP=${LOCAL_IP:-192.168.1.200}
    print_success "IP locale définie: $LOCAL_IP"
    echo ""
    
    echo -e "${CYAN}╭─────────────────────────────────────────────────────────────────╮${NC}"
    echo -e "${CYAN}│${NC} ${WHITE}${BOLD}Adresse IP de la passerelle - Gateway${NC}"
    echo -e "${CYAN}╰─────────────────────────────────────────────────────────────────╯${NC}"
    echo -e "${CYAN}${ARROW}${NC} Exemple: 192.168.1.254"
    read -p "Gateway [192.168.1.254]: " GATEWAY_IP
    GATEWAY_IP=${GATEWAY_IP:-192.168.1.254}
    print_success "Gateway défini: $GATEWAY_IP"
    echo ""
    
    print_section "CONFIGURATION DES PORTS"
    
    echo -e "${CYAN}╭─────────────────────────────────────────────────────────────────╮${NC}"
    echo -e "${CYAN}│${NC} ${WHITE}${BOLD}Port HTTP pour l'accès page Bolt.DIY${NC}"
    echo -e "${CYAN}╰─────────────────────────────────────────────────────────────────╯${NC}"
    read -p "Port HTTP [8080]: " HOST_PORT_HTTP
    HOST_PORT_HTTP=${HOST_PORT_HTTP:-8080}
    print_success "Port HTTP: $HOST_PORT_HTTP"
    echo ""
    
    echo -e "${CYAN}╭─────────────────────────────────────────────────────────────────╮${NC}"
    echo -e "${CYAN}│${NC} ${WHITE}${BOLD}Port HTTPS pour Bolt.DIY${NC}"
    echo -e "${CYAN}╰─────────────────────────────────────────────────────────────────╯${NC}"
    read -p "Port HTTPS [8443]: " HTTPS_HOST_PORT
    HTTPS_HOST_PORT=${HTTPS_HOST_PORT:-8443}
    print_success "Port HTTPS: $HTTPS_HOST_PORT"
    echo ""
    
    echo -e "${CYAN}╭─────────────────────────────────────────────────────────────────╮${NC}"
    echo -e "${CYAN}│${NC} ${WHITE}${BOLD}Port pour le User Manager${NC}"
    echo -e "${CYAN}╰─────────────────────────────────────────────────────────────────╯${NC}"
    read -p "Port User Manager [8081]: " HOST_PORT_UM
    HOST_PORT_UM=${HOST_PORT_UM:-8081}
    print_success "Port User Manager: $HOST_PORT_UM"
    echo ""
    
    print_section "AUTHENTIFICATION NGINX"
    
    echo -e "${CYAN}╭─────────────────────────────────────────────────────────────────╮${NC}"
    echo -e "${CYAN}│${NC} ${WHITE}${BOLD}Identifiants pour l'accès à Bolt.DIY${NC}"
    echo -e "${CYAN}╰─────────────────────────────────────────────────────────────────╯${NC}"
    read -p "Nom d'utilisateur [christophe]: " NGX_USER
    NGX_USER=${NGX_USER:-christophe}
    read -sp "Mot de passe: " NGX_PASS
    echo ""
    
    if [ -z "$NGX_PASS" ]; then
        print_error "Le mot de passe ne peut pas être vide"
        exit 1
    fi
    
    print_success "Authentification configurée pour: $NGX_USER"
    echo ""
    
    print_section "CLÉS API - optionnelles"
    
    echo -e "${CYAN}╭─────────────────────────────────────────────────────────────────╮${NC}"
    echo -e "${CYAN}│${NC} ${WHITE}${BOLD}Configuration des clés API pour les modèles d'IA${NC}"
    echo -e "${CYAN}╰─────────────────────────────────────────────────────────────────╯${NC}"
    echo -e "${YELLOW}Vous pouvez laisser vide et configurer plus tard dans le .env${NC}"
    echo ""
    
    read -p "1. OpenAI - GPT-4 GPT-3.5: " OPENAI_KEY
    read -p "2. Anthropic - Claude: " ANTHROPIC_KEY
    read -p "3. Google Gemini: " GEMINI_KEY
    read -p "4. Groq: " GROQ_KEY
    read -p "5. Azure OpenAI: " AZURE_KEY
    read -p "6. Cohere: " COHERE_KEY
    read -p "7. HuggingFace: " HF_KEY
    read -p "8. Mistral: " MISTRAL_KEY
    read -p "9. Mirexa: " MIREXA_KEY
    read -p "10. DeepSeek: " DEEPSEEK_KEY
    
    echo ""
    print_success "Configuration terminée"
    echo ""
    echo -e "${GREEN}${BOLD}Appuyez sur ENTRÉE pour démarrer l'installation...${NC}"
    read
}

# ═══════════════════════════════════════════════════════════════════════════
# GÉNÉRATION DES PAGES HTML
# ═══════════════════════════════════════════════════════════════════════════

generate_html_from_templates() {
    local template_file="$1"
    local output_file="$2"
    local description="$3"
    
    print_step "Génération de la $description..."
    
    if [ ! -f "$template_file" ]; then
        print_error "Template introuvable: $template_file"
        return 1
    fi
    
    # Déterminer le protocole
    local protocol="http"
    if [ "$HTTPS_HOST_PORT" != "8443" ]; then
        protocol="https"
    fi
    
    # Remplacer les placeholders
    sed -e "s|{{LOCAL_IP}}|$LOCAL_IP|g" \
        -e "s|{{HOST_PORT_HTTP}}|$HOST_PORT_HTTP|g" \
        -e "s|{{HOST_PORT_UM}}|$HOST_PORT_UM|g" \
        -e "s|{{PROTOCOL}}|$protocol|g" \
        "$template_file" > "$output_file"
    
    print_success "$description générée"
    return 0
}

# ═══════════════════════════════════════════════════════════════════════════
# INSTALLATION PRINCIPALE
# ═══════════════════════════════════════════════════════════════════════════

install_bolt() {
    HTPASSWD_FILE="$DATA_DEST/nginx/.htpasswd"
    BOLT_REPO_URL="https://github.com/stackblitz-labs/bolt.diy"
    BOLT_DIR="$SCRIPT_DIR/bolt.diy"
    NETWORK_NAME="bolt-network-app"
    VOLUME_DATA="bolt-nbility-data"
    VOLUME_NGINX_CONF="bolt-nbility-nginx-conf"
    
    print_banner
    print_section "INSTALLATION DE BOLT.DIY NBILITY"
    
    print_step "Création des répertoires manquants..."
    mkdir -p "$BOLT_DIR"
    mkdir -p "$DATA_DEST/nginx/html"
    print_success "Répertoires créés"
    
    print_step "Récupération du code source Bolt.DIY..."
    if [ -d "$BOLT_DIR/.git" ]; then
        cd "$BOLT_DIR"
        git fetch --all &> /dev/null
        git checkout main &> /dev/null
        git pull origin main &> /dev/null
        print_success "Dépôt mis à jour"
    else
        git clone -b main "$BOLT_REPO_URL" "$BOLT_DIR" &> /dev/null
        print_success "Dépôt cloné"
    fi
    cd "$SCRIPT_DIR"
    
    print_step "Configuration du fichier .env..."
    cat > "$BOLT_DIR/.env" << ENVFILE
BASE_URL=http://$LOCAL_IP:$HOST_PORT_HTTP/
OPENAI_KEY="$OPENAI_KEY"
ANTHROPIC_KEY="$ANTHROPIC_KEY"
GEMINI_KEY="$GEMINI_KEY"
GROQ_KEY="$GROQ_KEY"
AZURE_KEY="$AZURE_KEY"
COHERE_KEY="$COHERE_KEY"
HF_KEY="$HF_KEY"
MISTRAL_KEY="$MISTRAL_KEY"
MIREXA_KEY="$MIREXA_KEY"
DEEPSEEK_KEY="$DEEPSEEK_KEY"
ENVFILE
    print_success "Fichier .env configuré"
    
    # Génération des pages HTML depuis les templates
    print_section "GÉNÉRATION DES PAGES HTML"
    
    # Générer index.html depuis le template normal
    generate_html_from_templates \
        "$DATA_DEST/templates/index.html" \
        "$DATA_DEST/nginx/html/index.html" \
        "page d'accueil"
    
    # Générer 404.html si le template existe
    if [ -f "$DATA_DEST/templates/404.html" ]; then
        generate_html_from_templates \
            "$DATA_DEST/templates/404.html" \
            "$DATA_DEST/nginx/html/404.html" \
            "page d'erreur"
    fi
    
    # Copier également le template de maintenance pour usage futur
    if [ -f "$DATA_DEST/templates/index-maintenance.html" ]; then
        cp "$DATA_DEST/templates/index-maintenance.html" "$DATA_DEST/nginx/html/index-maintenance-backup.html"
        print_info "Template de maintenance sauvegardé pour usage futur"
    fi
    
    print_success "Pages HTML générées avec les bons paramètres"
    
    print_step "Configuration du réseau Docker..."
    docker network create "$NETWORK_NAME" 2>/dev/null || print_info "Réseau existant"
    print_success "Réseau Docker prêt"
    
    print_step "Configuration des volumes Docker..."
    docker volume create "$VOLUME_DATA" 2>/dev/null || print_info "Volume data existant"
    docker volume create "$VOLUME_NGINX_CONF" 2>/dev/null || print_info "Volume nginx existant"
    print_success "Volumes Docker prêts"
    
    print_step "Génération du fichier htpasswd..."
    htpasswd -cb "$HTPASSWD_FILE" "$NGX_USER" "$NGX_PASS" &> /dev/null
    print_success "Authentification configurée"
    
    print_step "Téléchargement de l'image officielle Bolt.DIY..."
    print_info "Test de connectivité au projet Bolt.DIY..."
    if ! curl -s -o /dev/null "https://ghcr.io"; then
        print_error "Impossible de joindre le dépôt Bolt.DIY"
        print_error "Veuillez vérifier votre connexion Internet et réessayer."
        exit 1
    fi
    print_success "Connexion au dépôt Bolt.DIY réussie"
    
    print_step "Téléchargement de l'image Bolt.DIY..."
    docker pull ghcr.io/stackblitz-labs/bolt.diy:latest &> /dev/null
    print_success "Image téléchargée"
    
    print_step "Construction de l'image User Manager..."
    docker build --network host -t bolt-user-manager:latest -f "$DATA_DEST/Dockerfile" "$DATA_DEST" &> /dev/null
    print_success "Image User Manager construite"
    
    echo ""
    print_step "Application des droits d'écriture au fichier .htpasswd..."
    sudo chmod 666 "$HTPASSWD_FILE"
    print_success "Droits d'écriture appliqués"
    echo ""
    
    export LOCAL_IP
    export HOST_PORT_HTTP
    export HTTPS_HOST_PORT
    export HOST_PORT_UM
    export HTPASSWD_FILE
    
    print_step "Démarrage des services Docker..."
    docker compose up -d &> /dev/null
    print_success "Services démarrés"
    
    print_step "Attente du démarrage complet - 30 secondes..."
    local count=0
    while [ $count -lt 30 ]; do
        count=$((count + 1))
        printf "\r  Chargement... [%d/30]" "$count"
        sleep 1
    done
    echo ""
    print_success "Démarrage terminé"
    echo ""
    
    print_section "INSTALLATION TERMINÉE AVEC SUCCÈS"
    
    echo -e "${WHITE}${BOLD}URLs d'accès :${NC}"
    echo -e "  ${CYAN}${ARROW}${NC} Bolt.DIY         : ${GREEN}http://$LOCAL_IP:$HOST_PORT_HTTP${NC}"
    echo -e "  ${CYAN}${ARROW}${NC} User Manager     : ${GREEN}http://$LOCAL_IP:$HOST_PORT_UM${NC}"
    echo ""
    
    echo -e "${WHITE}${BOLD}Identifiants :${NC}"
    echo -e "  ${CYAN}${ARROW}${NC} Utilisateur      : ${GREEN}$NGX_USER${NC}"
    echo -e "  ${CYAN}${ARROW}${NC} Mot de passe     : ${GREEN}********${NC}"
    echo ""
    
    echo -e "${WHITE}${BOLD}Prochaines étapes :${NC}"
    echo -e "  ${CYAN}1.${NC} Accédez à Bolt.DIY via votre navigateur"
    echo -e "  ${CYAN}2.${NC} Configurez vos clés API dans bolt.diy/.env si nécessaire"
    echo -e "  ${CYAN}3.${NC} Consultez les logs : ${YELLOW}docker logs -f bolt-nbility-core${NC}"
    echo ""
    
    echo -e "${CYAN}${STAR}${NC} ${YELLOW}Les pages HTML ont été générées avec vos ports personnalisés${NC}"
    echo -e "${CYAN}${STAR}${NC} ${YELLOW}Pour basculer en mode maintenance :${NC}"
    echo -e "    ${CYAN}cp DATA/nginx/html/index-maintenance-backup.html DATA/nginx/html/index.html${NC}"
    echo -e "    ${CYAN}docker compose restart bolt-nbility-nginx${NC}"
    echo ""
    
    echo -e "${CYAN}═══════════════════════════════════════════════════════════════════════${NC}"
    echo ""
}

# ═══════════════════════════════════════════════════════════════════════════
# FONCTION PRINCIPALE
# ═══════════════════════════════════════════════════════════════════════════

main() {
    # 1. Vérifier les pré-requis système
    check_prerequisites
    
    # 2. Gérer l'authentification GitHub
    handle_github_authentication
    
    # 3. Cloner ou mettre à jour le repository
    clone_or_update_repository
    
    # 4. Copier les fichiers de configuration
    copy_configuration_files
    
    # 5. Obtenir la configuration utilisateur
    get_configuration
    
    # 6. Installer Bolt.DIY
    install_bolt
}

# Lancement du script
main
