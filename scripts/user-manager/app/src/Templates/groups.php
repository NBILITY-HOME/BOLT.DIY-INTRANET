<!DOCTYPE html>
<html lang="fr">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Groupes - Bolt.DIY User Manager</title>
    
    <!-- CSS -->
    <link rel="stylesheet" href="/user-manager/assets/css/style.css">
    <link rel="stylesheet" href="/user-manager/assets/css/groups.css">
    
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
            <a href="/user-manager/groups" class="nav-link active">
                <i class="fas fa-user-friends"></i>
                <span>Groupes</span>
            </a>
            <a href="/user-manager/permissions" class="nav-link">
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
        <!-- Page Header -->
        <div class="page-header">
            <h1 class="page-title">Groupes</h1>
            <div class="page-actions">
                <button class="btn btn-primary" onclick="openGroupModal()">
                    <i class="fas fa-plus"></i> Créer un groupe
                </button>
            </div>
        </div>

        <!-- Filters Bar -->
        <div class="filters-bar">
            <div class="filter-group" style="flex: 2;">
                <label class="filter-label">Rechercher</label>
                <input 
                    type="text" 
                    class="form-control" 
                    placeholder="Nom du groupe, description..."
                    oninput="handleSearch(this)"
                >
            </div>
            
            <div class="filter-actions">
                <button class="btn btn-secondary" onclick="loadGroups()">
                    <i class="fas fa-sync-alt"></i> Actualiser
                </button>
            </div>
        </div>

        <!-- Groups Grid -->
        <div class="groups-grid" id="groupsGrid">
            <!-- Les groupes seront chargés ici par JavaScript -->
        </div>
    </main>

    <!-- Modal Groupe -->
    <div class="modal" id="groupModal">
        <div class="modal-content modal-lg">
            <div class="modal-header">
                <h2 class="modal-title" id="groupModalTitle">Créer un groupe</h2>
                <button class="modal-close" id="closeGroupModal">
                    <i class="fas fa-times"></i>
                </button>
            </div>
            
            <form id="groupForm" onsubmit="saveGroup(event)">
                <div class="modal-body">
                    <!-- Informations de base -->
                    <div class="form-section">
                        <h3 class="section-title">Informations générales</h3>
                        
                        <div class="form-row">
                            <div class="form-group">
                                <label class="form-label">Nom du groupe <span class="required">*</span></label>
                                <input 
                                    type="text" 
                                    class="form-control" 
                                    id="groupName"
                                    name="name"
                                    placeholder="Ex: Développeurs"
                                    required
                                    minlength="2"
                                    maxlength="100"
                                >
                            </div>
                        </div>
                        
                        <div class="form-row">
                            <div class="form-group">
                                <label class="form-label">Description</label>
                                <textarea 
                                    class="form-control" 
                                    id="groupDescription"
                                    name="description"
                                    placeholder="Description du groupe et de son rôle"
                                    rows="3"
                                    maxlength="500"
                                ></textarea>
                            </div>
                        </div>
                    </div>

                    <!-- Permissions -->
                    <div class="form-section">
                        <div class="permissions-section">
                            <h3 class="permissions-title">
                                <i class="fas fa-key"></i> Permissions
                            </h3>
                            
                            <div class="permissions-grid">
                                <div class="permission-item">
                                    <input 
                                        type="checkbox" 
                                        class="permission-checkbox" 
                                        name="permissions" 
                                        value="1"
                                        id="perm-1"
                                    >
                                    <label for="perm-1" class="permission-label">
                                        <div>Voir les utilisateurs</div>
                                        <div class="permission-description">Accès en lecture à la liste des utilisateurs</div>
                                    </label>
                                </div>
                                
                                <div class="permission-item">
                                    <input 
                                        type="checkbox" 
                                        class="permission-checkbox" 
                                        name="permissions" 
                                        value="2"
                                        id="perm-2"
                                    >
                                    <label for="perm-2" class="permission-label">
                                        <div>Créer des utilisateurs</div>
                                        <div class="permission-description">Créer de nouveaux utilisateurs</div>
                                    </label>
                                </div>
                                
                                <div class="permission-item">
                                    <input 
                                        type="checkbox" 
                                        class="permission-checkbox" 
                                        name="permissions" 
                                        value="3"
                                        id="perm-3"
                                    >
                                    <label for="perm-3" class="permission-label">
                                        <div>Modifier les utilisateurs</div>
                                        <div class="permission-description">Modifier les informations des utilisateurs</div>
                                    </label>
                                </div>
                                
                                <div class="permission-item">
                                    <input 
                                        type="checkbox" 
                                        class="permission-checkbox" 
                                        name="permissions" 
                                        value="4"
                                        id="perm-4"
                                    >
                                    <label for="perm-4" class="permission-label">
                                        <div>Supprimer des utilisateurs</div>
                                        <div class="permission-description">Supprimer des utilisateurs du système</div>
                                    </label>
                                </div>
                                
                                <div class="permission-item">
                                    <input 
                                        type="checkbox" 
                                        class="permission-checkbox" 
                                        name="permissions" 
                                        value="5"
                                        id="perm-5"
                                    >
                                    <label for="perm-5" class="permission-label">
                                        <div>Voir les groupes</div>
                                        <div class="permission-description">Accès en lecture aux groupes</div>
                                    </label>
                                </div>
                                
                                <div class="permission-item">
                                    <input 
                                        type="checkbox" 
                                        class="permission-checkbox" 
                                        name="permissions" 
                                        value="6"
                                        id="perm-6"
                                    >
                                    <label for="perm-6" class="permission-label">
                                        <div>Gérer les groupes</div>
                                        <div class="permission-description">Créer, modifier et supprimer des groupes</div>
                                    </label>
                                </div>
                                
                                <div class="permission-item">
                                    <input 
                                        type="checkbox" 
                                        class="permission-checkbox" 
                                        name="permissions" 
                                        value="7"
                                        id="perm-7"
                                    >
                                    <label for="perm-7" class="permission-label">
                                        <div>Voir les audits</div>
                                        <div class="permission-description">Accès aux logs d'audit</div>
                                    </label>
                                </div>
                                
                                <div class="permission-item">
                                    <input 
                                        type="checkbox" 
                                        class="permission-checkbox" 
                                        name="permissions" 
                                        value="8"
                                        id="perm-8"
                                    >
                                    <label for="perm-8" class="permission-label">
                                        <div>Gérer les paramètres</div>
                                        <div class="permission-description">Modifier les paramètres système</div>
                                    </label>
                                </div>
                            </div>
                        </div>
                    </div>

                    <!-- Membres -->
                    <div class="form-section">
                        <div class="members-selector">
                            <h3 class="section-title">
                                <i class="fas fa-users"></i> Membres du groupe
                            </h3>
                            
                            <div class="members-search">
                                <i class="fas fa-search"></i>
                                <input 
                                    type="text" 
                                    class="form-control" 
                                    placeholder="Rechercher un utilisateur..."
                                    oninput="handleMembersSearch(this)"
                                >
                            </div>
                            
                            <div class="members-list" id="membersList">
                                <!-- La liste des membres sera chargée ici -->
                            </div>
                        </div>
                    </div>
                </div>
                
                <div class="modal-footer">
                    <button type="button" class="btn btn-secondary" onclick="closeGroupModal()">
                        Annuler
                    </button>
                    <button type="submit" class="btn btn-primary">
                        <i class="fas fa-save"></i> Enregistrer
                    </button>
                </div>
            </form>
        </div>
    </div>

    <!-- JavaScript -->
    <script src="/user-manager/assets/js/app.js"></script>
    <script src="/user-manager/assets/js/groups.js"></script>
</body>
</html>
