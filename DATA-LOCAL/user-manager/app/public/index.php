<?php
declare(strict_types=1);
session_start();

// ═══════════════════════════════════════════════════════════════
// FONCTIONS UTILITAIRES
// ═══════════════════════════════════════════════════════════════
function jsonResponse(array $data, int $statusCode = 200): void {
    http_response_code($statusCode);
    header('Content-Type: application/json');
    echo json_encode($data, JSON_PRETTY_PRINT | JSON_UNESCAPED_SLASHES | JSON_UNESCAPED_UNICODE);
    exit;
}

// ═══════════════════════════════════════════════════════════════
// ROUTAGE BASÉ SUR REQUEST_URI
// ═══════════════════════════════════════════════════════════════
$requestUri = $_SERVER['REQUEST_URI'] ?? '/';
$path = parse_url($requestUri, PHP_URL_PATH);

// Nettoyage : on supprime le slash final sauf pour '/'
if ($path !== '/' && str_ends_with($path, '/')) {
    $path = rtrim($path, '/');
}

// Découpage en segments (filtrage des vides)
$segments = explode('/', $path);
$segments = array_filter($segments, fn($s) => $s !== '');
$segments = array_values($segments);

$endpoint = $segments[0] ?? '';
$resource = $segments[1] ?? null;
$id = $segments[2] ?? null;

// ───────────────────────────────────────────────────────────────
// ROUTAGE PRINCIPAL
// ───────────────────────────────────────────────────────────────
switch ($endpoint) {
    // ─────────────────────────────────────────────────────
    // ENDPOINT: /api/*
    // ─────────────────────────────────────────────────────
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

    // ─────────────────────────────────────────────────────
    // ENDPOINT: /health (healthcheck Docker)
    // ─────────────────────────────────────────────────────
    case 'health':
    case 'health.php':
        jsonResponse([
            'status' => 'healthy',
            'service' => 'bolt-user-manager',
            'version' => '2.0.0',
            'timestamp' => date('Y-m-d H:i:s'),
        ]);
        break;

    // ─────────────────────────────────────────────────────
    // ENDPOINT: /public/* (fichiers statiques + garde auth)
    // ─────────────────────────────────────────────────────
    case 'public':
        // Si on demande public/index.php ou public/index, on applique la garde
        if ($resource === 'index.php' || $resource === 'index' || $resource === null) {
            $isLoggedIn = !empty($_SESSION['user_id']);

            if (!$isLoggedIn) {
                header('Location: /user-manager/login.php');  // ✅ CORRIGÉ (était /user-manager/login.php)
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

    // ─────────────────────────────────────────────────────
    // ENDPOINT: / ou vide (racine)
    // ─────────────────────────────────────────────────────
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
            header('Location: login.php');  // ✅ CORRIGÉ (était /login.php)
            exit;
        }

        // Connecté → dashboard
        header('Location: index.html');
        exit;

    // ─────────────────────────────────────────────────────
    // DEFAULT: 404
    // ─────────────────────────────────────────────────────
    default:
        header('Content-Type: text/html; charset=utf-8');
        http_response_code(404);
        ?>
        <!DOCTYPE html>
        <html lang="fr">
        <head>
            <meta charset="UTF-8">
            <title>404 - Page non trouvée</title>
        </head>
        <body>
            <h1>404 - Page non trouvée</h1>
            <p>La ressource demandée n'existe pas.</p>
            <a href="login.php">← Retour au login</a>
        </body>
        </html>
        <?php
        exit;
}
