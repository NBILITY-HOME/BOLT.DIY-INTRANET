<?php
/**
 * ═══════════════════════════════════════════════════════════════════════════
 * BOLT.DIY USER MANAGER v2.0 - Configuration Application
 * © Copyright Nbility 2025 - contact@nbility.fr
 * 
 * Configuration générale de l'application
 * ═══════════════════════════════════════════════════════════════════════════
 */

declare(strict_types=1);

// ───────────────────────────────────────────────────────────────────────────
// INFORMATIONS DE L'APPLICATION
// ───────────────────────────────────────────────────────────────────────────

define('APP_CONFIG', [
    'name' => getenv('APP_NAME') ?: 'Bolt.DIY User Manager',
    'version' => '2.0.0',
    'description' => 'Interface de gestion des utilisateurs et groupes',
    'author' => 'Nbility',
    'email' => 'contact@nbility.fr',
    'url' => getenv('APP_URL') ?: 'http://192.168.1.200:8687',
    'timezone' => getenv('APP_TIMEZONE') ?: 'Europe/Paris',
    'locale' => getenv('APP_LOCALE') ?: 'fr_FR',
    'env' => getenv('APP_ENV') ?: 'production',
]);

// ───────────────────────────────────────────────────────────────────────────
// ENVIRONNEMENT
// ───────────────────────────────────────────────────────────────────────────

define('APP_ENV', APP_CONFIG['env']);
define('IS_PRODUCTION', APP_ENV === 'production');
define('IS_DEVELOPMENT', APP_ENV === 'development');
define('IS_DEBUG', getenv('APP_DEBUG') === 'true' || IS_DEVELOPMENT);

// ───────────────────────────────────────────────────────────────────────────
// CHEMINS DE L'APPLICATION
// ───────────────────────────────────────────────────────────────────────────

define('APP_ROOT', dirname(__DIR__));
define('APP_CONFIG_DIR', APP_ROOT . '/config');
define('APP_SRC_DIR', APP_ROOT . '/src');
define('APP_PUBLIC_DIR', APP_ROOT . '/public');
define('APP_LOGS_DIR', APP_ROOT . '/logs');
define('APP_CACHE_DIR', APP_ROOT . '/cache');
define('APP_UPLOADS_DIR', APP_ROOT . '/uploads');
define('APP_BACKUPS_DIR', APP_ROOT . '/backups');

// Créer les répertoires si nécessaire
foreach ([APP_LOGS_DIR, APP_CACHE_DIR, APP_UPLOADS_DIR, APP_BACKUPS_DIR] as $dir) {
    if (!is_dir($dir)) {
        mkdir($dir, 0755, true);
    }
}

// ───────────────────────────────────────────────────────────────────────────
// PAGINATION ET LIMITES
// ───────────────────────────────────────────────────────────────────────────

define('PAGINATION_CONFIG', [
    'default_per_page' => 20,
    'max_per_page' => 100,
    'min_per_page' => 5,
]);

// ───────────────────────────────────────────────────────────────────────────
// FORMATS DE DATES
// ───────────────────────────────────────────────────────────────────────────

define('DATE_FORMAT', [
    'datetime' => 'Y-m-d H:i:s',
    'date' => 'Y-m-d',
    'time' => 'H:i:s',
    'display' => 'd/m/Y H:i',
    'display_date' => 'd/m/Y',
    'display_time' => 'H:i',
]);

// ───────────────────────────────────────────────────────────────────────────
// CACHE
// ───────────────────────────────────────────────────────────────────────────

define('CACHE_CONFIG', [
    'enabled' => true,
    'ttl' => 3600, // 1 heure
    'driver' => 'file', // file, redis, memcached
]);

/**
 * Obtenir un élément du cache
 * 
 * @param string $key
 * @return mixed|null
 */
function cacheGet(string $key)
{
    if (!CACHE_CONFIG['enabled']) {
        return null;
    }

    $file = APP_CACHE_DIR . '/' . md5($key) . '.cache';

    if (!file_exists($file)) {
        return null;
    }

    $data = unserialize(file_get_contents($file));

    if ($data['expires_at'] < time()) {
        unlink($file);
        return null;
    }

    return $data['value'];
}

/**
 * Stocker un élément dans le cache
 * 
 * @param string $key
 * @param mixed $value
 * @param int|null $ttl
 */
function cacheSet(string $key, $value, ?int $ttl = null): void
{
    if (!CACHE_CONFIG['enabled']) {
        return;
    }

    $ttl = $ttl ?? CACHE_CONFIG['ttl'];
    $file = APP_CACHE_DIR . '/' . md5($key) . '.cache';

    $data = [
        'value' => $value,
        'expires_at' => time() + $ttl,
    ];

    file_put_contents($file, serialize($data));
}

/**
 * Supprimer un élément du cache
 * 
 * @param string $key
 */
function cacheDelete(string $key): void
{
    $file = APP_CACHE_DIR . '/' . md5($key) . '.cache';

    if (file_exists($file)) {
        unlink($file);
    }
}

/**
 * Vider tout le cache
 */
function cacheClear(): void
{
    $files = glob(APP_CACHE_DIR . '/*.cache');
    foreach ($files as $file) {
        if (is_file($file)) {
            unlink($file);
        }
    }
}

// ───────────────────────────────────────────────────────────────────────────
// MESSAGES ET NOTIFICATIONS
// ───────────────────────────────────────────────────────────────────────────

define('MESSAGE_TYPES', [
    'success' => 'Opération réussie',
    'error' => 'Une erreur est survenue',
    'warning' => 'Attention',
    'info' => 'Information',
]);

// ───────────────────────────────────────────────────────────────────────────
// RÔLES ET PERMISSIONS
// ───────────────────────────────────────────────────────────────────────────

define('USER_ROLES', [
    'superadmin' => [
        'name' => 'Super Administrateur',
        'level' => 3,
        'description' => 'Accès complet au système',
    ],
    'admin' => [
        'name' => 'Administrateur',
        'level' => 2,
        'description' => 'Gestion des utilisateurs et groupes',
    ],
    'user' => [
        'name' => 'Utilisateur',
        'level' => 1,
        'description' => 'Accès limité en lecture',
    ],
]);

// ───────────────────────────────────────────────────────────────────────────
// MAINTENANCE
// ───────────────────────────────────────────────────────────────────────────

define('MAINTENANCE_CONFIG', [
    'enabled' => getenv('MAINTENANCE_MODE') === 'true',
    'message' => 'Application en maintenance. Merci de réessayer plus tard.',
    'allowed_ips' => explode(',', getenv('MAINTENANCE_ALLOWED_IPS') ?: '127.0.0.1'),
]);

/**
 * Vérifier si le mode maintenance est activé
 * 
 * @return bool
 */
function isMaintenanceMode(): bool
{
    if (!MAINTENANCE_CONFIG['enabled']) {
        return false;
    }

    $clientIp = $_SERVER['REMOTE_ADDR'] ?? '0.0.0.0';

    return !in_array($clientIp, MAINTENANCE_CONFIG['allowed_ips'], true);
}

/**
 * ═══════════════════════════════════════════════════════════════════════════
 * FIN DE LA CONFIGURATION APPLICATION
 * ═══════════════════════════════════════════════════════════════════════════
 */
