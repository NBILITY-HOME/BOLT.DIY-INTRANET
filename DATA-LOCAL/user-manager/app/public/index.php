<?php
ini_set('session.cookie_path', '/user-manager');
session_start();
if (empty($_SESSION['user_logged']) || empty($_SESSION['user_name'])) {
    header('Location: /user-manager/login.php');
    exit;
}
if (isset($_GET['logout'])) {
    session_destroy();
    header('Location: /user-manager/login.php');
    exit;
}
?>
<!DOCTYPE html>
<html lang="fr">
<head>
    <meta charset="UTF-8">
    <title>Admin – Bolt.DIY User Manager</title>
    <link rel="stylesheet" href="assets/css/style.css">
    <meta name="viewport" content="width=device-width, initial-scale=1">
</head>
<body>
<div class="animated-bg"></div>
<div class="centered-box">
    <h1>Bienvenue,<br><span><?= htmlspecialchars($_SESSION['user_name']) ?></span></h1>
    <p class="subtitle">Authentification réussie sur l’administration Bolt.DIY User Manager.</p>
    <a class="logout" href="?logout=1">Déconnexion</a>
    <footer>&copy; <?= date('Y') ?> Nbility • Bolt.DIY</footer>
</div>
</body>
</html>
