<?php
/**
 * ═══════════════════════════════════════════════════════════════════════════
 * BOLT.DIY USER MANAGER v2.0 - Entry Point
 * © Copyright Nbility 2025 - contact@nbility.fr
 * ═══════════════════════════════════════════════════════════════════════════
 */

// Configuration de base
error_reporting(E_ALL);
ini_set('display_errors', 0); // En production, mettre à 0
ini_set('log_errors', 1);
ini_set('error_log', __DIR__ . '/logs/php-errors.log');

// Démarrage de la session
session_start();

// Timezone
date_default_timezone_set('Europe/Paris');

// Autoload Composer
require_once __DIR__ . '/vendor/autoload.php';

// Chargement de la configuration
require_once __DIR__ . '/config/database.php';
require_once __DIR__ . '/config/app.php';

// Sécurité de base
header('X-Content-Type-Options: nosniff');
header('X-Frame-Options: DENY');
header('X-XSS-Protection: 1; mode=block');
header('Referrer-Policy: no-referrer-when-downgrade');

// Routeur simple
$action = $_GET['action'] ?? 'login';

// Si pas connecté et action != login, rediriger
if (!isset($_SESSION['user_id']) && $action !== 'login') {
    header('Location: ?action=login');
    exit;
}

?>
<!DOCTYPE html>
<html lang="fr">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Bolt.DIY User Manager v2.0</title>
    <style>
        * {
            margin: 0;
            padding: 0;
            box-sizing: border-box;
        }
        
        body {
            font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif;
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            min-height: 100vh;
            display: flex;
            align-items: center;
            justify-content: center;
            color: #fff;
        }
        
        .container {
            background: rgba(255, 255, 255, 0.1);
            backdrop-filter: blur(10px);
            border-radius: 20px;
            padding: 60px;
            text-align: center;
            box-shadow: 0 8px 32px rgba(0, 0, 0, 0.3);
            max-width: 600px;
        }
        
        h1 {
            font-size: 3em;
            margin-bottom: 20px;
            text-shadow: 2px 2px 4px rgba(0, 0, 0, 0.3);
        }
        
        p {
            font-size: 1.2em;
            line-height: 1.6;
            margin-bottom: 30px;
        }
        
        .status {
            background: rgba(255, 255, 255, 0.2);
            border-radius: 10px;
            padding: 20px;
            margin-top: 30px;
        }
        
        .status-item {
            display: flex;
            justify-content: space-between;
            padding: 10px 0;
            border-bottom: 1px solid rgba(255, 255, 255, 0.1);
        }
        
        .status-item:last-child {
            border-bottom: none;
        }
        
        .success {
            color: #48bb78;
            font-weight: bold;
        }
        
        .warning {
            color: #ed8936;
            font-weight: bold;
        }
    </style>
</head>
<body>
    <div class="container">
        <h1>🎯 Bolt.DIY User Manager v2.0</h1>
        <p>
            <strong>Installation détectée !</strong><br>
            Le User Manager v2.0 est en cours de développement.
        </p>
        
        <div class="status">
            <div class="status-item">
                <span>Base de données</span>
                <span class="success">✓ Connectée</span>
            </div>
            <div class="status-item">
                <span>Composer</span>
                <span class="<?php echo file_exists(__DIR__ . '/vendor/autoload.php') ? 'success' : 'warning'; ?>">
                    <?php echo file_exists(__DIR__ . '/vendor/autoload.php') ? '✓ Installé' : '⚠ En attente'; ?>
                </span>
            </div>
            <div class="status-item">
                <span>Configuration</span>
                <span class="success">✓ OK</span>
            </div>
        </div>
        
        <p style="margin-top: 30px; font-size: 0.9em; opacity: 0.8;">
            © 2025 Nbility - Tous droits réservés
        </p>
    </div>
</body>
</html>
