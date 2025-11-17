<?php
declare(strict_types=1);

session_start();

// Nettoyage complet de la session
$_SESSION = [];
if (ini_get('session.use_cookies')) {
    $params = session_get_cookie_params();
    setcookie(
        session_name(),
        '',
        time() - 42000,
        $params['path'],
        $params['domain'],
        $params['secure'],
        $params['httponly']
    );
}
session_destroy();
?>
<!DOCTYPE html>
<html lang="fr">
<head>
    <meta charset="UTF-8">
    <title>User Manager – Déconnexion</title>
    <meta name="viewport" content="width=device-width, initial-scale=1.0">

    <link rel="stylesheet" href="/user-manager/public/css/style.css">
</head>
<body>
    <main class="auth-layout">
        <section class="auth-card">
            <h1>Vous êtes maintenant déconnecté(e).</h1>
            <p>
                Pour plus de sécurité, vous pouvez fermer complètement votre navigateur.
            </p>
            <p>
                <a href="/user-manager/public/login.php" class="btn btn-primary">
                    Revenir à la page de connexion
                </a>
            </p>
        </section>
    </main>
</body>
</html>
