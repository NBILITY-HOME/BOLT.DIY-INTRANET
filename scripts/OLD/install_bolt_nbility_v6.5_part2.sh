
# ═══════════════════════════════════════════════════════════════════════════
# FONCTION: Configuration interactive
# ═══════════════════════════════════════════════════════════════════════════
get_configuration() {
    print_section "CONFIGURATION DU SYSTÈME"

    # IP Locale
    print_step "Détection de l'IP locale..."
    DETECTED_IP=$(hostname -I | awk '{print $1}')
    echo -e "${CYAN}IP détectée: ${WHITE}$DETECTED_IP${NC}"
    read -p "$(echo -e ${YELLOW}Confirmer ou entrer l\'IP: ${NC})" input_ip
    LOCAL_IP=${input_ip:-$DETECTED_IP}
    print_success "IP configurée: $LOCAL_IP"
    echo ""

    # IP Gateway
    print_step "Configuration de la gateway (box/routeur)..."
    DETECTED_GW=$(ip route | grep default | awk '{print $3}' | head -n1)
    echo -e "${CYAN}Gateway détectée: ${WHITE}$DETECTED_GW${NC}"
    read -p "$(echo -e ${YELLOW}Confirmer ou entrer la gateway: ${NC})" input_gw
    GATEWAY_IP=${input_gw:-$DETECTED_GW}
    print_success "Gateway configurée: $GATEWAY_IP"
    echo ""

    # Ports
    print_step "Configuration des ports..."
    echo ""

    while true; do
        read -p "$(echo -e ${YELLOW}Port pour Bolt.DIY [défaut: 8585]: ${NC})" input_bolt
        HOST_PORT_BOLT=${input_bolt:-8585}
        if check_port_available $HOST_PORT_BOLT "Bolt.DIY"; then
            break
        fi
    done

    while true; do
        read -p "$(echo -e ${YELLOW}Port pour Home [défaut: 8686]: ${NC})" input_home
        HOST_PORT_HOME=${input_home:-8686}
        if check_port_available $HOST_PORT_HOME "Home"; then
            break
        fi
    done

    while true; do
        read -p "$(echo -e ${YELLOW}Port pour User Manager [défaut: 8687]: ${NC})" input_um
        HOST_PORT_UM=${input_um:-8687}
        if check_port_available $HOST_PORT_UM "User Manager"; then
            break
        fi
    done

    echo ""

    # Authentification NGINX
    print_step "Configuration de l'authentification NGINX..."
    echo ""
    read -p "$(echo -e ${YELLOW}Nom d\'utilisateur: ${NC})" NGINX_USER
    while true; do
        read -sp "$(echo -e ${YELLOW}Mot de passe: ${NC})" NGINX_PASS
        echo ""
        read -sp "$(echo -e ${YELLOW}Confirmer le mot de passe: ${NC})" NGINX_PASS_CONFIRM
        echo ""
        if [ "$NGINX_PASS" = "$NGINX_PASS_CONFIRM" ]; then
            break
        else
            print_error "Les mots de passe ne correspondent pas"
        fi
    done
    print_success "Authentification NGINX configurée"
    echo ""

    # Super Admin
    print_step "Configuration du Super Admin..."
    echo ""
    read -p "$(echo -e ${YELLOW}Username Super Admin: ${NC})" ADMIN_USERNAME
    read -p "$(echo -e ${YELLOW}Email Super Admin: ${NC})" ADMIN_EMAIL
    while true; do
        read -sp "$(echo -e ${YELLOW}Mot de passe Super Admin: ${NC})" ADMIN_PASSWORD
        echo ""
        read -sp "$(echo -e ${YELLOW}Confirmer le mot de passe: ${NC})" ADMIN_PASSWORD_CONFIRM
        echo ""
        if [ "$ADMIN_PASSWORD" = "$ADMIN_PASSWORD_CONFIRM" ]; then
            break
        else
            print_error "Les mots de passe ne correspondent pas"
        fi
    done
    print_success "Super Admin configuré"
    echo ""

    # Génération des mots de passe BDD
    print_step "Génération des mots de passe MariaDB..."
    MARIADB_ROOT_PASSWORD=$(generate_secure_password 32)
    MARIADB_USER_PASSWORD=$(generate_secure_password 32)
    APP_SECRET=$(generate_app_secret)
    print_success "Mots de passe générés automatiquement"
    echo ""

    # API Keys (optionnel)
    print_step "Configuration des API Keys (optionnel - Entrée pour ignorer)..."
    echo ""
    read -p "$(echo -e ${CYAN}Anthropic API Key: ${NC})" ANTHROPIC_KEY
    read -p "$(echo -e ${CYAN}OpenAI API Key: ${NC})" OPENAI_KEY
    read -p "$(echo -e ${CYAN}Google Gemini API Key: ${NC})" GEMINI_KEY
    read -p "$(echo -e ${CYAN}Groq API Key: ${NC})" GROQ_KEY
    read -p "$(echo -e ${CYAN}Mistral API Key: ${NC})" MISTRAL_KEY
    read -p "$(echo -e ${CYAN}DeepSeek API Key: ${NC})" DEEPSEEK_KEY
    read -p "$(echo -e ${CYAN}HuggingFace API Key: ${NC})" HF_KEY

    echo ""
    print_success "Configuration terminée"
    echo ""
}

