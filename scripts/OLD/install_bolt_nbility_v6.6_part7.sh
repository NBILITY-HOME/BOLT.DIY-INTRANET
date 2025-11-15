
# ═══════════════════════════════════════════════════════════════════════════
# FONCTION: Création du fichier htpasswd
# ═══════════════════════════════════════════════════════════════════════════
create_htpasswd() {
    print_section "CRÉATION DU FICHIER HTPASSWD"

    print_step "Génération du fichier htpasswd pour NGINX..."

    if [ -f "$HTPASSWD_FILE" ]; then
        rm -f "$HTPASSWD_FILE"
        print_info "Ancien fichier htpasswd supprimé"
    fi

    if command -v htpasswd &> /dev/null; then
        if htpasswd -cbB "$HTPASSWD_FILE" "$NGINX_USER" "$NGINX_PASS"; then
            print_success "Fichier htpasswd créé avec bcrypt"
        else
            print_error "Échec de la création du fichier htpasswd"
            exit 1
        fi
    else
        print_error "La commande htpasswd n'est pas disponible"
        echo "Installation de apache2-utils..."
        if command -v apt-get &> /dev/null; then
            sudo apt-get update
            sudo apt-get install -y apache2-utils
            htpasswd -cbB "$HTPASSWD_FILE" "$NGINX_USER" "$NGINX_PASS"
        else
            print_error "Impossible d'installer htpasswd automatiquement"
            exit 1
        fi
    fi

    chmod 644 "$HTPASSWD_FILE"

    if [ -s "$HTPASSWD_FILE" ]; then
        print_success "Fichier htpasswd valide"
    else
        print_error "Fichier htpasswd VIDE"
        exit 1
    fi

    echo ""
}

# ═══════════════════════════════════════════════════════════════════════════
# FONCTION: Création des fichiers User Manager
# ═══════════════════════════════════════════════════════════════════════════
create_usermanager_files() {
    print_section "CRÉATION DES FICHIERS USER MANAGER"

    print_step "Génération de composer.json..."
    cat > "$USERMANAGER_DIR/app/composer.json" << 'COMPOSER_EOF'
{
    "name": "nbility/bolt-user-manager",
    "description": "Bolt.DIY User Manager v2.0",
    "type": "project",
    "require": {
        "php": ">=8.2",
        "phpmailer/phpmailer": "^6.9",
        "phpoffice/phpspreadsheet": "^1.29",
        "tecnickcom/tcpdf": "^6.6"
    },
    "autoload": {
        "psr-4": {
            "App\\": "app/"
        }
    },
    "config": {
        "optimize-autoloader": true
    }
}
COMPOSER_EOF

    print_success "composer.json créé"

    print_step "Génération de index.php..."
    cat > "$USERMANAGER_DIR/app/index.php" << 'PHP_INDEX_EOF'
<?php
error_reporting(E_ALL);
ini_set('display_errors', 1);

$db_host = getenv('DB_HOST') ?: 'bolt-mariadb';
$db_port = getenv('DB_PORT') ?: '3306';
$db_name = getenv('DB_NAME') ?: 'bolt_usermanager';
$db_user = getenv('DB_USER') ?: 'bolt_um';
$db_password = getenv('DB_PASSWORD') ?: '';

try {
    $dsn = "mysql:host=$db_host;port=$db_port;dbname=$db_name;charset=utf8mb4";
    $pdo = new PDO($dsn, $db_user, $db_password, [
        PDO::ATTR_ERRMODE => PDO::ERRMODE_EXCEPTION,
        PDO::ATTR_DEFAULT_FETCH_MODE => PDO::FETCH_ASSOC
    ]);

    $stmt = $pdo->query("SELECT COUNT(*) FROM users");
    $total_users = $stmt->fetchColumn();

    $stmt = $pdo->query("SELECT COUNT(*) FROM users WHERE is_active = 1");
    $active_users = $stmt->fetchColumn();

    $stmt = $pdo->query("SELECT COUNT(*) FROM groups");
    $total_groups = $stmt->fetchColumn();
} catch (PDOException $e) {
    die('DB Error: ' . $e->getMessage());
}
?>
<!DOCTYPE html>
<html lang="fr">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>User Manager v2.0</title>
    <style>
        * { margin: 0; padding: 0; box-sizing: border-box; }
        body {
            font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif;
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            min-height: 100vh;
            padding: 20px;
        }
        .container { max-width: 1200px; margin: 0 auto; }
        .header {
            background: white;
            border-radius: 15px;
            padding: 30px;
            margin-bottom: 20px;
            box-shadow: 0 10px 30px rgba(0,0,0,0.2);
        }
        .header h1 { color: #667eea; font-size: 32px; }
        .stats {
            display: grid;
            grid-template-columns: repeat(auto-fit, minmax(250px, 1fr));
            gap: 20px;
        }
        .stat-card {
            background: white;
            border-radius: 15px;
            padding: 25px;
            box-shadow: 0 10px 30px rgba(0,0,0,0.2);
            text-align: center;
        }
        .stat-card h3 { color: #667eea; font-size: 36px; }
        .stat-card p { color: #666; font-size: 14px; }
    </style>
</head>
<body>
    <div class="container">
        <div class="header">
            <h1>🔧 User Manager v2.0</h1>
            <p>Bolt.DIY Intranet Edition</p>
        </div>
        <div class="stats">
            <div class="stat-card">
                <h3><?php echo $total_users; ?></h3>
                <p>Utilisateurs totaux</p>
            </div>
            <div class="stat-card">
                <h3><?php echo $active_users; ?></h3>
                <p>Utilisateurs actifs</p>
            </div>
            <div class="stat-card">
                <h3><?php echo $total_groups; ?></h3>
                <p>Groupes</p>
            </div>
        </div>
    </div>
</body>
</html>
PHP_INDEX_EOF

    print_success "index.php créé"
    echo ""
}

generate_html_pages() {
    print_section "GÉNÉRATION DES PAGES HTML"

    if [ -d "$TEMPLATES_DIR" ] && [ -f "$TEMPLATES_DIR/home.html" ]; then
        print_step "Génération de la page d'accueil..."
        sed -e "s/LOCAL_IP/$LOCAL_IP/g" \
            -e "s/HOST_PORT_BOLT/$HOST_PORT_BOLT/g" \
            -e "s/HOST_PORT_HOME/$HOST_PORT_HOME/g" \
            -e "s/HOST_PORT_UM/$HOST_PORT_UM/g" \
            "$TEMPLATES_DIR/home.html" > "$TEMPLATES_DIR/home_generated.html" 2>/dev/null || true
        print_success "Page d'accueil générée"
    else
        print_warning "Template home.html non trouvé"
    fi

    echo ""
}

fix_bolt_dockerfile() {
    print_section "FIX DOCKERFILE BOLT"

    cd "$INSTALL_DIR"

    local dockerfile_template="$TEMPLATES_DIR/bolt.diy/Dockerfile"
    local dockerfile_target="$BOLT_DIR/Dockerfile"

    if [ -f "$dockerfile_template" ] && [ -f "$dockerfile_target" ]; then
        print_step "Application du fix wrangler..."
        cp "$dockerfile_template" "$dockerfile_target"
        print_success "Fix Dockerfile appliqué"
    else
        print_warning "Templates Dockerfile non trouvés, skip"
    fi

    echo ""
}
