<?php
ini_set('session.cookie_path', '/user-manager');
session_start();

if (isset($_SESSION['user_logged']) && $_SESSION['user_logged'] === true) {
    header('Location: /user-manager/index.php');
    exit;
}

$error = '';
if ($_SERVER['REQUEST_METHOD'] === 'POST') {
    $username = trim($_POST['login'] ?? '');
    $password = trim($_POST['password'] ?? '');
    if ($username === 'admin' && $password === 'passdemo') {
        $_SESSION['user_logged'] = true;
        $_SESSION['user_name'] = $username;
        header('Location: /user-manager/index.php');
        exit;
    } else {
        $error = "Nom d'utilisateur ou mot de passe incorrect";
    }
}
if (isset($_GET['reset'])) {
    session_destroy();
    header('Location: /user-manager/login.php');
    exit;
}
?>
<!DOCTYPE html>
<html lang="fr">
<head>
    <meta charset="UTF-8">
    <title>Connexion – Bolt.DIY User Manager</title>
    <link rel="stylesheet" href="/user-manager/assets/css/style.css">
    <meta name="viewport" content="width=device-width, initial-scale=1">
</head>
<body>
<div class="animated-bg"></div>
<div class="centered-box">
    <h1>🔐 Bolt.DIY <span>User Manager</span></h1>
    <p class="subtitle">Connectez-vous pour accéder à l'administration</p>
    <?php if ($error): ?>
        <div class="error"><?= htmlspecialchars($error) ?></div>
    <?php endif; ?>
    <form method="post" autocomplete="off">
        <label for="login">Nom d'utilisateur</label>
        <input type="text" name="login" id="login" required autocomplete="username" autofocus>
        <label for="password">Mot de passe</label>
        <input type="password" name="password" id="password" required autocomplete="current-password">
        <button type="submit">Se connecter</button>
    </form>
    <footer>&copy; <?= date('Y') ?> Nbility • Bolt.DIY</footer>
</div>
</body>
</html>