# ═══════════════════════════════════════════════════════════════════════════
# FONCTION: Clonage du repository
# ═══════════════════════════════════════════════════════════════════════════
clone_repository() {
    print_section "CLONAGE DU REPOSITORY GITHUB"

    if [ -d "$INSTALL_DIR" ]; then
        print_warning "Le répertoire $REPO_NAME existe déjà"
        read -p "$(echo -e ${YELLOW}Supprimer et re-cloner ? (o/N): ${NC})" confirm
        if [[ "$confirm" =~ ^[Oo]$ ]]; then
            print_step "Suppression de l'ancien répertoire..."
            rm -rf "$INSTALL_DIR"
            print_success "Répertoire supprimé"
        else
            print_info "Utilisation du répertoire existant"
            return 0
        fi
    fi

    print_step "Clonage depuis $REPO_URL..."
    if git clone "$REPO_URL" "$INSTALL_DIR"; then
        print_success "Repository cloné avec succès"
    else
        print_error "Échec du clonage"
        exit 1
    fi

    echo ""
}

# ═══════════════════════════════════════════════════════════════════════════
# FONCTION: Création de la structure de répertoires
# ═══════════════════════════════════════════════════════════════════════════
create_directory_structure() {
    print_section "CRÉATION DE LA STRUCTURE DE RÉPERTOIRES"

    print_step "Création des répertoires..."

    mkdir -p "$NGINX_DIR"
    mkdir -p "$MARIADB_DIR/init"
    mkdir -p "$USERMANAGER_DIR/app"
    mkdir -p "$USERMANAGER_DIR/app/config"
    mkdir -p "$USERMANAGER_DIR/app/includes"
    mkdir -p "$USERMANAGER_DIR/app/models"
    mkdir -p "$USERMANAGER_DIR/app/controllers"
    mkdir -p "$USERMANAGER_DIR/app/views"
    mkdir -p "$USERMANAGER_DIR/app/assets"
    mkdir -p "$USERMANAGER_DIR/uploads"
    mkdir -p "$USERMANAGER_DIR/backups"

    print_success "Structure créée"
    echo ""
}

