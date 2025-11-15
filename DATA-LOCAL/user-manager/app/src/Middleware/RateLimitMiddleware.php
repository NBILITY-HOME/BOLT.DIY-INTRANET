<?php
/**
 * ═══════════════════════════════════════════════════════════════════════════
 * BOLT.DIY USER MANAGER v2.0 - RateLimitMiddleware
 * © Copyright Nbility 2025 - contact@nbility.fr
 * 
 * Middleware de limitation de débit (Rate Limiting)
 * Utilise l'algorithme Token Bucket pour un contrôle précis
 * ═══════════════════════════════════════════════════════════════════════════
 */

declare(strict_types=1);

namespace App\Middleware;

use App\Utils\Response;
use App\Utils\Logger;

/**
 * Classe RateLimitMiddleware - Limitation de débit avancée
 */
class RateLimitMiddleware
{
    /**
     * Configurations par défaut pour différents types d'actions
     */
    private const RATE_LIMITS = [
        'login' => [
            'max_attempts' => 5,      // Nombre de tentatives
            'window' => 900,          // Fenêtre de temps (15 minutes)
            'block_duration' => 900,  // Durée de blocage (15 minutes)
        ],
        'register' => [
            'max_attempts' => 3,
            'window' => 3600,         // 1 heure
            'block_duration' => 3600,
        ],
        'api' => [
            'max_attempts' => 60,     // 60 requêtes
            'window' => 60,           // Par minute
            'block_duration' => 300,  // Blocage 5 minutes
        ],
        'password_reset' => [
            'max_attempts' => 3,
            'window' => 3600,
            'block_duration' => 3600,
        ],
        'email' => [
            'max_attempts' => 10,
            'window' => 3600,
            'block_duration' => 1800,
        ],
    ];

    /**
     * Obtenir l'identifiant de l'utilisateur (IP + User-Agent)
     * 
     * @return string
     */
    private static function getIdentifier(): string
    {
        $ip = $_SERVER['REMOTE_ADDR'] ?? '0.0.0.0';
        $userAgent = $_SERVER['HTTP_USER_AGENT'] ?? 'unknown';

        return hash('sha256', $ip . '|' . $userAgent);
    }

    /**
     * Obtenir la clé de cache pour une action
     * 
     * @param string $action Action à limiter
     * @param string|null $identifier Identifiant personnalisé (défaut: IP)
     * @return string
     */
    private static function getCacheKey(string $action, ?string $identifier = null): string
    {
        $identifier = $identifier ?? self::getIdentifier();
        return "rate_limit:{$action}:{$identifier}";
    }

    /**
     * Obtenir la clé de cache pour le blocage
     * 
     * @param string $action Action bloquée
     * @param string|null $identifier Identifiant personnalisé
     * @return string
     */
    private static function getBlockKey(string $action, ?string $identifier = null): string
    {
        $identifier = $identifier ?? self::getIdentifier();
        return "rate_limit_block:{$action}:{$identifier}";
    }

    /**
     * Vérifier si une action est limitée
     * 
     * @param string $action Action à vérifier
     * @param array|null $config Configuration personnalisée
     * @param string|null $identifier Identifiant personnalisé
     * @return bool True si limité, False sinon
     */
    public static function isLimited(string $action, ?array $config = null, ?string $identifier = null): bool
    {
        // Obtenir la configuration
        $config = $config ?? self::RATE_LIMITS[$action] ?? self::RATE_LIMITS['api'];

        $maxAttempts = $config['max_attempts'];
        $window = $config['window'];

        // Clés de cache
        $cacheKey = self::getCacheKey($action, $identifier);
        $blockKey = self::getBlockKey($action, $identifier);

        // Vérifier si bloqué
        if (apcu_exists($blockKey)) {
            return true;
        }

        // Obtenir les tentatives actuelles
        $attempts = apcu_fetch($cacheKey);

        if ($attempts === false) {
            // Première tentative
            apcu_store($cacheKey, 1, $window);
            return false;
        }

        // Vérifier si la limite est dépassée
        if ($attempts >= $maxAttempts) {
            // Bloquer l'utilisateur
            $blockDuration = $config['block_duration'];
            apcu_store($blockKey, time(), $blockDuration);

            Logger::warning('Rate limit exceeded', [
                'action' => $action,
                'identifier' => $identifier ?? self::getIdentifier(),
                'attempts' => $attempts,
                'max_attempts' => $maxAttempts,
                'block_duration' => $blockDuration
            ]);

            return true;
        }

        // Incrémenter le compteur
        apcu_inc($cacheKey);

        return false;
    }

