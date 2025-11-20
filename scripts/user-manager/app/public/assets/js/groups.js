/* ============================================
   Bolt.DIY User Manager - Groups JS
   Version: 1.0
   Date: 19 novembre 2025
   ============================================ */

// État global des groupes
let groupsState = {
    groups: [],
    users: [],
    selectedGroup: null,
    searchTerm: '',
    filterMembers: ''
};

/* ============================================
   INITIALISATION
   ============================================ */

document.addEventListener('DOMContentLoaded', function() {
    console.log('🎯 Groups.js loaded');
    
    loadUsers();
    loadGroups();
    setupEventListeners();
});

/* ============================================
   CHARGEMENT DES DONNÉES
   ============================================ */

async function loadUsers() {
    try {
        const response = await fetch('/user-manager/api/users.php');
        if (!response.ok) throw new Error('Failed to load users');
        
        const data = await response.json();
        groupsState.users = data.users || [];
        console.log('✅ Users loaded:', groupsState.users.length);
    } catch (error) {
        console.error('❌ Error loading users:', error);
        showToast('Erreur lors du chargement des utilisateurs', 'error');
    }
}

async function loadGroups() {
    try {
        showLoader();
        
        const response = await fetch('/user-manager/api/groups.php');
        if (!response.ok) throw new Error('Failed to load groups');
        
        const data = await response.json();
        
        if (data.success) {
            groupsState.groups = data.groups || [];
            renderGroups();
            console.log('✅ Groups loaded:', groupsState.groups.length);
        } else {
            throw new Error(data.message || 'Failed to load groups');
        }
    } catch (error) {
        console.error('❌ Error loading groups:', error);
        showToast('Erreur lors du chargement des groupes', 'error');
        renderEmptyState();
    } finally {
        hideLoader();
    }
}

/* ============================================
   RENDU DE L'INTERFACE
   ============================================ */

function renderGroups() {
    const container = document.getElementById('groupsGrid');
    if (!container) return;
    
    if (groupsState.groups.length === 0) {
        renderEmptyState();
        return;
    }
    
    const filteredGroups = filterGroups();
    
    container.innerHTML = filteredGroups.map(group => `
        <div class="group-card" data-group-id="${group.id}">
            <div class="group-icon">
                <i class="fas fa-${getGroupIcon(group.name)}"></i>
            </div>
            <div class="group-header">
                <div>
                    <h3 class="group-name">${escapeHtml(group.name)}</h3>
                    <p class="group-description">${escapeHtml(group.description)}</p>
                </div>
            </div>
            
            <div class="group-stats">
                <div class="group-stat">
                    <div class="group-stat-label">Membres</div>
                    <div class="group-stat-value">${group.members.length}</div>
                </div>
                <div class="group-stat">
                    <div class="group-stat-label">Permissions</div>
                    <div class="group-stat-value">${group.permissions.length}</div>
                </div>
            </div>
            
            ${group.members.length > 0 ? `
                <div class="group-members-preview">
                    <div class="members-avatars">
                        ${group.members.slice(0, 3).map(userId => {
                            const user = groupsState.users.find(u => u.id === userId);
                            if (!user) return '';
                            const initials = getInitials(user.name);
                            return `<div class="member-avatar" title="${escapeHtml(user.name)}">${initials}</div>`;
                        }).join('')}
                    </div>
                    <span class="members-count">
                        ${group.members.length > 3 ? `+${group.members.length - 3} autres` : ''}
                    </span>
                </div>
            ` : ''}
            
            <div class="group-actions">
                <button class="btn btn-sm btn-primary" onclick="viewGroupMembers(${group.id})">
                    <i class="fas fa-users"></i> Membres
                </button>
                <button class="btn btn-sm btn-secondary" onclick="editGroup(${group.id})">
                    <i class="fas fa-edit"></i> Modifier
                </button>
                <button class="btn btn-sm btn-danger" onclick="deleteGroup(${group.id})">
                    <i class="fas fa-trash"></i>
                </button>
            </div>
        </div>
    `).join('');
}

