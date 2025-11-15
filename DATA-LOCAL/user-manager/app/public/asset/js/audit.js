/**
 * BOLT.DIY USER MANAGER v2.0 - AUDIT MODULE
 * © Copyright Nbility 2025
 */

let currentPage = 1;
let perPage = 50;
let currentFilters = {};

// Initialisation
document.addEventListener('DOMContentLoaded', () => {
    loadAuditLogs();
    initEventListeners();
    initDatePickers();
});

// Event listeners
function initEventListeners() {
    // Recherche
    document.getElementById('searchInput')?.addEventListener('input', debounce(() => {
        currentPage = 1;
        loadAuditLogs();
    }, 500));

    // Filtres
    document.getElementById('filterAction')?.addEventListener('change', () => {
        currentPage = 1;
        loadAuditLogs();
    });

    document.getElementById('filterUser')?.addEventListener('change', () => {
        currentPage = 1;
        loadAuditLogs();
    });

    document.getElementById('filterDateFrom')?.addEventListener('change', () => {
        currentPage = 1;
        loadAuditLogs();
    });

    document.getElementById('filterDateTo')?.addEventListener('change', () => {
        currentPage = 1;
        loadAuditLogs();
    });

    // Actions
    document.getElementById('btnRefresh')?.addEventListener('click', loadAuditLogs);
    document.getElementById('btnExport')?.addEventListener('click', exportAuditLogs);
    document.getElementById('btnClearFilters')?.addEventListener('click', clearFilters);

    // Pagination
    document.getElementById('perPageSelect')?.addEventListener('change', (e) => {
        perPage = parseInt(e.target.value);
        currentPage = 1;
        loadAuditLogs();
    });

    // Modal close
    document.querySelectorAll('[data-dismiss="modal"]').forEach(btn => {
        btn.addEventListener('click', (e) => {
            const modal = e.target.closest('.modal');
            if (modal) closeModal(modal.id);
        });
    });
}

// Init date pickers
function initDatePickers() {
    const today = new Date();
    const thirtyDaysAgo = new Date(today.getTime() - (30 * 24 * 60 * 60 * 1000));

    const dateFrom = document.getElementById('filterDateFrom');
    const dateTo = document.getElementById('filterDateTo');

    if (dateFrom) dateFrom.value = thirtyDaysAgo.toISOString().split('T')[0];
    if (dateTo) dateTo.value = today.toISOString().split('T')[0];
}

// Charger les logs d'audit
async function loadAuditLogs() {
    try {
        showLoading('auditTimeline');

        currentFilters = {
            search: document.getElementById('searchInput')?.value || '',
            action: document.getElementById('filterAction')?.value || '',
            user_id: document.getElementById('filterUser')?.value || '',
            date_from: document.getElementById('filterDateFrom')?.value || '',
            date_to: document.getElementById('filterDateTo')?.value || '',
            page: currentPage,
            per_page: perPage
        };

        const response = await API.get('/audit', currentFilters);
        renderAuditTimeline(response.data);
        renderPagination(response.pagination);
        updateStats(response.stats || {});

        // Charger la liste des utilisateurs pour le filtre
        loadUsersFilter();

    } catch (error) {
        handleApiError(error);
        showError('auditTimeline', 'Erreur de chargement');
    }
}

// Render audit timeline
function renderAuditTimeline(logs) {
    const timeline = document.getElementById('auditTimeline');
    if (!logs || logs.length === 0) {
        showEmpty('auditTimeline', 'Aucun log trouvé');
        return;
    }

    // Grouper par date
    const grouped = logs.reduce((acc, log) => {
        const date = new Date(log.created_at).toLocaleDateString('fr-FR', {
            weekday: 'long',
            year: 'numeric',
            month: 'long',
            day: 'numeric'
        });
        if (!acc[date]) acc[date] = [];
        acc[date].push(log);
        return acc;
    }, {});

    let html = '';
    Object.entries(grouped).forEach(([date, items]) => {
        html += `<div class="timeline-date">${date}</div>`;

        items.forEach(log => {
            const icon = getActionIcon(log.action);
            const color = getActionColor(log.action);

            html += `
                <div class="timeline-item">
                    <div class="timeline-marker" style="border-color: ${color}"></div>
                    <div class="timeline-content">
                        <div class="timeline-header">
                            <span class="timeline-time">
                                <i class="fas ${icon}" style="color: ${color}"></i>
                                ${formatTime(log.created_at)}
                            </span>
                            <span class="timeline-user">
                                <i class="fas fa-user"></i> ${log.user_username || 'Système'}
                            </span>
                        </div>
                        <div class="timeline-body">
                            <strong>${log.action}</strong>
                            ${log.description ? '<br>' + log.description : ''}
                            ${log.target_type ? '<br><small class="text-muted">Type: ' + log.target_type + (log.target_id ? ' (ID: ' + log.target_id + ')' : '') + '</small>' : ''}
                        </div>
                        ${log.metadata ? `
                            <div class="timeline-actions">
                                <button class="btn-sm btn-secondary" onclick="viewLogDetails(${log.id})">
                                    <i class="fas fa-info-circle"></i> Détails
                                </button>
                            </div>
                        ` : ''}
                    </div>
                </div>
            `;
        });
    });

    timeline.innerHTML = html;
}

