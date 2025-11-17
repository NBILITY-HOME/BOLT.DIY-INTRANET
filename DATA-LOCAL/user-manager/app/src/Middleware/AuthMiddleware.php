<?php
/**
 * ═══════════════════════════════════════════════════════════════════════════
 * BOLT.DIY USER MANAGER v2.0 - AuthMiddleware
 * © Copyright Nbility 2025 - contact@nbility.fr
 * 
 * Middleware d'authentification et d'autorisation
 * ═══════════════════════════════════════════════════════════════════════════
 */

declare(strict_types=1);

namespace App\Middleware;

use App\Utils\Response;
use App\Utils\Logger;

/**
 * Classe AuthMiddleware - Vérification authentification et autorisations
 */
class AuthMiddleware
{
    /**
     * Vérifier si l'utilisateur est authentifié
     * 
     * @return bool
     */
    public static function isAuthenticated(): bool
    {
        // Initialiser la session si nécessaire
        if (session_status() === PHP_SESSION_NONE) {
            session_start();
        }

        return isset($_SESSION['logged_in']) && $_SESSION['logged_in'] === true;
    }

    /**
     * Vérifier si l'utilisateur a un rôle spécifique
     * 
     * @param array|string $roles Rôle(s) autorisé(s)
     * @return bool
     */
    public static function hasRole($roles): bool
    {
        if (!self::isAuthenticated()) {
            return false;
        }

        if (!isset($_SESSION['role'])) {
            return false;
        }

        $roles = is_array($roles) ? $roles : [$roles];

        return in_array($_SESSION['role'], $roles, true);
    }

    /**
     * Vérifier si l'utilisateur est admin ou superadmin
     * 
     * @return bool
     */
    public static function isAdmin(): bool
    {
        return self::hasRole(['admin', 'superadmin']);
    }

    /**
     * Vérifier si l'utilisateur est superadmin
     * 
     * @return bool
     */
    public static function isSuperAdmin(): bool
    {
        return self::hasRole(['superadmin']);
    }

    /**
     * Middleware: Requiert authentification
     * Retourne une erreur 401 si non authentifié
     * 
     * @return void
     */
    public static function requireAuth(): void
    {
        if (!self::isAuthenticated()) {
            Logger::warning('Unauthorized access attempt', [
                'ip' => $_SERVER['REMOTE_ADDR'] ?? 'unknown',
                'uri' => $_SERVER['REQUEST_URI'] ?? 'unknown'
            ]);

            Response::unauthorized('Authentification requise');
        }
    }

    /**
     * Middleware: Requiert un rôle spécifique
     * Retourne une erreur 403 si rôle insuffisant
     * 
     * @param array|string $roles Rôle(s) requis
     * @return void
     */
    public static function requireRole($roles): void
    {
        self::requireAuth();

        if (!self::hasRole($roles)) {
            $roles = is_array($roles) ? implode(', ', $roles) : $roles;

            Logger::warning('Forbidden access attempt', [
                'user_id' => $_SESSION['user_id'] ?? null,
                'role' => $_SESSION['role'] ?? null,
                'required_roles' => $roles,
                'uri' => $_SERVER['REQUEST_URI'] ?? 'unknown'
            ]);

            Response::forbidden('Accès refusé. Rôle requis: ' . $roles);
        }
    }

    /**
     * Middleware: Requiert admin ou superadmin
     * 
     * @return void
     */
    public static function requireAdmin(): void
    {
        self::requireRole(['admin', 'superadmin']);
    }

    /**
     * Middleware: Requiert superadmin
     * 
     * @return void
     */
    public static function requireSuperAdmin(): void
    {
        self::requireRole(['superadmin']);
    }

