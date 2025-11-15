/**
 * BOLT.DIY USER MANAGER v2.0 - USERS MODULE
 * © Copyright Nbility 2025
 */

let currentPage = 1;
let perPage = 25;
let currentFilters = {};
let selectedUsers = new Set();

// Initialisation
document.addEventListener('DOMContentLoaded', () => {
    loadUsers();
    loadGroups();
    initEventListeners();
});

// Event listeners
function initEventListeners() {
    // Recherche
    document.getElementById('searchInput')?.addEventListener('input', debounce(() => {
        currentPage = 1;
        loadUsers();
    }, 500));

    // Filtres
    document.getElementById('filterRole')?.addEventListener('change', () => {
        currentPage = 1;
        loadUsers();
    });

    document.getElementById('filterStatus')?.addEventListener('change', () => {
        currentPage = 1;
        loadUsers();
    });

    // Pagination
    document.getElementById('perPageSelect')?.addEventListener('change', (e) => {
        perPage = parseInt(e.target.value);
        currentPage = 1;
        loadUsers();
    });

    // Actions
    document.getElementById('btnRefresh')?.addEventListener('click', loadUsers);
    document.getElementById('btnExport')?.addEventListener('click', exportUsers);
    document.getElementById('btnCreateUser')?.addEventListener('click', () => openCreateModal());

    // Select all
    document.getElementById('selectAll')?.addEventListener('change', (e) => {
        document.querySelectorAll('.user-checkbox').forEach(cb => {
            cb.checked = e.target.checked;
            if (e.target.checked) {
                selectedUsers.add(parseInt(cb.value));
            } else {
                selectedUsers.delete(parseInt(cb.value));
            }
        });
        updateBulkActions();
    });

    // Bulk actions
    document.getElementById('btnBulkActivate')?.addEventListener('click', () => bulkAction('activate'));
    document.getElementById('btnBulkDeactivate')?.addEventListener('click', () => bulkAction('deactivate'));
    document.getElementById('btnBulkDelete')?.addEventListener('click', () => bulkAction('delete'));

    // Form submit
    document.getElementById('btnSubmitUser')?.addEventListener('click', submitUser);

    // Password toggle
    document.querySelector('.btn-toggle-password')?.addEventListener('click', togglePassword);

    // Modal close
    document.querySelectorAll('[data-dismiss="modal"]').forEach(btn => {
        btn.addEventListener('click', (e) => {
            const modal = e.target.closest('.modal');
            if (modal) closeModal(modal.id);
        });
    });
}

// Charger les utilisateurs
async function loadUsers() {
    try {
        showLoading('usersTableBody');

        currentFilters = {
            search: document.getElementById('searchInput')?.value || '',
            role: document.getElementById('filterRole')?.value || '',
            status: document.getElementById('filterStatus')?.value || '',
            page: currentPage,
            per_page: perPage
        };

        const response = await API.get('/users', currentFilters);
        renderUsers(response.data);
        renderPagination(response.pagination);
        updateStats(response.stats || {});

    } catch (error) {
        handleApiError(error);
        document.getElementById('usersTableBody').innerHTML = '<tr><td colspan="10" class="text-center text-danger">Erreur de chargement</td></tr>';
    }
}

// Render users
function renderUsers(users) {
    const tbody = document.getElementById('usersTableBody');
    if (!users || users.length === 0) {
        tbody.innerHTML = '<tr><td colspan="10" class="text-center">Aucun utilisateur trouvé</td></tr>';
        return;
    }

    tbody.innerHTML = users.map(user => `
        <tr>
            <td><input type="checkbox" class="user-checkbox" value="${user.id}" onchange="toggleUserSelection(${user.id}, this.checked)"></td>
            <td>${user.id}</td>
            <td>
                <div><strong>${user.username}</strong></div>
                <div class="text-muted">${user.first_name || ''} ${user.last_name || ''}</div>
            </td>
            <td>${user.email}</td>
            <td><span class="badge badge-${getRoleBadgeClass(user.role)}">${user.role}</span></td>
            <td><span class="badge badge-${getStatusBadgeClass(user.status)}">${user.status}</span></td>
            <td>${user.groups ? user.groups.map(g => `<span class="badge badge-secondary">${g.name}</span>`).join(' ') : '-'}</td>
            <td>${formatDate(user.created_at)}</td>
            <td>${user.last_login ? formatDate(user.last_login) : '-'}</td>
            <td>
                <button class="btn-sm btn-secondary" onclick="viewUser(${user.id})" title="Voir">
                    <i class="fas fa-eye"></i>
                </button>
                <button class="btn-sm btn-secondary" onclick="editUser(${user.id})" title="Modifier">
                    <i class="fas fa-edit"></i>
                </button>
                <button class="btn-sm btn-danger" onclick="confirmDeleteUser(${user.id})" title="Supprimer" data-permission="users.delete">
                    <i class="fas fa-trash"></i>
                </button>
            </td>
        </tr>
    `).join('');

    Auth.hideElementsByRole();
}

