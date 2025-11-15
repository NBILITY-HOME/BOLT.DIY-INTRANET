/**
 * BOLT.DIY USER MANAGER v2.0 - GROUPS MODULE
 * © Copyright Nbility 2025
 */

let currentGroupId = null;
let currentTab = 'info';

// Initialisation
document.addEventListener('DOMContentLoaded', () => {
    loadGroups();
    initEventListeners();
});

// Event listeners
function initEventListeners() {
    // Recherche
    document.getElementById('searchInput')?.addEventListener('input', debounce(loadGroups, 500));

    // Actions
    document.getElementById('btnRefresh')?.addEventListener('click', loadGroups);
    document.getElementById('btnCreateGroup')?.addEventListener('click', () => openCreateModal());

    // Form submit
    document.getElementById('btnSubmitGroup')?.addEventListener('click', submitGroup);

    // Tabs
    document.querySelectorAll('.tab-button').forEach(btn => {
        btn.addEventListener('click', (e) => {
            const tab = e.currentTarget.dataset.tab;
            switchTab(tab);
        });
    });

    // Modal close
    document.querySelectorAll('[data-dismiss="modal"]').forEach(btn => {
        btn.addEventListener('click', (e) => {
            const modal = e.target.closest('.modal');
            if (modal) closeModal(modal.id);
        });
    });

    // Auto-generate slug
    document.getElementById('formName')?.addEventListener('input', (e) => {
        const slug = generateSlug(e.target.value);
        document.getElementById('formSlug').value = slug;
    });

    // Members actions
    document.getElementById('btnAddMembers')?.addEventListener('click', openAddMembersModal);
    document.getElementById('btnConfirmAddMembers')?.addEventListener('click', addMembers);

    // Permissions actions
    document.getElementById('btnManagePermissions')?.addEventListener('click', openManagePermissionsModal);
    document.getElementById('btnSavePermissions')?.addEventListener('click', savePermissions);
}

// Charger les groupes
async function loadGroups() {
    try {
        const search = document.getElementById('searchInput')?.value || '';
        const response = await API.get('/groups', { search });
        renderGroupsGrid(response.data);
        updateStats(response.stats || {});
    } catch (error) {
        handleApiError(error);
        document.getElementById('groupsGrid').innerHTML = '<div class="card"><div class="card-body text-center text-danger">Erreur de chargement</div></div>';
    }
}

// Render groups grid
function renderGroupsGrid(groups) {
    const grid = document.getElementById('groupsGrid');
    if (!groups || groups.length === 0) {
        grid.innerHTML = '<div class="card"><div class="card-body text-center">Aucun groupe trouvé</div></div>';
        return;
    }

    grid.innerHTML = groups.map(group => `
        <div class="card group-card">
            <div class="card-body">
                <h3>${group.name}</h3>
                <p class="text-muted">${group.description || 'Aucune description'}</p>
                <div class="group-stats">
                    <span><i class="fas fa-users"></i> ${group.member_count || 0} membres</span>
                    <span><i class="fas fa-shield-alt"></i> ${group.permission_count || 0} permissions</span>
                </div>
                <div class="group-actions">
                    <button class="btn-sm btn-secondary" onclick="viewGroupDetails(${group.id})" title="Voir">
                        <i class="fas fa-eye"></i> Voir
                    </button>
                    <button class="btn-sm btn-secondary" onclick="editGroup(${group.id})" title="Modifier">
                        <i class="fas fa-edit"></i> Modifier
                    </button>
                    <button class="btn-sm btn-danger" onclick="confirmDeleteGroup(${group.id})" title="Supprimer">
                        <i class="fas fa-trash"></i> Supprimer
                    </button>
                </div>
            </div>
        </div>
    `).join('');
}

// Ouvrir modal création
function openCreateModal() {
    document.getElementById('modalGroupTitle').textContent = 'Nouveau Groupe';
    document.getElementById('groupId').value = '';
    document.getElementById('formGroup').reset();
    openModal('modalGroup');
}

// Voir détails groupe
async function viewGroupDetails(id) {
    try {
        currentGroupId = id;
        const response = await API.get(`/groups/${id}`);
        const group = response.data;

        document.getElementById('groupDetailsName').textContent = group.name;

        // Render info tab
        renderGroupInfo(group);

        // Charger les membres et permissions
        await Promise.all([
            loadGroupMembers(id),
            loadGroupPermissions(id)
        ]);

        switchTab('info');
        openModal('modalGroupDetails');
    } catch (error) {
        handleApiError(error);
    }
}

