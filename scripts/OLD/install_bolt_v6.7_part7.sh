
# ═══════════════════════════════════════════════════════════════════════════
# FONCTION: Création des fichiers User Manager v6.7
# ═══════════════════════════════════════════════════════════════════════════
create_usermanager_files() {
    print_section "CRÉATION DES FICHIERS USER MANAGER v6.7"

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

    print_step "Génération de index.php avec bouton déconnexion (v6.7)..."
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
    $total_users = $active_users = $total_groups = 0;
    $db_error = $e->getMessage();
}
?>
<!DOCTYPE html>
<html lang="fr">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>User Manager v2.0</title>
    <style>
        *{margin:0;padding:0;box-sizing:border-box}
        body{font-family:-apple-system,BlinkMacSystemFont,'Segoe UI',Roboto,sans-serif;background:linear-gradient(135deg,#667eea 0%,#764ba2 100%);min-height:100vh;padding:20px}
        .container{max-width:1200px;margin:0 auto}
        .header{background:white;border-radius:15px;padding:30px;margin-bottom:20px;box-shadow:0 10px 30px rgba(0,0,0,0.2);display:flex;justify-content:space-between;align-items:center;flex-wrap:wrap;gap:20px}
        .header-left h1{color:#667eea;font-size:32px;margin-bottom:5px}
        .header-left p{color:#666;font-size:14px}
        .header-right{display:flex;gap:10px;align-items:center}
        .user-info{display:flex;align-items:center;gap:10px;padding:10px 15px;background:#f3f4f6;border-radius:10px;font-size:14px;color:#374151}
        .user-icon{width:35px;height:35px;background:linear-gradient(135deg,#667eea,#764ba2);border-radius:50%;display:flex;align-items:center;justify-content:center;color:white;font-weight:bold}
        .btn-logout{padding:12px 24px;background:linear-gradient(135deg,#ef4444,#dc2626);color:white;border:none;border-radius:10px;font-weight:600;cursor:pointer;transition:all 0.3s ease;text-decoration:none;display:inline-flex;align-items:center;gap:8px;font-size:15px}
        .btn-logout:hover{transform:translateY(-2px);box-shadow:0 8px 20px rgba(239,68,68,0.4)}
        .stats{display:grid;grid-template-columns:repeat(auto-fit,minmax(250px,1fr));gap:20px}
        .stat-card{background:white;border-radius:15px;padding:25px;box-shadow:0 10px 30px rgba(0,0,0,0.2);text-align:center}
        .stat-card h3{color:#667eea;font-size:36px;margin-bottom:10px}
        .stat-card p{color:#666;font-size:14px;text-transform:uppercase;letter-spacing:1px}
        .footer{text-align:center;color:white;margin-top:30px;font-size:14px;opacity:0.9}
        @media(max-width:768px){.header{flex-direction:column;text-align:center}.header-right{flex-direction:column;width:100%}.btn-logout{width:100%;justify-content:center}}
    </style>
</head>
<body>
    <div class="container">
        <div class="header">
            <div class="header-left">
                <h1>🔧 User Manager v2.0</h1>
                <p>Bolt.DIY Intranet Edition v6.7</p>
            </div>
            <div class="header-right">
                <div class="user-info">
                    <div class="user-icon"><?php echo strtoupper(substr($_SERVER['PHP_AUTH_USER']??'A',0,1));?></div>
                    <span><strong><?php echo htmlspecialchars($_SERVER['PHP_AUTH_USER']??'Admin');?></strong></span>
                </div>
                <a href="/logout.php" class="btn-logout">🚪 Déconnexion</a>
            </div>
        </div>
        <div class="stats">
            <div class="stat-card"><h3><?php echo $total_users;?></h3><p>Utilisateurs totaux</p></div>
            <div class="stat-card"><h3><?php echo $active_users;?></h3><p>Utilisateurs actifs</p></div>
            <div class="stat-card"><h3><?php echo $total_groups;?></h3><p>Groupes</p></div>
        </div>
        <?php if(isset($db_error)):?>
        <div style="background:#fef2f2;border:2px solid #ef4444;border-radius:15px;padding:20px;margin-top:20px">
            <h3 style="color:#dc2626;margin-bottom:10px">⚠️ Erreur de connexion</h3>
            <p style="color:#7f1d1d;font-size:14px"><?php echo htmlspecialchars($db_error);?></p>
        </div>
        <?php endif;?>
        <div class="footer">© 2025 Nbility - Bolt.DIY v6.7 - User Manager v2.0</div>
    </div>
</body>
</html>
PHP_INDEX_EOF
    print_success "index.php créé avec bouton déconnexion"

    print_step "Génération de logout.php (NOUVEAU v6.7)..."
    cat > "$USERMANAGER_DIR/app/logout.php" << 'PHP_LOGOUT_EOF'
<?php
header('WWW-Authenticate: Basic realm="Déconnexion"');
header('HTTP/1.0 401 Unauthorized');
?>
<!DOCTYPE html>
<html lang="fr">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Déconnexion - User Manager</title>
    <style>
        *{margin:0;padding:0;box-sizing:border-box}
        body{font-family:-apple-system,BlinkMacSystemFont,'Segoe UI',Roboto,sans-serif;background:linear-gradient(135deg,#667eea 0%,#764ba2 100%);min-height:100vh;display:flex;align-items:center;justify-content:center;padding:20px}
        .container{background:white;border-radius:20px;padding:60px 40px;box-shadow:0 20px 60px rgba(0,0,0,0.3);text-align:center;max-width:500px;width:100%;animation:slideUp 0.5s ease-out}
        @keyframes slideUp{from{opacity:0;transform:translateY(30px)}to{opacity:1;transform:translateY(0)}}
        .icon{font-size:80px;margin-bottom:20px;animation:bounce 1s ease infinite}
        @keyframes bounce{0%,100%{transform:translateY(0)}50%{transform:translateY(-10px)}}
        h1{color:#667eea;font-size:32px;margin-bottom:15px;font-weight:700}
        p{color:#666;font-size:16px;line-height:1.6;margin-bottom:30px}
        .success-message{background:#10b981;color:white;padding:15px 20px;border-radius:10px;margin-bottom:30px;font-weight:600}
        .buttons{display:flex;gap:15px;justify-content:center;flex-wrap:wrap}
        .btn{display:inline-block;padding:14px 32px;border-radius:12px;font-weight:600;font-size:16px;text-decoration:none;transition:all 0.3s ease;cursor:pointer;border:none}
        .btn-primary{background:linear-gradient(135deg,#667eea,#764ba2);color:white;box-shadow:0 4px 15px rgba(102,126,234,0.4)}
        .btn-primary:hover{transform:translateY(-2px);box-shadow:0 8px 25px rgba(102,126,234,0.6)}
        .btn-secondary{background:#f3f4f6;color:#667eea}
        .btn-secondary:hover{background:#e5e7eb;transform:translateY(-2px)}
        .info-box{background:#f0f9ff;border:2px solid #bfdbfe;border-radius:10px;padding:15px;margin-top:30px;font-size:14px;color:#1e40af;text-align:left}
        .info-box strong{display:block;margin-bottom:8px;font-size:15px}
        @media(max-width:600px){.container{padding:40px 30px}h1{font-size:26px}.buttons{flex-direction:column}.btn{width:100%}}
    </style>
</head>
<body>
    <div class="container">
        <div class="icon">👋</div>
        <h1>Déconnexion réussie</h1>
        <div class="success-message">✓ Vous avez été déconnecté avec succès</div>
        <p>Votre session a été fermée. Pour des raisons de sécurité, nous vous recommandons de fermer complètement votre navigateur.</p>
        <div class="buttons">
            <a href="http://LOCAL_IP:HOST_PORT_UM" class="btn btn-primary">🔐 Se reconnecter</a>
            <a href="http://LOCAL_IP:HOST_PORT_HOME" class="btn btn-secondary">🏠 Page d'accueil</a>
        </div>
        <div class="info-box">
            <strong>ℹ️ Note importante :</strong>
            L'authentification HTTP Basic est stockée par votre navigateur. Pour une déconnexion complète, fermez tous les onglets et redémarrez votre navigateur.
        </div>
    </div>
</body>
</html>
PHP_LOGOUT_EOF
    print_success "logout.php créé (NOUVEAU v6.7)"

    echo ""
}

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

generate_html_pages() {
    print_section "GÉNÉRATION DE home.html (v6.7 - avec rel)"

    print_step "Génération de la page d'accueil avec corrections..."

    if [ -f "$TEMPLATES_DIR/home.html" ]; then
        sed -i "s/LOCAL_IP/$LOCAL_IP/g" "$TEMPLATES_DIR/home.html"
        sed -i "s/HOST_PORT_BOLT/$HOST_PORT_BOLT/g" "$TEMPLATES_DIR/home.html"
        sed -i "s/HOST_PORT_HOME/$HOST_PORT_HOME/g" "$TEMPLATES_DIR/home.html"
        sed -i "s/HOST_PORT_UM/$HOST_PORT_UM/g" "$TEMPLATES_DIR/home.html"
        print_success "Variables remplacées dans home.html"
    else
        print_warning "home.html non trouvé, création par défaut..."
        echo "<!DOCTYPE html><html><head><title>Bolt.DIY v6.7</title></head><body><h1>Welcome to Bolt.DIY</h1></body></html>" > "$TEMPLATES_DIR/home.html"
    fi

    if [ -f "$USERMANAGER_DIR/app/logout.php" ]; then
        sed -i "s/LOCAL_IP/$LOCAL_IP/g" "$USERMANAGER_DIR/app/logout.php"
        sed -i "s/HOST_PORT_UM/$HOST_PORT_UM/g" "$USERMANAGER_DIR/app/logout.php"
        sed -i "s/HOST_PORT_HOME/$HOST_PORT_HOME/g" "$USERMANAGER_DIR/app/logout.php"
        print_success "Variables remplacées dans logout.php"
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
