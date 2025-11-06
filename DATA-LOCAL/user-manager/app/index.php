<?php
$htpasswdFile = getenv('HTPASSWD_FILE') ?: '/app/.htpasswd';
$message = '';

if ($_SERVER['REQUEST_METHOD'] === 'POST') {
    $action = $_POST['action'] ?? '';
    $username = $_POST['username'] ?? '';
    $password = $_POST['password'] ?? '';

    if ($action === 'add' && $username && $password) {
        $hash = password_hash($password, PASSWORD_BCRYPT);
        $entry = "$username:$hash\n";
        file_put_contents($htpasswdFile, $entry, FILE_APPEND);
        $message = "✅ Utilisateur $username ajouté";
    } elseif ($action === 'delete' && $username) {
        $lines = file($htpasswdFile);
        $newLines = array_filter($lines, function($line) use ($username) {
            return strpos($line, "$username:") !== 0;
        });
        file_put_contents($htpasswdFile, implode('', $newLines));
        $message = "🗑️ Utilisateur $username supprimé";
    }
}

$users = [];
if (file_exists($htpasswdFile)) {
    $lines = file($htpasswdFile);
    foreach ($lines as $line) {
        if (trim($line)) {
            $users[] = explode(':', trim($line))[0];
        }
    }
}
?>
<!DOCTYPE html>
<html lang="fr">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>User Manager - Bolt.DIY</title>
    <link href="https://fonts.googleapis.com/css2?family=Inter:wght@300;400;500;600;700&display=swap" rel="stylesheet">
    <style>
        * { margin: 0; padding: 0; box-sizing: border-box; }
        
        body {
            font-family: 'Inter', sans-serif;
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            min-height: 100vh;
            padding: 40px 20px;
        }
        
        .container {
            max-width: 1000px;
            margin: 0 auto;
            background: white;
            border-radius: 24px;
            padding: 48px;
            box-shadow: 0 20px 60px rgba(0,0,0,0.3);
        }
        
        h1 {
            color: #667eea;
            font-size: 2.5rem;
            margin-bottom: 8px;
            font-weight: 700;
        }
        
        .subtitle {
            color: #64748b;
            margin-bottom: 40px;
        }
        
        .message {
            padding: 16px 24px;
            margin-bottom: 32px;
            background: #d1fae5;
            color: #065f46;
            border-radius: 12px;
            font-weight: 500;
            border-left: 4px solid #10b981;
        }
        
        .section {
            background: #f8fafc;
            padding: 32px;
            border-radius: 16px;
            margin-bottom: 32px;
        }
        
        .section h2 {
            color: #1e293b;
            font-size: 1.5rem;
            margin-bottom: 24px;
            font-weight: 600;
        }
        
        input {
            width: 100%;
            padding: 14px 18px;
            margin-bottom: 16px;
            border: 2px solid #e2e8f0;
            border-radius: 12px;
            font-size: 1rem;
            font-family: 'Inter', sans-serif;
        }
        
        input:focus {
            outline: none;
            border-color: #667eea;
            box-shadow: 0 0 0 3px rgba(102, 126, 234, 0.1);
        }
        
        button {
            width: 100%;
            padding: 14px 24px;
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            color: white;
            border: none;
            border-radius: 12px;
            font-size: 1rem;
            font-weight: 600;
            cursor: pointer;
            font-family: 'Inter', sans-serif;
        }
        
        button:hover {
            transform: translateY(-2px);
            box-shadow: 0 8px 25px rgba(102, 126, 234, 0.4);
        }
        
        .user-list {
            list-style: none;
        }
        
        .user-item {
            display: flex;
            justify-content: space-between;
            align-items: center;
            padding: 20px;
            margin-bottom: 12px;
            background: white;
            border-radius: 12px;
            border: 2px solid #e2e8f0;
        }
        
        .user-name {
            font-weight: 600;
            color: #1e293b;
            font-size: 1.1rem;
        }
        
        .delete-btn {
            width: auto;
            padding: 10px 20px;
            background: linear-gradient(135deg, #ef4444 0%, #dc2626 100%);
            font-size: 0.9rem;
        }
        
        .delete-btn:hover {
            background: linear-gradient(135deg, #dc2626 0%, #b91c1c 100%);
        }
        
        .empty-state {
            text-align: center;
            padding: 48px;
            color: #64748b;
        }
        
        .empty-state-icon {
            font-size: 4rem;
            margin-bottom: 16px;
        }
    </style>
</head>
<body>
    <div class="container">
        <h1>👥 User Manager</h1>
        <p class="subtitle">Gestion des utilisateurs Bolt.DIY Nbility</p>
        
        <?php if ($message): ?>
            <div class="message"><?= htmlspecialchars($message) ?></div>
        <?php endif; ?>

        <div class="section">
            <h2>➕ Ajouter un utilisateur</h2>
            <form method="POST">
                <input type="hidden" name="action" value="add">
                <input type="text" name="username" placeholder="Nom d'utilisateur" required>
                <input type="password" name="password" placeholder="Mot de passe" required>
                <button type="submit">Ajouter l'utilisateur</button>
            </form>
        </div>

        <div class="section">
            <h2>📋 Utilisateurs existants (<?= count($users) ?>)</h2>
            <?php if (empty($users)): ?>
                <div class="empty-state">
                    <div class="empty-state-icon">👤</div>
                    <p>Aucun utilisateur enregistré</p>
                </div>
            <?php else: ?>
                <ul class="user-list">
                    <?php foreach ($users as $user): ?>
                        <li class="user-item">
                            <span class="user-name">👤 <?= htmlspecialchars($user) ?></span>
                            <form method="POST" style="margin: 0;">
                                <input type="hidden" name="action" value="delete">
                                <input type="hidden" name="username" value="<?= htmlspecialchars($user) ?>">
                                <button type="submit" class="delete-btn" onclick="return confirm('Supprimer <?= htmlspecialchars($user) ?> ?')">
                                    🗑️ Supprimer
                                </button>
                            </form>
                        </li>
                    <?php endforeach; ?>
                </ul>
            <?php endif; ?>
        </div>
    </div>
</body>
</html>
