<?php
/**
 * Bolt.DIY User Manager - Page de déconnexion
 * Permet de révoquer l'authentification HTTP Basic
 */

// Forcer le navigateur à oublier les credentials HTTP Basic
header('WWW-Authenticate: Basic realm="Déconnexion"');
header('HTTP/1.0 401 Unauthorized');

?>
<!DOCTYPE html>
<html lang="fr">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Déconnexion - User Manager</title>
    <style>
        * {
            margin: 0;
            padding: 0;
            box-sizing: border-box;
        }

        body {
            font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif;
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            min-height: 100vh;
            display: flex;
            align-items: center;
            justify-content: center;
            padding: 20px;
        }

        .container {
            background: white;
            border-radius: 20px;
            padding: 60px 40px;
            box-shadow: 0 20px 60px rgba(0, 0, 0, 0.3);
            text-align: center;
            max-width: 500px;
            width: 100%;
            animation: slideUp 0.5s ease-out;
        }

        @keyframes slideUp {
            from {
                opacity: 0;
                transform: translateY(30px);
            }
            to {
                opacity: 1;
                transform: translateY(0);
            }
        }

        .icon {
            font-size: 80px;
            margin-bottom: 20px;
            animation: bounce 1s ease infinite;
        }

        @keyframes bounce {
            0%, 100% { transform: translateY(0); }
            50% { transform: translateY(-10px); }
        }

        h1 {
            color: #667eea;
            font-size: 32px;
            margin-bottom: 15px;
            font-weight: 700;
        }

        p {
            color: #666;
            font-size: 16px;
            line-height: 1.6;
            margin-bottom: 30px;
        }

        .success-message {
            background: #10b981;
            color: white;
            padding: 15px 20px;
            border-radius: 10px;
            margin-bottom: 30px;
            font-weight: 600;
        }

        .buttons {
            display: flex;
            gap: 15px;
            justify-content: center;
            flex-wrap: wrap;
        }

        .btn {
            display: inline-block;
            padding: 14px 32px;
            border-radius: 12px;
            font-weight: 600;
            font-size: 16px;
            text-decoration: none;
            transition: all 0.3s ease;
            cursor: pointer;
            border: none;
        }

        .btn-primary {
            background: linear-gradient(135deg, #667eea, #764ba2);
            color: white;
            box-shadow: 0 4px 15px rgba(102, 126, 234, 0.4);
        }

        .btn-primary:hover {
            transform: translateY(-2px);
            box-shadow: 0 8px 25px rgba(102, 126, 234, 0.6);
        }

        .btn-secondary {
            background: #f3f4f6;
            color: #667eea;
        }

        .btn-secondary:hover {
            background: #e5e7eb;
            transform: translateY(-2px);
        }

        .info-box {
            background: #f0f9ff;
            border: 2px solid #bfdbfe;
            border-radius: 10px;
            padding: 15px;
            margin-top: 30px;
            font-size: 14px;
            color: #1e40af;
            text-align: left;
        }

        .info-box strong {
            display: block;
            margin-bottom: 8px;
            font-size: 15px;
        }

        @media (max-width: 600px) {
            .container {
                padding: 40px 30px;
            }

            h1 {
                font-size: 26px;
            }

            .buttons {
                flex-direction: column;
            }

            .btn {
                width: 100%;
            }
        }
    </style>
</head>
<body>
    <div class="container">
        <div class="icon">👋</div>
        <h1>Déconnexion réussie</h1>
        <div class="success-message">
            ✓ Vous avez été déconnecté avec succès
        </div>
        <p>
            Votre session a été fermée. Pour des raisons de sécurité, 
            nous vous recommandons de fermer complètement votre navigateur.
        </p>

        <div class="buttons">
            <a href="http://LOCAL_IP:HOST_PORT_UM" class="btn btn-primary">
                🔐 Se reconnecter
            </a>
            <a href="http://LOCAL_IP:HOST_PORT_HOME" class="btn btn-secondary">
                🏠 Page d'accueil
            </a>
        </div>

        <div class="info-box">
            <strong>ℹ️ Note importante :</strong>
            L'authentification HTTP Basic est stockée par votre navigateur. 
            Pour une déconnexion complète, fermez tous les onglets de cette 
            application et redémarrez votre navigateur.
        </div>
    </div>
</body>
</html>
