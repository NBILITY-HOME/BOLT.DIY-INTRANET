<?php
/**
 * Bolt.DIY User Manager - Template Dashboard
 * Version: 1.0
 * Date: 19 novembre 2025
 */

// Empêcher l'accès direct
if (!defined('USER_MANAGER_APP')) {
    die('Accès interdit');
}

// CSS et JS supplémentaires pour le dashboard
$extra_css = ['css/dashboard.css'];
$extra_js = ['js/dashboard.js'];
?>

<!-- En-tête du Dashboard -->
<div class="dashboard-header fade-in">
    <div style="display: flex; justify-content: space-between; align-items: start; flex-wrap: wrap; gap: var(--spacing-md);">
        <div>
            <h1 class="dashboard-title">Dashboard</h1>
            <p class="dashboard-subtitle">
                <i class="far fa-calendar"></i>
                <?= date('l j F Y') ?> • <?= date('H:i') ?>
            </p>
        </div>
        <div class="dashboard-actions">
            <button class="btn btn-outline" id="refresh-dashboard">
                <i class="fas fa-sync"></i>
                Rafraîchir
            </button>
            <a href="<?= url('users/add') ?>" class="btn btn-primary">
                <i class="fas fa-plus"></i>
                Nouvel utilisateur
            </a>
        </div>
    </div>
</div>

<!-- Tuiles statistiques -->
<div class="stats-grid">
    <!-- Carte 1 : Total utilisateurs -->
    <div class="stat-card primary fade-in">
        <div class="stat-card-header">
            <div class="stat-card-icon">
                <i class="fas fa-users"></i>
            </div>
            <div class="stat-card-trend up" id="users-trend">
                <i class="fas fa-arrow-up"></i> +12%
            </div>
        </div>
        <div class="stat-card-body">
            <div class="stat-card-value" id="total-users">0</div>
            <div class="stat-card-label">Total Utilisateurs</div>
        </div>
        <div class="stat-card-footer">
            <i class="fas fa-info-circle"></i>
            Par rapport au mois dernier
        </div>
    </div>

    <!-- Carte 2 : Utilisateurs actifs -->
    <div class="stat-card success fade-in" style="animation-delay: 0.1s;">
        <div class="stat-card-header">
            <div class="stat-card-icon">
                <i class="fas fa-user-check"></i>
            </div>
            <div class="stat-card-trend up" id="active-trend">
                <i class="fas fa-arrow-up"></i> +8%
            </div>
        </div>
        <div class="stat-card-body">
            <div class="stat-card-value" id="active-users">0</div>
            <div class="stat-card-label">Utilisateurs Actifs</div>
        </div>
        <div class="stat-card-footer">
            <i class="fas fa-info-circle"></i>
            Actifs sur 7 derniers jours
        </div>
    </div>

    <!-- Carte 3 : Groupes -->
    <div class="stat-card warning fade-in" style="animation-delay: 0.2s;">
        <div class="stat-card-header">
            <div class="stat-card-icon">
                <i class="fas fa-layer-group"></i>
            </div>
            <div class="stat-card-trend neutral">
                <i class="fas fa-minus"></i> 0%
            </div>
        </div>
        <div class="stat-card-body">
            <div class="stat-card-value" id="total-groups">0</div>
            <div class="stat-card-label">Groupes</div>
        </div>
        <div class="stat-card-footer">
            <i class="fas fa-info-circle"></i>
            Groupes configurés
        </div>
    </div>

    <!-- Carte 4 : Permissions -->
    <div class="stat-card neutral fade-in" style="animation-delay: 0.3s;">
        <div class="stat-card-header">
            <div class="stat-card-icon">
                <i class="fas fa-shield-alt"></i>
            </div>
            <div class="stat-card-trend neutral">
                <i class="fas fa-minus"></i> 0%
            </div>
        </div>
        <div class="stat-card-body">
            <div class="stat-card-value" id="total-permissions">0</div>
            <div class="stat-card-label">Permissions</div>
        </div>
        <div class="stat-card-footer">
            <i class="fas fa-info-circle"></i>
            Permissions actives
        </div>
    </div>
</div>

<!-- Actions rapides -->
<div class="quick-actions fade-in" style="animation-delay: 0.4s;">
    <a href="<?= url('users/add') ?>" class="quick-action">
        <div class="quick-action-icon">
            <i class="fas fa-user-plus"></i>
        </div>
        <div class="quick-action-text">
            <span class="quick-action-label">Nouvel utilisateur</span>
            <span class="quick-action-desc">Créer un compte</span>
        </div>
    </a>

    <a href="<?= url('groups') ?>" class="quick-action">
        <div class="quick-action-icon">
            <i class="fas fa-users-cog"></i>
        </div>
        <div class="quick-action-text">
            <span class="quick-action-label">Gérer les groupes</span>
            <span class="quick-action-desc">8 groupes actifs</span>
        </div>
    </a>

    <a href="<?= url('audit') ?>" class="quick-action">
        <div class="quick-action-icon">
            <i class="fas fa-clipboard-list"></i>
        </div>
        <div class="quick-action-text">
            <span class="quick-action-label">Journal d'audit</span>
            <span class="quick-action-desc">Consulter l'historique</span>
        </div>
    </a>

    <a href="<?= url('settings') ?>" class="quick-action">
        <div class="quick-action-icon">
            <i class="fas fa-cog"></i>
        </div>
        <div class="quick-action-text">
            <span class="quick-action-label">Paramètres</span>
            <span class="quick-action-desc">Configuration</span>
        </div>
    </a>
</div>

<!-- Graphiques -->
<div class="charts-grid">
    <!-- Graphique 1 : Activité utilisateurs -->
    <div class="chart-card fade-in" style="animation-delay: 0.5s;">
        <div class="chart-card-header">
            <div class="chart-card-title">
                <i class="fas fa-chart-line"></i>
                Activité utilisateurs
            </div>
            <div class="chart-controls">
                <button class="chart-control-btn active" data-period="7days">7 jours</button>
                <button class="chart-control-btn" data-period="30days">30 jours</button>
                <button class="chart-control-btn" data-period="90days">90 jours</button>
            </div>
        </div>
        <div class="chart-wrapper">
            <canvas id="activityChart"></canvas>
        </div>
    </div>

    <!-- Graphique 2 : Répartition par rôle -->
    <div class="chart-card fade-in" style="animation-delay: 0.6s;">
        <div class="chart-card-header">
            <div class="chart-card-title">
                <i class="fas fa-chart-pie"></i>
                Répartition par rôle
            </div>
        </div>
        <div class="chart-wrapper">
            <canvas id="roleChart"></canvas>
        </div>
    </div>
</div>

<!-- Activité récente -->
<div class="activity-card fade-in" style="animation-delay: 0.7s;">
    <div class="activity-header">
        <div class="activity-title">
            <i class="fas fa-history"></i>
            Activité récente
        </div>
        <a href="<?= url('audit') ?>" class="btn btn-sm btn-outline">
            Voir tout
            <i class="fas fa-arrow-right"></i>
        </a>
    </div>
    <div class="activity-feed" id="activity-feed">
        <!-- Les activités seront chargées dynamiquement par JavaScript -->
        <div style="text-align: center; padding: var(--spacing-xl); color: var(--text-muted);">
            <i class="fas fa-spinner fa-spin" style="font-size: 32px; margin-bottom: var(--spacing-md);"></i>
            <p>Chargement de l'activité...</p>
        </div>
    </div>
</div>

<!-- Charger Chart.js depuis CDN -->
<script src="https://cdn.jsdelivr.net/npm/chart.js@4.4.0/dist/chart.umd.min.js"></script>
