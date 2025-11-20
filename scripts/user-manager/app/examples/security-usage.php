<?php
/* ============================================
   Bolt.DIY User Manager - Security Usage Example
   Version: 1.0
   Date: 19 novembre 2025
   ============================================ */

// Load security bootstrap
require_once __DIR__ . '/bootstrap/security.php';

use App\Security\Security;
use App\Security\Session;
use App\Security\Validator;

/* ============================================
   EXEMPLE 1 : FORMULAIRE DE CONNEXION
   ============================================ */

// Traitement du formulaire
if ($_SERVER['REQUEST_METHOD'] === 'POST') {
    
    // Validation des données
    $validator = Validator::make($_POST);
    
    $validator
        ->required('email', 'Email requis')
        ->email('email', 'Email invalide')
        ->required('password', 'Mot de passe requis');
    
    if ($validator->fails()) {
        $_SESSION['errors'] = $validator->getErrors();
        $_SESSION['old_input'] = $_POST;
        header('Location: /user-manager/login');
        exit;
    }
    
    $email = $security->sanitizeEmail($_POST['email']);
    $password = $_POST['password'];
    
    // Rate limiting
    $clientIp = $security->getClientIp();
    if (!$security->checkRateLimit('login_' . $clientIp, 5, 900)) {
        $_SESSION['errors'] = ['login' => ['Trop de tentatives. Réessayez dans 15 minutes.']];
        header('Location: /user-manager/login');
        exit;
    }
    
    // Vérifier les credentials (exemple simplifié)
    // En production, vérifier contre la base de données
    $user = [
        'id' => 1,
        'email' => 'admin@example.com',
        'password_hash' => '$argon2id$v=19$m=65536,t=4,p=3$...',
        'name' => 'Admin User',
        'role' => 'Administrateur'
    ];
    
    if ($email === $user['email'] && $security->verifyPassword($password, $user['password_hash'])) {
        // Connexion réussie
        $security->resetRateLimit('login_' . $clientIp);
        
        $session->login($user['id'], [
            'name' => $user['name'],
            'email' => $user['email'],
            'role' => $user['role']
        ]);
        
        // Remember me
        if (isset($_POST['remember_me'])) {
            $token = bin2hex(random_bytes(32));
            $session->setRememberMe($user['id'], $token, 30);
        }
        
        header('Location: /user-manager/');
        exit;
    } else {
        // Connexion échouée
        $_SESSION['errors'] = ['login' => ['Email ou mot de passe incorrect']];
        header('Location: /user-manager/login');
        exit;
    }
}

?>
<!DOCTYPE html>
<html lang="fr">
<head>
    <meta charset="UTF-8">
    <title>Connexion</title>
</head>
<body>
    <form method="POST" action="">
        <?php echo csrf_field(); ?>
        
        <?php if ($error = errors('login')): ?>
            <div class="error"><?php echo $error[0]; ?></div>
        <?php endif; ?>
        
        <div>
            <label>Email</label>
            <input type="email" name="email" value="<?php echo old('email'); ?>" required>
            <?php if ($error = errors('email')): ?>
                <span class="error"><?php echo $error[0]; ?></span>
            <?php endif; ?>
        </div>
        
        <div>
            <label>Mot de passe</label>
            <input type="password" name="password" required>
            <?php if ($error = errors('password')): ?>
                <span class="error"><?php echo $error[0]; ?></span>
            <?php endif; ?>
        </div>
        
        <div>
            <label>
                <input type="checkbox" name="remember_me">
                Se souvenir de moi
            </label>
        </div>
        
        <button type="submit">Se connecter</button>
    </form>
</body>
</html>

<?php

/* ============================================
   EXEMPLE 2 : CRÉATION D'UTILISATEUR
   ============================================ */

if ($_SERVER['REQUEST_METHOD'] === 'POST' && isset($_POST['action']) && $_POST['action'] === 'create_user') {
    
    // Vérifier que l'utilisateur est connecté et est admin
    if (!$session->isLoggedIn() || $session->getUserData('role') !== 'Administrateur') {
        http_response_code(403);
        die('Accès refusé');
    }
    
    // Validation
    $validator = Validator::make($_POST);
    
    $validator
        ->required('name', 'Nom requis')
        ->min('name', 2, 'Nom trop court')
        ->max('name', 100, 'Nom trop long')
        ->required('email', 'Email requis')
        ->email('email', 'Email invalide')
        ->required('password', 'Mot de passe requis')
        ->password('password', 8, true, 'Mot de passe trop faible')
        ->same('password_confirmation', 'password', 'Les mots de passe ne correspondent pas')
        ->in('role', ['Administrateur', 'Manager', 'Utilisateur'], 'Rôle invalide');
    
    if ($validator->fails()) {
        echo json_encode([
            'success' => false,
            'errors' => $validator->getErrors()
        ]);
        exit;
    }
    
    // Sanitize data
    $name = $security->sanitizeString($_POST['name']);
    $email = $security->sanitizeEmail($_POST['email']);
    $role = $security->sanitizeString($_POST['role']);
    
    // Hash password
    $passwordHash = $security->hashPassword($_POST['password']);
    
    // En production : sauvegarder en base de données
    // $pdo->prepare("INSERT INTO users (name, email, password, role) VALUES (?, ?, ?, ?)")
    //     ->execute([$name, $email, $passwordHash, $role]);
    
    echo json_encode([
        'success' => true,
        'message' => 'Utilisateur créé avec succès'
    ]);
    exit;
}

