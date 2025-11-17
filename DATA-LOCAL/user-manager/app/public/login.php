<?php
declare(strict_types=1);

session_start();

/**
 * Si déjà connecté, on renvoie vers le dashboard.
 */
if (!empty($_SESSION['user_id'])) {
    header('Location: /public/index.php');
    exit;
}

$error = '';

if ($_SERVER['REQUEST_METHOD'] === 'POST') {
    $username = trim($_POST['username'] ?? '');
    $password = $_POST['password'] ?? '';

    if ($username === '' || $password === '') {
        $error = 'Merci de renseigner votre nom d\'utilisateur et mot de passe.';
    } else {
        // Connexion à MariaDB
        $dsn = sprintf(
            'mysql:host=%s;dbname=%s;charset=utf8mb4',
            getenv('MARIADB_HOST') ?: 'mariadb',
            getenv('MARIADB_DATABASE') ?: 'user_manager'
        );
        $dbUser = getenv('MARIADB_USER') ?: 'user_manager';
        $dbPass = getenv('MARIADB_PASSWORD') ?: 'change_me';

        try {
            $pdo = new PDO($dsn, $dbUser, $dbPass, [
                PDO::ATTR_ERRMODE            => PDO::ERRMODE_EXCEPTION,
                PDO::ATTR_DEFAULT_FETCH_MODE => PDO::FETCH_ASSOC,
            ]);

            // Recherche par username au lieu d'email
            $stmt = $pdo->prepare(
                'SELECT id, username, email, password_hash, is_active
                 FROM users
                 WHERE username = :username
                 LIMIT 1'
            );
            $stmt->execute(['username' => $username]);
            $user = $stmt->fetch();

            if (!$user || !$user['is_active']) {
                $error = 'Compte introuvable ou désactivé.';
            } elseif (!password_verify($password, $user['password_hash'])) {
                $error = 'Mot de passe incorrect.';
            } else {
                // Authentification OK → créer la session
                $_SESSION['user_id']    = $user['id'];
                $_SESSION['username']   = $user['username'];
                $_SESSION['email']      = $user['email'];

                // Redirection vers le dashboard
                header('Location: /public/index.php');
                exit;
            }
        } catch (PDOException $e) {
            $error = 'Erreur de connexion à la base de données.';
            error_log('Login DB error: ' . $e->getMessage());
        }
    }
}
?>
<!DOCTYPE html>
<html lang="fr">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Connexion - User Manager</title>
    <style>
        * { margin: 0; padding: 0; box-sizing: border-box; }
        body {
            font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, sans-serif;
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            min-height: 100vh;
            display: flex;
            align-items: center;
            justify-content: center;
            padding: 20px;
        }
        .login-container {
            background: white;
            padding: 40px;
            border-radius: 16px;
            box-shadow: 0 20px 60px rgba(0,0,0,0.3);
            width: 100%;
            max-width: 420px;
        }
        h1 {
            color: #2d3748;
            margin-bottom: 30px;
            font-size: 28px;
            text-align: center;
        }
        .form-group {
            margin-bottom: 20px;
        }
        label {
            display: block;
            margin-bottom: 8px;
            color: #4a5568;
            font-weight: 500;
            font-size: 14px;
        }
        input[type="text"],
        input[type="password"] {
            width: 100%;
            padding: 12px 16px;
            border: 2px solid #e2e8f0;
            border-radius: 8px;
            font-size: 16px;
            transition: border-color 0.3s;
        }
        input[type="text"]:focus,
        input[type="password"]:focus {
            outline: none;
            border-color: #667eea;
        }
        button {
            width: 100%;
            padding: 14px;
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            color: white;
            border: none;
            border-radius: 8px;
            font-size: 16px;
            font-weight: 600;
            cursor: pointer;
            transition: transform 0.2s;
        }
        button:hover {
            transform: translateY(-2px);
        }
        button:active {
            transform: translateY(0);
        }
        .error {
            background: #fed7d7;
            color: #c53030;
            padding: 12px 16px;
            border-radius: 8px;
            margin-bottom: 20px;
            font-size: 14px;
            border-left: 4px solid #c53030;
        }
    </style>
</head>
<body>
    <div class="login-container">
        <h1>Connexion au User Manager</h1>

        <?php if ($error): ?>
            <div class="error"><?= htmlspecialchars($error) ?></div>
        <?php endif; ?>

        <form method="POST" action="">
            <div class="form-group">
                <label for="username">Nom d'utilisateur</label>
                <input
                    type="text"
                    id="username"
                    name="username"
                    value="<?= htmlspecialchars($_POST['username'] ?? '') ?>"
                    required
                    autofocus
                >
            </div>

            <div class="form-group">
                <label for="password">Mot de passe</label>
                <input
                    type="password"
                    id="password"
                    name="password"
                    required
                >
            </div>

            <button type="submit">Se connecter</button>
        </form>
    </div>
</body>
</html>
