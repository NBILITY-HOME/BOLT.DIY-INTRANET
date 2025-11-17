<?php
/**
 * ═══════════════════════════════════════════════════════════════════════════
 * BOLT.DIY USER MANAGER v2.0 - CSRFMiddleware
 * © Copyright Nbility 2025 - contact@nbility.fr
 * 
 * Middleware de protection CSRF (Cross-Site Request Forgery)
 * ═══════════════════════════════════════════════════════════════════════════
 */

declare(strict_types=1);

namespace App\Middleware;

use App\Utils\Response;
use App\Utils\Logger;

/**
 * Classe CSRFMiddleware - Protection contre les attaques CSRF
 */
class CSRFMiddleware
{
    /**
     * Nom de la clé du token dans la session
     */
    private const SESSION_KEY = 'csrf_token';

    /**
     * Durée de validité du token (en secondes)
     */
    private const TOKEN_LIFETIME = 3600; // 1 heure

    /**
     * Nom de la clé pour le timestamp du token
     */
    private const TIMESTAMP_KEY = 'csrf_token_time';

    /**
     * Générer un nouveau token CSRF
     * 
     * @param bool $force Forcer la génération même si un token existe
     * @return string
     */
    public static function generateToken(bool $force = false): string
    {
        // Initialiser la session si nécessaire
        if (session_status() === PHP_SESSION_NONE) {
            session_start();
        }

        // Si un token existe déjà et qu'on ne force pas, le retourner
        if (!$force && isset($_SESSION[self::SESSION_KEY]) && self::isTokenValid()) {
            return $_SESSION[self::SESSION_KEY];
        }

        // Générer un nouveau token
        $token = bin2hex(random_bytes(32)); // 64 caractères hex

        // Stocker dans la session
        $_SESSION[self::SESSION_KEY] = $token;
        $_SESSION[self::TIMESTAMP_KEY] = time();

        Logger::debug('CSRF token generated', [
            'user_id' => $_SESSION['user_id'] ?? null,
            'token_hash' => hash('sha256', $token)
        ]);

        return $token;
    }

    /**
     * Obtenir le token CSRF actuel (ou en générer un nouveau)
     * 
     * @return string
     */
    public static function getToken(): string
    {
        return self::generateToken(false);
    }

    /**
     * Vérifier si le token CSRF est valide
     * 
     * @param string|null $token Token à vérifier
     * @return bool
     */
    public static function verifyToken(?string $token): bool
    {
        // Initialiser la session si nécessaire
        if (session_status() === PHP_SESSION_NONE) {
            session_start();
        }

        // Vérifier si un token existe en session
        if (!isset($_SESSION[self::SESSION_KEY])) {
            Logger::warning('CSRF token verification failed: no token in session');
            return false;
        }

        // Vérifier si le token n'a pas expiré
        if (!self::isTokenValid()) {
            Logger::warning('CSRF token verification failed: token expired');
            return false;
        }

        // Comparer les tokens de manière sécurisée (timing-safe)
        if (!hash_equals($_SESSION[self::SESSION_KEY], $token ?? '')) {
            Logger::warning('CSRF token verification failed: token mismatch', [
                'user_id' => $_SESSION['user_id'] ?? null,
                'ip' => $_SERVER['REMOTE_ADDR'] ?? 'unknown'
            ]);
            return false;
        }

        return true;
    }

    /**
     * Vérifier si le token en session est encore valide (pas expiré)
     * 
     * @return bool
     */
    private static function isTokenValid(): bool
    {
        if (!isset($_SESSION[self::TIMESTAMP_KEY])) {
            return false;
        }

        $elapsed = time() - $_SESSION[self::TIMESTAMP_KEY];
        return $elapsed < self::TOKEN_LIFETIME;
    }

    /**
     * Extraire le token CSRF de la requête
     * Cherche dans : header X-CSRF-Token, POST, GET, JSON body
     * 
     * @return string|null
     */
    public static function extractTokenFromRequest(): ?string
    {
        // 1. Chercher dans les headers (priorité)
        if (isset($_SERVER['HTTP_X_CSRF_TOKEN'])) {
            return $_SERVER['HTTP_X_CSRF_TOKEN'];
        }

        // 2. Chercher dans POST
        if (isset($_POST['csrf_token'])) {
            return $_POST['csrf_token'];
        }

        // 3. Chercher dans GET (moins recommandé mais supporté)
        if (isset($_GET['csrf_token'])) {
            return $_GET['csrf_token'];
        }

        // 4. Chercher dans le body JSON
        $contentType = $_SERVER['CONTENT_TYPE'] ?? '';
        if (strpos($contentType, 'application/json') !== false) {
            $input = json_decode(file_get_contents('php://input'), true);
            if (isset($input['csrf_token'])) {
                return $input['csrf_token'];
            }
        }

        return null;
    }

