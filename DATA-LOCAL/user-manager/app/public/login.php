<?php
declare(strict_types=1);

session_start();

/**
 * Si déjà connecté, on renvoie vers le dashboard.
 */
if (!empty($_SESSION['user_id'])) {
    header('Location: /user-manager/public/index.php');
    exit;
}

$error = '';

if ($_SERVER['REQUEST_METHOD'] === 'POST') {
    $email    = trim($_POST['email'] ?? '');
    $password = $_POST['password'] ?? '';

    if ($email === '' || $password === '') {
        $error = 'Merci de renseigner email et mot de passe.';
    } else {
        // Connexion à MariaDB – à adapter si besoin aux variables d’environnement réelles
        $dsn      = sprintf(
            'mysql:host=%s;dbname=%s;charset=utf8mb4',
            getenv('MARIADB_HOST') ?: 'mariadb',
            getenv('MARIADB_DATABASE') ?: 'user_manager'
        );
        $dbUser   = getenv('MARIADB_USER') ?: 'user_manager';
        $dbPass   = getenv('MARIADB_PASSWORD') ?: 'change_me';

        try {
            $pdo = new PDO($dsn, $dbUser, $dbPass, [
                PDO::ATTR_ERRMODE            => PDO::ERRMODE_EXCEPTION,
                PDO::ATTR_DEFAULT_FETCH_MODE => PDO::FETCH_ASSOC,
            ]);

            // Exemple de schéma : table users(id, email, password_hash, is_active, is_super_admin, ...)
            $stmt = $pdo->prepare(
                'SELECT id, email, password_hash, is_active
                 FROM users
                 WHERE email = :email
                 LIMIT 1'
            );
            $stmt->execute(['email' => $email]);
            $user = $stmt->fetch();

            if (!$user || !$user['is_active']) {
                $error = 'Compte introuvable ou désactivé.';
            } elseif (!password_verify($password, $user['password_hash'])) {
                $error = 'Mot de passe incorrect.';
            } else {
                // Auth OK : on initialise la session
                $_SESSION['user_id']    = (int) $user['id'];
                $_SESSION['user_email'] = $user['email'];

                // Redirection vers le dashboard
                header('Location: /user-manager/public/index.php');
                exit;
            }
        } catch (Throwable $e) {
            // En production, loguer le détail dans un fichier plutôt que l’afficher
            $error = "Erreur de connexion au service d'authentification.";
        }
    }
}
?>
<!DOCTYPE html>
<html lang="fr">
<head>
    <meta charset="UTF-8">
    <title>User Manager – Connexion</title>
    <meta name="viewport" content="width=device-width, initial-scale=1.0">

    <!-- Tu peux replacer ici tes <link> CSS actuels -->
    <link rel="stylesheet" href="/user-manager/public/css/style.css">
</head>
<body>
    <main class="auth-layout">
        <section class="auth-card">
            <h1>Connexion au User Manager</h1>

            <?php if ($error !== ''): ?>
                <div class="alert alert-error">
                    <?= htmlspecialchars($error, ENT_QUOTES | ENT_SUBSTITUTE, 'UTF-8') ?>
                </div>
            <?php endif; ?>

            <form method="post" action="/user-manager/public/login.php" class="auth-form" autocomplete="off">
                <div class="form-group">
                    <label for="email">Adresse e-mail</label>
                    <input
                        type="email"
                        id="email"
                        name="email"
                        required
                        value="<?= htmlspecialchars($email ?? '', ENT_QUOTES | ENT_SUBSTITUTE, 'UTF-8') ?>"
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

                <button type="submit" class="btn btn-primary">
                    Se connecter
                </button>
            </form>
        </section>
    </main>
</body>
</html>
