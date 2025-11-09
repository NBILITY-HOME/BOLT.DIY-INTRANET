#!/bin/bash
#═══════════════════════════════════════════════════════════════════════════
# BOLT.DIY NBILITY - Installation Script v4.6
# Clone complet depuis GitHub repository + Fix Wrangler PATH + Functions
# © Copyright Nbility 2025 - contact@nbility.fr
#═══════════════════════════════════════════════════════════════════════════

clear
printf "\\033[8;55;116t"

# ═══════════════════════════════════════════════════════════════════════════
# VÉRIFICATION SUDO
# ═══════════════════════════════════════════════════════════════════════════

if [ "$EUID" -en 0 ]; then 
    echo -e "\033[0;31m✗ ERREUR: Ce script NE DOIT PAS être lancé en sudo/root\033[0m"
    echo ""
    echo "Raison: Docker et les fichiers doivent appartenir à votre utilisateur"
    echo ""
    echo "Solution: Lancez le script sans sudo:"
    echo "  ./install_bolt_nbility_v4_6.sh"
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
TEMPLATES_DIR="$DATA_DIR/templates"
HTPASSWD_FILE="$NGINX_DIR/.htpasswd"
BOLT_DIR="$INSTALL_DIR/bolt.diy"
NETWORK_NAME="bolt-network-app"
VOLUME_DATA="bolt-nbility-data"
VOLUME_NGINX_CONF="bolt-nbility-nginx-conf"

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
    echo "              ║                                                                       ║"
    echo "              ╚═══════════════════════════════════════════════════════════════════════╝"
    echo -e "${NC}"
    echo -e "${MAGENTA}${BOLD}                                    Installation Interactive v4.6${NC}"
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
# VÉRIFICATIONS PRÉALABLES
# ═══════════════════════════════════════════════════════════════════════════

check_internet_and_github() {
    print_banner
    print_section "VÉRIFICATION DE LA CONNEXION RÉSEAU"
    
    print_step "Test de connexion Internet..."
    if ping -c 1 8.8.8.8 &> /dev/null; then
        print_success "Connexion Internet active"
    else
        print_error "Pas de connexion Internet"
        exit 1
    fi
    
    print_step "Test d'accès à GitHub..."
    if ping -c 1 github.com &> /dev/null; then
        print_success "GitHub accessible"
    else
        print_error "GitHub inaccessible"
        exit 1
    fi
    
    echo ""
    echo -e "${GREEN}${BOLD}Appuyez sur ENTRÉE pour continuer...${NC}"
    read
}