function renderEmptyState() {
    const container = document.getElementById('groupsGrid');
    if (!container) return;
    
    container.innerHTML = `
        <div class="empty-state" style="grid-column: 1/-1;">
            <div class="empty-state-icon">
                <i class="fas fa-users-slash"></i>
            </div>
            <h3 class="empty-state-title">Aucun groupe trouvé</h3>
            <p class="empty-state-description">Commencez par créer votre premier groupe d'utilisateurs</p>
            <button class="btn btn-primary" onclick="openGroupModal()">
                <i class="fas fa-plus"></i> Créer un groupe
            </button>
        </div>
    `;
}

/* ============================================
   FILTRAGE
   ============================================ */

function filterGroups() {
    let filtered = [...groupsState.groups];
    
    // Filtre par recherche
    if (groupsState.searchTerm) {
        const term = groupsState.searchTerm.toLowerCase();
        filtered = filtered.filter(group => 
            group.name.toLowerCase().includes(term) ||
            group.description.toLowerCase().includes(term)
        );
    }
    
    return filtered;
}

function handleSearch(input) {
    groupsState.searchTerm = input.value;
    renderGroups();
}

/* ============================================
   MODAL GROUPE
   ============================================ */

function openGroupModal(groupId = null) {
    groupsState.selectedGroup = groupId ? groupsState.groups.find(g => g.id === groupId) : null;
    
    const modal = document.getElementById('groupModal');
    const form = document.getElementById('groupForm');
    const title = document.getElementById('groupModalTitle');
    
    if (!modal || !form) return;
    
    // Reset form
    form.reset();
    
    if (groupsState.selectedGroup) {
        title.textContent = 'Modifier le groupe';
        document.getElementById('groupName').value = groupsState.selectedGroup.name;
        document.getElementById('groupDescription').value = groupsState.selectedGroup.description;
        
        // Cocher les permissions
        groupsState.selectedGroup.permissions.forEach(permId => {
            const checkbox = document.querySelector(`input[name="permissions"][value="${permId}"]`);
            if (checkbox) checkbox.checked = true;
        });
    } else {
        title.textContent = 'Créer un groupe';
    }
    
    renderMembersList();
    modal.classList.add('active');
}

function closeGroupModal() {
    const modal = document.getElementById('groupModal');
    if (modal) {
        modal.classList.remove('active');
        groupsState.selectedGroup = null;
    }
}

function renderMembersList() {
    const container = document.getElementById('membersList');
    if (!container) return;
    
    const selectedMembers = groupsState.selectedGroup ? groupsState.selectedGroup.members : [];
    const searchTerm = groupsState.filterMembers.toLowerCase();
    
    const filteredUsers = groupsState.users.filter(user => {
        if (searchTerm) {
            return user.name.toLowerCase().includes(searchTerm) || 
                   user.email.toLowerCase().includes(searchTerm);
        }
        return true;
    });
    
    container.innerHTML = filteredUsers.map(user => {
        const isSelected = selectedMembers.includes(user.id);
        const initials = getInitials(user.name);
        
        return `
            <div class="member-item ${isSelected ? 'selected' : ''}" data-user-id="${user.id}">
                <div class="member-item-avatar">${initials}</div>
                <div class="member-item-info">
                    <div class="member-item-name">${escapeHtml(user.name)}</div>
                    <div class="member-item-email">${escapeHtml(user.email)}</div>
                </div>
                <input 
                    type="checkbox" 
                    class="member-item-checkbox" 
                    name="members" 
                    value="${user.id}"
                    ${isSelected ? 'checked' : ''}
                    onchange="toggleMemberSelection(${user.id})"
                >
            </div>
        `;
    }).join('');
}

function toggleMemberSelection(userId) {
    const checkbox = document.querySelector(`input[name="members"][value="${userId}"]`);
    const item = checkbox.closest('.member-item');
    
    if (checkbox.checked) {
        item.classList.add('selected');
    } else {
        item.classList.remove('selected');
    }
}

