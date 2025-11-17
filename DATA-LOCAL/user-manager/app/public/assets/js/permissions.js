/**
 * BOLT.DIY USER MANAGER v2.0 - PERMISSIONS MODULE
 * © Copyright Nbility 2025
 */

let currentPage = 1;
let perPage = 25;
let currentFilters = {};

// Initialisation
document.addEventListener('DOMContentLoaded', () => {
    loadPermissions();
    initEventListeners();
});

// Event listeners
function initEventListeners() {
    // Recherche
    document.getElementById('searchInput')?.addEventListener('input', debounce(() => {
        currentPage = 1;
        loadPermissions();
    }, 500));

    // Filtres
    document.getElementById('filterCategory')?.addEventListener('change', () => {
        currentPage = 1;
        loadPermissions();
    });

    // Actions
    document.getElementById('btnRefresh')?.addEventListener('click', loadPermissions);
    document.getElementById('btnCreatePermission')?.addEventListener('click', () => openCreateModal());

    // Pagination
    document.getElementById('perPageSelect')?.addEventListener('change', (e) => {
        perPage = parseInt(e.target.value);
        currentPage = 1;
        loadPermissions();
    });

    // Form submit
    document.getElementById('btnSubmitPermission')?.addEventListener('click', submitPermission);

    // Modal close
    document.querySelectorAll('[data-dismiss="modal"]').forEach(btn => {
        btn.addEventListener('click', (e) => {
            const modal = e.target.closest('.modal');
            if (modal) closeModal(modal.id);
        });
    });
}

// Charger les permissions
async function loadPermissions() {
    try {
        showLoading('permissionsTableBody');

        currentFilters = {
            search: document.getElementById('searchInput')?.value || '',
            category: document.getElementById('filterCategory')?.value || '',
            page: currentPage,
            per_page: perPage
        };

        const response = await API.get('/permissions', currentFilters);
        renderPermissions(response.data);
        renderPagination(response.pagination);
        updateStats(response.stats || {});

    } catch (error) {
        handleApiError(error);
        showError('permissionsTableBody', 'Erreur de chargement', 7);
    }
}

// Render permissions (groupées par catégorie)
function renderPermissions(permissions) {
    const tbody = document.getElementById('permissionsTableBody');
    if (!permissions || permissions.length === 0) {
        showEmpty('permissionsTableBody', 'Aucune permission trouvée', 7);
        return;
    }

    // Grouper par catégorie
    const grouped = permissions.reduce((acc, perm) => {
        if (!acc[perm.category]) acc[perm.category] = [];
        acc[perm.category].push(perm);
        return acc;
    }, {});

    let html = '';
    Object.entries(grouped).forEach(([category, perms]) => {
        // Ligne de catégorie
        html += `
            <tr class="category-row">
                <td colspan="7">
                    <strong>${category.toUpperCase()}</strong>
                    <span class="text-muted">(${perms.length} permissions)</span>
                </td>
            </tr>
        `;

        // Permissions de la catégorie
        perms.forEach(perm => {
            html += `
                <tr>
                    <td>${perm.id}</td>
                    <td><code>${perm.slug}</code></td>
                    <td>
                        <strong>${perm.name}</strong>
                        <div class="text-muted small">${perm.description || '-'}</div>
                    </td>
                    <td>${perm.users_count || 0}</td>
                    <td>${perm.groups_count || 0}</td>
                    <td>${formatDate(perm.created_at, false)}</td>
                    <td>
                        <button class="btn-sm btn-secondary" onclick="viewPermission(${perm.id})" title="Voir">
                            <i class="fas fa-eye"></i>
                        </button>
                        <button class="btn-sm btn-secondary" onclick="editPermission(${perm.id})" title="Modifier" data-role="superadmin">
                            <i class="fas fa-edit"></i>
                        </button>
                        <button class="btn-sm btn-danger" onclick="confirmDeletePermission(${perm.id})" title="Supprimer" data-role="superadmin">
                            <i class="fas fa-trash"></i>
                        </button>
                    </td>
                </tr>
            `;
        });
    });

    tbody.innerHTML = html;
    Auth.hideElementsByRole();
}

// Ouvrir modal création
function openCreateModal() {
    document.getElementById('modalPermissionTitle').textContent = 'Nouvelle Permission';
    document.getElementById('permissionId').value = '';
    document.getElementById('formPermission').reset();
    openModal('modalPermission');
}

// Voir permission
async function viewPermission(id) {
    try {
        const response = await API.get(`/permissions/${id}`);
        const perm = response.data;

        document.getElementById('permissionDetailsContent').innerHTML = `
            <dl>
                <dt>ID</dt><dd>${perm.id}</dd>
                <dt>Nom</dt><dd>${perm.name}</dd>
                <dt>Slug</dt><dd><code>${perm.slug}</code></dd>
                <dt>Catégorie</dt><dd>${perm.category}</dd>
                <dt>Description</dt><dd>${perm.description || '-'}</dd>
                <dt>Utilisateurs</dt><dd>${perm.users_count || 0}</dd>
                <dt>Groupes</dt><dd>${perm.groups_count || 0}</dd>
                <dt>Créé le</dt><dd>${formatDate(perm.created_at)}</dd>
                <dt>Créé par</dt><dd>${perm.created_by_name || '-'}</dd>
            </dl>
        `;

        // Charger les utilisateurs et groupes
        loadPermissionUsersGroups(id);

        openModal('modalPermissionDetails');
    } catch (error) {
        handleApiError(error);
    }
}

