<?php
declare(strict_types=1);

session_start();

/**
 * Bolt.DIY User Manager v2
 * Front controller unique pour :
 *  - API REST (/api/...)
 *  - Healthcheck (/health)
 *  - Redirection frontend (/ → login ou dashboard)
 */

// ─────────────────────────────────────────────────────────────
// Chargement de l'autoload Composer (si présent)
// ─────────────────────────────────────────────────────────────
$autoloadPath = __DIR__ . '/../vendor/autoload.php';
if (file_exists($autoloadPath)) {
    require_once $autoloadPath;
}

// ─────────────────────────────────────────────────────────────
// Helpers généraux
// ─────────────────────────────────────────────────────────────

/**
 * Envoie une réponse JSON et termine le script.
 */
function jsonResponse(array $data, int $status = 200): void
{
    http_response_code($status);
    header('Content-Type: application/json; charset=utf-8');
    echo json_encode($data, JSON_UNESCAPED_UNICODE | JSON_UNESCAPED_SLASHES);
    exit;
}

/**
 * Log basique des requêtes API (à améliorer selon tes besoins).
 */
function logRequest(string $method, string $uri, array $context = []): void
{
    $logFile = __DIR__ . '/../logs/api.log';
    $line    = sprintf(
        "[%s] %s %s %s\n",
        date('Y-m-d H:i:s'),
        $method,
        $uri,
        json_encode($context, JSON_UNESCAPED_UNICODE | JSON_UNESCAPED_SLASHES)
    );

    @file_put_contents($logFile, $line, FILE_APPEND);
}

// ─────────────────────────────────────────────────────────────
// Normalisation de la requête
// ─────────────────────────────────────────────────────────────

$method = strtoupper($_SERVER['REQUEST_METHOD'] ?? 'GET');

$rawPath = parse_url($_SERVER['REQUEST_URI'] ?? '/', PHP_URL_PATH) ?: '/';
$path    = trim($rawPath, '/');

// Si l'app est montée sous /user-manager, on retire ce préfixe
if (str_starts_with($path, 'user-manager/')) {
    $path = substr($path, strlen('user-manager/'));
}
if ($path === 'user-manager') {
    $path = '';
}

// Exemple : "api/users/12" → ['api', 'users', '12']
$segments = $path === '' ? [] : explode('/', $path);
$endpoint = $segments[0] ?? 'index';
$resource = $segments[1] ?? null;
$id       = $segments[2] ?? null;

logRequest($method, $rawPath, [
    'endpoint' => $endpoint,
    'resource' => $resource,
    'id'       => $id,
    'ip'       => $_SERVER['REMOTE_ADDR'] ?? 'unknown',
    'agent'    => $_SERVER['HTTP_USER_AGENT'] ?? 'unknown',
]);

// ─────────────────────────────────────────────────────────────
// ROUTAGE PRINCIPAL
// ─────────────────────────────────────────────────────────────

