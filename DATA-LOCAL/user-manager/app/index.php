<?php
// Configuration
$htpasswd_file = getenv('HTPASSWD_FILE') ?: '/var/www/html/.htpasswd';
$message = '';
$error = '';

// Vérifier si le fichier existe et est accessible
if (!file_exists($htpasswd_file)) {
    touch($htpasswd_file);
    chmod($htpasswd_file, 0666);
}

// Traitement des actions
if ($_SERVER['REQUEST_METHOD'] === 'POST') {
    $action = $_POST['action'] ?? '';
    $username = trim($_POST['username'] ?? '');
    $password = $_POST['password'] ?? '';
    
    if ($action === 'add' && $username && $password) {
        // Vérifier que htpasswd est disponible
        $htpasswd_exists = shell_exec('which htpasswd 2>&1');
        
        if ($htpasswd_exists) {
            // Utiliser htpasswd avec algorithme bcrypt
            $cmd = sprintf(
                'htpasswd -nbB %s %s 2>&1',
                escapeshellarg($username),
                escapeshellarg($password)
            );
            $output = shell_exec($cmd);
            
            if ($output && strpos($output, ':') !== false) {
                // Vérifier que l'utilisateur n'existe pas déjà
                $existing_users = [];
                if (file_exists($htpasswd_file)) {
                    $lines = file($htpasswd_file, FILE_IGNORE_NEW_LINES | FILE_SKIP_EMPTY_LINES);
                    foreach ($lines as $line) {
                        if (strpos($line, ':') !== false) {
                            $existing_users[] = explode(':', $line)[0];
                        }
                    }
                }
                
                if (in_array($username, $existing_users)) {
                    $error = "L'utilisateur '$username' existe déjà";
                } else {
                    // Ajouter la nouvelle ligne
                    $result = file_put_contents($htpasswd_file, $output, FILE_APPEND | LOCK_EX);
                    
                    if ($result !== false) {
                        // Vérifier les permissions
                        chmod($htpasswd_file, 0666);
                        $message = "Utilisateur '$username' ajouté avec succès";
                    } else {
                        $error = "Impossible d'écrire dans le fichier .htpasswd (permissions?)";
                    }
                }
            } else {
                $error = "Erreur lors de la génération du hash : " . htmlspecialchars($output);
            }
        } else {
            $error = "La commande htpasswd n'est pas disponible. Installation en cours...";
        }
        
    } elseif ($action === 'delete' && $username) {
        if (!file_exists($htpasswd_file)) {
            $error = "Fichier .htpasswd introuvable";
        } else {
            $lines = file($htpasswd_file, FILE_IGNORE_NEW_LINES | FILE_SKIP_EMPTY_LINES);
            $new_lines = array_filter($lines, function($line) use ($username) {
                if (strpos($line, ':') === false) return true;
                return explode(':', $line)[0] !== $username;
            });
            
            $result = file_put_contents($htpasswd_file, implode(PHP_EOL, $new_lines) . PHP_EOL, LOCK_EX);
            
            if ($result !== false) {
                $message = "Utilisateur '$username' supprimé";
            } else {
                $error = "Impossible de supprimer l'utilisateur";
            }
        }
    }
}

