<!DOCTYPE html>
<html lang="fr">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Audit - Bolt.DIY User Manager</title>
    
    <!-- CSS -->
    <link rel="stylesheet" href="/user-manager/assets/css/style.css">
    <link rel="stylesheet" href="/user-manager/assets/css/audit.css">
    
    <!-- Font Awesome -->
    <link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.4.0/css/all.min.css">
</head>
<body>
    <!-- Sidebar -->
    <aside class="sidebar">
        <div class="sidebar-header">
            <div class="logo">
                <i class="fas fa-shield-alt"></i>
                <span>User Manager</span>
            </div>
        </div>
        
        <nav class="sidebar-nav">
            <a href="/user-manager/" class="nav-link">
                <i class="fas fa-home"></i>
                <span>Dashboard</span>
            </a>
            <a href="/user-manager/users" class="nav-link">
                <i class="fas fa-users"></i>
                <span>Utilisateurs</span>
            </a>
            <a href="/user-manager/groups" class="nav-link">
                <i class="fas fa-user-friends"></i>
                <span>Groupes</span>
            </a>
            <a href="/user-manager/permissions" class="nav-link">
                <i class="fas fa-key"></i>
                <span>Permissions</span>
            </a>
            <a href="/user-manager/audit" class="nav-link active">
                <i class="fas fa-clipboard-list"></i>
                <span>Audit</span>
            </a>
            <a href="/user-manager/settings" class="nav-link">
                <i class="fas fa-cog"></i>
                <span>Paramètres</span>
            </a>
        </nav>
        
        <div class="sidebar-footer">
            <div class="user-info">
                <div class="user-avatar">
                    <i class="fas fa-user"></i>
                </div>
                <div class="user-details">
                    <div class="user-name">Admin User</div>
                    <div class="user-role">Administrateur</div>
                </div>
            </div>
        </div>
    </aside>

    <!-- Main Content -->
    <main class="main-content">
        <!-- Page Header -->
        <div class="page-header">
            <h1 class="page-title">Audit & Logs</h1>
            <div class="page-actions">
                <button class="btn btn-secondary" onclick="exportAudit('csv')">
                    <i class="fas fa-download"></i> Exporter CSV
                </button>
                <button class="btn btn-primary" onclick="loadAuditLogs()">
                    <i class="fas fa-sync-alt"></i> Actualiser
                </button>
            </div>
        </div>

        <!-- Statistics Cards -->
        <div class="audit-stats">
            <div class="audit-stat-card">
                <div class="stat-header">
                    <div class="stat-icon primary">
                        <i class="fas fa-clipboard-list"></i>
                    </div>
                    <div class="stat-trend up">
                        <i class="fas fa-arrow-up"></i>
                        12%
                    </div>
                </div>
                <div class="stat-label">Total d'événements</div>
                <div class="stat-value" id="totalEvents">0</div>
            </div>

            <div class="audit-stat-card">
                <div class="stat-header">
                    <div class="stat-icon success">
                        <i class="fas fa-calendar-day"></i>
                    </div>
                    <div class="stat-trend up">
                        <i class="fas fa-arrow-up"></i>
                        8%
                    </div>
                </div>
                <div class="stat-label">Événements aujourd'hui</div>
                <div class="stat-value" id="todayEvents">0</div>
            </div>

            <div class="audit-stat-card">
                <div class="stat-header">
                    <div class="stat-icon warning">
                        <i class="fas fa-users"></i>
                    </div>
                    <div class="stat-trend up">
                        <i class="fas fa-arrow-up"></i>
                        5%
                    </div>
                </div>
                <div class="stat-label">Utilisateurs actifs</div>
                <div class="stat-value" id="activeUsers">0</div>
            </div>

            <div class="audit-stat-card">
                <div class="stat-header">
                    <div class="stat-icon danger">
                        <i class="fas fa-exclamation-triangle"></i>
                    </div>
                    <div class="stat-trend down">
                        <i class="fas fa-arrow-down"></i>
                        3%
                    </div>
                </div>
                <div class="stat-label">Actions critiques</div>
                <div class="stat-value" id="criticalActions">0</div>
            </div>
        </div>

        <!-- Filters -->
        <div class="audit-filters">
            <form id="auditFiltersForm">
                <div class="filters-grid">
                    <div class="filter-group">
                        <label class="filter-label">Rechercher</label>
                        <input 
                            type="text" 
                            class="form-control" 
                            placeholder="Utilisateur, description, IP..."
                            oninput="handleSearch(this)"
                        >
                    </div>

                    <div class="filter-group">
                        <label class="filter-label">Action</label>
                        <select class="form-control" onchange="handleActionFilter(this)">
                            <option value="">Toutes les actions</option>
                            <option value="login">Connexion</option>
                            <option value="logout">Déconnexion</option>
                            <option value="create">Création</option>
                            <option value="update">Modification</option>
                            <option value="delete">Suppression</option>
                            <option value="view">Consultation</option>
                        </select>
                    </div>

                    <div class="filter-group">
                        <label class="filter-label">Statut</label>
                        <select class="form-control" onchange="handleStatusFilter(this)">
                            <option value="">Tous les statuts</option>
                            <option value="success">Succès</option>
                            <option value="error">Erreur</option>
                            <option value="warning">Avertissement</option>
                        </select>
                    </div>

                    <div class="filter-group">
                        <label class="filter-label">Date de début</label>
                        <input 
                            type="date" 
                            class="form-control" 
                            id="dateFrom"
                            onchange="handleDateFromFilter(this)"
                        >
                    </div>

                    <div class="filter-group">
                        <label class="filter-label">Date de fin</label>
                        <input 
                            type="date" 
                            class="form-control" 
                            id="dateTo"
                            onchange="handleDateToFilter(this)"
                        >
                    </div>
                </div>

                <div class="filters-actions">
                    <button type="button" class="btn btn-secondary" onclick="resetFilters()">
                        <i class="fas fa-times"></i> Réinitialiser
                    </button>
                </div>
            </form>
        </div>

        <!-- Audit Table -->
        <div class="audit-table-container">
            <div class="audit-table-header">
                <h2 class="table-title">Historique des événements</h2>
                <div class="table-actions">
                    <button class="btn btn-sm btn-secondary" onclick="exportAudit('csv')">
                        <i class="fas fa-file-csv"></i> CSV
                    </button>
                </div>
            </div>

            <div class="audit-table-wrapper">
                <table class="audit-table">
                    <thead>
                        <tr>
                            <th class="sortable" onclick="sortTable('timestamp')">
                                Date & Heure
                            </th>
                            <th class="sortable" onclick="sortTable('user_name')">
                                Utilisateur
                            </th>
                            <th class="sortable" onclick="sortTable('action_type')">
                                Action
                            </th>
                            <th>
                                Description
                            </th>
                            <th>
                                Adresse IP
                            </th>
                            <th class="sortable" onclick="sortTable('status')">
                                Statut
                            </th>
                        </tr>
                    </thead>
                    <tbody id="auditTableBody">
                        <!-- Les logs seront chargés ici par JavaScript -->
                    </tbody>
                </table>
            </div>

            <div class="audit-pagination">
                <div class="pagination-info" id="paginationInfo">
                    Chargement...
                </div>
                <div class="pagination-controls" id="paginationControls">
                    <!-- Les contrôles de pagination seront chargés ici -->
                </div>
            </div>
        </div>
    </main>

    <!-- Modal Log Detail -->
    <div class="modal" id="logDetailModal">
        <div class="modal-content modal-lg">
            <div class="modal-header">
                <h2 class="modal-title">Détails de l'événement</h2>
                <button class="modal-close" onclick="closeLogDetailModal()">
                    <i class="fas fa-times"></i>
                </button>
            </div>
            
            <div class="modal-body">
                <div class="log-detail-section">
                    <h3 class="log-detail-title">Informations générales</h3>
                    <div class="log-detail-content">
                        <div class="log-detail-row">
                            <span class="log-detail-label">Date et heure</span>
                            <span class="log-detail-value" id="logDetailTimestamp">-</span>
                        </div>
                        <div class="log-detail-row">
                            <span class="log-detail-label">Utilisateur</span>
                            <span class="log-detail-value" id="logDetailUser">-</span>
                        </div>
                        <div class="log-detail-row">
                            <span class="log-detail-label">Rôle</span>
                            <span class="log-detail-value" id="logDetailRole">-</span>
                        </div>
                        <div class="log-detail-row">
                            <span class="log-detail-label">Action</span>
                            <span class="log-detail-value" id="logDetailAction">-</span>
                        </div>
                        <div class="log-detail-row">
                            <span class="log-detail-label">Description</span>
                            <span class="log-detail-value" id="logDetailDescription">-</span>
                        </div>
                        <div class="log-detail-row">
                            <span class="log-detail-label">Adresse IP</span>
                            <span class="log-detail-value" id="logDetailIP">-</span>
                        </div>
                        <div class="log-detail-row">
                            <span class="log-detail-label">Statut</span>
                            <span class="log-detail-value" id="logDetailStatus">-</span>
                        </div>
                    </div>
                </div>

                <div class="log-detail-section" style="display: none;">
                    <h3 class="log-detail-title">Modifications effectuées</h3>
                    <div class="log-changes" id="logDetailChanges">
                        <!-- Les changements seront affichés ici -->
                    </div>
                </div>
            </div>
            
            <div class="modal-footer">
                <button type="button" class="btn btn-secondary" onclick="closeLogDetailModal()">
                    Fermer
                </button>
            </div>
        </div>
    </div>

    <!-- JavaScript -->
    <script src="/user-manager/assets/js/app.js"></script>
    <script src="/user-manager/assets/js/audit.js"></script>
</body>
</html>