# ═══════════════════════════════════════════════════════════════════════════
# FONCTION: Génération du fichier docker-compose.yml
# ═══════════════════════════════════════════════════════════════════════════
generate_docker_compose() {
    print_section "GÉNÉRATION DU DOCKER-COMPOSE.YML"

    print_step "Création de docker-compose.yml..."

    cat > "$INSTALL_DIR/docker-compose.yml" << 'DOCKER_COMPOSE_EOF'
version: '3.8'

services:
  # ════════════════════════════════════════════════════════════════
  # NGINX REVERSE PROXY
  # ════════════════════════════════════════════════════════════════
  nginx:
    image: nginx:alpine
    container_name: bolt-nginx
    restart: unless-stopped
    ports:
      - "${HOST_PORT_BOLT}:8585"
      - "${HOST_PORT_HOME}:8686"
      - "${HOST_PORT_UM}:8687"
    volumes:
      - ./DATA-LOCAL/nginx/nginx.conf:/etc/nginx/nginx.conf:ro
      - ./DATA-LOCAL/nginx/.htpasswd:/etc/nginx/.htpasswd:ro
      - ./DATA-LOCAL/templates:/usr/share/nginx/html:ro
    networks:
      - bolt-network-app
    depends_on:
      - bolt-core
      - bolt-user-manager
    healthcheck:
      test: ["CMD", "wget", "--quiet", "--tries=1", "--spider", "http://localhost:8585/health"]
      interval: 30s
      timeout: 10s
      retries: 3

  # ════════════════════════════════════════════════════════════════
  # BOLT.DIY CORE APPLICATION
  # ════════════════════════════════════════════════════════════════
  bolt-core:
    build:
      context: ./bolt.diy
      dockerfile: Dockerfile
    container_name: bolt-core
    restart: unless-stopped
    expose:
      - "5173"
    environment:
      - BASE_URL=http://${LOCAL_IP}:${HOST_PORT_BOLT}
      - APP_URL=http://${LOCAL_IP}:${HOST_PORT_BOLT}
      - VITE_BASE_URL=/
      - PUBLIC_URL=http://${LOCAL_IP}:${HOST_PORT_BOLT}
      - BASE_PATH=/
      - VITE_ROUTER_BASE=/
      - ANTHROPIC_API_KEY=${ANTHROPIC_API_KEY:-}
      - OPENAI_API_KEY=${OPENAI_API_KEY:-}
      - GOOGLE_GENERATIVE_AI_API_KEY=${GOOGLE_GENERATIVE_AI_API_KEY:-}
      - GROQ_API_KEY=${GROQ_API_KEY:-}
      - MISTRAL_API_KEY=${MISTRAL_API_KEY:-}
      - DEEPSEEK_API_KEY=${DEEPSEEK_API_KEY:-}
      - HF_API_KEY=${HF_API_KEY:-}
    volumes:
      - bolt-nbility-data:/app/data
      - ./bolt.diy:/app:cached
    networks:
      - bolt-network-app
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:5173"]
      interval: 30s
      timeout: 10s
      retries: 3

  # ════════════════════════════════════════════════════════════════
  # BOLT HOME (Page d accueil HTML statique)
  # ════════════════════════════════════════════════════════════════
  bolt-home:
    image: nginx:alpine
    container_name: bolt-home
    restart: unless-stopped
    expose:
      - "80"
    volumes:
      - ./DATA-LOCAL/templates/home.html:/usr/share/nginx/html/index.html:ro
    networks:
      - bolt-network-app

  # ════════════════════════════════════════════════════════════════
  # USER MANAGER v2.0 (PHP + Apache)
  # ════════════════════════════════════════════════════════════════
  bolt-user-manager:
    build:
      context: ./DATA-LOCAL/user-manager
      dockerfile: Dockerfile
    container_name: bolt-user-manager
    restart: unless-stopped
    expose:
      - "80"
    environment:
      - DB_HOST=bolt-mariadb
      - DB_PORT=3306
      - DB_NAME=bolt_usermanager
      - DB_USER=bolt_um
      - DB_PASSWORD=${MARIADB_PASSWORD}
      - APP_SECRET=${APP_SECRET}
      - APP_URL=http://${LOCAL_IP}:${HOST_PORT_UM}
      - PHP_MEMORY_LIMIT=256M
      - PHP_UPLOAD_MAX_FILESIZE=20M
      - PHP_POST_MAX_SIZE=20M
    volumes:
      - ./DATA-LOCAL/user-manager/app:/var/www/html:cached
    networks:
      - bolt-network-app
    depends_on:
      bolt-mariadb:
        condition: service_healthy
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost/health.php"]
      interval: 30s
      timeout: 10s
      retries: 3

  # ════════════════════════════════════════════════════════════════
  # MARIADB DATABASE
  # ════════════════════════════════════════════════════════════════
  bolt-mariadb:
    image: mariadb:10.11
    container_name: bolt-mariadb
    restart: unless-stopped
    expose:
      - "3306"
    environment:
      - MARIADB_ROOT_PASSWORD=${MARIADB_ROOT_PASSWORD}
      - MARIADB_DATABASE=bolt_usermanager
      - MARIADB_USER=bolt_um
      - MARIADB_PASSWORD=${MARIADB_PASSWORD}
      - MARIADB_AUTO_UPGRADE=1
    volumes:
      - mariadb-data:/var/lib/mysql
      - ./DATA-LOCAL/mariadb/init:/docker-entrypoint-initdb.d:ro
    networks:
      - bolt-network-app
    command: 
      - --character-set-server=utf8mb4
      - --collation-server=utf8mb4_unicode_ci
      - --max-connections=200
      - --innodb-buffer-pool-size=256M
    healthcheck:
      test: ["CMD", "healthcheck.sh", "--connect", "--innodb_initialized"]
      interval: 10s
      timeout: 5s
      retries: 5

networks:
  bolt-network-app:
    name: bolt-network-app
    driver: bridge

volumes:
  bolt-nbility-data:
    name: bolt-nbility-data
    driver: local
  mariadb-data:
    name: mariadb-data
    driver: local
DOCKER_COMPOSE_EOF

    print_success "docker-compose.yml créé"
    echo ""
}