switch ($endpoint) {

    // ─────────────────────────────────────────────────────
    // ENDPOINT: /api/*
    // ─────────────────────────────────────────────────────
    case 'api':
        if ($resource === null) {
            jsonResponse([
                'status'    => 'success',
                'message'   => 'Bolt.DIY User Manager API v2.0',
                'version'   => '2.0.0',
                'endpoints' => [
                    '/api/auth/login'      => 'POST - Authentification',
                    '/api/auth/logout'     => 'POST - Déconnexion',
                    '/api/auth/me'         => 'GET  - Info utilisateur connecté',
                    '/api/users'           => 'GET  - Liste des utilisateurs',
                    '/api/users/{id}'      => 'GET  - Détail utilisateur',
                    '/api/users'           => 'POST - Créer un utilisateur',
                    '/api/users/{id}'      => 'PUT  - Mettre à jour un utilisateur',
                    '/api/users/{id}'      => 'DELETE - Supprimer un utilisateur',
                    '/api/groups'          => 'GET  - Liste des groupes',
                    '/api/groups/{id}'     => 'GET  - Détail groupe',
                    '/api/permissions'     => 'GET  - Permissions',
                    '/api/audit'           => 'GET  - Logs d’audit',
                ],
            ]);
        }

        switch ($resource) {
            case 'auth':
                require_once __DIR__ . '/../src/Controllers/AuthController.php';
                $controller = new App\Controllers\AuthController();
                $controller->handle($method, $id);
                break;

            case 'users':
                require_once __DIR__ . '/../src/Controllers/UserController.php';
                $controller = new App\Controllers\UserController();
                $controller->handle($method, $id);
                break;

            case 'groups':
                require_once __DIR__ . '/../src/Controllers/GroupController.php';
                $controller = new App\Controllers\GroupController();
                $controller->handle($method, $id);
                break;

            case 'permissions':
                require_once __DIR__ . '/../src/Controllers/PermissionController.php';
                $controller = new App\Controllers\PermissionController();
                $controller->handle($method, $id);
                break;

            case 'audit':
                require_once __DIR__ . '/../src/Controllers/AuditController.php';
                $controller = new App\Controllers\AuditController();
                $controller->handle($method, $id);
                break;

            default:
                jsonResponse([
                    'status'  => 'error',
                    'message' => 'Endpoint API non trouvé',
                ], 404);
        }

        break;

    // ─────────────────────────────────────────────────────
    // ENDPOINT: /health (healthcheck Docker)
    // ─────────────────────────────────────────────────────
    case 'health':
    case 'health.php':
        jsonResponse([
            'status'    => 'healthy',
            'service'   => 'bolt-user-manager',
            'version'   => '2.0.0',
            'timestamp' => date('Y-m-d H:i:s'),
            'uptime'    => sys_getloadavg()[0] ?? 0,
        ]);
        break;

    // ─────────────────────────────────────────────────────
    // ENDPOINT: / (page d’accueil → login ou dashboard)
    // ─────────────────────────────────────────────────────
    case 'index':
    case '':
        // Si demande explicite JSON, on renvoie un statut API
        if (strpos($_SERVER['HTTP_ACCEPT'] ?? '', 'application/json') !== false) {
            jsonResponse([
                'status'       => 'success',
                'message'      => 'Bolt.DIY User Manager v2.0',
                'api_endpoint' => '/api',
                'documentation'=> '/api',
            ]);
        }

        // Requête web classique : on protège par session
        $frontendDir = __DIR__ . '/public';

        $isLoggedIn  = !empty($_SESSION['user_id']);
        $loginFile   = $frontendDir . '/login.html';
        $dashboardFile = $frontendDir . '/index.html';

        if (!$isLoggedIn) {
            // Non connecté → page de login
            if (file_exists($loginFile)) {
                header('Location: /public/login.html');
                exit;
            }

            // Fallback minimal si le login.html n’existe pas
            ?>
            <!DOCTYPE html>
            <html lang="fr">
            <head>
                <meta charset="UTF-8">
                <title>User Manager – Connexion requise</title>
            </head>
            <body>
                <h1>User Manager</h1>
                <p>Vous devez vous authentifier pour accéder au tableau de bord.</p>
                <p>Créez un fichier <code>public/login.html</code> pour gérer l’interface de login.</p>
            </body>
            </html>
            <?php
            exit;
        }

        // Connecté → dashboard
        if (file_exists($dashboardFile)) {
            header('Location: /public/index.html');
            exit;
        }

        // Fallback temporaire si le frontend n’est pas encore déployé
        ?>
        <!DOCTYPE html>
        <html lang="fr">
        <head>
            <meta charset="UTF-8">
            <title>User Manager – API prête</title>
        </head>
        <body>
            <h1>Version 2.0.0 - API REST opérationnelle</h1>
            <p>✅ Service démarré avec succès.</p>
            <p>🔗 API accessible : <code>/api</code></p>
            <p>📊 Base de données : connectée.</p>
            <p>Déployez le frontend dans <code>public/index.html</code> pour le dashboard, et <code>public/login.html</code> pour la connexion.</p>
        </body>
        </html>
        <?php
        break;

    // ─────────────────────────────────────────────────────
    // ENDPOINTS inconnus
    // ─────────────────────────────────────────────────────
    default:
        // Pour les appels API → JSON 404
        if (str_starts_with($endpoint, 'api')) {
            jsonResponse([
                'status'  => 'error',
                'message' => 'Route non trouvée',
            ], 404);
        }

        // Pour le reste → 404 HTML simple
        http_response_code(404);
        ?>
        <!DOCTYPE html>
        <html lang="fr">
        <head>
            <meta charset="UTF-8">
            <title>404 – Page non trouvée</title>
        </head>
        <body>
            <h1>404 – Page non trouvée</h1>
            <p>La ressource demandée n’existe pas.</p>
        </body>
        </html>
        <?php
        break;
}
