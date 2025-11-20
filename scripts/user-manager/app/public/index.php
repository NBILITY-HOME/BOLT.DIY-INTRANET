<?php
/**
 * Bolt.DIY User Manager - Point d'entrée principal
 * Version: 1.0
 * Date: 18 novembre 2025
 */

// Démarrer la session
session_start();

// Définir la constante d'application
define('USER_MANAGER_APP', true);

// Charger la configuration
require_once __DIR__ . '/../config/config.php';

// Charger les helpers
require_once __DIR__ . '/../src/helpers.php';

// ============================================
// ROUTAGE SIMPLE
// ============================================

// Obtenir le chemin demandé
$request_uri = $_SERVER['REQUEST_URI'];
$script_name = dirname($_SERVER['SCRIPT_NAME']);

// Supprimer le préfixe /user-manager si présent
$path = str_replace($script_name, '', $request_uri);
$path = trim($path, '/');

// Supprimer les paramètres GET
$path = strtok($path, '?');

// Router par défaut : dashboard
if (empty($path) || $path === 'index.php') {
    $path = 'dashboard';
}

// Déterminer la page courante
$current_page = $path;

// ============================================
// PAGES DISPONIBLES (TEMPORAIRE - NIVEAU 2)
// ============================================

$available_pages = [
    'dashboard' => true,
    'users' => true,
    'groups' => true,
    'permissions' => true,
    'audit' => true,
    'settings' => true,
];

// Vérifier si la page existe
if (!isset($available_pages[$current_page])) {
    // Page 404
    http_response_code(404);
    $page_title = 'Page non trouvée';
    $content = '<div class="glass-card" style="text-align: center; padding: var(--spacing-xl);">
        <i class="fas fa-exclamation-triangle" style="font-size: 64px; color: var(--warning); margin-bottom: var(--spacing-lg);"></i>
        <h1>404 - Page non trouvée</h1>
        <p style="color: var(--text-secondary); margin-bottom: var(--spacing-lg);">
            La page que vous recherchez n\'existe pas.
        </p>
        <a href="' . url() . '" class="btn btn-primary">
            <i class="fas fa-home"></i> Retour au Dashboard
        </a>
    </div>';
    
    include __DIR__ . '/../src/Templates/base.php';
    exit;
}

// ============================================
// SIMULATION D'AUTHENTIFICATION (TEMPORAIRE)
// ============================================

// Pour le niveau 2, on simule un utilisateur connecté
if (!is_logged_in()) {
    $_SESSION['user_id'] = 1;
    $_SESSION['username'] = 'admin';
    $_SESSION['email'] = 'admin@bolt.diy';
    $_SESSION['role'] = 'admin';
}

// ============================================
// CHARGER LA PAGE DEMANDÉE
// ============================================

// Préparer les données de la page
$page_title = ucfirst($current_page);

// Template de contenu temporaire pour chaque page
switch ($current_page) {
    case 'dashboard':
        $page_title = 'Dashboard';
        $content_template = 'dashboard';
        break;
        
    case 'users':
        $page_title = 'Gestion des utilisateurs';
        $content_template = 'users';
        break;
        
    case 'groups':
        $page_title = 'Gestion des groupes';
        $content_template = 'groups';
        break;
        
    case 'permissions':
        $page_title = 'Gestion des permissions';
        $content_template = 'permissions';
        break;
        
    case 'audit':
        $page_title = 'Journal d\'audit';
        $content_template = 'audit';
        break;
        
    case 'settings':
        $page_title = 'Paramètres';
        $content_template = 'settings';
        break;
        
    default:
        $page_title = 'Page';
        $content = '<div class="glass-card"><h2>Page en construction</h2></div>';
}

// Vérifier si le template de contenu existe, sinon utiliser un placeholder
if (isset($content_template)) {
    $template_path = __DIR__ . '/../src/Templates/' . $content_template . '.php';
    if (!file_exists($template_path)) {
        // Template placeholder
        $content = '<div class="glass-card fade-in">
            <div style="text-align: center; padding: var(--spacing-xl);">
                <i class="fas fa-hammer" style="font-size: 64px; color: var(--primary); margin-bottom: var(--spacing-lg);"></i>
                <h1>' . e($page_title) . '</h1>
                <p style="color: var(--text-secondary); margin-bottom: var(--spacing-md);">
                    Cette page sera développée au niveau suivant.
                </p>
                <p style="color: var(--text-muted); font-size: 14px;">
                    Template: <code style="background: rgba(255,255,255,0.1); padding: 4px 8px; border-radius: 4px;">' . $content_template . '.php</code>
                </p>
            </div>
        </div>';
        unset($content_template);
    }
}

// ============================================
// AFFICHER LA PAGE
// ============================================

// Inclure le template de base qui chargera le contenu
include __DIR__ . '/../src/Templates/base.php';
