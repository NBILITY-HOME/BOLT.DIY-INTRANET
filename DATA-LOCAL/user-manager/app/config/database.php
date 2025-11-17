<?php
/**
 * ═══════════════════════════════════════════════════════════════════════════
 * BOLT.DIY USER MANAGER v2.0 - Configuration Base de Données
 * © Copyright Nbility 2025 - contact@nbility.fr
 * 
 * Configuration de connexion à MariaDB
 * ═══════════════════════════════════════════════════════════════════════════
 */

declare(strict_types=1);

// ───────────────────────────────────────────────────────────────────────────
// CONFIGURATION MARIADB
// ───────────────────────────────────────────────────────────────────────────

define('DB_CONFIG', [
    'host' => getenv('DB_HOST') ?: 'bolt-mariadb',
    'port' => (int)(getenv('DB_PORT') ?: 3306),
    'database' => getenv('DB_NAME') ?: 'bolt_usermanager',
    'username' => getenv('DB_USER') ?: 'bolt_um',
    'password' => getenv('DB_PASSWORD') ?: '',
    'charset' => 'utf8mb4',
    'collation' => 'utf8mb4_unicode_ci',
    'prefix' => 'um_',

    // Options PDO
    'options' => [
        PDO::ATTR_ERRMODE => PDO::ERRMODE_EXCEPTION,
        PDO::ATTR_DEFAULT_FETCH_MODE => PDO::FETCH_ASSOC,
        PDO::ATTR_EMULATE_PREPARES => false,
        PDO::ATTR_PERSISTENT => false,
        PDO::MYSQL_ATTR_INIT_COMMAND => "SET NAMES utf8mb4 COLLATE utf8mb4_unicode_ci"
    ]
]);

// ───────────────────────────────────────────────────────────────────────────
// FONCTION DE CONNEXION PDO
// ───────────────────────────────────────────────────────────────────────────

/**
 * Obtenir une connexion PDO à la base de données
 * 
 * @return PDO
 * @throws PDOException
 */
function getDbConnection(): PDO
{
    static $pdo = null;

    if ($pdo === null) {
        $config = DB_CONFIG;

        $dsn = sprintf(
            'mysql:host=%s;port=%d;dbname=%s;charset=%s',
            $config['host'],
            $config['port'],
            $config['database'],
            $config['charset']
        );

        try {
            $pdo = new PDO(
                $dsn,
                $config['username'],
                $config['password'],
                $config['options']
            );
        } catch (PDOException $e) {
            error_log("Database connection failed: " . $e->getMessage());
            throw new PDOException("Impossible de se connecter à la base de données", 0, $e);
        }
    }

    return $pdo;
}

/**
 * Tester la connexion à la base de données
 * 
 * @return bool
 */
function testDbConnection(): bool
{
    try {
        $pdo = getDbConnection();
        $pdo->query('SELECT 1');
        return true;
    } catch (PDOException $e) {
        error_log("Database test failed: " . $e->getMessage());
        return false;
    }
}

// ───────────────────────────────────────────────────────────────────────────
// TABLES DE LA BASE DE DONNÉES
// ───────────────────────────────────────────────────────────────────────────

define('DB_TABLES', [
    'users' => DB_CONFIG['prefix'] . 'users',
    'groups' => DB_CONFIG['prefix'] . 'groups',
    'user_groups' => DB_CONFIG['prefix'] . 'user_groups',
    'permissions' => DB_CONFIG['prefix'] . 'permissions',
    'group_permissions' => DB_CONFIG['prefix'] . 'group_permissions',
    'sessions' => DB_CONFIG['prefix'] . 'sessions',
    'audit_logs' => DB_CONFIG['prefix'] . 'audit_logs',
    'settings' => DB_CONFIG['prefix'] . 'settings',
    'password_resets' => DB_CONFIG['prefix'] . 'password_resets',
    'notifications' => DB_CONFIG['prefix'] . 'notifications',
    'themes' => DB_CONFIG['prefix'] . 'themes',
]);

/**
 * ═══════════════════════════════════════════════════════════════════════════
 * FIN DE LA CONFIGURATION DATABASE
 * ═══════════════════════════════════════════════════════════════════════════
 */