check_prerequisites() {
    print_banner
    print_section "VÉRIFICATION DES PRÉ-REQUIS"
    
    local all_ok=true
    
    print_step "Vérification de Docker..."
    if command -v docker &> /dev/null; then
        local docker_version=$(docker --version | cut -d ' ' -f3 | cut -d ',' -f1)
        print_success "Docker $docker_version installé"
    else
        print_error "Docker n'est pas installé"
        all_ok=false
    fi
    
    print_step "Vérification de Docker Compose..."
    if command -v docker compose &> /dev/null; then
        local compose_version=$(docker compose version | cut -d ' ' -f4)
        print_success "Docker Compose $compose_version installé"
    else
        print_error "Docker Compose n'est pas installé"
        all_ok=false
    fi
    
    print_step "Vérification de Git..."
    if command -v git &> /dev/null; then
        local git_version=$(git --version | cut -d ' ' -f3)
        print_success "Git $git_version installé"
    else
        print_error "Git n'est pas installé"
        all_ok=false
    fi
    
    print_step "Vérification de htpasswd..."
    if command -v htpasswd &> /dev/null; then
        print_success "htpasswd installé"
    else
        print_error "htpasswd n'est pas installé (paquet apache2-utils)"
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
# CLONAGE DU REPOSITORY
# ═══════════════════════════════════════════════════════════════════════════

clone_repository() {
    print_banner
    print_section "RÉCUPÉRATION DU PROJET DEPUIS GITHUB"
    
    if [ -d "$INSTALL_DIR/.git" ]; then
        print_step "Repository existant trouvé - Mise à jour..."
        cd "$INSTALL_DIR"
        git fetch --all &>/dev/null
        git reset --hard origin/main &>/dev/null
        git pull origin main &>/dev/null
        print_success "Repository mis à jour"
    else
        print_step "Clonage du repository complet..."
        print_info "Ceci peut prendre quelques minutes..."
        git clone "$REPO_URL" "$INSTALL_DIR" &>/dev/null
        print_success "Repository cloné"
    fi
    
    cd "$INSTALL_DIR"
    
    # Vérifications de la structure
    print_step "Vérification de la structure du projet..."
    
    if [ ! -f "docker-compose.yml" ]; then
        print_error "Fichier manquant: docker-compose.yml"
        exit 1
    fi
    
    if [ ! -d "DATA-LOCAL" ]; then
        print_error "Dossier manquant: DATA-LOCAL"
        print_info "Structure trouvée: $(ls -1)"
        exit 1
    fi
    
    if [ ! -d "bolt.diy" ]; then
        print_error "Dossier manquant: bolt.diy"
        exit 1
    fi
    
    if [ ! -f "DATA-LOCAL/nginx/nginx.conf" ]; then
        print_error "Fichier manquant: DATA-LOCAL/nginx/nginx.conf"
        exit 1
    fi
    
    print_success "Structure du projet validée"
    
    # CORRECTION CRITIQUE : Remplacer ./DATA/ par ./DATA-LOCAL/ dans docker-compose.yml
    print_step "Correction des chemins dans docker-compose.yml..."
    sed -i 's|./DATA/|./DATA-LOCAL/|g' docker-compose.yml
    print_success "Chemins corrigés (DATA → DATA-LOCAL)"
    
    echo ""
    print_success "Projet récupéré avec succès"
    echo ""
    echo -e "${GREEN}${BOLD}Appuyez sur ENTRÉE pour continuer...${NC}"
    read
}

# ═══════════════════════════════════════════════════════════════════════════
# CORRECTION DU DOCKERFILE BOLT.DIY ET DOCKER-COMPOSE
# ═══════════════════════════════════════════════════════════════════════════

fix_bolt_dockerfile() {
    print_banner
    print_section "APPLICATION DU FIX DOCKERFILE COMPLET"
    
    print_step "Vérification du template Dockerfile..."
    
    local TEMPLATE_DOCKERFILE="$TEMPLATES_DIR/bolt.diy/Dockerfile"
    
    if [ ! -f "$TEMPLATE_DOCKERFILE" ]; then
        print_error "Template Dockerfile non trouvé: $TEMPLATE_DOCKERFILE"
        exit 1
    fi
    
    print_success "Template Dockerfile trouvé"
    
    print_step "Sauvegarde du Dockerfile original de bolt.diy..."
    if [ -f "$BOLT_DIR/Dockerfile" ]; then
        cp "$BOLT_DIR/Dockerfile" "$BOLT_DIR/Dockerfile.original"
        print_success "Sauvegarde créée: Dockerfile.original"
    fi
    
    print_step "Copie du Dockerfile corrigé depuis le template..."
    cp "$TEMPLATE_DOCKERFILE" "$BOLT_DIR/Dockerfile"
    print_success "Dockerfile corrigé copié vers bolt.diy/"
    
    print_step "Vérification du contenu du Dockerfile..."
    if grep -q 'COPY --from=build /app/functions /app/functions' "$BOLT_DIR/Dockerfile"; then
        print_success "Le Dockerfile contient le fix complet (PATH + functions)"
    else
        print_warning "Le Dockerfile pourrait ne pas contenir tous les fix"
    fi
    
    print_step "Vérification du docker-compose.yml..."
    
    if [ ! -f "$INSTALL_DIR/docker-compose.yml" ]; then
        print_error "docker-compose.yml non trouvé"
        exit 1
    fi
    
    # Vérifier si le fix est déjà appliqué
    if grep -q "context: ./bolt.diy" "$INSTALL_DIR/docker-compose.yml"; then
        print_info "Le docker-compose.yml utilise déjà le build local"
    else
        print_step "Modification du docker-compose.yml pour utiliser le build local..."
        
        # Sauvegarder l'original
        cp "$INSTALL_DIR/docker-compose.yml" "$INSTALL_DIR/docker-compose.yml.backup"
        print_info "Sauvegarde créée: docker-compose.yml.backup"
        
        # Remplacer image: par build:
        cat > "$INSTALL_DIR/docker-compose.yml.tmp" << 'DOCKERCOMPOSE'
services:
  bolt-nbility-core:
    # FIX NBILITY v4.6: Use local build instead of official image to fix wrangler PATH issue
    build:
      context: ./bolt.diy
      dockerfile: Dockerfile
      target: bolt-ai-production
    container_name: bolt-nbility-core
    restart: always
    environment:
      - NODE_ENV=production
    volumes:
      - bolt-nbility-data:/app/data
    expose:
      - "5173"
    networks:
      - bolt-network-app

  bolt-nbility-nginx:
    image: nginx:stable-alpine
    container_name: bolt-nbility-nginx
    restart: always
    depends_on:
      - bolt-nbility-core
    volumes:
      - ./DATA-LOCAL/nginx/nginx.conf:/etc/nginx/nginx.conf:ro
      - ./DATA-LOCAL/nginx/html:/usr/share/nginx/html:ro
      - ${HTPASSWD_FILE}:/etc/nginx/.htpasswd:ro
    ports:
      - "${HOST_PORT_HTTP}:80"
      - "${HTTPS_HOST_PORT}:443"
    networks:
      - bolt-network-app

  bolt-user-manager:
    image: bolt-user-manager:latest
    container_name: bolt-user-manager
    restart: always
    user: "root"
    volumes:
      - ./DATA-LOCAL/user-manager/app:/var/www/html
      - ${HTPASSWD_FILE}:/app/.htpasswd:rw
    environment:
      HTPASSWD_FILE: /app/.htpasswd
    ports:
      - "${HOST_PORT_UM}:80"
    networks:
      - bolt-network-app

networks:
  bolt-network-app:
    external: true
    
volumes:
  bolt-nbility-data:
    external: true
  bolt-nbility-nginx-conf:
    external: true
DOCKERCOMPOSE
        
        mv "$INSTALL_DIR/docker-compose.yml.tmp" "$INSTALL_DIR/docker-compose.yml"
        print_success "docker-compose.yml modifié pour utiliser le build local"
    fi
    
    echo ""
    print_success "Fix Dockerfile complet appliqué avec succès"
    print_info "Le conteneur bolt-nbility-core sera construit localement avec tous les fichiers nécessaires"
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
    echo -e "${CYAN}│${NC} ${WHITE}${BOLD}Adresse IP de la box internet (Gateway)${NC}"
    echo -e "${CYAN}╰─────────────────────────────────────────────────────────────────╯${NC}"
    echo -e "${CYAN}${ARROW}${NC} Exemple: 192.168.1.1 ou 192.168.1.254"
    read -p "IP Gateway [192.168.1.1]: " GATEWAY_IP
    GATEWAY_IP=${GATEWAY_IP:-192.168.1.1}
    print_success "Gateway défini: $GATEWAY_IP"
    echo ""
    
    print_section "CONFIGURATION DES PORTS"
    
    echo -e "${CYAN}╭─────────────────────────────────────────────────────────────────╮${NC}"
    echo -e "${CYAN}│${NC} ${WHITE}${BOLD}Port HTTP pour l'accès à Bolt.DIY${NC}"
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
    read -p "Nom d'utilisateur [admin]: " NGX_USER
    NGX_USER=${NGX_USER:-admin}
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
    echo -e "${YELLOW}Vous pouvez laisser vide et configurer plus tard dans bolt.diy/.env${NC}"
    echo ""
    
    read -p "1. OpenAI (GPT-4, GPT-3.5): " OPENAI_KEY
    read -p "2. Anthropic (Claude): " ANTHROPIC_KEY
    read -p "3. Google Gemini: " GEMINI_KEY
    read -p "4. Groq: " GROQ_KEY
    read -p "5. Mistral: " MISTRAL_KEY
    read -p "6. DeepSeek: " DEEPSEEK_KEY
    read -p "7. HuggingFace: " HF_KEY
    
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
        print_warning "Template introuvable: $template_file (optionnel)"
        return 0
    fi
    
    local protocol="http"
    
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
    cd "$INSTALL_DIR"
    
    print_banner
    print_section "INSTALLATION DE BOLT.DIY NBILITY INTRANET"
    
    print_step "Création des répertoires manquants..."
    mkdir -p "$NGINX_DIR/html"
    mkdir -p "$DATA_DIR/htpasswd-manager"
    print_success "Répertoires créés"
    
    print_step "Configuration du fichier .env pour Bolt.DIY..."
    cat > "$BOLT_DIR/.env" << ENVFILE
BASE_URL=http://$LOCAL_IP:$HOST_PORT_HTTP/
OPENAI_API_KEY="${OPENAI_KEY}"
ANTHROPIC_API_KEY="${ANTHROPIC_KEY}"
GOOGLE_GENERATIVE_AI_API_KEY="${GEMINI_KEY}"
GROQ_API_KEY="${GROQ_KEY}"
MISTRAL_API_KEY="${MISTRAL_KEY}"
DEEPSEEK_API_KEY="${DEEPSEEK_KEY}"
HF_API_KEY="${HF_KEY}"
ENVFILE
    print_success "Fichier .env configuré"
    
    print_section "GÉNÉRATION DES PAGES HTML"
    
    if [ -d "$TEMPLATES_DIR" ]; then
        if [ -f "$TEMPLATES_DIR/index.html" ]; then
            generate_html_from_templates \
                "$TEMPLATES_DIR/index.html" \
                "$NGINX_DIR/html/index.html" \
                "page d'accueil"
        fi
        
        if [ -f "$TEMPLATES_DIR/404.html" ]; then
            generate_html_from_templates \
                "$TEMPLATES_DIR/404.html" \
                "$NGINX_DIR/html/404.html" \
                "page d'erreur"
        fi
        
        if [ -f "$TEMPLATES_DIR/index-maintenance.html" ]; then
            cp "$TEMPLATES_DIR/index-maintenance.html" "$NGINX_DIR/html/index-maintenance-backup.html"
            print_info "Template de maintenance sauvegardé"
        fi
        
        print_success "Pages HTML générées"
    else
        print_warning "Dossier templates introuvable"
    fi
    
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
    
    print_step "Application des droits sur le fichier .htpasswd..."
    chmod 666 "$HTPASSWD_FILE"
    print_success "Droits appliqués"
    
    # Export des variables pour docker-compose
    export LOCAL_IP
    export HOST_PORT_HTTP
    export HTTPS_HOST_PORT
    export HOST_PORT_UM
    export HTPASSWD_FILE
    
    print_step "Construction de l'image bolt-user-manager..."
    print_info "Construction depuis le Dockerfile local..."
    if ! docker build -t bolt-user-manager:latest -f "$DATA_DIR/Dockerfile" "$DATA_DIR"; then
        print_error "Échec de la construction de l'image bolt-user-manager"
        exit 1
    fi
    print_success "Image bolt-user-manager construite"
    
    print_step "Construction de l'image bolt-nbility-core..."
    print_info "Construction depuis le Dockerfile corrigé de bolt.diy (cela peut prendre plusieurs minutes)..."
    print_warning "Première construction: patientez 5-10 minutes selon votre machine..."
    if ! docker compose build --no-cache bolt-nbility-core; then
        print_error "Échec de la construction de l'image bolt-nbility-core"
        print_info "Logs Docker Compose:"
        docker compose logs bolt-nbility-core
        exit 1
    fi
    print_success "Image bolt-nbility-core construite avec succès"
    
    echo ""
    print_step "Démarrage des services Docker..."
    if ! docker compose up -d; then
        print_error "Échec du démarrage des services Docker"
        print_info "Logs Docker Compose:"
        docker compose logs
        exit 1
    fi
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
    
    echo -e "${WHITE}${BOLD}Configuration réseau :${NC}"
    echo -e "  ${CYAN}${ARROW}${NC} IP serveur       : ${GREEN}$LOCAL_IP${NC}"
    echo -e "  ${CYAN}${ARROW}${NC} Gateway (box)    : ${GREEN}$GATEWAY_IP${NC}"
    echo ""
    
    echo -e "${WHITE}${BOLD}Commandes utiles :${NC}"
    echo -e "  ${CYAN}${ARROW}${NC} Logs             : ${YELLOW}cd $INSTALL_DIR && docker compose logs -f${NC}"
    echo -e "  ${CYAN}${ARROW}${NC} Arrêter          : ${YELLOW}cd $INSTALL_DIR && docker compose down${NC}"
    echo -e "  ${CYAN}${ARROW}${NC} Redémarrer       : ${YELLOW}cd $INSTALL_DIR && docker compose restart${NC}"
    echo ""
    
    echo -e "${CYAN}═══════════════════════════════════════════════════════════════════════${NC}"
    echo ""
}

# ═══════════════════════════════════════════════════════════════════════════
# FONCTION PRINCIPALE
# ═══════════════════════════════════════════════════════════════════════════

main() {
    check_internet_and_github
    check_prerequisites
    clone_repository
    fix_bolt_dockerfile
    get_configuration
    install_bolt
}

main
