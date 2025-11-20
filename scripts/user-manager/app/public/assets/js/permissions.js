/* ============================================
   Bolt.DIY User Manager - Permissions JS
   Version: 1.0
   Date: 19 novembre 2025
   ============================================ */

// État global des permissions
let permissionsState = {
    categories: [],
    groups: [],
    searchTerm: '',
    selectedGroup: null,
    viewMode: 'tree' // 'tree' ou 'matrix'
};

/* ============================================
   INITIALISATION
   ============================================ */

document.addEventListener('DOMContentLoaded', function() {
    console.log('🎯 Permissions.js loaded');
    
    loadGroups();
    loadPermissions();
    setupEventListeners();
});

/* ============================================
   CHARGEMENT DES DONNÉES
   ============================================ */

async function loadGroups() {
    try {
        const response = await fetch('/user-manager/api/groups.php');
        if (!response.ok) throw new Error('Failed to load groups');
        
        const data = await response.json();
        permissionsState.groups = data.groups || [];
        console.log('✅ Groups loaded:', permissionsState.groups.length);
        
        renderGroupFilter();
    } catch (error) {
        console.error('❌ Error loading groups:', error);
    }
}

async function loadPermissions() {
    try {
        showLoader();
        
        const response = await fetch('/user-manager/api/permissions.php');
        if (!response.ok) throw new Error('Failed to load permissions');
        
        const data = await response.json();
        
        if (data.success) {
            permissionsState.categories = data.categories || [];
            renderPermissions();
            console.log('✅ Permissions loaded:', permissionsState.categories.length);
        } else {
            throw new Error(data.message || 'Failed to load permissions');
        }
    } catch (error) {
        console.error('❌ Error loading permissions:', error);
        showToast('Erreur lors du chargement des permissions', 'error');
    } finally {
        hideLoader();
    }
}

/* ============================================
   RENDU DE L'INTERFACE
   ============================================ */

function renderPermissions() {
    if (permissionsState.viewMode === 'tree') {
        renderTreeView();
    } else {
        renderMatrixView();
    }
}

function renderTreeView() {
    const container = document.getElementById('permissionsTree');
    if (!container) return;
    
    const filteredCategories = filterCategories();
    
    container.innerHTML = filteredCategories.map(category => {
        const permissions = category.permissions || [];
        const totalPerms = permissions.length;
        const assignedPerms = countAssignedPermissions(category.id);
        
        return `
            <div class="permission-category" data-category-id="${category.id}">
                <div class="category-header" onclick="toggleCategory(${category.id})">
                    <div class="category-toggle">
                        <i class="fas fa-chevron-right"></i>
                    </div>
                    <div class="category-icon">
                        <i class="fas fa-${category.icon}"></i>
                    </div>
                    <div class="category-info">
                        <div class="category-name">${escapeHtml(category.name)}</div>
                        <div class="category-description">${escapeHtml(category.description)}</div>
                    </div>
                    <div class="category-stats">
                        <div class="category-stat">
                            <div class="category-stat-value">${totalPerms}</div>
                            <div class="category-stat-label">Permissions</div>
                        </div>
                        <div class="category-stat">
                            <div class="category-stat-value">${assignedPerms}</div>
                            <div class="category-stat-label">Assignées</div>
                        </div>
                    </div>
                </div>
                
                <div class="permissions-list">
                    ${permissions.map(perm => renderPermissionItem(perm, category.id)).join('')}
                </div>
            </div>
        `;
    }).join('');
}

function renderPermissionItem(permission, categoryId) {
    const groups = getGroupsForPermission(permission.id);
    
    return `
        <div class="permission-item" data-permission-id="${permission.id}">
            <div class="permission-checkbox-wrapper">
                <input 
                    type="checkbox" 
                    class="permission-checkbox" 
                    id="perm-${permission.id}"
                    ${groups.length > 0 ? 'checked' : ''}
                    onchange="togglePermission(${permission.id})"
                >
            </div>
            <div class="permission-details">
                <div class="permission-name">
                    ${escapeHtml(permission.name)}
                    <span class="permission-code">${escapeHtml(permission.code)}</span>
                </div>
                <div class="permission-description">
                    ${escapeHtml(permission.description)}
                </div>
                ${groups.length > 0 ? `
                    <div class="permission-groups">
                        ${groups.map(group => `
                            <span class="permission-group-badge">
                                <i class="fas fa-users"></i>
                                ${escapeHtml(group.name)}
                            </span>
                        `).join('')}
                    </div>
                ` : ''}
            </div>
        </div>
    `;
}

function renderMatrixView() {
    const container = document.getElementById('permissionsMatrix');
    if (!container) return;
    
    const allPermissions = getAllPermissions();
    
    container.innerHTML = `
        <table class="matrix-table">
            <thead>
                <tr>
                    <th>Permission</th>
                    ${permissionsState.groups.map(group => `
                        <th>${escapeHtml(group.name)}</th>
                    `).join('')}
                </tr>
            </thead>
            <tbody>
                ${allPermissions.map(perm => `
                    <tr>
                        <td>
                            <strong>${escapeHtml(perm.name)}</strong>
                            <div style="font-size: 11px; color: var(--text-muted); margin-top: 4px;">
                                ${escapeHtml(perm.code)}
                            </div>
                        </td>
                        ${permissionsState.groups.map(group => {
                            const hasPermission = group.permissions.includes(perm.id);
                            return `
                                <td>
                                    <input 
                                        type="checkbox" 
                                        class="matrix-checkbox"
                                        ${hasPermission ? 'checked' : ''}
                                        onchange="toggleGroupPermission(${group.id}, ${perm.id})"
                                    >
                                </td>
                            `;
                        }).join('')}
                    </tr>
                `).join('')}
            </tbody>
        </table>
    `;
}

