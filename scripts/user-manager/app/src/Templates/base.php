<?php
/**
 * Bolt.DIY User Manager - Template de base
 * Layout principal avec sidebar et navigation
 * Version: 1.0
 * Date: 18 novembre 2025
 */

// Empêcher l'accès direct
if (!defined('USER_MANAGER_APP')) {
    die('Accès interdit');
}

// Obtenir l'utilisateur courant
$current_user_data = current_user();
$is_authenticated = is_logged_in();

// Navigation
global $navigation;
?>
<!DOCTYPE html>
<html lang="fr">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <meta http-equiv="X-UA-Compatible" content="IE=edge">
    
    <title><?= isset($page_title) ? e($page_title) . ' - ' : '' ?><?= APP_NAME ?></title>
    
    <!-- Favicon -->
    <link rel="icon" type="image/png" href="<?= asset('img/favicon.png') ?>">
    
    <!-- Font Awesome -->
    <link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.4.0/css/all.min.css">
    
    <!-- Google Fonts -->
    <link rel="preconnect" href="https://fonts.googleapis.com">
    <link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
    <link href="https://fonts.googleapis.com/css2?family=Inter:wght@400;500;600;700&display=swap" rel="stylesheet">
    
    <!-- CSS Principal -->
    <link rel="stylesheet" href="<?= asset('css/style.css') ?>">
    
    <!-- CSS supplémentaire de la page -->
    <?php if (isset($extra_css)): ?>
        <?php foreach ($extra_css as $css): ?>
            <link rel="stylesheet" href="<?= asset($css) ?>">
        <?php endforeach; ?>
    <?php endif; ?>
