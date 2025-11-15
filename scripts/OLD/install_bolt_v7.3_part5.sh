
#═══════════════════════════════════════════════════════════════════════════
# COPIE DES FICHIERS SQL
#═══════════════════════════════════════════════════════════════════════════

copy_sql_files() {
    print_section "COPIE DES FICHIERS SQL"

    # Copier 01-schema.sql
    print_step "Copie de 01-schema.sql vers mariadb/init..."

    if [ -f "$USERMANAGER_DIR/app/database/migrations/01-schema.sql" ]; then
        cp "$USERMANAGER_DIR/app/database/migrations/01-schema.sql" "$MARIADB_DIR/init/"
        print_success "01-schema.sql copié"
    else
        print_error "01-schema.sql manquant dans le repository"
        print_error "Chemin attendu: $USERMANAGER_DIR/app/database/migrations/01-schema.sql"
        exit 1
    fi

    # Copier 02-seed.sql et remplacer les variables
    print_step "Copie de 02-seed.sql vers mariadb/init..."

    if [ -f "$USERMANAGER_DIR/app/database/migrations/02-seed.sql" ]; then
        cp "$USERMANAGER_DIR/app/database/migrations/02-seed.sql" "$MARIADB_DIR/init/"

        # Remplacer les variables dans seed.sql
        print_step "Configuration de l'utilisateur admin dans 02-seed.sql..."
        sed -i "s/{{ADMIN_USER}}/$ADMIN_USER/g" "$MARIADB_DIR/init/02-seed.sql"
        sed -i "s/{{ADMIN_PASSWORD_HASH}}/$ADMIN_PASSWORD_HASH/g" "$MARIADB_DIR/init/02-seed.sql"

        print_success "02-seed.sql copié et configuré"
    else
        print_error "02-seed.sql manquant dans le repository"
        print_error "Chemin attendu: $USERMANAGER_DIR/app/database/migrations/02-seed.sql"
        exit 1
    fi
}

#═══════════════════════════════════════════════════════════════════════════
# GÉNÉRATION HEALTH.PHP
#═══════════════════════════════════════════════════════════════════════════

generate_health_php() {
    print_section "GÉNÉRATION HEALTH.PHP"

    print_step "Création du fichier health.php..."

    cat > "$USERMANAGER_DIR/app/public/health.php" << 'HEALTH_PHP_EOF'
<?php
/**
 * Health Check Endpoint
 * Vérifie l'état de santé de l'application User Manager
 */

header('Content-Type: application/json');

$health = [
    'status' => 'healthy',
    'timestamp' => date('Y-m-d H:i:s'),
    'checks' => []
];

// Vérifier PHP
$health['checks']['php'] = [
    'status' => 'ok',
    'version' => PHP_VERSION
];

// Vérifier la connexion à la base de données
try {
    $host = getenv('DB_HOST') ?: 'mariadb';
    $db = getenv('DB_DATABASE') ?: 'usermanager';
    $user = getenv('DB_USERNAME') ?: 'usermanager';
    $pass = getenv('DB_PASSWORD') ?: '';

    $dsn = "mysql:host=$host;dbname=$db;charset=utf8mb4";
    $pdo = new PDO($dsn, $user, $pass, [
        PDO::ATTR_ERRMODE => PDO::ERRMODE_EXCEPTION,
        PDO::ATTR_TIMEOUT => 5
    ]);

    $health['checks']['database'] = [
        'status' => 'ok',
        'host' => $host,
        'database' => $db
    ];
} catch (PDOException $e) {
    $health['status'] = 'unhealthy';
    $health['checks']['database'] = [
        'status' => 'error',
        'message' => 'Database connection failed'
    ];
}

// Vérifier les dossiers d'écriture
$writableDirs = [
    '/var/www/html/logs',
    '/var/www/html/uploads'
];

foreach ($writableDirs as $dir) {
    $isWritable = is_dir($dir) && is_writable($dir);
    $health['checks']['filesystem'][$dir] = [
        'status' => $isWritable ? 'ok' : 'error',
        'writable' => $isWritable
    ];

    if (!$isWritable) {
        $health['status'] = 'unhealthy';
    }
}

// Définir le code HTTP approprié
http_response_code($health['status'] === 'healthy' ? 200 : 503);

echo json_encode($health, JSON_PRETTY_PRINT);
HEALTH_PHP_EOF

    print_success "health.php créé"
}

#═══════════════════════════════════════════════════════════════════════════
# VÉRIFICATION FINALE
#═══════════════════════════════════════════════════════════════════════════

final_verification() {
    print_section "VÉRIFICATION FINALE"

    local all_ok=true

    print_step "Vérification de la structure..."

    # Vérifier les fichiers critiques
    local critical_files=(
        "$PROJECT_ROOT/docker-compose.yml"
        "$PROJECT_ROOT/.env"
        "$NGINX_DIR/nginx.conf"
        "$NGINX_DIR/.htpasswd"
        "$NGINX_DIR/index.html"
        "$BOLTDIY_DIR/.env"
        "$USERMANAGER_DIR/.env"
        "$USERMANAGER_DIR/Dockerfile"
        "$MARIADB_DIR/init/01-schema.sql"
        "$MARIADB_DIR/init/02-seed.sql"
    )

    for file in "${critical_files[@]}"; do
        if [ -f "$file" ]; then
            print_success "$(basename "$file") présent"
        else
            print_error "$(basename "$file") manquant"
            all_ok=false
        fi
    done

    # Vérifier les dossiers critiques
    local critical_dirs=(
        "$BOLTDIY_DIR"
        "$NGINX_DIR"
        "$MARIADB_DIR/init"
        "$MARIADB_DIR/data"
        "$USERMANAGER_DIR/app"
    )

    for dir in "${critical_dirs[@]}"; do
        if [ -d "$dir" ]; then
            print_success "$(basename "$dir")/ présent"
        else
            print_error "$(basename "$dir")/ manquant"
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
