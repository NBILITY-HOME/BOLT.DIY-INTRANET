<?php
$htpasswd_file = getenv('HTPASSWD_FILE') ?: '/var/www/html/.htpasswd';
$message = '';
$error = '';

if (!file_exists($htpasswd_file)) {
    touch($htpasswd_file);
    chmod($htpasswd_file, 0666);
}

if ($_SERVER['REQUEST_METHOD'] === 'POST') {
    $action = $_POST['action'] ?? '';
    $username = trim($_POST['username'] ?? '');
    $password = $_POST['password'] ?? '';
    
    if ($action === 'add' && $username && $password) {
        $cmd = 'htpasswd -nbB ' . escapeshellarg($username) . ' ' . escapeshellarg($password) . ' 2>&1';
        $output = trim(shell_exec($cmd));
        
        if ($output && strpos($output, ':') !== false) {
            $content = file_exists($htpasswd_file) ? file_get_contents($htpasswd_file) : '';
            $lines = array_filter(explode("\n", $content), function($l) { return trim($l) !== ''; });
            $existing = array_map(function($l) { return explode(':', trim($l))[0]; }, $lines);
            
            if (in_array($username, $existing)) {
                $error = "L'utilisateur existe déjà";
            } else {
                $lines[] = $output;
                file_put_contents($htpasswd_file, implode("\n", $lines) . "\n", LOCK_EX);
                chmod($htpasswd_file, 0666);
                $message = "Utilisateur ajouté avec succès";
            }
        }
    } elseif ($action === 'delete' && $username) {
        $content = file_get_contents($htpasswd_file);
        $lines = array_filter(explode("\n", $content), function($line) use ($username) {
            $line = trim($line);
            return $line && !str_starts_with($line, $username . ':');
        });
        file_put_contents($htpasswd_file, implode("\n", $lines) . "\n", LOCK_EX);
        chmod($htpasswd_file, 0666);
        $message = "Utilisateur supprimé";
    }
}

$users = [];
if (file_exists($htpasswd_file) && filesize($htpasswd_file) > 0) {
    $content = file_get_contents($htpasswd_file);
    foreach (explode("\n", $content) as $line) {
        $line = trim($line);
        if ($line && str_contains($line, ':')) {
            $users[] = explode(':', $line)[0];
        }
    }
    $users = array_unique($users);
    sort($users);
}
?>
<!DOCTYPE html>
<html lang="fr">
<head>
<meta charset="UTF-8">
<title>🔐 Bolt.DIY User Manager</title>
<style>
*{margin:0;padding:0;box-sizing:border-box}
body{font-family:-apple-system,BlinkMacSystemFont,"Segoe UI",Roboto,sans-serif;background:linear-gradient(135deg,#667eea 0%,#764ba2 100%);min-height:100vh;padding:20px}
.container{max-width:900px;margin:0 auto;background:#fff;border-radius:12px;box-shadow:0 20px 60px rgba(0,0,0,0.3);overflow:hidden}
.header{background:linear-gradient(135deg,#667eea 0%,#764ba2 100%);color:#fff;padding:30px;text-align:center}
.header h1{font-size:28px;margin-bottom:5px}
.header p{opacity:0.9;font-size:14px}
.content{padding:30px}
.message{padding:15px;margin-bottom:20px;border-radius:8px;background:#d4edda;color:#155724;border:1px solid #c3e6cb;font-weight:600}
.error{padding:15px;margin-bottom:20px;border-radius:8px;background:#f8d7da;color:#721c24;border:1px solid #f5c6cb;font-weight:600}
.form-section{background:#f8f9fa;padding:20px;border-radius:8px;margin-bottom:30px}
.form-section h2{margin-bottom:15px;color:#333;font-size:18px}
.form-group{margin-bottom:15px}
label{display:block;margin-bottom:5px;color:#555;font-weight:500}
input[type="text"],input[type="password"]{width:100%;padding:10px;border:2px solid #ddd;border-radius:6px;font-size:14px;transition:border-color 0.3s}
input:focus{outline:none;border-color:#667eea}
button{background:linear-gradient(135deg,#667eea 0%,#764ba2 100%);color:#fff;border:none;padding:12px 24px;border-radius:6px;cursor:pointer;font-size:14px;font-weight:600;transition:transform 0.2s}
button:hover{transform:translateY(-2px)}
button.delete{background:linear-gradient(135deg,#f093fb 0%,#f5576c 100%);padding:8px 16px;font-size:13px}
.users-list{background:#f8f9fa;padding:20px;border-radius:8px}
.users-list h2{margin-bottom:15px;color:#333;font-size:18px}
.user-item{background:#fff;padding:15px;margin-bottom:10px;border-radius:6px;display:flex;justify-content:space-between;align-items:center;border:1px solid #e0e0e0}
.user-name{font-weight:600;color:#333;font-size:15px}
.empty-state{text-align:center;padding:40px;color:#999}
.footer{text-align:center;padding:20px;color:#666;font-size:12px;border-top:1px solid #e0e0e0}
</style>
</head>
<body>
<div class="container">
<div class="header">
<h1>🔐 Bolt.DIY User Manager</h1>
<p>Nbility Edition - Gestion des utilisateurs</p>
</div>
<div class="content">
<?php if($message):?><div class="message">✓ <?=htmlspecialchars($message)?></div><?php endif;?>
<?php if($error):?><div class="error">✗ <?=htmlspecialchars($error)?></div><?php endif;?>
<div class="form-section">
<h2>➕ Ajouter un utilisateur</h2>
<form method="POST">
<input type="hidden" name="action" value="add">
<div class="form-group">
<label>Nom d'utilisateur</label>
<input type="text" name="username" required placeholder="ex: pierre" autocomplete="off">
</div>
<div class="form-group">
<label>Mot de passe</label>
<input type="password" name="password" required placeholder="Minimum 6 caractères" autocomplete="new-password">
</div>
<button type="submit">Ajouter l'utilisateur</button>
</form>
</div>
<div class="users-list">
<h2>👥 Utilisateurs existants (<?=count($users)?>)</h2>
<?php if(empty($users)):?>
<div class="empty-state"><p>Aucun utilisateur trouvé</p><p style="font-size:12px;margin-top:10px;color:#aaa">Ajoutez votre premier utilisateur ci-dessus</p></div>
<?php else:?>
<?php foreach($users as $user):?>
<div class="user-item">
<span class="user-name">👤 <?=htmlspecialchars($user)?></span>
<form method="POST" style="display:inline" onsubmit="return confirm('Supprimer <?=htmlspecialchars($user)?> ?')">
<input type="hidden" name="action" value="delete">
<input type="hidden" name="username" value="<?=htmlspecialchars($user)?>">
<button type="submit" class="delete">Supprimer</button>
</form>
</div>
<?php endforeach;?>
<?php endif;?>
</div>
</div>
<div class="footer">© 2025 Nbility - Bolt.DIY Intranet Edition v5.1</div>
</div>
</body>
</html>