function handleMembersSearch(input) {
    groupsState.filterMembers = input.value;
    renderMembersList();
}

/* ============================================
   CRUD OPERATIONS
   ============================================ */

async function saveGroup(event) {
    event.preventDefault();
    
    const form = event.target;
    const formData = new FormData(form);
    
    // Récupérer les données
    const name = formData.get('name');
    const description = formData.get('description');
    const permissions = formData.getAll('permissions').map(Number);
    const members = formData.getAll('members').map(Number);
    
    // Validation
    if (!name || name.trim().length < 2) {
        showToast('Le nom du groupe doit contenir au moins 2 caractères', 'error');
        return;
    }
    
    const groupData = {
        name: name.trim(),
        description: description.trim(),
        permissions: permissions,
        members: members
    };
    
    try {
        showLoader();
        
        const url = '/user-manager/api/groups.php';
        const method = groupsState.selectedGroup ? 'PUT' : 'POST';
        
        const response = await fetch(url + (groupsState.selectedGroup ? `?id=${groupsState.selectedGroup.id}` : ''), {
            method: method,
            headers: {
                'Content-Type': 'application/json'
            },
            body: JSON.stringify(groupData)
        });
        
        if (!response.ok) throw new Error('Request failed');
        
        const data = await response.json();
        
        if (data.success) {
            showToast(data.message || 'Groupe enregistré avec succès', 'success');
            closeGroupModal();
            loadGroups();
        } else {
            throw new Error(data.message || 'Failed to save group');
        }
    } catch (error) {
        console.error('❌ Error saving group:', error);
        showToast('Erreur lors de l\'enregistrement du groupe', 'error');
    } finally {
        hideLoader();
    }
}

function editGroup(groupId) {
    openGroupModal(groupId);
}

async function deleteGroup(groupId) {
    const group = groupsState.groups.find(g => g.id === groupId);
    if (!group) return;
    
    if (!confirm(`Êtes-vous sûr de vouloir supprimer le groupe "${group.name}" ?`)) {
        return;
    }
    
    try {
        showLoader();
        
        const response = await fetch(`/user-manager/api/groups.php?id=${groupId}`, {
            method: 'DELETE'
        });
        
        if (!response.ok) throw new Error('Request failed');
        
        const data = await response.json();
        
        if (data.success) {
            showToast(data.message || 'Groupe supprimé avec succès', 'success');
            loadGroups();
        } else {
            throw new Error(data.message || 'Failed to delete group');
        }
    } catch (error) {
        console.error('❌ Error deleting group:', error);
        showToast('Erreur lors de la suppression du groupe', 'error');
    } finally {
        hideLoader();
    }
}

function viewGroupMembers(groupId) {
    const group = groupsState.groups.find(g => g.id === groupId);
    if (!group) return;
    
    openGroupModal(groupId);
}

/* ============================================
   UTILITAIRES
   ============================================ */

function getGroupIcon(name) {
    const icons = {
        'admin': 'user-shield',
        'manager': 'user-tie',
        'developer': 'code',
        'designer': 'palette',
        'support': 'headset',
        'sales': 'chart-line'
    };
    
    const key = name.toLowerCase();
    for (const [keyword, icon] of Object.entries(icons)) {
        if (key.includes(keyword)) return icon;
    }
    
    return 'users';
}

function getInitials(name) {
    if (!name) return '??';
    const parts = name.trim().split(' ');
    if (parts.length >= 2) {
        return (parts[0][0] + parts[1][0]).toUpperCase();
    }
    return name.substring(0, 2).toUpperCase();
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
    // Close modal on outside click
    document.getElementById('groupModal')?.addEventListener('click', function(e) {
        if (e.target === this) {
            closeGroupModal();
        }
    });
    
    // Form submission
    document.getElementById('groupForm')?.addEventListener('submit', saveGroup);
    
    // Close button
    document.getElementById('closeGroupModal')?.addEventListener('click', closeGroupModal);
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
    // Utilise le système de toast global si disponible
    if (window.showToast) {
        window.showToast(message, type);
    } else {
        alert(message);
    }
}
