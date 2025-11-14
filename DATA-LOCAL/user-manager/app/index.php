<?php
/**
 * BOLT.DIY User Manager v2.0 - Entry Point
 * Copyright Nbility 2025
 */

error_reporting(E_ALL);
ini_set('display_errors', 1);

// Récupération des variables d'environnement
$db_host = getenv('DB_HOST') ?: 'bolt-mariadb';
$db_port = getenv('DB_PORT') ?: '3306';
$db_name = getenv('DB_NAME') ?: 'bolt_usermanager';
$db_user = getenv('DB_USER') ?: 'bolt_um';
$db_password = getenv('DB_PASSWORD') ?: '';

// Connexion à la base de données
try {
    $dsn = "mysql:host=$db_host;port=$db_port;dbname=$db_name;charset=utf8mb4";
    $pdo = new PDO($dsn, $db_user, $db_password, [
        PDO::ATTR_ERRMODE => PDO::ERRMODE_EXCEPTION,
        PDO::ATTR_DEFAULT_FETCH_MODE => PDO::FETCH_ASSOC,
        PDO::ATTR_EMULATE_PREPARES => false
    ]);

    // Récupérer les statistiques
    $stmt = $pdo->query("SELECT COUNT(*) as total FROM users");
    $stats['total_users'] = $stmt->fetchColumn();

    $stmt = $pdo->query("SELECT COUNT(*) as total FROM users WHERE is_active = 1");
    $stats['active_users'] = $stmt->fetchColumn();

    $stmt = $pdo->query("SELECT COUNT(*) as total FROM groups");
    $stats['total_groups'] = $stmt->fetchColumn();
} catch (PDOException $e) {
    $stats = ['total_users' => 0, 'active_users' => 0, 'total_groups' => 0];
    $db_error = $e->getMessage();
}
?>
<!DOCTYPE html>
<html lang="fr">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>User Manager v2.0 - Bolt.DIY</title>
    <style>
        * { margin: 0; padding: 0; box-sizing: border-box; }
        body {
            font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, Oxygen, Ubuntu, sans-serif;
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            min-height: 100vh;
            padding: 20px;
        }
        .container { max-width: 1200px; margin: 0 auto; }

        .header {
            background: white;
            border-radius: 15px;
            padding: 30px;
            margin-bottom: 20px;
            box-shadow: 0 10px 30px rgba(0,0,0,0.2);
            display: flex;
            justify-content: space-between;
            align-items: center;
            flex-wrap: wrap;
            gap: 20px;
        }

        .header-left h1 { 
            color: #667eea; 
            font-size: 32px; 
            margin-bottom: 5px; 
        }

        .header-left p { 
            color: #666; 
            font-size: 14px; 
        }

        .header-right {
            display: flex;
            gap: 10px;
            align-items: center;
        }

        .user-info {
            display: flex;
            align-items: center;
            gap: 10px;
            padding: 10px 15px;
            background: #f3f4f6;
            border-radius: 10px;
            font-size: 14px;
            color: #374151;
        }

        .user-icon {
            width: 35px;
            height: 35px;
            background: linear-gradient(135deg, #667eea, #764ba2);
            border-radius: 50%;
            display: flex;
            align-items: center;
            justify-content: center;
            color: white;
            font-weight: bold;
        }

        .btn-logout {
            padding: 12px 24px;
            background: linear-gradient(135deg, #ef4444, #dc2626);
            color: white;
            border: none;
            border-radius: 10px;
            font-weight: 600;
            cursor: pointer;
            transition: all 0.3s ease;
            text-decoration: none;
            display: inline-flex;
            align-items: center;
            gap: 8px;
            font-size: 15px;
        }

        .btn-logout:hover {
            transform: translateY(-2px);
            box-shadow: 0 8px 20px rgba(239, 68, 68, 0.4);
        }

        .stats {
            display: grid;
            grid-template-columns: repeat(auto-fit, minmax(250px, 1fr));
            gap: 20px;
            margin-bottom: 20px;
        }

        .stat-card {
            background: white;
            border-radius: 15px;
            padding: 25px;
            box-shadow: 0 10px 30px rgba(0,0,0,0.2);
            text-align: center;
        }

        .stat-card h3 { 
            color: #667eea; 
            font-size: 36px; 
            margin-bottom: 10px; 
        }

        .stat-card p { 
            color: #666; 
            font-size: 14px; 
            text-transform: uppercase; 
            letter-spacing: 1px; 
        }

        .footer {
            text-align: center;
            color: white;
            margin-top: 30px;
            font-size: 14px;
            opacity: 0.9;
        }

        @media(max-width:768px){
            .header {
                flex-direction: column;
                text-align: center;
            }

            .header-right {
                flex-direction: column;
                width: 100%;
            }

            .btn-logout {
                width: 100%;
                justify-content: center;
            }
        }
    </style>
</head>
<body>
    <div class="container">
        <div class="header">
            <div class="header-left">
                <h1>🔧 User Manager v2.0</h1>
                <p>Bolt.DIY Intranet Edition - Système de gestion des utilisateurs</p>
            </div>
            <div class="header-right">
                <div class="user-info">
                    <div class="user-icon">
                        <?php echo strtoupper(substr($_SERVER['PHP_AUTH_USER'] ?? 'A', 0, 1)); ?>
                    </div>
                    <span><strong><?php echo htmlspecialchars($_SERVER['PHP_AUTH_USER'] ?? 'Admin'); ?></strong></span>
                </div>
                <a href="/logout.php" class="btn-logout">
                    🚪 Déconnexion
                </a>
            </div>
        </div>

        <div class="stats">
            <div class="stat-card">
                <h3><?php echo $stats['total_users']; ?></h3>
                <p>Utilisateurs totaux</p>
            </div>
            <div class="stat-card">
                <h3><?php echo $stats['active_users']; ?></h3>
                <p>Utilisateurs actifs</p>
            </div>
            <div class="stat-card">
                <h3><?php echo $stats['total_groups']; ?></h3>
                <p>Groupes</p>
            </div>
        </div>

        <?php if (isset($db_error)): ?>
        <div style="background: #fef2f2; border: 2px solid #ef4444; border-radius: 15px; padding: 20px; margin-top: 20px;">
            <h3 style="color: #dc2626; margin-bottom: 10px;">⚠️ Erreur de connexion à la base de données</h3>
            <p style="color: #7f1d1d; font-size: 14px;"><?php echo htmlspecialchars($db_error); ?></p>
        </div>
        <?php endif; ?>

        <div class="footer">
            © 2025 Nbility - Bolt.DIY Intranet Edition v6.6 - User Manager v2.0
        </div>
    </div>
</body>
</html>