    /**
     * Middleware: Vérifier le token CSRF
     * Envoie une réponse 403 si le token est invalide
     * 
     * @param bool $autoExtract Extraire automatiquement le token de la requête
     * @return void
     */
    public static function verify(bool $autoExtract = true): void
    {
        $token = $autoExtract ? self::extractTokenFromRequest() : null;

        if (!self::verifyToken($token)) {
            Logger::warning('CSRF protection blocked request', [
                'method' => $_SERVER['REQUEST_METHOD'] ?? 'unknown',
                'uri' => $_SERVER['REQUEST_URI'] ?? 'unknown',
                'ip' => $_SERVER['REMOTE_ADDR'] ?? 'unknown',
                'user_id' => $_SESSION['user_id'] ?? null
            ]);

            Response::forbidden('CSRF token invalide ou expiré');
        }
    }

    /**
     * Middleware: Vérifier le token CSRF pour les méthodes modifiant les données
     * (POST, PUT, DELETE, PATCH)
     * 
     * @return void
     */
    public static function verifyModifyingMethods(): void
    {
        $method = $_SERVER['REQUEST_METHOD'] ?? 'GET';

        // Vérifier seulement pour les méthodes modifiant les données
        if (in_array($method, ['POST', 'PUT', 'DELETE', 'PATCH'], true)) {
            self::verify();
        }
    }

    /**
     * Invalider le token actuel (forcer une régénération)
     * 
     * @return void
     */
    public static function invalidateToken(): void
    {
        if (session_status() !== PHP_SESSION_NONE) {
            unset($_SESSION[self::SESSION_KEY]);
            unset($_SESSION[self::TIMESTAMP_KEY]);

            Logger::debug('CSRF token invalidated', [
                'user_id' => $_SESSION['user_id'] ?? null
            ]);
        }
    }

    /**
     * Régénérer un nouveau token (invalider l'ancien et en créer un nouveau)
     * 
     * @return string
     */
    public static function regenerateToken(): string
    {
        self::invalidateToken();
        return self::generateToken(true);
    }

    /**
     * Obtenir le token sous forme de meta tag HTML
     * Utile pour l'inclure dans les pages
     * 
     * @return string
     */
    public static function getMetaTag(): string
    {
        $token = self::getToken();
        return '<meta name="csrf-token" content="' . htmlspecialchars($token, ENT_QUOTES, 'UTF-8') . '">';
    }

    /**
     * Obtenir le token sous forme d'input hidden HTML
     * Utile pour les formulaires
     * 
     * @return string
     */
    public static function getHiddenInput(): string
    {
        $token = self::getToken();
        return '<input type="hidden" name="csrf_token" value="' . htmlspecialchars($token, ENT_QUOTES, 'UTF-8') . '">';
    }

    /**
     * Obtenir le token sous forme JSON (pour les API)
     * 
     * @return array
     */
    public static function getTokenAsJson(): array
    {
        return [
            'csrf_token' => self::getToken(),
            'expires_in' => self::getTokenTimeRemaining()
        ];
    }

    /**
     * Obtenir le temps restant avant expiration du token (en secondes)
     * 
     * @return int
     */
    public static function getTokenTimeRemaining(): int
    {
        if (!isset($_SESSION[self::TIMESTAMP_KEY])) {
            return 0;
        }

        $elapsed = time() - $_SESSION[self::TIMESTAMP_KEY];
        $remaining = self::TOKEN_LIFETIME - $elapsed;

        return max(0, $remaining);
    }

    /**
     * Vérifier si le token va bientôt expirer
     * 
     * @param int $threshold Seuil en secondes (défaut: 5 minutes)
     * @return bool
     */
    public static function isTokenExpiringSoon(int $threshold = 300): bool
    {
        return self::getTokenTimeRemaining() < $threshold;
    }

    /**
     * Middleware: Régénérer automatiquement le token s'il va expirer bientôt
     * Utile pour les sessions longues
     * 
     * @param int $threshold Seuil en secondes
     * @return void
     */
    public static function autoRenewToken(int $threshold = 300): void
    {
        if (self::isTokenExpiringSoon($threshold)) {
            self::regenerateToken();

            Logger::debug('CSRF token auto-renewed', [
                'user_id' => $_SESSION['user_id'] ?? null
            ]);
        }
    }

    /**
     * Obtenir les statistiques du token CSRF
     * 
     * @return array
     */
    public static function getTokenStats(): array
    {
        $hasToken = isset($_SESSION[self::SESSION_KEY]);
        $isValid = $hasToken && self::isTokenValid();
        $timeRemaining = self::getTokenTimeRemaining();

        return [
            'has_token' => $hasToken,
            'is_valid' => $isValid,
            'time_remaining' => $timeRemaining,
            'expires_in_minutes' => round($timeRemaining / 60, 2),
            'created_at' => $hasToken && isset($_SESSION[self::TIMESTAMP_KEY]) 
                ? date('Y-m-d H:i:s', $_SESSION[self::TIMESTAMP_KEY])
                : null,
        ];
    }
}

/**
 * ═══════════════════════════════════════════════════════════════════════════
 * FIN DU CSRFMIDDLEWARE
 * ═══════════════════════════════════════════════════════════════════════════
 */