// Charger les groupes
async function loadGroups() {
    try {
        const response = await API.get('/groups');
        const groupsContainer = document.getElementById('formGroups');
        if (!groupsContainer) return;

        groupsContainer.innerHTML = response.data.map(group => `
            <label class="checkbox-label">
                <input type="checkbox" name="groups[]" value="${group.id}">
                <span>${group.name}</span>
            </label>
        `).join('');
    } catch (error) {
        console.error('Erreur chargement groupes:', error);
    }
}

// Ouvrir modal création
function openCreateModal() {
    document.getElementById('modalUserTitle').textContent = 'Nouvel Utilisateur';
    document.getElementById('userId').value = '';
    document.getElementById('formUser').reset();
    document.getElementById('passwordGroup').style.display = 'block';
    document.getElementById('formPassword').required = true;
    openModal('modalUser');
}

// Voir utilisateur
async function viewUser(id) {
    try {
        const response = await API.get(`/users/${id}`);
        const user = response.data;

        document.getElementById('userDetailsContent').innerHTML = `
            <dl>
                <dt>ID</dt><dd>${user.id}</dd>
                <dt>Username</dt><dd>${user.username}</dd>
                <dt>Email</dt><dd>${user.email}</dd>
                <dt>Nom complet</dt><dd>${user.first_name || ''} ${user.last_name || ''}</dd>
                <dt>Rôle</dt><dd><span class="badge badge-${getRoleBadgeClass(user.role)}">${user.role}</span></dd>
                <dt>Statut</dt><dd><span class="badge badge-${getStatusBadgeClass(user.status)}">${user.status}</span></dd>
                <dt>Groupes</dt><dd>${user.groups ? user.groups.map(g => `<span class="badge badge-secondary">${g.name}</span>`).join(' ') : '-'}</dd>
                <dt>Créé le</dt><dd>${formatDate(user.created_at)}</dd>
                <dt>Dernière connexion</dt><dd>${user.last_login ? formatDate(user.last_login) : 'Jamais'}</dd>
            </dl>
        `;

        openModal('modalUserDetails');
    } catch (error) {
        handleApiError(error);
    }
}

// Éditer utilisateur
async function editUser(id) {
    try {
        const response = await API.get(`/users/${id}`);
        const user = response.data;

        document.getElementById('modalUserTitle').textContent = 'Modifier Utilisateur';
        document.getElementById('userId').value = user.id;
        document.getElementById('formUsername').value = user.username;
        document.getElementById('formEmail').value = user.email;
        document.getElementById('formFirstName').value = user.first_name || '';
        document.getElementById('formLastName').value = user.last_name || '';
        document.getElementById('formRole').value = user.role;
        document.getElementById('formStatus').value = user.status;
        document.getElementById('passwordGroup').style.display = 'none';
        document.getElementById('formPassword').required = false;

        // Cocher les groupes
        document.querySelectorAll('input[name="groups[]"]').forEach(cb => {
            cb.checked = user.groups && user.groups.some(g => g.id == cb.value);
        });

        openModal('modalUser');
    } catch (error) {
        handleApiError(error);
    }
}

// Soumettre formulaire
async function submitUser() {
    try {
        const userId = document.getElementById('userId').value;
        const formData = {
            username: document.getElementById('formUsername').value,
            email: document.getElementById('formEmail').value,
            first_name: document.getElementById('formFirstName').value,
            last_name: document.getElementById('formLastName').value,
            role: document.getElementById('formRole').value,
            status: document.getElementById('formStatus').value,
            groups: Array.from(document.querySelectorAll('input[name="groups[]"]:checked')).map(cb => cb.value)
        };

        if (document.getElementById('passwordGroup').style.display !== 'none') {
            formData.password = document.getElementById('formPassword').value;
        }

        const response = userId
            ? await API.put(`/users/${userId}`, formData)
            : await API.post('/users', formData);

        showToast(response.message || 'Utilisateur enregistré', 'success');
        closeModal('modalUser');
        loadUsers();

    } catch (error) {
        handleApiError(error);
    }
}

