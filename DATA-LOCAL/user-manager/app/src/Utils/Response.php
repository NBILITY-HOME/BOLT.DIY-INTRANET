<?php
/**
 * ═══════════════════════════════════════════════════════════════════════════
 * BOLT.DIY USER MANAGER v2.0 - Classe Response
 * © Copyright Nbility 2025 - contact@nbility.fr
 * 
 * Gestion des réponses HTTP et JSON
 * ═══════════════════════════════════════════════════════════════════════════
 */

declare(strict_types=1);

namespace App\Utils;

/**
 * Classe Response - Gestion des réponses HTTP
 */
class Response
{
    /**
     * Codes HTTP standards
     */
    public const HTTP_OK = 200;
    public const HTTP_CREATED = 201;
    public const HTTP_NO_CONTENT = 204;
    public const HTTP_BAD_REQUEST = 400;
    public const HTTP_UNAUTHORIZED = 401;
    public const HTTP_FORBIDDEN = 403;
    public const HTTP_NOT_FOUND = 404;
    public const HTTP_METHOD_NOT_ALLOWED = 405;
    public const HTTP_CONFLICT = 409;
    public const HTTP_UNPROCESSABLE_ENTITY = 422;
    public const HTTP_TOO_MANY_REQUESTS = 429;
    public const HTTP_INTERNAL_SERVER_ERROR = 500;
    public const HTTP_SERVICE_UNAVAILABLE = 503;

    /**
     * Messages HTTP par défaut
     */
    private const HTTP_MESSAGES = [
        200 => 'OK',
        201 => 'Created',
        204 => 'No Content',
        400 => 'Bad Request',
        401 => 'Unauthorized',
        403 => 'Forbidden',
        404 => 'Not Found',
        405 => 'Method Not Allowed',
        409 => 'Conflict',
        422 => 'Unprocessable Entity',
        429 => 'Too Many Requests',
        500 => 'Internal Server Error',
        503 => 'Service Unavailable',
    ];

    /**
     * Retourner une réponse JSON
     * 
     * @param array $data Données à retourner
     * @param int $statusCode Code HTTP
     * @param array $headers Headers additionnels
     */
    public static function json(array $data, int $statusCode = self::HTTP_OK, array $headers = []): void
    {
        // Définir le code HTTP
        http_response_code($statusCode);

        // Headers par défaut
        header('Content-Type: application/json; charset=utf-8');

        // Headers additionnels
        foreach ($headers as $key => $value) {
            header("{$key}: {$value}");
        }

        // Encoder et retourner le JSON
        echo json_encode($data, JSON_UNESCAPED_UNICODE | JSON_UNESCAPED_SLASHES | JSON_PRETTY_PRINT);
        exit;
    }

    /**
     * Réponse de succès
     * 
     * @param mixed $data Données
     * @param string|null $message Message de succès
     * @param int $statusCode Code HTTP
     */
    public static function success($data = null, ?string $message = null, int $statusCode = self::HTTP_OK): void
    {
        $response = [
            'status' => 'success',
            'message' => $message ?? self::HTTP_MESSAGES[$statusCode] ?? 'Success',
        ];

        if ($data !== null) {
            $response['data'] = $data;
        }

        self::json($response, $statusCode);
    }

    /**
     * Réponse d'erreur
     * 
     * @param string $message Message d'erreur
     * @param int $statusCode Code HTTP
     * @param array|null $errors Erreurs détaillées
     */
    public static function error(string $message, int $statusCode = self::HTTP_BAD_REQUEST, ?array $errors = null): void
    {
        $response = [
            'status' => 'error',
            'message' => $message,
        ];

        if ($errors !== null) {
            $response['errors'] = $errors;
        }

        self::json($response, $statusCode);
    }

    /**
     * Réponse non autorisé (401)
     * 
     * @param string $message Message
     */
    public static function unauthorized(string $message = 'Authentication required'): void
    {
        self::error($message, self::HTTP_UNAUTHORIZED);
    }

    /**
     * Réponse interdit (403)
     * 
     * @param string $message Message
     */
    public static function forbidden(string $message = 'Access denied'): void
    {
        self::error($message, self::HTTP_FORBIDDEN);
    }

    /**
     * Réponse non trouvé (404)
     * 
     * @param string $message Message
     */
    public static function notFound(string $message = 'Resource not found'): void
    {
        self::error($message, self::HTTP_NOT_FOUND);
    }

    /**
     * Réponse de validation échouée (422)
     * 
     * @param array $errors Erreurs de validation
     * @param string $message Message principal
     */
    public static function validationError(array $errors, string $message = 'Validation failed'): void
    {
        self::error($message, self::HTTP_UNPROCESSABLE_ENTITY, $errors);
    }

    /**
     * Réponse trop de requêtes (429)
     * 
     * @param string $message Message
     * @param int|null $retryAfter Temps d'attente en secondes
     */
    public static function tooManyRequests(string $message = 'Too many requests', ?int $retryAfter = null): void
    {
        $headers = [];
        if ($retryAfter !== null) {
            $headers['Retry-After'] = (string)$retryAfter;
        }

        http_response_code(self::HTTP_TOO_MANY_REQUESTS);
        foreach ($headers as $key => $value) {
            header("{$key}: {$value}");
        }

        self::json([
            'status' => 'error',
            'message' => $message,
            'retry_after' => $retryAfter,
        ], self::HTTP_TOO_MANY_REQUESTS);
    }

    /**
     * Réponse erreur serveur (500)
     * 
     * @param string $message Message
     */
    public static function serverError(string $message = 'Internal server error'): void
    {
        self::error($message, self::HTTP_INTERNAL_SERVER_ERROR);
    }

    /**
     * Réponse de liste paginée
     * 
     * @param array $items Items
     * @param int $total Total d'items
     * @param int $page Page actuelle
     * @param int $perPage Items par page
     */
    public static function paginated(array $items, int $total, int $page, int $perPage): void
    {
        $totalPages = (int)ceil($total / $perPage);

        self::success([
            'items' => $items,
            'pagination' => [
                'current_page' => $page,
                'per_page' => $perPage,
                'total_items' => $total,
                'total_pages' => $totalPages,
                'has_next' => $page < $totalPages,
                'has_previous' => $page > 1,
            ]
        ]);
    }

    /**
     * Redirection HTTP
     * 
     * @param string $url URL de destination
     * @param int $statusCode Code HTTP (301 ou 302)
     */
    public static function redirect(string $url, int $statusCode = 302): void
    {
        http_response_code($statusCode);
        header("Location: {$url}");
        exit;
    }
}

/**
 * ═══════════════════════════════════════════════════════════════════════════
 * FIN DE LA CLASSE RESPONSE
 * ═══════════════════════════════════════════════════════════════════════════
 */