/* ============================================
   EXEMPLE 3 : UPLOAD DE FICHIER
   ============================================ */

if ($_SERVER['REQUEST_METHOD'] === 'POST' && isset($_FILES['avatar'])) {
    
    // Vérifier connexion
    if (!$session->isLoggedIn()) {
        http_response_code(403);
        die('Connexion requise');
    }
    
    // Valider l'upload
    $result = $security->validateFileUpload(
        $_FILES['avatar'],
        ['image/jpeg', 'image/png', 'image/webp'],
        5242880 // 5 MB
    );
    
    if (!$result['valid']) {
        echo json_encode([
            'success' => false,
            'message' => $result['message']
        ]);
        exit;
    }
    
    // Générer nom sécurisé
    $filename = $security->generateSecureFilename($_FILES['avatar']['name']);
    $uploadPath = __DIR__ . '/uploads/avatars/' . $filename;
    
    // Déplacer le fichier
    if (move_uploaded_file($_FILES['avatar']['tmp_name'], $uploadPath)) {
        echo json_encode([
            'success' => true,
            'filename' => $filename,
            'message' => 'Fichier uploadé avec succès'
        ]);
    } else {
        echo json_encode([
            'success' => false,
            'message' => 'Erreur lors de l\'upload'
        ]);
    }
    exit;
}

/* ============================================
   EXEMPLE 4 : CHANGEMENT DE MOT DE PASSE
   ============================================ */

if ($_SERVER['REQUEST_METHOD'] === 'POST' && isset($_POST['action']) && $_POST['action'] === 'change_password') {
    
    // Vérifier connexion
    if (!$session->isLoggedIn()) {
        http_response_code(403);
        die('Connexion requise');
    }
    
    // Validation
    $validator = Validator::make($_POST);
    
    $validator
        ->required('current_password', 'Mot de passe actuel requis')
        ->required('new_password', 'Nouveau mot de passe requis')
        ->password('new_password', 8, true, 'Nouveau mot de passe trop faible')
        ->same('new_password_confirmation', 'new_password', 'Les mots de passe ne correspondent pas')
        ->different('new_password', 'current_password', 'Le nouveau mot de passe doit être différent');
    
    if ($validator->fails()) {
        echo json_encode([
            'success' => false,
            'errors' => $validator->getErrors()
        ]);
        exit;
    }
    
    // En production : récupérer l'utilisateur de la base
    $userId = $session->getUserId();
    // $user = $pdo->prepare("SELECT * FROM users WHERE id = ?")->execute([$userId]);
    
    // Vérifier l'ancien mot de passe
    $currentPasswordHash = '$argon2id$v=19$m=65536,t=4,p=3$...'; // De la base
    
    if (!$security->verifyPassword($_POST['current_password'], $currentPasswordHash)) {
        echo json_encode([
            'success' => false,
            'message' => 'Mot de passe actuel incorrect'
        ]);
        exit;
    }
    
    // Hash le nouveau mot de passe
    $newPasswordHash = $security->hashPassword($_POST['new_password']);
    
    // En production : mettre à jour en base
    // $pdo->prepare("UPDATE users SET password = ? WHERE id = ?")
    //     ->execute([$newPasswordHash, $userId]);
    
    echo json_encode([
        'success' => true,
        'message' => 'Mot de passe modifié avec succès'
    ]);
    exit;
}

/* ============================================
   EXEMPLE 5 : VÉRIFICATION DE SESSION
   ============================================ */

// Protéger une page admin
function requireAdmin() {
    global $session;
    
    if (!$session->isLoggedIn()) {
        header('Location: /user-manager/login');
        exit;
    }
    
    if ($session->getUserData('role') !== 'Administrateur') {
        http_response_code(403);
        die('Accès refusé');
    }
}

// Utilisation
// requireAdmin();

/* ============================================
   EXEMPLE 6 : DÉCONNEXION
   ============================================ */

if (isset($_GET['action']) && $_GET['action'] === 'logout') {
    $session->logout();
    $session->clearRememberMe();
    header('Location: /user-manager/login');
    exit;
}

/* ============================================
   EXEMPLE 7 : REMEMBER ME
   ============================================ */

// Vérifier le cookie remember_me au chargement de la page
if (!$session->isLoggedIn()) {
    $rememberData = $session->getRememberMe();
    
    if ($rememberData) {
        // En production : vérifier le token en base
        // $user = $pdo->prepare("SELECT * FROM users WHERE id = ? AND remember_token = ?")
        //     ->execute([$rememberData['user_id'], $rememberData['token']]);
        
        // Si valide, reconnecter automatiquement
        // $session->login($user['id'], [...]);
    }
}