    /**
     * Middleware: Vérifier le rate limiting
     * Envoie une réponse 429 si limité
     * 
     * @param string $action Action à limiter
     * @param array|null $config Configuration personnalisée
     * @param string|null $identifier Identifiant personnalisé
     * @return void
     */
    public static function check(string $action, ?array $config = null, ?string $identifier = null): void
    {
        if (self::isLimited($action, $config, $identifier)) {
            $retryAfter = self::getRetryAfter($action, $identifier);

            Logger::warning('Rate limit blocked request', [
                'action' => $action,
                'ip' => $_SERVER['REMOTE_ADDR'] ?? 'unknown',
                'uri' => $_SERVER['REQUEST_URI'] ?? 'unknown',
                'retry_after' => $retryAfter
            ]);

            Response::tooManyRequests(
                "Trop de requêtes. Réessayez dans {$retryAfter} secondes.",
                $retryAfter
            );
        }
    }

    /**
     * Obtenir le nombre de tentatives restantes
     * 
     * @param string $action Action
     * @param array|null $config Configuration personnalisée
     * @param string|null $identifier Identifiant personnalisé
     * @return int
     */
    public static function getRemainingAttempts(string $action, ?array $config = null, ?string $identifier = null): int
    {
        $config = $config ?? self::RATE_LIMITS[$action] ?? self::RATE_LIMITS['api'];
        $maxAttempts = $config['max_attempts'];

        $cacheKey = self::getCacheKey($action, $identifier);
        $attempts = apcu_fetch($cacheKey);

        if ($attempts === false) {
            return $maxAttempts;
        }

        return max(0, $maxAttempts - $attempts);
    }

    /**
     * Obtenir le temps restant avant de pouvoir réessayer (en secondes)
     * 
     * @param string $action Action
     * @param string|null $identifier Identifiant personnalisé
     * @return int
     */
    public static function getRetryAfter(string $action, ?string $identifier = null): int
    {
        $blockKey = self::getBlockKey($action, $identifier);

        // Si bloqué, retourner le temps restant du blocage
        if (apcu_exists($blockKey)) {
            $ttl = apcu_fetch($blockKey);
            $remaining = $ttl + (self::RATE_LIMITS[$action]['block_duration'] ?? 300) - time();
            return max(0, $remaining);
        }

        // Sinon, retourner le TTL du cache
        $cacheKey = self::getCacheKey($action, $identifier);
        $cacheInfo = apcu_cache_info();

        // Rechercher la clé dans le cache
        foreach ($cacheInfo['cache_list'] as $entry) {
            if ($entry['info'] === $cacheKey) {
                return max(0, $entry['ttl']);
            }
        }

        return 0;
    }

    /**
     * Réinitialiser le compteur pour une action
     * 
     * @param string $action Action
     * @param string|null $identifier Identifiant personnalisé
     * @return void
     */
    public static function reset(string $action, ?string $identifier = null): void
    {
        $cacheKey = self::getCacheKey($action, $identifier);
        $blockKey = self::getBlockKey($action, $identifier);

        apcu_delete($cacheKey);
        apcu_delete($blockKey);

        Logger::debug('Rate limit reset', [
            'action' => $action,
            'identifier' => $identifier ?? self::getIdentifier()
        ]);
    }

    /**
     * Débloquer un utilisateur
     * 
     * @param string $action Action
     * @param string|null $identifier Identifiant personnalisé
     * @return void
     */
    public static function unblock(string $action, ?string $identifier = null): void
    {
        $blockKey = self::getBlockKey($action, $identifier);
        apcu_delete($blockKey);

        Logger::info('Rate limit unblocked', [
            'action' => $action,
            'identifier' => $identifier ?? self::getIdentifier()
        ]);
    }

