<!DOCTYPE html>
<html lang="fr">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Permissions - Bolt.DIY User Manager</title>
    
    <!-- CSS -->
    <link rel="stylesheet" href="/user-manager/assets/css/style.css">
    <link rel="stylesheet" href="/user-manager/assets/css/permissions.css">
    
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
            <a href="/user-manager/permissions" class="nav-link active">
                <i class="fas fa-key"></i>
                <span>Permissions</span>
            </a>
            <a href="/user-manager/audit" class="nav-link">
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
        <!-- Permissions Container -->
        <div class="permissions-container">
            <div class="permissions-header">
                <div>
                    <h1 class="permissions-title">Permissions</h1>
                    <p class="permissions-subtitle">Gérez les permissions et contrôlez l'accès aux fonctionnalités</p>
                </div>
                <div class="permissions-actions">
                    <button class="btn btn-secondary view-btn active" onclick="switchView('tree')">
                        <i class="fas fa-list"></i> Vue Arbre
                    </button>
                    <button class="btn btn-secondary view-btn" onclick="switchView('matrix')">
                        <i class="fas fa-table"></i> Vue Matrice
                    </button>
                </div>
            </div>

            <!-- Filters -->
            <div class="permissions-filters">
                <div class="filter-search">
                    <i class="fas fa-search"></i>
                    <input 
                        type="text" 
                        class="form-control" 
                        placeholder="Rechercher une permission..."
                        oninput="handleSearch(this)"
                    >
                </div>
                
                <div class="filter-group-select">
                    <select class="form-control" id="groupFilter" onchange="handleGroupFilter(this)">
                        <option value="">Tous les groupes</option>
                    </select>
                </div>
            </div>

            <!-- Quick Actions -->
            <div class="quick-actions">
                <button class="quick-action-btn" onclick="expandAll()">
                    <i class="fas fa-expand-alt"></i> Tout développer
                </button>
                <button class="quick-action-btn" onclick="collapseAll()">
                    <i class="fas fa-compress-alt"></i> Tout réduire
                </button>
            </div>

            <!-- Tree View -->
            <div id="treeView">
                <div class="permissions-tree" id="permissionsTree">
                    <!-- Les catégories seront chargées ici par JavaScript -->
                </div>
            </div>

            <!-- Matrix View -->
            <div id="matrixView" style="display: none;">
                <div class="permissions-matrix" id="permissionsMatrix">
                    <!-- La matrice sera chargée ici par JavaScript -->
                </div>
            </div>

            <!-- Legend -->
            <div class="permissions-legend">
                <div class="legend-item">
                    <div class="legend-icon read"></div>
                    <span>Lecture</span>
                </div>
                <div class="legend-item">
                    <div class="legend-icon write"></div>
                    <span>Écriture</span>
                </div>
                <div class="legend-item">
                    <div class="legend-icon delete"></div>
                    <span>Suppression</span>
                </div>
                <div class="legend-item">
                    <div class="legend-icon admin"></div>
                    <span>Administration</span>
                </div>
            </div>
        </div>
    </main>

    <!-- JavaScript -->
    <script src="/user-manager/assets/js/app.js"></script>
    <script src="/user-manager/assets/js/permissions.js"></script>
</body>
</html>