// Voir détails d'un log
async function viewLogDetails(id) {
    try {
        const response = await API.get(`/audit/${id}`);
        const log = response.data;

        document.getElementById('logDetailsContent').innerHTML = `
            <dl>
                <dt>ID</dt><dd>${log.id}</dd>
                <dt>Action</dt><dd><span class="badge badge-${getActionBadgeClass(log.action)}">${log.action}</span></dd>
                <dt>Description</dt><dd>${log.description || '-'}</dd>
                <dt>Utilisateur</dt><dd>${log.user_username || 'Système'} (ID: ${log.user_id || '-'})</dd>
                <dt>Type de cible</dt><dd>${log.target_type || '-'}</dd>
                <dt>ID de cible</dt><dd>${log.target_id || '-'}</dd>
                <dt>Adresse IP</dt><dd><code>${log.ip_address || '-'}</code></dd>
                <dt>User Agent</dt><dd><small>${log.user_agent || '-'}</small></dd>
                <dt>Date</dt><dd>${formatDate(log.created_at)}</dd>
            </dl>
            ${log.metadata ? `
                <h4>Métadonnées</h4>
                <pre>${JSON.stringify(JSON.parse(log.metadata), null, 2)}</pre>
            ` : ''}
        `;

        openModal('modalLogDetails');
    } catch (error) {
        handleApiError(error);
    }
}

// Charger les utilisateurs pour le filtre
async function loadUsersFilter() {
    try {
        const response = await API.get('/users', { per_page: 1000 });
        const select = document.getElementById('filterUser');
        if (!select) return;

        select.innerHTML = '<option value="">Tous les utilisateurs</option>';
        response.data.forEach(user => {
            select.innerHTML += `<option value="${user.id}">${user.username}</option>`;
        });
    } catch (error) {
        console.error('Erreur chargement users:', error);
    }
}

// Export logs
async function exportAuditLogs() {
    try {
        await API.download('/audit/export', 'audit-logs.csv');
        showToast('Export réussi', 'success');
    } catch (error) {
        handleApiError(error);
    }
}

// Clear filters
function clearFilters() {
    document.getElementById('searchInput').value = '';
    document.getElementById('filterAction').value = '';
    document.getElementById('filterUser').value = '';
    initDatePickers();
    currentPage = 1;
    loadAuditLogs();
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
    loadAuditLogs();
}

// Stats
function updateStats(stats) {
    document.getElementById('totalLogs').textContent = stats.total || 0;
    document.getElementById('todayLogs').textContent = stats.today || 0;
}

// Helpers
function getActionIcon(action) {
    const icons = {
        'login': 'fa-sign-in-alt',
        'logout': 'fa-sign-out-alt',
        'create': 'fa-plus-circle',
        'update': 'fa-edit',
        'delete': 'fa-trash',
        'view': 'fa-eye',
        'export': 'fa-download',
        'import': 'fa-upload'
    };
    return icons[action.toLowerCase()] || 'fa-info-circle';
}

function getActionColor(action) {
    const colors = {
        'login': '#10b981',
        'logout': '#6b7280',
        'create': '#3b82f6',
        'update': '#f59e0b',
        'delete': '#ef4444',
        'view': '#8b5cf6',
        'export': '#06b6d4',
        'import': '#06b6d4'
    };
    return colors[action.toLowerCase()] || '#4f46e5';
}

function getActionBadgeClass(action) {
    const classes = {
        'login': 'success',
        'logout': 'secondary',
        'create': 'info',
        'update': 'warning',
        'delete': 'danger'
    };
    return classes[action.toLowerCase()] || 'primary';
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

function formatTime(dateString) {
    if (!dateString) return '-';
    const date = new Date(dateString);
    return date.toLocaleTimeString('fr-FR', { hour: '2-digit', minute: '2-digit' });
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
    if (el) el.innerHTML = '<div class="loading"><i class="fas fa-spinner fa-spin"></i> Chargement...</div>';
}

function showError(elementId, message) {
    const el = document.getElementById(elementId);
    if (el) el.innerHTML = `<div class="text-center text-danger"><i class="fas fa-exclamation-triangle"></i> ${message}</div>`;
}

function showEmpty(elementId, message) {
    const el = document.getElementById(elementId);
    if (el) el.innerHTML = `<div class="text-center text-muted">${message}</div>`;
}