// Render group info
function renderGroupInfo(group) {
    document.getElementById('groupInfoContent').innerHTML = `
        <dl>
            <dt>Nom</dt><dd>${group.name}</dd>
            <dt>Slug</dt><dd><code>${group.slug}</code></dd>
            <dt>Description</dt><dd>${group.description || '-'}</dd>
            <dt>Créé le</dt><dd>${formatDate(group.created_at)}</dd>
            <dt>Créé par</dt><dd>${group.created_by_name || '-'}</dd>
            <dt>Modifié le</dt><dd>${group.updated_at ? formatDate(group.updated_at) : '-'}</dd>
        </dl>
    `;
}

// Charger les membres du groupe
async function loadGroupMembers(groupId) {
    try {
        const response = await API.get(`/groups/${groupId}/members`);
        const members = response.data || [];

        document.getElementById('membersCount').textContent = members.length;

        const membersList = document.getElementById('membersList');
        if (members.length === 0) {
            membersList.innerHTML = '<p class="text-muted text-center">Aucun membre</p>';
            return;
        }

        membersList.innerHTML = members.map(member => `
            <div class="member-item">
                <div class="member-info">
                    <strong>${member.username}</strong>
                    <span class="text-muted">${member.email}</span>
                </div>
                <button class="btn-sm btn-danger" onclick="removeMember(${groupId}, ${member.id})">
                    <i class="fas fa-times"></i> Retirer
                </button>
            </div>
        `).join('');
    } catch (error) {
        console.error('Erreur chargement membres:', error);
    }
}

// Charger les permissions du groupe
async function loadGroupPermissions(groupId) {
    try {
        const response = await API.get(`/groups/${groupId}/permissions`);
        const permissions = response.data || [];

        document.getElementById('permissionsCount').textContent = permissions.length;

        const permissionsGrid = document.getElementById('permissionsGrid');
        if (permissions.length === 0) {
            permissionsGrid.innerHTML = '<p class="text-muted text-center">Aucune permission</p>';
            return;
        }

        // Grouper par catégorie
        const grouped = permissions.reduce((acc, perm) => {
            if (!acc[perm.category]) acc[perm.category] = [];
            acc[perm.category].push(perm);
            return acc;
        }, {});

        permissionsGrid.innerHTML = Object.entries(grouped).map(([category, perms]) => `
            <div class="permission-category">
                <h4>${category.toUpperCase()}</h4>
                ${perms.map(p => `
                    <div class="permission-item">
                        <span><i class="fas fa-check-circle text-success"></i> ${p.name}</span>
                        <span class="text-muted">${p.description}</span>
                    </div>
                `).join('')}
            </div>
        `).join('');
    } catch (error) {
        console.error('Erreur chargement permissions:', error);
    }
}

// Éditer groupe
async function editGroup(id) {
    try {
        const response = await API.get(`/groups/${id}`);
        const group = response.data;

        document.getElementById('modalGroupTitle').textContent = 'Modifier Groupe';
        document.getElementById('groupId').value = group.id;
        document.getElementById('formName').value = group.name;
        document.getElementById('formSlug').value = group.slug;
        document.getElementById('formDescription').value = group.description || '';

        openModal('modalGroup');
    } catch (error) {
        handleApiError(error);
    }
}

// Soumettre formulaire
async function submitGroup() {
    try {
        const groupId = document.getElementById('groupId').value;
        const formData = {
            name: document.getElementById('formName').value,
            slug: document.getElementById('formSlug').value,
            description: document.getElementById('formDescription').value
        };

        const response = groupId
            ? await API.put(`/groups/${groupId}`, formData)
            : await API.post('/groups', formData);

        showToast(response.message || 'Groupe enregistré', 'success');
        closeModal('modalGroup');
        loadGroups();
    } catch (error) {
        handleApiError(error);
    }
}

// Confirmer suppression
function confirmDeleteGroup(id) {
    document.getElementById('deleteGroupInfo').textContent = `Groupe ID: ${id}`;
    document.getElementById('btnConfirmDelete').onclick = () => deleteGroup(id);
    openModal('modalConfirmDelete');
}

// Supprimer groupe
async function deleteGroup(id) {
    try {
        await API.delete(`/groups/${id}`);
        showToast('Groupe supprimé', 'success');
        closeModal('modalConfirmDelete');
        loadGroups();
    } catch (error) {
        handleApiError(error);
    }
}

