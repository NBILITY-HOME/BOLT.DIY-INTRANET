<?php
/**
 * ═══════════════════════════════════════════════════════════════════════════
 * BOLT.DIY USER MANAGER v2.0 - Router API REST Principal
 * © Copyright Nbility 2025 - contact@nbility.fr
 * 
 * Point d'entrée unique pour toutes les requêtes API
 * Architecture : RESTful API avec routage simple
 * ═══════════════════════════════════════════════════════════════════════════
 */

declare(strict_types=1);

// ───────────────────────────────────────────────────────────────────────────
// CONFIGURATION DE BASE
// ───────────────────────────────────────────────────────────────────────────

// Désactiver l'affichage des erreurs en production
error_reporting(E_ALL);
ini_set('display_errors', '0');
ini_set('log_errors', '1');
ini_set('error_log', __DIR__ . '/logs/php_errors.log');

// Timezone
date_default_timezone_set('Europe/Paris');

// Headers de sécurité
header('X-Content-Type-Options: nosniff');
header('X-Frame-Options: DENY');
header('X-XSS-Protection: 1; mode=block');
header('Referrer-Policy: strict-origin-when-cross-origin');
header('Content-Security-Policy: default-src \'self\'; script-src \'self\' \'unsafe-inline\'; style-src \'self\' \'unsafe-inline\';');

// CORS (à adapter selon vos besoins)
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: GET, POST, PUT, DELETE, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type, Authorization, X-CSRF-Token');
header('Access-Control-Max-Age: 3600');

// Gestion des requêtes OPTIONS (preflight)
if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    http_response_code(200);
    exit;
}

// ───────────────────────────────────────────────────────────────────────────
// AUTOLOADER PSR-4 SIMPLE
// ───────────────────────────────────────────────────────────────────────────

spl_autoload_register(function ($class) {
    // Convertir le namespace en chemin de fichier
    $prefix = 'App\\';
    $base_dir = __DIR__ . '/src/';

    $len = strlen($prefix);
    if (strncmp($prefix, $class, $len) !== 0) {
        return;
    }

    $relative_class = substr($class, $len);
    $file = $base_dir . str_replace('\\', '/', $relative_class) . '.php';

    if (file_exists($file)) {
        require $file;
    }
});

// ───────────────────────────────────────────────────────────────────────────
// CHARGEMENT DES CONFIGURATIONS
// ───────────────────────────────────────────────────────────────────────────

require_once __DIR__ . '/config/app.php';
require_once __DIR__ . '/config/database.php';
require_once __DIR__ . '/config/security.php';

// ───────────────────────────────────────────────────────────────────────────
// HELPERS
// ───────────────────────────────────────────────────────────────────────────

use App\Utils\Response;
use App\Utils\Logger;

/**
 * Fonction helper pour retourner une réponse JSON
 */
function jsonResponse(array $data, int $statusCode = 200): void
{
    Response::json($data, $statusCode);
}

/**
 * Fonction helper pour logger
 */
function logMessage(string $level, string $message, array $context = []): void
{
    Logger::log($level, $message, $context);
}

// ───────────────────────────────────────────────────────────────────────────
// ROUTEUR PRINCIPAL
// ───────────────────────────────────────────────────────────────────────────