    /**
     * Vérifier si l'utilisateur peut accéder à une ressource utilisateur
     * Un utilisateur peut accéder à ses propres données ou être admin/superadmin
     * 
     * @param int $userId ID de l'utilisateur cible
     * @return bool
     */
    public static function canAccessUser(int $userId): bool
    {
        if (!self::isAuthenticated()) {
            return false;
        }

        // Admin et superadmin peuvent accéder à tous les utilisateurs
        if (self::isAdmin()) {
            return true;
        }

        // Un utilisateur peut accéder à ses propres données
        return $userId === ($_SESSION['user_id'] ?? null);
    }

    /**
     * Vérifier si l'utilisateur peut modifier une ressource utilisateur
     * Un utilisateur peut modifier ses propres données ou être admin/superadmin
     * 
     * @param int $userId ID de l'utilisateur cible
     * @return bool
     */
    public static function canModifyUser(int $userId): bool
    {
        return self::canAccessUser($userId);
    }

    /**
     * Vérifier la validité de la session
     * Vérifie l'expiration et régénère l'ID si nécessaire
     * 
     * @return bool
     */
    public static function validateSession(): bool
    {
        if (!self::isAuthenticated()) {
            return false;
        }

        // Vérifier l'expiration de la session
        if (isset($_SESSION['login_time'])) {
            $sessionLifetime = SESSION_CONFIG['lifetime'] ?? 3600;
            $elapsed = time() - $_SESSION['login_time'];

            if ($elapsed > $sessionLifetime) {
                Logger::info('Session expired', [
                    'user_id' => $_SESSION['user_id'] ?? null,
                    'elapsed' => $elapsed
                ]);

                self::destroySession();
                return false;
            }
        }

        // Régénérer l'ID de session périodiquement (sécurité)
        if (!isset($_SESSION['last_regeneration'])) {
            $_SESSION['last_regeneration'] = time();
        }

        $regenerationInterval = SESSION_CONFIG['regenerate_interval'] ?? 300; // 5 minutes
        if ((time() - $_SESSION['last_regeneration']) > $regenerationInterval) {
            session_regenerate_id(true);
            $_SESSION['last_regeneration'] = time();

            Logger::debug('Session ID regenerated', [
                'user_id' => $_SESSION['user_id'] ?? null
            ]);
        }

        return true;
    }

    /**
     * Middleware: Valider la session
     * Vérifie l'expiration et régénère l'ID
     * 
     * @return void
     */
    public static function requireValidSession(): void
    {
        if (!self::validateSession()) {
            Response::unauthorized('Session expirée. Veuillez vous reconnecter.');
        }
    }

    /**
     * Détruire la session
     * 
     * @return void
     */
    public static function destroySession(): void
    {
        if (session_status() === PHP_SESSION_ACTIVE) {
            $_SESSION = [];

            // Détruire le cookie de session
            if (isset($_COOKIE[session_name()])) {
                setcookie(
                    session_name(),
                    '',
                    time() - 3600,
                    '/',
                    '',
                    true,
                    true
                );
            }

            session_destroy();
        }
    }

    /**
     * Obtenir l'ID de l'utilisateur connecté
     * 
     * @return int|null
     */
    public static function getUserId(): ?int
    {
        return $_SESSION['user_id'] ?? null;
    }

    /**
     * Obtenir le nom d'utilisateur connecté
     * 
     * @return string|null
     */
    public static function getUsername(): ?string
    {
        return $_SESSION['username'] ?? null;
    }

    /**
     * Obtenir le rôle de l'utilisateur connecté
     * 
     * @return string|null
     */
    public static function getRole(): ?string
    {
        return $_SESSION['role'] ?? null;
    }

    /**
     * Obtenir toutes les infos de l'utilisateur connecté
     * 
     * @return array|null
     */
    public static function getUser(): ?array
    {
        if (!self::isAuthenticated()) {
            return null;
        }

        return [
            'id' => $_SESSION['user_id'] ?? null,
            'username' => $_SESSION['username'] ?? null,
            'role' => $_SESSION['role'] ?? null,
            'logged_in' => $_SESSION['logged_in'] ?? false,
            'login_time' => $_SESSION['login_time'] ?? null,
        ];
    }