</head>
<body>
    <!-- Fond animé "IA 2025" -->
    <div class="animated-background">
        <div class="bg-glow bg-glow-1"></div>
        <div class="bg-glow bg-glow-2"></div>
        <div class="bg-glow bg-glow-3"></div>
        <div class="bg-glow bg-glow-4"></div>
    </div>

    <!-- Bouton menu mobile -->
    <button class="mobile-menu-toggle" aria-label="Toggle menu">
        <i class="fas fa-bars"></i>
    </button>

    <!-- Overlay mobile -->
    <div class="sidebar-overlay"></div>

    <!-- Container principal -->
    <div class="app-container">
        <!-- Sidebar -->
        <aside class="sidebar">
            <!-- En-tête sidebar -->
            <div class="sidebar-header">
                <div class="sidebar-logo">
                    <i class="fas fa-user-shield"></i>
                </div>
                <div class="sidebar-title">
                    <h2>User Manager</h2>
                    <span class="sidebar-version">v<?= APP_VERSION ?></span>
                </div>
            </div>

            <!-- Navigation principale -->
            <nav class="sidebar-nav">
                <!-- Menu principal -->
                <div class="nav-section">
                    <div class="nav-section-title">Navigation</div>
                    <?php foreach ($navigation['main'] as $item): ?>
                        <?= render_nav_item($item) ?>
                    <?php endforeach; ?>
                </div>

                <!-- Raccourcis -->
                <div class="nav-section">
                    <div class="nav-section-title">Raccourcis</div>
                    <?php foreach ($navigation['shortcuts'] as $item): ?>
                        <?= render_nav_item($item) ?>
                    <?php endforeach; ?>
                </div>
            </nav>

            <!-- Pied de sidebar (utilisateur) -->
            <?php if ($is_authenticated): ?>
            <div class="sidebar-footer" style="padding: var(--spacing-lg); border-top: 1px solid var(--border-color); margin-top: auto;">
                <div style="display: flex; align-items: center; gap: var(--spacing-md);">
                    <div style="width: 40px; height: 40px; border-radius: 50%; background: linear-gradient(135deg, var(--primary), var(--neutral)); display: flex; align-items: center; justify-content: center; font-weight: 600; color: white;">
                        <?= strtoupper(substr($current_user_data['username'], 0, 2)) ?>
                    </div>
                    <div style="flex: 1; min-width: 0;">
                        <div style="font-weight: 600; color: var(--text-primary); font-size: 14px; white-space: nowrap; overflow: hidden; text-overflow: ellipsis;">
                            <?= e($current_user_data['username']) ?>
                        </div>
                        <div style="font-size: 12px; color: var(--text-muted);">
                            <?= e($current_user_data['role']) ?>
                        </div>
                    </div>
                    <a href="<?= url('logout') ?>" class="topbar-icon" style="position: static; margin: 0;" title="Déconnexion">
                        <i class="fas fa-sign-out-alt"></i>
                    </a>
                </div>
            </div>
            <?php endif; ?>
        </aside>

        <!-- Zone principale -->
        <main class="main-content">
            <!-- Topbar (optionnelle) -->
            <?php if (!isset($hide_topbar) || !$hide_topbar): ?>
            <div class="topbar">
                <!-- Barre de recherche -->
                <div class="topbar-search">
                    <div class="search-bar">
                        <i class="fas fa-search"></i>
                        <input type="text" placeholder="Rechercher..." id="global-search">
                    </div>
                </div>

                <!-- Actions topbar -->
                <div class="topbar-actions">
                    <!-- Notifications -->
                    <button class="topbar-icon" id="notifications-btn" title="Notifications">
                        <i class="fas fa-bell"></i>
                        <span class="notification-badge">3</span>
                    </button>

                    <!-- Messages -->
                    <button class="topbar-icon" id="messages-btn" title="Messages">
                        <i class="fas fa-envelope"></i>
                    </button>

                    <!-- Profil -->
                    <?php if ($is_authenticated): ?>
                    <div class="topbar-icon" style="cursor: pointer;" title="Profil">
                        <i class="fas fa-user-circle"></i>
                    </div>
                    <?php endif; ?>
                </div>
            </div>
            <?php endif; ?>

            <!-- Contenu de la page -->
            <div class="content-wrapper">
                <!-- Messages flash -->
                <?php if (has_flash('success')): ?>
                <div class="alert alert-success fade-in" style="background: rgba(50, 255, 226, 0.1); border: 1px solid rgba(50, 255, 226, 0.3); border-radius: var(--radius-md); padding: var(--spacing-md); margin-bottom: var(--spacing-lg); color: var(--success);">
                    <i class="fas fa-check-circle"></i>
                    <?= e(get_flash('success')) ?>
                </div>
                <?php endif; ?>

                <?php if (has_flash('error')): ?>
                <div class="alert alert-error fade-in" style="background: rgba(253, 101, 255, 0.1); border: 1px solid rgba(253, 101, 255, 0.3); border-radius: var(--radius-md); padding: var(--spacing-md); margin-bottom: var(--spacing-lg); color: var(--danger);">
                    <i class="fas fa-exclamation-circle"></i>
                    <?= e(get_flash('error')) ?>
                </div>
                <?php endif; ?>

                <?php if (has_flash('warning')): ?>
                <div class="alert alert-warning fade-in" style="background: rgba(255, 247, 72, 0.1); border: 1px solid rgba(255, 247, 72, 0.3); border-radius: var(--radius-md); padding: var(--spacing-md); margin-bottom: var(--spacing-lg); color: var(--warning);">
                    <i class="fas fa-exclamation-triangle"></i>
                    <?= e(get_flash('warning')) ?>
                </div>
                <?php endif; ?>

                <?php if (has_flash('info')): ?>
                <div class="alert alert-info fade-in" style="background: rgba(71, 118, 255, 0.1); border: 1px solid rgba(71, 118, 255, 0.3); border-radius: var(--radius-md); padding: var(--spacing-md); margin-bottom: var(--spacing-lg); color: var(--primary);">
                    <i class="fas fa-info-circle"></i>
                    <?= e(get_flash('info')) ?>
                </div>
                <?php endif; ?>

                <!-- Inclure le contenu de la page -->
                <?php if (isset($content_template)): ?>
                    <?php view($content_template, get_defined_vars()); ?>
                <?php elseif (isset($content)): ?>
                    <?= $content ?>
                <?php else: ?>
                    <div class="glass-card" style="text-align: center; padding: var(--spacing-xl);">
                        <i class="fas fa-exclamation-triangle" style="font-size: 48px; color: var(--warning); margin-bottom: var(--spacing-lg);"></i>
                        <h2>Contenu non défini</h2>
                        <p>Le contenu de cette page n'a pas été défini.</p>
                    </div>
                <?php endif; ?>
            </div>
        </main>
    </div>

    <!-- JavaScript Principal -->
    <script src="<?= asset('js/app.js') ?>"></script>

    <!-- JavaScript supplémentaire de la page -->
    <?php if (isset($extra_js)): ?>
        <?php foreach ($extra_js as $js): ?>
            <script src="<?= asset($js) ?>"></script>
        <?php endforeach; ?>
    <?php endif; ?>

    <!-- JavaScript inline de la page -->
    <?php if (isset($inline_js)): ?>
        <script><?= $inline_js ?></script>
    <?php endif; ?>

    <!-- Afficher les messages flash en Toast -->
    <script>
        // Afficher les messages flash automatiquement
        <?php if (has_flash('success')): ?>
            UserManager.Toast.success('<?= addslashes(get_flash('success')) ?>');
        <?php endif; ?>
        
        <?php if (has_flash('error')): ?>
            UserManager.Toast.error('<?= addslashes(get_flash('error')) ?>');
        <?php endif; ?>
        
        <?php if (has_flash('warning')): ?>
            UserManager.Toast.warning('<?= addslashes(get_flash('warning')) ?>');
        <?php endif; ?>
        
        <?php if (has_flash('info')): ?>
            UserManager.Toast.info('<?= addslashes(get_flash('info')) ?>');
        <?php endif; ?>
    </script>
</body>
</html>