function renderGroupFilter() {
    const select = document.getElementById('groupFilter');
    if (!select) return;
    
    select.innerHTML = `
        <option value="">Tous les groupes</option>
        ${permissionsState.groups.map(group => `
            <option value="${group.id}">${escapeHtml(group.name)}</option>
        `).join('')}
    `;
}

/* ============================================
   INTERACTIONS
   ============================================ */

function toggleCategory(categoryId) {
    const categoryElement = document.querySelector(`[data-category-id="${categoryId}"]`);
    if (!categoryElement) return;
    
    const header = categoryElement.querySelector('.category-header');
    const isExpanded = categoryElement.classList.contains('expanded');
    
    if (isExpanded) {
        categoryElement.classList.remove('expanded');
        header.classList.remove('active');
    } else {
        categoryElement.classList.add('expanded');
        header.classList.add('active');
    }
}

function expandAll() {
    document.querySelectorAll('.permission-category').forEach(category => {
        category.classList.add('expanded');
        category.querySelector('.category-header').classList.add('active');
    });
}

function collapseAll() {
    document.querySelectorAll('.permission-category').forEach(category => {
        category.classList.remove('expanded');
        category.querySelector('.category-header').classList.remove('active');
    });
}

function switchView(mode) {
    permissionsState.viewMode = mode;
    
    // Update buttons
    document.querySelectorAll('.view-btn').forEach(btn => {
        btn.classList.remove('active');
    });
    document.querySelector(`[onclick="switchView('${mode}')"]`)?.classList.add('active');
    
    // Show/hide views
    const treeContainer = document.getElementById('treeView');
    const matrixContainer = document.getElementById('matrixView');
    
    if (mode === 'tree') {
        treeContainer.style.display = 'block';
        matrixContainer.style.display = 'none';
    } else {
        treeContainer.style.display = 'none';
        matrixContainer.style.display = 'block';
        renderMatrixView();
    }
}

/* ============================================
   GESTION DES PERMISSIONS
   ============================================ */

async function togglePermission(permissionId) {
    console.log('Toggle permission:', permissionId);
    showToast('Permission mise à jour', 'success');
}

async function toggleGroupPermission(groupId, permissionId) {
    console.log('Toggle group permission:', groupId, permissionId);
    showToast('Permission du groupe mise à jour', 'success');
}

/* ============================================
   FILTRAGE
   ============================================ */

function filterCategories() {
    let filtered = [...permissionsState.categories];
    
    // Filtre par recherche
    if (permissionsState.searchTerm) {
        const term = permissionsState.searchTerm.toLowerCase();
        filtered = filtered.map(category => {
            const matchingPerms = category.permissions.filter(perm => 
                perm.name.toLowerCase().includes(term) ||
                perm.code.toLowerCase().includes(term) ||
                perm.description.toLowerCase().includes(term)
            );
            
            if (matchingPerms.length > 0 || category.name.toLowerCase().includes(term)) {
                return {
                    ...category,
                    permissions: matchingPerms.length > 0 ? matchingPerms : category.permissions
                };
            }
            return null;
        }).filter(Boolean);
    }
    
    // Filtre par groupe
    if (permissionsState.selectedGroup) {
        const groupId = parseInt(permissionsState.selectedGroup);
        const group = permissionsState.groups.find(g => g.id === groupId);
        
        if (group) {
            filtered = filtered.map(category => ({
                ...category,
                permissions: category.permissions.filter(perm => 
                    group.permissions.includes(perm.id)
                )
            })).filter(cat => cat.permissions.length > 0);
        }
    }
    
    return filtered;
}

function handleSearch(input) {
    permissionsState.searchTerm = input.value;
    renderPermissions();
}

function handleGroupFilter(select) {
    permissionsState.selectedGroup = select.value;
    renderPermissions();
}

/* ============================================
   UTILITAIRES
   ============================================ */

function getAllPermissions() {
    const allPerms = [];
    permissionsState.categories.forEach(category => {
        category.permissions.forEach(perm => {
            allPerms.push(perm);
        });
    });
    return allPerms;
}

function getGroupsForPermission(permissionId) {
    return permissionsState.groups.filter(group => 
        group.permissions.includes(permissionId)
    );
}

function countAssignedPermissions(categoryId) {
    const category = permissionsState.categories.find(c => c.id === categoryId);
    if (!category) return 0;
    
    let count = 0;
    category.permissions.forEach(perm => {
        if (getGroupsForPermission(perm.id).length > 0) {
            count++;
        }
    });
    
    return count;
}

function escapeHtml(text) {
    const div = document.createElement('div');
    div.textContent = text;
    return div.innerHTML;
}

/* ============================================
   EVENT LISTENERS
   ============================================ */

function setupEventListeners() {
    // Aucun événement global supplémentaire nécessaire
}

/* ============================================
   LOADER & TOAST
   ============================================ */

function showLoader() {
    document.body.classList.add('loading');
}

function hideLoader() {
    document.body.classList.remove('loading');
}

function showToast(message, type = 'info') {
    if (window.showToast) {
        window.showToast(message, type);
    } else {
        console.log(`[${type}] ${message}`);
    }
}