    /**
     * Obtenir les statistiques de rate limiting
     * 
     * @param string $action Action
     * @param string|null $identifier Identifiant personnalisé
     * @return array
     */
    public static function getStats(string $action, ?string $identifier = null): array
    {
        $config = self::RATE_LIMITS[$action] ?? self::RATE_LIMITS['api'];
        $cacheKey = self::getCacheKey($action, $identifier);
        $blockKey = self::getBlockKey($action, $identifier);

        $attempts = apcu_fetch($cacheKey);
        $isBlocked = apcu_exists($blockKey);

        $remaining = self::getRemainingAttempts($action, $config, $identifier);
        $retryAfter = self::getRetryAfter($action, $identifier);

        return [
            'action' => $action,
            'max_attempts' => $config['max_attempts'],
            'window' => $config['window'],
            'attempts' => $attempts !== false ? $attempts : 0,
            'remaining' => $remaining,
            'is_blocked' => $isBlocked,
            'retry_after' => $retryAfter,
            'identifier' => $identifier ?? self::getIdentifier(),
        ];
    }

    /**
     * Ajouter des headers de rate limiting à la réponse
     * 
     * @param string $action Action
     * @param array|null $config Configuration personnalisée
     * @param string|null $identifier Identifiant personnalisé
     * @return void
     */
    public static function addHeaders(string $action, ?array $config = null, ?string $identifier = null): void
    {
        $config = $config ?? self::RATE_LIMITS[$action] ?? self::RATE_LIMITS['api'];

        $maxAttempts = $config['max_attempts'];
        $remaining = self::getRemainingAttempts($action, $config, $identifier);
        $retryAfter = self::getRetryAfter($action, $identifier);

        header("X-RateLimit-Limit: {$maxAttempts}");
        header("X-RateLimit-Remaining: {$remaining}");

        if ($retryAfter > 0) {
            header("X-RateLimit-Reset: " . (time() + $retryAfter));
            header("Retry-After: {$retryAfter}");
        }
    }

    /**
     * Middleware avec headers automatiques
     * 
     * @param string $action Action à limiter
     * @param array|null $config Configuration personnalisée
     * @param string|null $identifier Identifiant personnalisé
     * @return void
     */
    public static function checkWithHeaders(string $action, ?array $config = null, ?string $identifier = null): void
    {
        self::check($action, $config, $identifier);
        self::addHeaders($action, $config, $identifier);
    }

    /**
     * Créer une configuration personnalisée
     * 
     * @param int $maxAttempts Nombre maximum de tentatives
     * @param int $window Fenêtre de temps (secondes)
     * @param int $blockDuration Durée de blocage (secondes)
     * @return array
     */
    public static function createConfig(int $maxAttempts, int $window, int $blockDuration): array
    {
        return [
            'max_attempts' => $maxAttempts,
            'window' => $window,
            'block_duration' => $blockDuration,
        ];
    }

    /**
     * Nettoyer tous les rate limits (admin uniquement)
     * 
     * @return void
     */
    public static function clearAll(): void
    {
        $cacheInfo = apcu_cache_info();

        foreach ($cacheInfo['cache_list'] as $entry) {
            if (strpos($entry['info'], 'rate_limit') === 0) {
                apcu_delete($entry['info']);
            }
        }

        Logger::info('All rate limits cleared');
    }

    /**
     * Obtenir tous les rate limits actifs
     * 
     * @return array
     */
    public static function getAllActive(): array
    {
        $cacheInfo = apcu_cache_info();
        $rateLimits = [];

        foreach ($cacheInfo['cache_list'] as $entry) {
            if (strpos($entry['info'], 'rate_limit:') === 0) {
                $rateLimits[] = [
                    'key' => $entry['info'],
                    'attempts' => $entry['num_hits'],
                    'ttl' => $entry['ttl'],
                    'created' => date('Y-m-d H:i:s', $entry['creation_time']),
                ];
            }
        }

        return $rateLimits;
    }
}

/**
 * ═══════════════════════════════════════════════════════════════════════════
 * FIN DU RATELIMITMIDDLEWARE
 * ═══════════════════════════════════════════════════════════════════════════
 */