// Confirmer suppression
function confirmDeleteUser(id) {
    const modal = document.getElementById('modalConfirmDelete');
    document.getElementById('deleteUserInfo').textContent = `Utilisateur ID: ${id}`;
    document.getElementById('btnConfirmDelete').onclick = () => deleteUser(id);
    openModal('modalConfirmDelete');
}

// Supprimer utilisateur
async function deleteUser(id) {
    try {
        await API.delete(`/users/${id}`);
        showToast('Utilisateur supprimé', 'success');
        closeModal('modalConfirmDelete');
        loadUsers();
    } catch (error) {
        handleApiError(error);
    }
}

// Bulk actions
function toggleUserSelection(id, checked) {
    if (checked) {
        selectedUsers.add(id);
    } else {
        selectedUsers.delete(id);
    }
    updateBulkActions();
}

function updateBulkActions() {
    const bulkActions = document.getElementById('bulkActions');
    const count = document.getElementById('selectedCount');
    if (selectedUsers.size > 0) {
        bulkActions.style.display = 'flex';
        count.textContent = selectedUsers.size;
    } else {
        bulkActions.style.display = 'none';
    }
}

async function bulkAction(action) {
    if (selectedUsers.size === 0) return;

    try {
        await API.post('/users/bulk', {
            action,
            ids: Array.from(selectedUsers)
        });

        showToast(`Action "${action}" effectuée`, 'success');
        selectedUsers.clear();
        loadUsers();
    } catch (error) {
        handleApiError(error);
    }
}

// Export
async function exportUsers() {
    try {
        await API.download('/users/export', 'users.csv');
        showToast('Export réussi', 'success');
    } catch (error) {
        handleApiError(error);
    }
}

// Pagination
function renderPagination(pagination) {
    if (!pagination) return;

    document.getElementById('paginationStart').textContent = pagination.from || 0;
    document.getElementById('paginationEnd').textContent = pagination.to || 0;
    document.getElementById('paginationTotal').textContent = pagination.total || 0;

    const paginationEl = document.getElementById('pagination');
    if (!paginationEl) return;

    let html = '';

    if (pagination.current_page > 1) {
        html += `<button onclick="loadPage(${pagination.current_page - 1})">‹ Précédent</button>`;
    }

    for (let i = 1; i <= pagination.last_page; i++) {
        if (i === 1 || i === pagination.last_page || (i >= pagination.current_page - 2 && i <= pagination.current_page + 2)) {
            html += `<button class="${i === pagination.current_page ? 'active' : ''}" onclick="loadPage(${i})">${i}</button>`;
        } else if (i === pagination.current_page - 3 || i === pagination.current_page + 3) {
            html += '<button disabled>...</button>';
        }
    }

    if (pagination.current_page < pagination.last_page) {
        html += `<button onclick="loadPage(${pagination.current_page + 1})">Suivant ›</button>`;
    }

    paginationEl.innerHTML = html;
}

function loadPage(page) {
    currentPage = page;
    loadUsers();
}

// Helpers
function getRoleBadgeClass(role) {
    const classes = { user: 'secondary', admin: 'primary', superadmin: 'danger' };
    return classes[role] || 'secondary';
}

function getStatusBadgeClass(status) {
    const classes = { active: 'success', inactive: 'secondary', suspended: 'warning' };
    return classes[status] || 'secondary';
}

function togglePassword() {
    const input = document.getElementById('formPassword');
    const icon = document.querySelector('.btn-toggle-password i');
    if (input.type === 'password') {
        input.type = 'text';
        icon.classList.replace('fa-eye', 'fa-eye-slash');
    } else {
        input.type = 'password';
        icon.classList.replace('fa-eye-slash', 'fa-eye');
    }
}

function updateStats(stats) {
    document.getElementById('userCount').textContent = stats.total || 0;
}

function showLoading(elementId) {
    const el = document.getElementById(elementId);
    if (el) el.innerHTML = '<tr><td colspan="10" class="text-center"><i class="fas fa-spinner fa-spin"></i> Chargement...</td></tr>';
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