    /**
     * Vérifier le CSRF token
     * 
     * @param string|null $token Token à vérifier
     * @return bool
     */
    public static function verifyCsrfToken(?string $token): bool
    {
        if (!isset($_SESSION['csrf_token'])) {
            return false;
        }

        return hash_equals($_SESSION['csrf_token'], $token ?? '');
    }

    /**
     * Middleware: Requiert CSRF token valide
     * 
     * @return void
     */
    public static function requireCsrfToken(): void
    {
        $token = null;

        // Chercher le token dans les headers
        if (isset($_SERVER['HTTP_X_CSRF_TOKEN'])) {
            $token = $_SERVER['HTTP_X_CSRF_TOKEN'];
        }
        // Ou dans le POST
        elseif (isset($_POST['csrf_token'])) {
            $token = $_POST['csrf_token'];
        }
        // Ou dans le body JSON
        else {
            $input = json_decode(file_get_contents('php://input'), true);
            $token = $input['csrf_token'] ?? null;
        }

        if (!self::verifyCsrfToken($token)) {
            Logger::warning('CSRF token validation failed', [
                'user_id' => $_SESSION['user_id'] ?? null,
                'ip' => $_SERVER['REMOTE_ADDR'] ?? 'unknown'
            ]);

            Response::forbidden('CSRF token invalide');
        }
    }

    /**
     * Vérifier le rate limiting
     * 
     * @param string $action Action à vérifier
     * @return bool
     */
    public static function checkRateLimit(string $action): bool
    {
        $ip = $_SERVER['REMOTE_ADDR'] ?? '0.0.0.0';
        return !isRateLimited($ip, $action);
    }

    /**
     * Middleware: Appliquer le rate limiting
     * 
     * @param string $action Action à limiter
     * @return void
     */
    public static function requireRateLimit(string $action): void
    {
        if (!self::checkRateLimit($action)) {
            $ip = $_SERVER['REMOTE_ADDR'] ?? '0.0.0.0';

            Logger::warning('Rate limit exceeded', [
                'action' => $action,
                'ip' => $ip
            ]);

            Response::tooManyRequests('Trop de requêtes. Veuillez réessayer plus tard.', 900);
        }
    }

    /**
     * Middleware: Protection contre les requêtes CORS non autorisées
     * 
     * @param array $allowedOrigins Origines autorisées
     * @return void
     */
    public static function requireCors(array $allowedOrigins = ['*']): void
    {
        $origin = $_SERVER['HTTP_ORIGIN'] ?? '';

        // Si wildcard, autoriser toutes les origines
        if (in_array('*', $allowedOrigins, true)) {
            header('Access-Control-Allow-Origin: *');
            header('Access-Control-Allow-Methods: GET, POST, PUT, DELETE, OPTIONS');
            header('Access-Control-Allow-Headers: Content-Type, Authorization, X-CSRF-Token');
            header('Access-Control-Allow-Credentials: true');
            return;
        }

        // Vérifier si l'origine est autorisée
        if (in_array($origin, $allowedOrigins, true)) {
            header("Access-Control-Allow-Origin: {$origin}");
            header('Access-Control-Allow-Methods: GET, POST, PUT, DELETE, OPTIONS');
            header('Access-Control-Allow-Headers: Content-Type, Authorization, X-CSRF-Token');
            header('Access-Control-Allow-Credentials: true');
        } else {
            Logger::warning('CORS violation', [
                'origin' => $origin,
                'allowed' => $allowedOrigins
            ]);

            Response::forbidden('Origine non autorisée');
        }
    }
}

/**
 * ═══════════════════════════════════════════════════════════════════════════
 * FIN DU AUTHMIDDLEWARE
 * ═══════════════════════════════════════════════════════════════════════════
 */
