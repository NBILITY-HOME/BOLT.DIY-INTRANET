<?php
/**
 * ═══════════════════════════════════════════════════════════════════════════
 * BOLT.DIY USER MANAGER v2.0 - Login
 * © Copyright Nbility 2025 - contact@nbility.fr
 * Page de connexion avec authentification par username
 * ═══════════════════════════════════════════════════════════════════════════
 */

session_start();

// Si déjà connecté, rediriger vers le dashboard
if (!empty($_SESSION['user_id'])) {
    header('Location: /index.php');
    exit;
}

$error = '';

if ($_SERVER['REQUEST_METHOD'] === 'POST') {
    $username = trim($_POST['username'] ?? '');
    $password = trim($_POST['password'] ?? '');

    if (empty($username) || empty($password)) {
        $error = 'Veuillez remplir tous les champs.';
    } else {
        try {
            // Connexion à la base de données
            $dsn = 'mysql:host=' . ($_ENV['DB_HOST'] ?? 'mariadb') . ';dbname=' . ($_ENV['DB_NAME'] ?? 'bolt_cms') . ';charset=utf8mb4';
            $pdo = new PDO(
                $dsn,
                $_ENV['DB_USER'] ?? 'bolt_user',
                $_ENV['DB_PASSWORD'] ?? 'bolt_password',
                [
                    PDO::ATTR_ERRMODE => PDO::ERRMODE_EXCEPTION,
                    PDO::ATTR_DEFAULT_FETCH_MODE => PDO::FETCH_ASSOC,
                ]
            );

            // Recherche par username au lieu d'email
            $stmt = $pdo->prepare(
                'SELECT id, username, email, password_hash, is_active FROM users WHERE username = :username LIMIT 1'
            );
            $stmt->execute(['username' => $username]);
            $user = $stmt->fetch();

            if (!$user || !$user['is_active']) {
                $error = 'Compte introuvable ou désactivé.';
            } elseif (!password_verify($password, $user['password_hash'])) {
                $error = 'Mot de passe incorrect.';
            } else {
                // Authentification OK → créer la session
                $_SESSION['user_id'] = $user['id'];
                $_SESSION['username'] = $user['username'];
                $_SESSION['email'] = $user['email'];

                // ✅ CORRECTION : Redirection vers le dashboard
                header('Location: /index.php');
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
    <title>Connexion - Bolt.DIY User Manager</title>
    <link rel="stylesheet" href="/user-manager/assets/css/style.css">
</head>
<body class="login-page">
    <div class="login-container">
        <div class="login-card">
            <h1>🔐 Bolt.DIY User Manager</h1>
            <p class="subtitle">Connectez-vous pour accéder à l'administration</p>

            <?php if (!empty($error)): ?>
                <div class="alert alert-error">
                    <?= htmlspecialchars($error, ENT_QUOTES, 'UTF-8') ?>
                </div>
            <?php endif; ?>

            <form method="POST" action="/login.php">
                <div class="form-group">
                    <label for="username">Nom d'utilisateur</label>
                    <input
                        type="text"
                        id="username"
                        name="username"
                        required
                        autofocus
                        placeholder="Entrez votre nom d'utilisateur"
                        value="<?= htmlspecialchars($_POST['username'] ?? '', ENT_QUOTES, 'UTF-8') ?>"
                    >
                </div>

                <div class="form-group">
                    <label for="password">Mot de passe</label>
                    <input
                        type="password"
                        id="password"
                        name="password"
                        required
                        placeholder="Entrez votre mot de passe"
                    >
                </div>

                <button type="submit" class="btn btn-primary btn-block">
                    Se connecter
                </button>
            </form>

            <div class="login-footer">
                <p>© 2025 Nbility - Bolt.DIY v2.0</p>
            </div>
        </div>
    </div>
</body>
</html>