try {
    // Récupérer la méthode HTTP
    $method = $_SERVER['REQUEST_METHOD'];

    // Récupérer l'URI et nettoyer
    $uri = parse_url($_SERVER['REQUEST_URI'], PHP_URL_PATH);
    $uri = trim($uri, '/');

    // Log de la requête
    logMessage('info', "Request: {$method} /{$uri}", [
        'ip' => $_SERVER['REMOTE_ADDR'] ?? 'unknown',
        'user_agent' => $_SERVER['HTTP_USER_AGENT'] ?? 'unknown'
    ]);

    // Extraire les segments de l'URI
    $segments = explode('/', $uri);
    $endpoint = $segments[0] ?? 'index';
    $resource = $segments[1] ?? null;
    $id = $segments[2] ?? null;

    // ───────────────────────────────────────────────────────────────────────
    // ROUTAGE DES ENDPOINTS API
    // ───────────────────────────────────────────────────────────────────────

    switch ($endpoint) {
        // ──────────────────────────────────────────────────────────────────
        // ENDPOINT: /api/*
        // ──────────────────────────────────────────────────────────────────
        case 'api':
            if ($resource === null) {
                jsonResponse([
                    'status' => 'success',
                    'message' => 'Bolt.DIY User Manager API v2.0',
                    'version' => '2.0.0',
                    'endpoints' => [
                        '/api/auth/login' => 'POST - Authentification',
                        '/api/auth/logout' => 'POST - Déconnexion',
                        '/api/auth/me' => 'GET - Info utilisateur connecté',
                        '/api/users' => 'GET - Liste des utilisateurs',
                        '/api/users/{id}' => 'GET - Détails utilisateur',
                        '/api/users' => 'POST - Créer utilisateur',
                        '/api/users/{id}' => 'PUT - Modifier utilisateur',
                        '/api/users/{id}' => 'DELETE - Supprimer utilisateur',
                        '/api/groups' => 'GET - Liste des groupes',
                        '/api/groups/{id}' => 'GET - Détails groupe',
                        '/api/permissions' => 'GET - Liste des permissions',
                        '/api/audit' => 'GET - Logs d\'audit',
                    ]
                ]);
            }

            // Router vers les contrôleurs appropriés
            switch ($resource) {
                case 'auth':
                    require_once __DIR__ . '/src/Controllers/AuthController.php';
                    $controller = new App\Controllers\AuthController();
                    $controller->handle($method, $id);
                    break;

                case 'users':
                    require_once __DIR__ . '/src/Controllers/UserController.php';
                    $controller = new App\Controllers\UserController();
                    $controller->handle($method, $id);
                    break;

                case 'groups':
                    require_once __DIR__ . '/src/Controllers/GroupController.php';
                    $controller = new App\Controllers\GroupController();
                    $controller->handle($method, $id);
                    break;

                case 'permissions':
                    require_once __DIR__ . '/src/Controllers/PermissionController.php';
                    $controller = new App\Controllers\PermissionController();
                    $controller->handle($method, $id);
                    break;

                case 'audit':
                    require_once __DIR__ . '/src/Controllers/AuditController.php';
                    $controller = new App\Controllers\AuditController();
                    $controller->handle($method, $id);
                    break;

                default:
                    jsonResponse([
                        'status' => 'error',
                        'message' => 'Endpoint API non trouvé'
                    ], 404);
            }
            break;

        // ──────────────────────────────────────────────────────────────────
        // ENDPOINT: /health (healthcheck Docker)
        // ──────────────────────────────────────────────────────────────────
        case 'health':
        case 'health.php':
            jsonResponse([
                'status' => 'healthy',
                'service' => 'bolt-user-manager',
                'version' => '2.0.0',
                'timestamp' => date('Y-m-d H:i:s'),
                'uptime' => sys_getloadavg()[0]
            ]);
            break;

        // ──────────────────────────────────────────────────────────────────
        // ENDPOINT: / (page d'accueil - redirige vers le frontend)
        // ──────────────────────────────────────────────────────────────────
        case 'index':
        case '':
            // Si c'est une requête API, retourner le statut
            if (strpos($_SERVER['HTTP_ACCEPT'] ?? '', 'application/json') !== false) {
                jsonResponse([
                    'status' => 'success',
                    'message' => 'Bolt.DIY User Manager v2.0',
                    'api_endpoint' => '/api',
                    'documentation' => '/api'
                ]);
            } else {
                // Rediriger vers le dashboard frontend
                if (file_exists(__DIR__ . '/public/index.html')) {
                    header('Location: /public/index.html');
                    exit;
                } else {
                    // Page d'accueil temporaire si le frontend n'est pas encore créé
                    ?>
<!DOCTYPE html>
<html lang="fr">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Bolt.DIY User Manager v2.0</title>
    <style>
        * { margin: 0; padding: 0; box-sizing: border-box; }
        body {
            font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif;
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            color: #fff;
            display: flex;
            justify-content: center;
            align-items: center;
            min-height: 100vh;
            text-align: center;
        }
        .container {
            background: rgba(255, 255, 255, 0.1);
            backdrop-filter: blur(10px);
            border-radius: 20px;
            padding: 60px 40px;
            max-width: 600px;
        }
        h1 { font-size: 48px; margin-bottom: 20px; }
        p { font-size: 18px; margin-bottom: 30px; opacity: 0.9; }
        .status { 
            background: rgba(255, 255, 255, 0.2);
            padding: 20px;
            border-radius: 10px;
            margin-top: 30px;
        }
        .api-link {
            display: inline-block;
            background: #fff;
            color: #667eea;
            padding: 15px 30px;
            border-radius: 10px;
            text-decoration: none;
            font-weight: 600;
            margin-top: 20px;
            transition: transform 0.3s;
        }
        .api-link:hover { transform: translateY(-2px); }
    </style>
</head>
<body>
    <div class="container">
        <h1>🚀 Bolt.DIY User Manager</h1>
        <p>Version 2.0.0 - API REST opérationnelle</p>
        <div class="status">
            <p>✅ Service démarré avec succès</p>
            <p>🔗 API accessible : <strong>/api</strong></p>
            <p>📊 Base de données : connectée</p>
        </div>
        <a href="/api" class="api-link">Accéder à l'API</a>
    </div>
</body>
</html>
                    <?php
                    exit;
                }
            }
            break;

        // ──────────────────────────────────────────────────────────────────
        // ENDPOINT: Inconnu
        // ──────────────────────────────────────────────────────────────────
        default:
            jsonResponse([
                'status' => 'error',
                'message' => 'Endpoint non trouvé',
                'path' => $uri
            ], 404);
    }

} catch (\Throwable $e) {
    // Log de l'erreur
    logMessage('error', $e->getMessage(), [
        'file' => $e->getFile(),
        'line' => $e->getLine(),
        'trace' => $e->getTraceAsString()
    ]);

    // Retourner une erreur générique
    jsonResponse([
        'status' => 'error',
        'message' => 'Une erreur interne est survenue',
        'error_id' => uniqid('err_', true)
    ], 500);
}

/**
 * ═══════════════════════════════════════════════════════════════════════════
 * FIN DU ROUTER PRINCIPAL
 * ═══════════════════════════════════════════════════════════════════════════
 */
