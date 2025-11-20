<?php
/**
 * Bolt.DIY User Manager - Template Utilisateurs
 * Version: 1.0
 * Date: 19 novembre 2025
 */

// Empêcher l'accès direct
if (!defined('USER_MANAGER_APP')) {
    die('Accès interdit');
}

// CSS et JS supplémentaires
$extra_css = ['css/users.css'];
$extra_js = ['js/users.js'];
?>

<!-- En-tête de la page -->
<div class="page-header fade-in">
    <h1 class="page-title">Gestion des utilisateurs</h1>
    <div class="page-actions">
        <button class="btn btn-outline" onclick="location.reload()">
            <i class="fas fa-sync"></i>
            Actualiser
        </button>
        <button class="btn btn-primary" id="add-user-btn">
            <i class="fas fa-plus"></i>
            Nouvel utilisateur
        </button>
    </div>
</div>

<!-- Barre de filtres -->
<div class="filters-bar fade-in" style="animation-delay: 0.1s;">
    <!-- Recherche -->
    <div class="filter-group">
        <label class="filter-label">Rechercher</label>
        <div class="search-bar">
            <i class="fas fa-search"></i>
            <input type="text" id="search-users" placeholder="Nom, email...">
        </div>
    </div>

    <!-- Filtre par rôle -->
    <div class="filter-group">
        <label class="filter-label">Rôle</label>
        <select class="form-select" id="filter-role">
            <option value="">Tous les rôles</option>
            <option value="admin">Administrateur</option>
            <option value="moderator">Modérateur</option>
            <option value="user">Utilisateur</option>
            <option value="guest">Invité</option>
        </select>
    </div>

    <!-- Filtre par statut -->
    <div class="filter-group">
        <label class="filter-label">Statut</label>
        <select class="form-select" id="filter-status">
            <option value="">Tous les statuts</option>
            <option value="active">Actif</option>
            <option value="inactive">Inactif</option>
        </select>
    </div>

    <!-- Actions filtres -->
    <div class="filter-actions">
        <button class="btn btn-outline" id="reset-filters">
            <i class="fas fa-redo"></i>
            Réinitialiser
        </button>
    </div>
</div>

<!-- Tableau des utilisateurs -->
<div class="users-table-container glass-card fade-in relative" style="animation-delay: 0.2s;">
    <table class="users-table">
        <thead>
            <tr>
                <th class="sortable" onclick="usersManager?.sortUsers('username')">
                    Utilisateur
                    <i class="fas fa-sort"></i>
                </th>
                <th class="sortable" onclick="usersManager?.sortUsers('lastName')">
                    Nom complet
                    <i class="fas fa-sort"></i>
                </th>
                <th class="sortable" onclick="usersManager?.sortUsers('role')">
                    Rôle
                    <i class="fas fa-sort"></i>
                </th>
                <th class="sortable" onclick="usersManager?.sortUsers('status')">
                    Statut
                    <i class="fas fa-sort"></i>
                </th>
                <th class="sortable" onclick="usersManager?.sortUsers('lastLogin')">
                    Dernière connexion
                    <i class="fas fa-sort"></i>
                </th>
                <th>Actions</th>
            </tr>
        </thead>
        <tbody id="users-tbody">
            <!-- Les lignes seront ajoutées dynamiquement par JavaScript -->
            <tr>
                <td colspan="6" style="text-align: center; padding: var(--spacing-xl); color: var(--text-muted);">
                    <i class="fas fa-spinner fa-spin" style="font-size: 32px; margin-bottom: var(--spacing-md);"></i>
                    <p>Chargement des utilisateurs...</p>
                </td>
            </tr>
        </tbody>
    </table>

    <!-- Pagination -->
    <div class="pagination">
        <div class="pagination-info" id="pagination-info">
            Chargement...
        </div>
        <div class="pagination-controls">
            <button class="pagination-btn" id="pagination-prev" disabled>
                <i class="fas fa-chevron-left"></i>
                Précédent
            </button>
            <button class="pagination-btn" id="pagination-next" disabled>
                Suivant
                <i class="fas fa-chevron-right"></i>
            </button>
        </div>
    </div>
</div>

<!-- Modal Utilisateur -->
<div class="modal" id="user-modal">
    <div class="modal-content">
        <!-- En-tête -->
        <div class="modal-header">
            <h2 class="modal-title">
                <i class="fas fa-user"></i>
                <span id="modal-title-text">Nouvel utilisateur</span>
            </h2>
            <button class="modal-close" id="modal-close">
                <i class="fas fa-times"></i>
            </button>
        </div>

        <!-- Corps -->
        <div class="modal-body">
            <form id="user-form">
                <input type="hidden" name="id" id="user-id">

                <!-- Informations de connexion -->
                <div class="form-row">
                    <div class="form-group">
                        <label class="form-label">
                            Nom d'utilisateur <span class="required">*</span>
                        </label>
                        <input 
                            type="text" 
                            class="form-input" 
                            name="username" 
                            id="user-username"
                            placeholder="johndoe"
                            required
                            autocomplete="off"
                        >
                        <div class="form-help">
                            3-20 caractères, lettres, chiffres, - et _
                        </div>
                    </div>

                    <div class="form-group">
                        <label class="form-label">
                            Email <span class="required">*</span>
                        </label>
                        <input 
                            type="email" 
                            class="form-input" 
                            name="email" 
                            id="user-email"
                            placeholder="john@example.com"
                            required
                            autocomplete="off"
                        >
                    </div>
                </div>

                <!-- Informations personnelles -->
                <div class="form-row">
                    <div class="form-group">
                        <label class="form-label">Prénom</label>
                        <input 
                            type="text" 
                            class="form-input" 
                            name="firstName" 
                            id="user-firstName"
                            placeholder="John"
                            autocomplete="off"
                        >
                    </div>

                    <div class="form-group">
                        <label class="form-label">Nom</label>
                        <input 
                            type="text" 
                            class="form-input" 
                            name="lastName" 
                            id="user-lastName"
                            placeholder="Doe"
                            autocomplete="off"
                        >
                    </div>
                </div>

                <!-- Rôle -->
                <div class="form-row single">
                    <div class="form-group">
                        <label class="form-label">
                            Rôle <span class="required">*</span>
                        </label>
                        <select class="form-select" name="role" id="user-role" required>
                            <option value="user">Utilisateur</option>
                            <option value="moderator">Modérateur</option>
                            <option value="admin">Administrateur</option>
                            <option value="guest">Invité</option>
                        </select>
                        <div class="form-help">
                            Les administrateurs ont tous les droits
                        </div>
                    </div>
                </div>

                <!-- Statut actif/inactif -->
                <div class="switch-field">
                    <div class="switch-label">
                        <div class="switch-label-title">Compte actif</div>
                        <div class="switch-label-desc">
                            L'utilisateur peut se connecter et accéder à l'application
                        </div>
                    </div>
                    <label class="switch">
                        <input type="checkbox" name="status" id="user-status" checked>
                        <span class="switch-slider"></span>
                    </label>
                </div>
            </form>
        </div>

        <!-- Pied -->
        <div class="modal-footer">
            <button class="btn btn-outline" id="modal-cancel">
                <i class="fas fa-times"></i>
                Annuler
            </button>
            <button class="btn btn-primary" form="user-form" type="submit">
                <i class="fas fa-check"></i>
                Enregistrer
            </button>
        </div>
    </div>
</div>
