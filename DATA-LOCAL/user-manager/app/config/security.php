<?php
/**
 * ═══════════════════════════════════════════════════════════════════════════
 * BOLT.DIY USER MANAGER v2.0 - Configuration Sécurité
 * © Copyright Nbility 2025 - contact@nbility.fr
 * 
 * Paramètres de sécurité, sessions, authentification
 * ═══════════════════════════════════════════════════════════════════════════
 */

declare(strict_types=1);

// ───────────────────────────────────────────────────────────────────────────
// CONFIGURATION DES SESSIONS
// ───────────────────────────────────────────────────────────────────────────

define('SESSION_CONFIG', [
    'name' => 'BOLTUMSESSID',
    'lifetime' => (int)(getenv('SESSION_LIFETIME') ?: 1800), // 30 minutes
    'path' => '/',
    'domain' => '',
    'secure' => false, // Mettre à true si HTTPS
    'httponly' => true,
    'samesite' => 'Strict',
    'save_path' => '/tmp/bolt_um_sessions',
]);

/**
 * Initialiser les sessions sécurisées
 */
function initSecureSession(): void
{
    $config = SESSION_CONFIG;

    // Créer le répertoire de sessions si nécessaire
    if (!is_dir($config['save_path'])) {
        mkdir($config['save_path'], 0700, true);
    }

    // Configuration de la session
    ini_set('session.save_path', $config['save_path']);
    ini_set('session.name', $config['name']);
    ini_set('session.gc_maxlifetime', (string)$config['lifetime']);
    ini_set('session.cookie_lifetime', (string)$config['lifetime']);
    ini_set('session.cookie_httponly', '1');
    ini_set('session.cookie_secure', $config['secure'] ? '1' : '0');
    ini_set('session.cookie_samesite', $config['samesite']);
    ini_set('session.use_strict_mode', '1');
    ini_set('session.use_only_cookies', '1');

    // Démarrer la session
    if (session_status() === PHP_SESSION_NONE) {
        session_start();
    }

    // Régénérer l'ID de session périodiquement
    if (!isset($_SESSION['last_regeneration'])) {
        $_SESSION['last_regeneration'] = time();
    } elseif (time() - $_SESSION['last_regeneration'] > 300) { // Toutes les 5 minutes
        session_regenerate_id(true);
        $_SESSION['last_regeneration'] = time();
    }
}

// ───────────────────────────────────────────────────────────────────────────
// PROTECTION CSRF
// ───────────────────────────────────────────────────────────────────────────

/**
 * Générer un token CSRF
 * 
 * @return string
 */
function generateCsrfToken(): string
{
    if (!isset($_SESSION['csrf_token'])) {
        $_SESSION['csrf_token'] = bin2hex(random_bytes(32));
    }
    return $_SESSION['csrf_token'];
}

/**
 * Vérifier le token CSRF
 * 
 * @param string|null $token
 * @return bool
 */
function verifyCsrfToken(?string $token): bool
{
    if ($token === null || !isset($_SESSION['csrf_token'])) {
        return false;
    }
    return hash_equals($_SESSION['csrf_token'], $token);
}

// ───────────────────────────────────────────────────────────────────────────
// GESTION DES MOTS DE PASSE
// ───────────────────────────────────────────────────────────────────────────

define('PASSWORD_CONFIG', [
    'algorithm' => PASSWORD_BCRYPT,
    'cost' => 12,
    'min_length' => (int)(getenv('PASSWORD_MIN_LENGTH') ?: 8),
    'require_uppercase' => true,
    'require_lowercase' => true,
    'require_number' => true,
    'require_special' => true,
]);

/**
 * Hasher un mot de passe
 * 
 * @param string $password
 * @return string
 */
function hashPassword(string $password): string
{
    return password_hash($password, PASSWORD_CONFIG['algorithm'], [
        'cost' => PASSWORD_CONFIG['cost']
    ]);
}

/**
 * Vérifier un mot de passe
 * 
 * @param string $password
 * @param string $hash
 * @return bool
 */
function verifyPassword(string $password, string $hash): bool
{
    return password_verify($password, $hash);
}

