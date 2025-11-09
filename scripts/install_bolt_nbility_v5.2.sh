#!/bin/bash
#═══════════════════════════════════════════════════════════════════════════
# BOLT.DIY NBILITY - Installation Script v5.1
# Architecture Multi-Ports avec Services à la Racine + User Manager
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
    echo "  ./install_bolt_nbility_v5.1.sh"
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
    echo -e "${MAGENTA}${BOLD}                                    Installation Interactive v5.1${NC}"
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
    print_section "VÉRIFICATION DE LA CONNECTIVITÉ"
    
    print_step "Test de connexion Internet..."
    if ping -c 1 8.8.8.8 &> /dev/null; then
        print_success "Connexion Internet OK"
    else
        print_error "Pas de connexion Internet"
        exit 1
    fi
    
    print_step "Test d'accès à GitHub..."
    if ping -c 1 github.com &> /dev/null; then
        print_success "Accès GitHub OK"
    else
        print_error "Impossible d'accéder à GitHub"
        exit 1
    fi
}

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
        print_error "Pas de permission Docker. Ajoutez votre utilisateur au groupe docker:"
        echo "  sudo usermod -aG docker \$USER"
        echo "  newgrp docker"
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
# FIX DOCKERFILE WRANGLER
# ═══════════════════════════════════════════════════════════════════════════

fix_bolt_dockerfile() {
    print_section "APPLICATION DU FIX DOCKERFILE WRANGLER"
    
    cd "$INSTALL_DIR"
    
    local dockerfile_template="$TEMPLATES_DIR/bolt.diy/Dockerfile"
    local dockerfile_target="$BOLT_DIR/Dockerfile"
    
    if [ ! -f "$dockerfile_template" ]; then
        print_error "Template Dockerfile introuvable: $dockerfile_template"
        exit 1
    fi
    
    print_step "Copie du Dockerfile corrigé..."
    cp "$dockerfile_template" "$dockerfile_target"
    
    if grep -q "ENV PATH=\"/app/node_modules/.bin:\${PATH}\"" "$dockerfile_target"; then
        print_success "Dockerfile corrigé appliqué avec succès"
        print_info "Le fix wrangler PATH est actif"
    else
        print_warning "Le Dockerfile ne contient pas le fix wrangler"
    fi
    
    echo ""
    echo -e "${GREEN}${BOLD}Appuyez sur ENTRÉE pour continuer...${NC}"
    read
}

# ═══════════════════════════════════════════════════════════════════════════
# VALIDATION DES PORTS
# ═══════════════════════════════════════════════════════════════════════════

check_port_available() {
    local port=$1
    if ss -tuln | grep -q ":$port "; then
        return 1
    fi
    return 0
}

validate_port() {
    local port=$1
    local port_name=$2
    local reserved_port=$3
    
    if [ -z "$port" ]; then
        print_error "Le port ne peut pas être vide"
        return 1
    fi
    
    if ! [[ "$port" =~ ^[0-9]+$ ]]; then
        print_error "Le port doit être un nombre"
        return 1
    fi
    
    if [ "$port" -lt 1024 ] || [ "$port" -gt 65535 ]; then
        print_error "Le port doit être entre 1024 et 65535"
        return 1
    fi
    
    if [ "$port" -eq "$reserved_port" ]; then
        print_error "Ce port est réservé pour Bolt.DIY"
        return 1
    fi
    
    if ! check_port_available "$port"; then
        print_error "Le port $port est déjà utilisé"
        return 1
    fi
    
    return 0
}

# ═══════════════════════════════════════════════════════════════════════════
# CONFIGURATION UTILISATEUR
# ═══════════════════════════════════════════════════════════════════════════

