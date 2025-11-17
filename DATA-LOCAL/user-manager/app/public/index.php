<?php
// /var/www/html/public/index.php
declare(strict_types=1);

session_start();

// Vérifier si l'utilisateur est connecté
if (!isset($_SESSION['user_id'])) {
    header('Location: login.php');
    exit;
}

// Charger la configuration
require_once __DIR__ . '/../config/database.php';

try {
    $pdo = getDbConnection();

    // Récupérer les informations de l'utilisateur connecté
    $stmt = $pdo->prepare('SELECT username, email, role FROM um_users WHERE id = :id');
    $stmt->execute(['id' => $_SESSION['user_id']]);
    $user = $stmt->fetch(PDO::FETCH_ASSOC);

    if (!$user) {
        session_destroy();
        header('Location: login.php');
        exit;
    }

    // Récupérer la liste des utilisateurs (admin uniquement)
    $users = [];
    if (in_array($user['role'], ['admin', 'superadmin'])) {
        $stmt = $pdo->query('
            SELECT id, username, email, role, status,
                   DATE_FORMAT(created_at, "%Y-%m-%d %H:%i") as created_at,
                   DATE_FORMAT(last_login, "%Y-%m-%d %H:%i") as last_login
            FROM um_users
            ORDER BY created_at DESC
        ');
        $users = $stmt->fetchAll(PDO::FETCH_ASSOC);
    }

} catch (PDOException $e) {
    error_log('Database error: ' . $e->getMessage());
    $error = 'Erreur de connexion à la base de données';
}
?>
<!DOCTYPE html>
<html lang="fr">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Gestion des utilisateurs - Bolt.DIY</title>
    <link rel="stylesheet" href="/user-manager/assets/css/style.css">
</head>
<body>
    <div class="container">
        <header class="page-header">
            <h1>🔐 Gestion des utilisateurs</h1>
            <div class="user-info">
                <span>Connecté en tant que: <strong><?= htmlspecialchars($user['username']) ?></strong> (<?= htmlspecialchars($user['role']) ?>)</span>
                <a href="logout.php" class="btn btn-secondary">Déconnexion</a>
            </div>
        </header>

        <?php if (isset($error)): ?>
            <div class="alert alert-error"><?= htmlspecialchars($error) ?></div>
        <?php endif; ?>

        <?php if (!empty($users)): ?>
            <section class="users-section">
                <h2>Liste des utilisateurs (<?= count($users) ?>)</h2>
                <div class="table-container">
                    <table class="users-table">
                        <thead>
                            <tr>
                                <th>ID</th>
                                <th>Nom d'utilisateur</th>
                                <th>Email</th>
                                <th>Rôle</th>
                                <th>Statut</th>
                                <th>Créé le</th>
                                <th>Dernière connexion</th>
                            </tr>
                        </thead>
                        <tbody>
                            <?php foreach ($users as $u): ?>
                                <tr>
                                    <td><?= htmlspecialchars((string)$u['id']) ?></td>
                                    <td><?= htmlspecialchars($u['username']) ?></td>
                                    <td><?= htmlspecialchars($u['email']) ?></td>
                                    <td><span class="badge badge-<?= strtolower($u['role']) ?>"><?= htmlspecialchars($u['role']) ?></span></td>
                                    <td><span class="badge badge-<?= strtolower($u['status']) ?>"><?= htmlspecialchars($u['status']) ?></span></td>
                                    <td><?= htmlspecialchars($u['created_at'] ?? 'N/A') ?></td>
                                    <td><?= htmlspecialchars($u['last_login'] ?? 'Jamais') ?></td>
                                </tr>
                            <?php endforeach; ?>
                        </tbody>
                    </table>
                </div>
            </section>
        <?php else: ?>
            <div class="alert alert-info">Vous n'avez pas les permissions pour voir les utilisateurs.</div>
        <?php endif; ?>
    </div>
</body>
</html>