/**
 * Valider la force d'un mot de passe
 * 
 * @param string $password
 * @return array ['valid' => bool, 'errors' => array]
 */
function validatePasswordStrength(string $password): array
{
    $errors = [];
    $config = PASSWORD_CONFIG;

    if (strlen($password) < $config['min_length']) {
        $errors[] = "Le mot de passe doit contenir au moins {$config['min_length']} caractères";
    }

    if ($config['require_uppercase'] && !preg_match('/[A-Z]/', $password)) {
        $errors[] = "Le mot de passe doit contenir au moins une majuscule";
    }

    if ($config['require_lowercase'] && !preg_match('/[a-z]/', $password)) {
        $errors[] = "Le mot de passe doit contenir au moins une minuscule";
    }

    if ($config['require_number'] && !preg_match('/[0-9]/', $password)) {
        $errors[] = "Le mot de passe doit contenir au moins un chiffre";
    }

    if ($config['require_special'] && !preg_match('/[^a-zA-Z0-9]/', $password)) {
        $errors[] = "Le mot de passe doit contenir au moins un caractère spécial";
    }

    return [
        'valid' => empty($errors),
        'errors' => $errors
    ];
}

// ───────────────────────────────────────────────────────────────────────────
// RATE LIMITING (Protection contre les attaques par force brute)
// ───────────────────────────────────────────────────────────────────────────

define('RATE_LIMIT_CONFIG', [
    'max_attempts' => 5,
    'lockout_duration' => 900, // 15 minutes en secondes
]);

/**
 * Vérifier si une IP est bloquée
 * 
 * @param string $ip
 * @param string $action
 * @return bool
 */
function isRateLimited(string $ip, string $action = 'login'): bool
{
    $key = "rate_limit_{$action}_{$ip}";

    if (!isset($_SESSION[$key])) {
        return false;
    }

    $data = $_SESSION[$key];

    // Si le blocage est expiré
    if ($data['locked_until'] < time()) {
        unset($_SESSION[$key]);
        return false;
    }

    return true;
}

/**
 * Enregistrer une tentative échouée
 * 
 * @param string $ip
 * @param string $action
 */
function recordFailedAttempt(string $ip, string $action = 'login'): void
{
    $key = "rate_limit_{$action}_{$ip}";
    $config = RATE_LIMIT_CONFIG;

    if (!isset($_SESSION[$key])) {
        $_SESSION[$key] = [
            'attempts' => 0,
            'first_attempt' => time(),
            'locked_until' => 0,
        ];
    }

    $_SESSION[$key]['attempts']++;

    // Bloquer si max attempts atteint
    if ($_SESSION[$key]['attempts'] >= $config['max_attempts']) {
        $_SESSION[$key]['locked_until'] = time() + $config['lockout_duration'];
    }
}

/**
 * Réinitialiser les tentatives après un succès
 * 
 * @param string $ip
 * @param string $action
 */
function resetRateLimit(string $ip, string $action = 'login'): void
{
    $key = "rate_limit_{$action}_{$ip}";
    unset($_SESSION[$key]);
}

// ───────────────────────────────────────────────────────────────────────────
// SANITIZATION ET VALIDATION
// ───────────────────────────────────────────────────────────────────────────

/**
 * Nettoyer une chaîne de caractères
 * 
 * @param string $input
 * @return string
 */
function sanitizeString(string $input): string
{
    return htmlspecialchars(trim($input), ENT_QUOTES, 'UTF-8');
}

/**
 * Valider une adresse email
 * 
 * @param string $email
 * @return bool
 */
function validateEmail(string $email): bool
{
    return filter_var($email, FILTER_VALIDATE_EMAIL) !== false;
}

/**
 * Valider un nom d'utilisateur
 * 
 * @param string $username
 * @return bool
 */
function validateUsername(string $username): bool
{
    // 3-32 caractères, alphanumérique + underscore/tiret
    return preg_match('/^[a-zA-Z0-9_-]{3,32}$/', $username) === 1;
}

/**
 * ═══════════════════════════════════════════════════════════════════════════
 * FIN DE LA CONFIGURATION SÉCURITÉ
 * ═══════════════════════════════════════════════════════════════════════════
 */