// Lire la liste des utilisateurs
$users = [];
if (file_exists($htpasswd_file)) {
    clearstatcache(true, $htpasswd_file); // Forcer le rafraîchissement du cache
    
    $lines = file($htpasswd_file, FILE_IGNORE_NEW_LINES | FILE_SKIP_EMPTY_LINES);
    foreach ($lines as $line) {
        if (strpos($line, ':') !== false) {
            $parts = explode(':', $line, 2);
            $users[] = $parts[0];
        }
    }
}
?>
<!DOCTYPE html>
<html lang="fr">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>🔐 Bolt.DIY User Manager</title>
    <style>
        * { margin: 0; padding: 0; box-sizing: border-box; }
        body { 
            font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, sans-serif; 
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%); 
            min-height: 100vh; 
            padding: 20px; 
        }
        .container { 
            max-width: 900px; 
            margin: 0 auto; 
            background: white; 
            border-radius: 12px; 
            box-shadow: 0 20px 60px rgba(0,0,0,0.3); 
            overflow: hidden; 
        }
        .header { 
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%); 
            color: white; 
            padding: 30px; 
            text-align: center; 
        }
        .header h1 { font-size: 28px; margin-bottom: 5px; }
        .header p { opacity: 0.9; font-size: 14px; }
        .content { padding: 30px; }
        .message { 
            padding: 15px; 
            margin-bottom: 20px; 
            border-radius: 8px; 
            background: #d4edda; 
            color: #155724; 
            border: 1px solid #c3e6cb; 
        }
        .error { 
            padding: 15px; 
            margin-bottom: 20px; 
            border-radius: 8px; 
            background: #f8d7da; 
            color: #721c24; 
            border: 1px solid #f5c6cb; 
        }
        .form-section { 
            background: #f8f9fa; 
            padding: 20px; 
            border-radius: 8px; 
            margin-bottom: 30px; 
        }
        .form-section h2 { 
            margin-bottom: 15px; 
            color: #333; 
            font-size: 18px; 
        }
        .form-group { margin-bottom: 15px; }
        label { 
            display: block; 
            margin-bottom: 5px; 
            color: #555; 
            font-weight: 500; 
        }
        input[type="text"], input[type="password"] { 
            width: 100%; 
            padding: 10px; 
            border: 2px solid #ddd; 
            border-radius: 6px; 
            font-size: 14px; 
            transition: border-color 0.3s; 
        }
        input:focus { 
            outline: none; 
            border-color: #667eea; 
        }
        button { 
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%); 
            color: white; 
            border: none; 
            padding: 12px 24px; 
            border-radius: 6px; 
            cursor: pointer; 
            font-size: 14px; 
            font-weight: 600; 
            transition: transform 0.2s; 
        }
        button:hover { transform: translateY(-2px); }
        button.delete { 
            background: linear-gradient(135deg, #f093fb 0%, #f5576c 100%); 
            padding: 8px 16px;
            font-size: 13px;
        }
        .users-list { 
            background: #f8f9fa; 
            padding: 20px; 
            border-radius: 8px; 
        }
        .users-list h2 { 
            margin-bottom: 15px; 
            color: #333; 
            font-size: 18px; 
        }
        .user-item { 
            background: white; 
            padding: 15px; 
            margin-bottom: 10px; 
            border-radius: 6px; 
            display: flex; 
            justify-content: space-between; 
            align-items: center; 
            border: 1px solid #e0e0e0; 
        }
        .user-name { 
            font-weight: 600; 
            color: #333; 
            font-size: 15px;
        }
        .empty-state {
            text-align: center;
            padding: 40px;
            color: #999;
        }
        .footer { 
            text-align: center; 
            padding: 20px; 
            color: #666; 
            font-size: 12px; 
            border-top: 1px solid #e0e0e0; 
        }
    </style>
</head>
<body>
    <div class="container">
        <div class="header">
            <h1>🔐 Bolt.DIY User Manager</h1>
            <p>Nbility Edition - Gestion des utilisateurs</p>
        </div>
        
        <div class="content">
            <?php if ($message): ?>
                <div class="message">✓ <?= htmlspecialchars($message) ?></div>
            <?php endif; ?>
            
            <?php if ($error): ?>
                <div class="error">✗ <?= htmlspecialchars($error) ?></div>
            <?php endif; ?>
            
            <div class="form-section">
                <h2>➕ Ajouter un utilisateur</h2>
                <form method="POST">
                    <input type="hidden" name="action" value="add">
                    <div class="form-group">
                        <label>Nom d'utilisateur</label>
                        <input type="text" name="username" required placeholder="ex: pierre">
                    </div>
                    <div class="form-group">
                        <label>Mot de passe</label>
                        <input type="password" name="password" required placeholder="Minimum 6 caractères">
                    </div>
                    <button type="submit">Ajouter l'utilisateur</button>
                </form>
            </div>
            
            <div class="users-list">
                <h2>👥 Utilisateurs existants (<?= count($users) ?>)</h2>
                <?php if (empty($users)): ?>
                    <div class="empty-state">
                        <p>Aucun utilisateur trouvé</p>
                        <p style="font-size: 12px; margin-top: 10px; color: #aaa;">Ajoutez votre premier utilisateur ci-dessus</p>
                    </div>
                <?php else: ?>
                    <?php foreach ($users as $user): ?>
                        <div class="user-item">
                            <span class="user-name">👤 <?= htmlspecialchars($user) ?></span>
                            <form method="POST" style="display: inline;" onsubmit="return confirm('Supprimer <?= htmlspecialchars($user) ?> ?')">
                                <input type="hidden" name="action" value="delete">
                                <input type="hidden" name="username" value="<?= htmlspecialchars($user) ?>">
                                <button type="submit" class="delete">Supprimer</button>
                            </form>
                        </div>
                    <?php endforeach; ?>
                <?php endif; ?>
            </div>
        </div>
        
        <div class="footer">
            © 2025 Nbility - Bolt.DIY Intranet Edition v5.1
        </div>
    </div>
</body>
</html>