get_configuration() {
    print_banner
    print_section "CONFIGURATION RÉSEAU"
    
    # IP SERVEUR
    echo -e "${CYAN}╭─────────────────────────────────────────────────────────────────╮${NC}"
    echo -e "${CYAN}│${NC} ${WHITE}${BOLD}Adresse IP locale du serveur${NC}"
    echo -e "${CYAN}╰─────────────────────────────────────────────────────────────────╯${NC}"
    echo -e "${CYAN}${ARROW}${NC} Exemple: 192.168.1.200"
    read -p "IP locale [192.168.1.200]: " LOCAL_IP
    export LOCAL_IP=${LOCAL_IP:-192.168.1.200}
    print_success "IP locale définie: $LOCAL_IP"
    echo ""
    
    # IP BOX
    echo -e "${CYAN}╭─────────────────────────────────────────────────────────────────╮${NC}"
    echo -e "${CYAN}│${NC} ${WHITE}${BOLD}Adresse IP de la box internet (Gateway)${NC}"
    echo -e "${CYAN}╰─────────────────────────────────────────────────────────────────╯${NC}"
    echo -e "${CYAN}${ARROW}${NC} Exemple: 192.168.1.1 ou 192.168.1.254"
    read -p "IP Gateway [192.168.1.1]: " GATEWAY_IP
    export GATEWAY_IP=${GATEWAY_IP:-192.168.1.1}
    print_success "Gateway défini: $GATEWAY_IP"
    echo ""
    
    print_section "CONFIGURATION DES PORTS"
    
    # PORT BOLT (PREMIER)
    echo -e "${CYAN}╭─────────────────────────────────────────────────────────────────╮${NC}"
    echo -e "${CYAN}│${NC} ${WHITE}${BOLD}Port pour Bolt.DIY (Login + Application)${NC}"
    echo -e "${CYAN}╰─────────────────────────────────────────────────────────────────╯${NC}"
    echo -e "${CYAN}${ARROW}${NC} Ce port affichera la page de login et l'application Bolt"
    echo -e "${YELLOW}${ARROW}${NC} Ce port sera réservé et ne pourra pas être réutilisé"
    while true; do
        read -p "Port BOLT [6969]: " HOST_PORT_BOLT
        HOST_PORT_BOLT=${HOST_PORT_BOLT:-6969}
        if validate_port "$HOST_PORT_BOLT" "BOLT" "0"; then
            export HOST_PORT_BOLT
            print_success "Port BOLT: $HOST_PORT_BOLT"
            break
        fi
    done
    echo ""
    
    # PORT HTTPS
    echo -e "${CYAN}╭─────────────────────────────────────────────────────────────────╮${NC}"
    echo -e "${CYAN}│${NC} ${WHITE}${BOLD}Port HTTPS (Réservé pour SSL futur)${NC}"
    echo -e "${CYAN}╰─────────────────────────────────────────────────────────────────╯${NC}"
    while true; do
        read -p "Port HTTPS [8443]: " HTTPS_HOST_PORT
        HTTPS_HOST_PORT=${HTTPS_HOST_PORT:-8443}
        if validate_port "$HTTPS_HOST_PORT" "HTTPS" "$HOST_PORT_BOLT"; then
            export HTTPS_HOST_PORT
            print_success "Port HTTPS: $HTTPS_HOST_PORT"
            break
        fi
    done
    echo ""
    
    # PORT HOME
    echo -e "${CYAN}╭─────────────────────────────────────────────────────────────────╮${NC}"
    echo -e "${CYAN}│${NC} ${WHITE}${BOLD}Port pour la Page d'Accueil${NC}"
    echo -e "${CYAN}╰─────────────────────────────────────────────────────────────────╯${NC}"
    echo -e "${CYAN}${ARROW}${NC} Page statique avec liens vers Bolt et Admin Manager"
    while true; do
        read -p "Port HOME [7070]: " HOST_PORT_HOME
        HOST_PORT_HOME=${HOST_PORT_HOME:-7070}
        if validate_port "$HOST_PORT_HOME" "HOME" "$HOST_PORT_BOLT"; then
            if [ "$HOST_PORT_HOME" -eq "$HTTPS_HOST_PORT" ]; then
                print_error "Ce port est déjà utilisé pour HTTPS"
                continue
            fi
            export HOST_PORT_HOME
            print_success "Port HOME: $HOST_PORT_HOME"
            break
        fi
    done
    echo ""
    
    # PORT ADMIN MANAGER
    echo -e "${CYAN}╭─────────────────────────────────────────────────────────────────╮${NC}"
    echo -e "${CYAN}│${NC} ${WHITE}${BOLD}Port pour le Admin Manager${NC}"
    echo -e "${CYAN}╰─────────────────────────────────────────────────────────────────╯${NC}"
    while true; do
        read -p "Port Admin Manager [7071]: " HOST_PORT_UM
        HOST_PORT_UM=${HOST_PORT_UM:-7071}
        if validate_port "$HOST_PORT_UM" "Admin Manager" "$HOST_PORT_BOLT"; then
            if [ "$HOST_PORT_UM" -eq "$HTTPS_HOST_PORT" ] || [ "$HOST_PORT_UM" -eq "$HOST_PORT_HOME" ]; then
                print_error "Ce port est déjà utilisé"
                continue
            fi
            export HOST_PORT_UM
            print_success "Port Admin Manager: $HOST_PORT_UM"
            break
        fi
    done
    echo ""
    
    print_section "AUTHENTIFICATION NGINX"
    
    echo -e "${CYAN}╭─────────────────────────────────────────────────────────────────╮${NC}"
    echo -e "${CYAN}│${NC} ${WHITE}${BOLD}Identifiants pour l'accès à Bolt.DIY${NC}"
    echo -e "${CYAN}╰─────────────────────────────────────────────────────────────────╯${NC}"
    read -p "Nom d'utilisateur [admin]: " NGX_USER
    export NGX_USER=${NGX_USER:-admin}
    read -sp "Mot de passe: " NGX_PASS
    export NGX_PASS
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
    export OPENAI_KEY
    read -p "2. Anthropic (Claude): " ANTHROPIC_KEY
    export ANTHROPIC_KEY
    read -p "3. Google Gemini: " GEMINI_KEY
    export GEMINI_KEY
    read -p "4. Groq: " GROQ_KEY
    export GROQ_KEY
    read -p "5. Mistral: " MISTRAL_KEY
    export MISTRAL_KEY
    read -p "6. DeepSeek: " DEEPSEEK_KEY
    export DEEPSEEK_KEY
    read -p "7. HuggingFace: " HF_KEY
    export HF_KEY
    
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
    
    sed -e "s|{{LOCAL_IP}}|$LOCAL_IP|g" \
        -e "s|{{HOST_PORT_BOLT}}|$HOST_PORT_BOLT|g" \
        -e "s|{{HOST_PORT_HOME}}|$HOST_PORT_HOME|g" \
        -e "s|{{HOST_PORT_UM}}|$HOST_PORT_UM|g" \
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
    
    print_step "Vérification du docker-compose.yml..."
    if grep -q "HOST_PORT_HTTP" docker-compose.yml 2>/dev/null; then
        print_error "Ancien docker-compose.yml détecté (contient HOST_PORT_HTTP)"
        print_warning "Le fichier docker-compose.yml n'a pas été mis à jour correctement"
        print_info "Le script va utiliser le docker-compose.yml du repository"
    fi
    
    if ! grep -q "HOST_PORT_BOLT" docker-compose.yml 2>/dev/null; then
        print_error "docker-compose.yml invalide (HOST_PORT_BOLT manquant)"
        exit 1
    fi
    print_success "docker-compose.yml v5.0 détecté"
    
    print_step "Création des répertoires manquants..."
    mkdir -p "$NGINX_DIR/html"
    mkdir -p "$DATA_DIR/user-manager/app"
    print_success "Répertoires créés"
    
    print_step "Création de l'interface User Manager..."
    cat > "$DATA_DIR/user-manager/app/index.php" << 'PHPEOF'
<?php
$htpasswd_file = getenv('HTPASSWD_FILE') ?: '.htpasswd';
$message = '';

if ($_SERVER['REQUEST_METHOD'] === 'POST') {
    $action = $_POST['action'] ?? '';
    $username = $_POST['username'] ?? '';
    $password = $_POST['password'] ?? '';
    
    if ($action === 'add' && $username && $password) {
        $hash = password_hash($password, PASSWORD_BCRYPT);
        $hash_apr1 = exec("htpasswd -nbB " . escapeshellarg($username) . " " . escapeshellarg($password) . " 2>&1");
        file_put_contents($htpasswd_file, $hash_apr1 . PHP_EOL, FILE_APPEND);
        $message = "Utilisateur '$username' ajouté avec succès";
    } elseif ($action === 'delete' && $username) {
        $lines = file($htpasswd_file, FILE_IGNORE_NEW_LINES);
        $new_lines = array_filter($lines, function($line) use ($username) {
            return !str_starts_with($line, $username . ':');
        });
        file_put_contents($htpasswd_file, implode(PHP_EOL, $new_lines) . PHP_EOL);
        $message = "Utilisateur '$username' supprimé";
    }
}

$users = [];
if (file_exists($htpasswd_file)) {
    $lines = file($htpasswd_file, FILE_IGNORE_NEW_LINES | FILE_SKIP_EMPTY_LINES);
    foreach ($lines as $line) {
        if (str_contains($line, ':')) {
            $users[] = explode(':', $line)[0];
        }
    }
}
?>
<!DOCTYPE html>
<html lang="fr">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Bolt.DIY - User Manager</title>
    <style>
        * { margin: 0; padding: 0; box-sizing: border-box; }
        body { font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, sans-serif; background: linear-gradient(135deg, #667eea 0%, #764ba2 100%); min-height: 100vh; padding: 20px; }
        .container { max-width: 800px; margin: 0 auto; background: white; border-radius: 12px; box-shadow: 0 20px 60px rgba(0,0,0,0.3); overflow: hidden; }
        .header { background: linear-gradient(135deg, #667eea 0%, #764ba2 100%); color: white; padding: 30px; text-align: center; }
        .header h1 { font-size: 28px; margin-bottom: 5px; }
        .header p { opacity: 0.9; font-size: 14px; }
        .content { padding: 30px; }
        .message { padding: 15px; margin-bottom: 20px; border-radius: 8px; background: #d4edda; color: #155724; border: 1px solid #c3e6cb; }
        .form-section { background: #f8f9fa; padding: 20px; border-radius: 8px; margin-bottom: 30px; }
        .form-section h2 { margin-bottom: 15px; color: #333; font-size: 18px; }
        .form-group { margin-bottom: 15px; }
        label { display: block; margin-bottom: 5px; color: #555; font-weight: 500; }
        input[type="text"], input[type="password"] { width: 100%; padding: 10px; border: 2px solid #ddd; border-radius: 6px; font-size: 14px; transition: border-color 0.3s; }
        input:focus { outline: none; border-color: #667eea; }
        button { background: linear-gradient(135deg, #667eea 0%, #764ba2 100%); color: white; border: none; padding: 12px 24px; border-radius: 6px; cursor: pointer; font-size: 14px; font-weight: 600; transition: transform 0.2s; }
        button:hover { transform: translateY(-2px); }
        button.delete { background: linear-gradient(135deg, #f093fb 0%, #f5576c 100%); }
        .users-list { background: #f8f9fa; padding: 20px; border-radius: 8px; }
        .users-list h2 { margin-bottom: 15px; color: #333; font-size: 18px; }
        .user-item { background: white; padding: 15px; margin-bottom: 10px; border-radius: 6px; display: flex; justify-content: space-between; align-items: center; border: 1px solid #e0e0e0; }
        .user-name { font-weight: 600; color: #333; }
        .footer { text-align: center; padding: 20px; color: #666; font-size: 12px; border-top: 1px solid #e0e0e0; }
    </style>
</head>
<body>
    <div class="container">
        <div class="header">
            <h1>🔐 Bolt.DIY User Manager</h1>
            <p>Nbility Edition - Gestion des utilisateurs</p>
        </div>
        <div class="content">
            <?php if ($message): ?>
                <div class="message"><?= htmlspecialchars($message) ?></div>
            <?php endif; ?>
            
            <div class="form-section">
                <h2>➕ Ajouter un utilisateur</h2>
                <form method="POST">
                    <input type="hidden" name="action" value="add">
                    <div class="form-group">
                        <label>Nom d'utilisateur</label>
                        <input type="text" name="username" required>
                    </div>
                    <div class="form-group">
                        <label>Mot de passe</label>
                        <input type="password" name="password" required>
                    </div>
                    <button type="submit">Ajouter</button>
                </form>
            </div>
            
            <div class="users-list">
                <h2>👥 Utilisateurs existants (<?= count($users) ?>)</h2>
                <?php if (empty($users)): ?>
                    <p style="color: #666; padding: 20px; text-align: center;">Aucun utilisateur</p>
                <?php else: ?>
                    <?php foreach ($users as $user): ?>
                        <div class="user-item">
                            <span class="user-name"><?= htmlspecialchars($user) ?></span>
                            <form method="POST" style="display: inline;">
                                <input type="hidden" name="action" value="delete">
                                <input type="hidden" name="username" value="<?= htmlspecialchars($user) ?>">
                                <button type="submit" class="delete" onclick="return confirm('Supprimer <?= htmlspecialchars($user) ?> ?')">Supprimer</button>
                            </form>
                        </div>
                    <?php endforeach; ?>
                <?php endif; ?>
            </div>
        </div>
        <div class="footer">
            © 2025 Nbility - Bolt.DIY Intranet Edition
        </div>
    </div>
</body>
</html>
PHPEOF
    print_success "Interface User Manager créée"
    
    print_step "Configuration du fichier .env pour Bolt.DIY..."
    cat > "$BOLT_DIR/.env" << ENVFILE
BASE_URL=http://$LOCAL_IP:$HOST_PORT_BOLT/
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
        
        if [ -f "$TEMPLATES_DIR/login.html" ]; then
            generate_html_from_templates \
                "$TEMPLATES_DIR/login.html" \
                "$NGINX_DIR/html/login.html" \
                "page de login"
        fi
        
        if [ -f "$TEMPLATES_DIR/404.html" ]; then
            generate_html_from_templates \
                "$TEMPLATES_DIR/404.html" \
                "$NGINX_DIR/html/404.html" \
                "page d'erreur"
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
    print_success "Volumes Docker prêts"
    
    print_step "Création du fichier htpasswd..."
    if command -v htpasswd &> /dev/null; then
        htpasswd -cb "$HTPASSWD_FILE" "$NGX_USER" "$NGX_PASS"
    else
        echo "$NGX_USER:$(openssl passwd -apr1 "$NGX_PASS")" > "$HTPASSWD_FILE"
    fi
    chmod 666 "$HTPASSWD_FILE"
    print_success "Fichier htpasswd créé"
    
    print_step "Création du fichier .env Docker Compose..."
    cat > "$INSTALL_DIR/.env" << ENVFILE
# Configuration des ports
HOST_PORT_BOLT=$HOST_PORT_BOLT
HOST_PORT_HOME=$HOST_PORT_HOME
HOST_PORT_UM=$HOST_PORT_UM
HTTPS_HOST_PORT=$HTTPS_HOST_PORT

# Fichier htpasswd
HTPASSWD_FILE=$HTPASSWD_FILE
ENVFILE
    print_success "Fichier .env créé"
    
    print_section "BUILD ET DÉMARRAGE DES CONTENEURS"
    
    print_step "Build de l'image Bolt.DIY (cela peut prendre plusieurs minutes)..."
    echo -e "${YELLOW}La sortie complète du build est affichée ci-dessous...${NC}"
    echo ""
    
    docker compose build bolt-nbility-core 2>&1 | tee /tmp/bolt-build.log
    BUILD_EXIT_CODE=${PIPESTATUS[0]}
    
    echo ""
    if [ $BUILD_EXIT_CODE -eq 0 ]; then
        print_success "Build de bolt-nbility-core réussi"
    else
        print_error "Échec du build (code de sortie: $BUILD_EXIT_CODE)"
        echo -e "${YELLOW}Consultez /tmp/bolt-build.log pour les détails complets${NC}"
        exit 1
    fi
    
    print_step "Préparation de l'image User Manager..."
    docker pull php:8.2-apache > /dev/null 2>&1
    print_success "Image PHP préparée"
    
    print_step "Démarrage des conteneurs..."
    if docker compose up -d; then
        print_success "Conteneurs démarrés"
    else
        print_error "Échec du démarrage"
        exit 1
    fi
    
    print_step "Vérification des conteneurs..."
    sleep 5
    docker compose ps
    
    print_section "RÉSUMÉ DE L'INSTALLATION"
    
    echo -e "${GREEN}${BOLD}✓ Installation terminée avec succès !${NC}"
    echo ""
    echo -e "${CYAN}╔═══════════════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║${NC} ${WHITE}${BOLD}ACCÈS AUX SERVICES${NC}"
    echo -e "${CYAN}╠═══════════════════════════════════════════════════════════════════════╣${NC}"
    echo -e "${CYAN}║${NC} ${YELLOW}Login Bolt.DIY:${NC}      http://$LOCAL_IP:$HOST_PORT_BOLT/"
    echo -e "${CYAN}║${NC} ${YELLOW}Page d'Accueil:${NC}      http://$LOCAL_IP:$HOST_PORT_HOME/"
    echo -e "${CYAN}║${NC} ${YELLOW}Admin Manager:${NC}       http://$LOCAL_IP:$HOST_PORT_UM/"
    echo -e "${CYAN}╠═══════════════════════════════════════════════════════════════════════╣${NC}"
    echo -e "${CYAN}║${NC} ${WHITE}${BOLD}IDENTIFIANTS${NC}"
    echo -e "${CYAN}╠═══════════════════════════════════════════════════════════════════════╣${NC}"
    echo -e "${CYAN}║${NC} ${YELLOW}Utilisateur:${NC}         $NGX_USER"
    echo -e "${CYAN}║${NC} ${YELLOW}Mot de passe:${NC}        ••••••••"
    echo -e "${CYAN}╠═══════════════════════════════════════════════════════════════════════╣${NC}"
    echo -e "${CYAN}║${NC} ${WHITE}${BOLD}ARCHITECTURE${NC}"
    echo -e "${CYAN}╠═══════════════════════════════════════════════════════════════════════╣${NC}"
    echo -e "${CYAN}║${NC} Port $HOST_PORT_BOLT → Login + Bolt.DIY (à la racine /)"
    echo -e "${CYAN}║${NC} Port $HOST_PORT_HOME → Page d'accueil statique"
    echo -e "${CYAN}║${NC} Port $HOST_PORT_UM → Admin Manager"
    echo -e "${CYAN}╚═══════════════════════════════════════════════════════════════════════╝${NC}"
    echo ""
    echo -e "${MAGENTA}${BOLD}Commandes utiles:${NC}"
    echo -e "  ${CYAN}${ARROW}${NC} Voir les logs:        docker compose logs -f"
    echo -e "  ${CYAN}${ARROW}${NC} Arrêter:              docker compose stop"
    echo -e "  ${CYAN}${ARROW}${NC} Redémarrer:           docker compose restart"
    echo -e "  ${CYAN}${ARROW}${NC} Status:               docker compose ps"
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