// Ajouter des membres
async function openAddMembersModal() {
    try {
        const response = await API.get('/users');
        const users = response.data || [];

        const usersSelection = document.getElementById('usersSelection');
        usersSelection.innerHTML = users.map(user => `
            <label class="checkbox-label">
                <input type="checkbox" name="users[]" value="${user.id}">
                <span>${user.username} (${user.email})</span>
            </label>
        `).join('');

        openModal('modalAddMembers');
    } catch (error) {
        handleApiError(error);
    }
}

async function addMembers() {
    try {
        const userIds = Array.from(document.querySelectorAll('input[name="users[]"]:checked')).map(cb => cb.value);

        if (userIds.length === 0) {
            showToast('Sélectionnez au moins un utilisateur', 'warning');
            return;
        }

        await API.post(`/groups/${currentGroupId}/members`, { user_ids: userIds });
        showToast('Membres ajoutés', 'success');
        closeModal('modalAddMembers');
        loadGroupMembers(currentGroupId);
    } catch (error) {
        handleApiError(error);
    }
}

// Retirer un membre
async function removeMember(groupId, userId) {
    try {
        await API.delete(`/groups/${groupId}/members/${userId}`);
        showToast('Membre retiré', 'success');
        loadGroupMembers(groupId);
    } catch (error) {
        handleApiError(error);
    }
}

// Gérer les permissions
async function openManagePermissionsModal() {
    try {
        const [currentPerms, allPerms] = await Promise.all([
            API.get(`/groups/${currentGroupId}/permissions`),
            API.get('/permissions')
        ]);

        const currentPermIds = (currentPerms.data || []).map(p => p.id);
        const permissions = allPerms.data || [];

        // Grouper par catégorie
        const grouped = permissions.reduce((acc, perm) => {
            if (!acc[perm.category]) acc[perm.category] = [];
            acc[perm.category].push(perm);
            return acc;
        }, {});

        const permissionsManager = document.getElementById('permissionsManager');
        permissionsManager.innerHTML = Object.entries(grouped).map(([category, perms]) => `
            <div class="permission-category">
                <h4>${category.toUpperCase()}</h4>
                ${perms.map(p => `
                    <label class="checkbox-label">
                        <input type="checkbox" name="permissions[]" value="${p.id}" ${currentPermIds.includes(p.id) ? 'checked' : ''}>
                        <span>
                            <strong>${p.name}</strong>
                            <span class="text-muted">${p.description}</span>
                        </span>
                    </label>
                `).join('')}
            </div>
        `).join('');

        openModal('modalManagePermissions');
    } catch (error) {
        handleApiError(error);
    }
}

async function savePermissions() {
    try {
        const permissionIds = Array.from(document.querySelectorAll('input[name="permissions[]"]:checked')).map(cb => cb.value);

        await API.post(`/groups/${currentGroupId}/permissions`, { permission_ids: permissionIds });
        showToast('Permissions mises à jour', 'success');
        closeModal('modalManagePermissions');
        loadGroupPermissions(currentGroupId);
    } catch (error) {
        handleApiError(error);
    }
}

// Tabs
function switchTab(tab) {
    currentTab = tab;

    // Update buttons
    document.querySelectorAll('.tab-button').forEach(btn => {
        btn.classList.toggle('active', btn.dataset.tab === tab);
    });

    // Update panes
    document.querySelectorAll('.tab-pane').forEach(pane => {
        pane.classList.toggle('active', pane.dataset.tab === tab);
    });
}

// Helpers
function generateSlug(text) {
    return text
        .toLowerCase()
        .trim()
        .replace(/[^a-z0-9]+/g, '-')
        .replace(/^-+|-+$/g, '');
}

function updateStats(stats) {
    document.getElementById('groupCount').textContent = stats.total || 0;
}

function debounce(func, wait) {
    let timeout;
    return function executedFunction(...args) {
        clearTimeout(timeout);
        timeout = setTimeout(() => func.apply(this, args), wait);
    };
}

function formatDate(dateString) {
    if (!dateString) return '-';
    const date = new Date(dateString);
    return date.toLocaleDateString('fr-FR') + ' ' + date.toLocaleTimeString('fr-FR', { hour: '2-digit', minute: '2-digit' });
}

function openModal(id) {
    document.getElementById(id)?.classList.add('show');
}

function closeModal(id) {
    document.getElementById(id)?.classList.remove('show');
}

function showToast(message, type = 'success') {
    if (window.showToast) {
        window.showToast(message, type);
    } else {
        alert(message);
    }
}
