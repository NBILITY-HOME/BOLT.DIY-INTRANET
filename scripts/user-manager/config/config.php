<?php
/**
 * Bolt.DIY User Manager - Configuration
 * Version: 1.0
 * Date: 18 novembre 2025
 */

// Empêcher l'accès direct
if (!defined('USER_MANAGER_APP')) {
    die('Accès interdit');
}

// ============================================
// CONFIGURATION GÉNÉRALE
// ============================================

// URLs
define('BASE_URL', '/user-manager');
define('ASSETS_URL', BASE_URL . '/assets');
define('API_URL', BASE_URL . '/api');

// Chemins du système de fichiers
define('APP_ROOT', dirname(__DIR__));
define('PUBLIC_ROOT', APP_ROOT . '/public');
define('SRC_ROOT', APP_ROOT . '/src');
define('CONFIG_ROOT', dirname(APP_ROOT) . '/config');
define('LOGS_ROOT', dirname(APP_ROOT) . '/logs');

// ============================================
// CONFIGURATION DE LA BASE DE DONNÉES
// ============================================

define('DB_HOST', getenv('DB_HOST') ?: 'localhost');
define('DB_NAME', getenv('DB_NAME') ?: 'user_manager');
define('DB_USER', getenv('DB_USER') ?: 'root');
define('DB_PASS', getenv('DB_PASS') ?: '');
define('DB_CHARSET', 'utf8mb4');

// ============================================
// CONFIGURATION DES SESSIONS
// ============================================

define('SESSION_NAME', 'USERMGR_SESSION');
define('SESSION_LIFETIME', 3600); // 1 heure
define('SESSION_SECURE', false); // Mettre true en HTTPS
define('SESSION_HTTPONLY', true);
define('SESSION_SAMESITE', 'Strict');

// ============================================
// CONFIGURATION DE SÉCURITÉ
// ============================================

define('CSRF_TOKEN_NAME', 'csrf_token');
define('PASSWORD_MIN_LENGTH', 8);
define('MAX_LOGIN_ATTEMPTS', 5);
define('LOGIN_TIMEOUT', 900); // 15 minutes

// ============================================
// CONFIGURATION DE L'APPLICATION
// ============================================

define('APP_NAME', 'Bolt.DIY User Manager');
define('APP_VERSION', '1.0');
define('APP_ENV', getenv('APP_ENV') ?: 'development'); // production, development
define('APP_DEBUG', APP_ENV === 'development');

// Timezone
date_default_timezone_set('Europe/Paris');

// ============================================
// CONFIGURATION DES LOGS
// ============================================

define('LOG_LEVEL', APP_DEBUG ? 'DEBUG' : 'ERROR'); // DEBUG, INFO, WARNING, ERROR
define('LOG_FILE', LOGS_ROOT . '/app.log');
define('ERROR_LOG_FILE', LOGS_ROOT . '/error.log');
define('AUDIT_LOG_FILE', LOGS_ROOT . '/audit.log');

// ============================================
// CONFIGURATION PHP
// ============================================

// Gestion des erreurs
if (APP_DEBUG) {
    error_reporting(E_ALL);
    ini_set('display_errors', 1);
    ini_set('display_startup_errors', 1);
} else {
    error_reporting(E_ALL & ~E_DEPRECATED & ~E_STRICT);
    ini_set('display_errors', 0);
    ini_set('display_startup_errors', 0);
}

ini_set('log_errors', 1);
ini_set('error_log', ERROR_LOG_FILE);

// Limites
ini_set('memory_limit', '256M');
ini_set('max_execution_time', '60');
ini_set('upload_max_filesize', '10M');
ini_set('post_max_size', '10M');

// ============================================
// CONFIGURATION DES EMAILS
// ============================================

define('SMTP_HOST', getenv('SMTP_HOST') ?: 'smtp.example.com');
define('SMTP_PORT', getenv('SMTP_PORT') ?: 587);
define('SMTP_USER', getenv('SMTP_USER') ?: '');
define('SMTP_PASS', getenv('SMTP_PASS') ?: '');
define('SMTP_FROM', getenv('SMTP_FROM') ?: 'noreply@example.com');
define('SMTP_FROM_NAME', getenv('SMTP_FROM_NAME') ?: APP_NAME);

// ============================================
// ROUTES DE L'APPLICATION
// ============================================

$routes = [
    '' => 'dashboard',
    'dashboard' => 'dashboard',
    'users' => 'users',
    'users/add' => 'users_add',
    'users/edit' => 'users_edit',
    'groups' => 'groups',
    'permissions' => 'permissions',
    'audit' => 'audit',
    'settings' => 'settings',
    'login' => 'login',
    'logout' => 'logout',
];

// ============================================
// MENU DE NAVIGATION
// ============================================

$navigation = [
    'main' => [
        [
            'id' => 'dashboard',
            'icon' => 'fa-home',
            'label' => 'Dashboard',
            'url' => BASE_URL . '/',
            'badge' => null
        ],
        [
            'id' => 'users',
            'icon' => 'fa-users',
            'label' => 'Utilisateurs',
            'url' => BASE_URL . '/users',
            'badge' => null
        ],
        [
            'id' => 'groups',
            'icon' => 'fa-layer-group',
            'label' => 'Groupes',
            'url' => BASE_URL . '/groups',
            'badge' => null
        ],
        [
            'id' => 'permissions',
            'icon' => 'fa-shield-alt',
            'label' => 'Permissions',
            'url' => BASE_URL . '/permissions',
            'badge' => null
        ],
        [
            'id' => 'audit',
            'icon' => 'fa-clipboard-list',
            'label' => 'Audit',
            'url' => BASE_URL . '/audit',
            'badge' => null
        ],
        [
            'id' => 'settings',
            'icon' => 'fa-cog',
            'label' => 'Paramètres',
            'url' => BASE_URL . '/settings',
            'badge' => null
        ],
    ],
    'shortcuts' => [
        [
            'id' => 'add-user',
            'icon' => 'fa-plus-circle',
            'label' => 'Nouvel utilisateur',
            'url' => BASE_URL . '/users/add',
            'badge' => null
        ],
        [
            'id' => 'export',
            'icon' => 'fa-calendar',
            'label' => 'Programmer export',
            'url' => '#',
            'badge' => null
        ],
    ]
];

// ============================================
// FONCTIONS DE CONFIGURATION
// ============================================

/**
 * Obtenir une valeur de configuration
 */
function config($key, $default = null) {
    if (defined($key)) {
        return constant($key);
    }
    return $default;
}

/**
 * Vérifier si l'environnement est en développement
 */
function is_dev() {
    return APP_ENV === 'development';
}

/**
 * Vérifier si l'environnement est en production
 */
function is_prod() {
    return APP_ENV === 'production';
}
