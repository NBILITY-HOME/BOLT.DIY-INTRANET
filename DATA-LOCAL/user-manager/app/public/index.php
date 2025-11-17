<?php
declare(strict_types=1);

// ═══════════════════════════════════════════════════════════════════════════
// BOLT.DIY USER MANAGER v2.0 - Front Controller
// © Copyright Nbility 2025 - contact@nbility.fr
// ═══════════════════════════════════════════════════════════════════════════

// ───────────────────────────────────────────────────────────────
// Configuration : Démarrer session AVANT tout output
// ───────────────────────────────────────────────────────────────
ini_set('session.save_path', '/tmp');
session_start();

error_reporting(E_ALL);
ini_set('display_errors', '0');

// ───────────────────────────────────────────────────────────────
// Helper JSON Response
// ───────────────────────────────────────────────────────────────
function jsonResponse(array $data, int $statusCode = 200): void {
    header('Content-Type: application/json; charset=utf-8');
    http_response_code($statusCode);
    echo json_encode($data, JSON_UNESCAPED_UNICODE | JSON_PRETTY_PRINT);
    exit;
}

// ───────────────────────────────────────────────────────────────
// Routage simple
// ───────────────────────────────────────────────────────────────
$requestUri = $_SERVER['REQUEST_URI'] ?? '/';
$method = $_SERVER['REQUEST_METHOD'] ?? 'GET';

// Nettoyage de l'URI
$path = parse_url($requestUri, PHP_URL_PATH) ?? '/';

// Parsing du chemin
$segments = array_filter(explode('/', $path), fn($s) => $s !== '');
$segments = array_values($segments);

$endpoint = $segments[0] ?? '';
$resource = $segments[1] ?? null;
$id = $segments[2] ?? null;

// ───────────────────────────────────────────────────────────────
// ROUTAGE PRINCIPAL
// ───────────────────────────────────────────────────────────────
switch ($endpoint) {

    // ───────────────────────────────────────────────────────
    // ENDPOINT: /api/*
    // ───────────────────────────────────────────────────────
    case 'api':
        if ($resource === null) {
            jsonResponse([
                'status' => 'success',
                'message' => 'Bolt.DIY User Manager API v2.0',
                'version' => '2.0.0',
                'endpoints' => [
                    '/api/auth/login' => 'POST - Authentification',
                    '/api/auth/logout' => 'POST - Déconnexion',
                    '/api/users' => 'GET - Liste des utilisateurs',
                    '/api/groups' => 'GET - Liste des groupes',
                    '/api/permissions' => 'GET - Permissions',
                    '/api/audit' => 'GET - Logs d\'audit',
                ],
            ]);
        }

        // Pour l'instant, on retourne un message "non implémenté"
        jsonResponse([
            'status' => 'error',
            'message' => 'API endpoint not yet implemented',
            'requested' => $resource,
        ], 501);
        break;

    // ───────────────────────────────────────────────────────
    // ENDPOINT: /health (healthcheck Docker)
    // ───────────────────────────────────────────────────────
    case 'health':
    case 'health.php':
        jsonResponse([
            'status' => 'healthy',
            'service' => 'bolt-user-manager',
            'version' => '2.0.0',
            'timestamp' => date('Y-m-d H:i:s'),
        ]);
        break;

    // ───────────────────────────────────────────────────────
    // ENDPOINT: /public/* (fichiers statiques + garde auth)
    // ───────────────────────────────────────────────────────
    case 'public':
        // Si on demande public/index.php ou public/index, on applique la garde
        if ($resource === 'index.php' || $resource === 'index' || $resource === null) {
            $isLoggedIn = !empty($_SESSION['user_id']);
            if (!$isLoggedIn) {
                header('Location: /public/login.php');
                exit;
            }
            // Connecté : on sert le dashboard
            $dashboardFile = __DIR__ . '/index.html';
            if (file_exists($dashboardFile)) {
                header('Content-Type: text/html; charset=utf-8');
                readfile($dashboardFile);
                exit;
            }
        }
        // Sinon Apache sert directement les fichiers statiques
        break;

    // ───────────────────────────────────────────────────────
    // ENDPOINT: / ou vide (racine)
    // ───────────────────────────────────────────────────────
    case '':
    case 'index':
    case 'index.php':
        // Si demande explicite JSON
        if (strpos($_SERVER['HTTP_ACCEPT'] ?? '', 'application/json') !== false) {
            jsonResponse([
                'status' => 'success',
                'message' => 'Bolt.DIY User Manager v2.0',
                'api_endpoint' => '/api',
            ]);
        }

        // Requête web : protection par session
        $isLoggedIn = !empty($_SESSION['user_id']);

        if (!$isLoggedIn) {
            header('Location: /public/login.php');
            exit;
        }

        // Connecté → dashboard
        header('Location: /public/index.html');
        exit;

    // ───────────────────────────────────────────────────────
    // DEFAULT: 404
    // ───────────────────────────────────────────────────────
    default:
        header('Content-Type: text/html; charset=utf-8');
        http_response_code(404);
        ?>
        <!DOCTYPE html>
        <html lang="fr">
        <head>
            <meta charset="UTF-8">
            <meta name="viewport" content="width=device-width, initial-scale=1.0">
            <title>404 – Page non trouvée</title>
            <style>
                body { font-family: Arial, sans-serif; text-align: center; padding: 50px; background: #f5f5f5; }
                h1 { color: #e74c3c; }
                a { color: #3498db; text-decoration: none; }
            </style>
        </head>
        <body>
            <h1>404 – Page non trouvée</h1>
            <p>La ressource demandée n'existe pas.</p>
            <p><a href="/public/login.php">← Retour au login</a></p>
        </body>
        </html>
        <?php
        exit;
}