// Charger users/groups ayant la permission
async function loadPermissionUsersGroups(permissionId) {
    try {
        const [usersRes, groupsRes] = await Promise.all([
            API.get(`/permissions/${permissionId}/users`),
            API.get(`/permissions/${permissionId}/groups`)
        ]);

        // Users
        const usersList = document.getElementById('permissionUsersList');
        if (usersRes.data && usersRes.data.length > 0) {
            usersList.innerHTML = usersRes.data.map(user => `
                <div class="user-item">
                    <span>${user.username} (${user.email})</span>
                </div>
            `).join('');
        } else {
            usersList.innerHTML = '<p class="text-muted">Aucun utilisateur</p>';
        }

        // Groups
        const groupsList = document.getElementById('permissionGroupsList');
        if (groupsRes.data && groupsRes.data.length > 0) {
            groupsList.innerHTML = groupsRes.data.map(group => `
                <div class="group-item">
                    <span>${group.name}</span>
                </div>
            `).join('');
        } else {
            groupsList.innerHTML = '<p class="text-muted">Aucun groupe</p>';
        }
    } catch (error) {
        console.error('Erreur chargement users/groups:', error);
    }
}

// Éditer permission
async function editPermission(id) {
    try {
        const response = await API.get(`/permissions/${id}`);
        const perm = response.data;

        document.getElementById('modalPermissionTitle').textContent = 'Modifier Permission';
        document.getElementById('permissionId').value = perm.id;
        document.getElementById('formName').value = perm.name;
        document.getElementById('formSlug').value = perm.slug;
        document.getElementById('formCategory').value = perm.category;
        document.getElementById('formDescription').value = perm.description || '';

        openModal('modalPermission');
    } catch (error) {
        handleApiError(error);
    }
}

// Soumettre formulaire
async function submitPermission() {
    try {
        const permissionId = document.getElementById('permissionId').value;
        const formData = {
            name: document.getElementById('formName').value,
            slug: document.getElementById('formSlug').value,
            category: document.getElementById('formCategory').value,
            description: document.getElementById('formDescription').value
        };

        const response = permissionId
            ? await API.put(`/permissions/${permissionId}`, formData)
            : await API.post('/permissions', formData);

        showToast(response.message || 'Permission enregistrée', 'success');
        closeModal('modalPermission');
        loadPermissions();

    } catch (error) {
        handleApiError(error);
    }
}

// Confirmer suppression
function confirmDeletePermission(id) {
    document.getElementById('deletePermissionInfo').textContent = `Permission ID: ${id}`;
    document.getElementById('btnConfirmDelete').onclick = () => deletePermission(id);
    openModal('modalConfirmDelete');
}

// Supprimer permission
async function deletePermission(id) {
    try {
        await API.delete(`/permissions/${id}`);
        showToast('Permission supprimée', 'success');
        closeModal('modalConfirmDelete');
        loadPermissions();
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
    loadPermissions();
}

// Stats
function updateStats(stats) {
    document.getElementById('permissionCount').textContent = stats.total || 0;
    document.getElementById('categoryCount').textContent = stats.categories || 0;
}

// Auto-generate slug
document.getElementById('formName')?.addEventListener('input', (e) => {
    const slug = slugify(e.target.value);
    document.getElementById('formSlug').value = slug;
});

// Helpers
function debounce(func, wait) {
    let timeout;
    return function executedFunction(...args) {
        clearTimeout(timeout);
        timeout = setTimeout(() => func.apply(this, args), wait);
    };
}

function formatDate(dateString, includeTime = true) {
    if (!dateString) return '-';
    const date = new Date(dateString);
    const dateStr = date.toLocaleDateString('fr-FR');
    if (!includeTime) return dateStr;
    const timeStr = date.toLocaleTimeString('fr-FR', { hour: '2-digit', minute: '2-digit' });
    return `${dateStr} ${timeStr}`;
}

function slugify(text) {
    return text
        .toLowerCase()
        .trim()
        .replace(/[^a-z0-9]+/g, '.')
        .replace(/^\.+|\.+$/g, '');
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

function showLoading(elementId) {
    const el = document.getElementById(elementId);
    if (el) el.innerHTML = '<tr><td colspan="7" class="text-center"><i class="fas fa-spinner fa-spin"></i> Chargement...</td></tr>';
}

function showError(elementId, message, colspan = 7) {
    const el = document.getElementById(elementId);
    if (el) el.innerHTML = `<tr><td colspan="${colspan}" class="text-center text-danger"><i class="fas fa-exclamation-triangle"></i> ${message}</td></tr>`;
}

function showEmpty(elementId, message, colspan = 7) {
    const el = document.getElementById(elementId);
    if (el) el.innerHTML = `<tr><td colspan="${colspan}" class="text-center text-muted">${message}</td></tr>`;
}
