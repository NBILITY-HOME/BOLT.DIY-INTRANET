/* ============================================
   Bolt.DIY User Manager - Audit JS
   Version: 1.0
   Date: 19 novembre 2025
   ============================================ */

// État global de l'audit
let auditState = {
    logs: [],
    filteredLogs: [],
    stats: {},
    currentPage: 1,
    itemsPerPage: 20,
    sortColumn: 'timestamp',
    sortDirection: 'desc',
    filters: {
        search: '',
        action: '',
        user: '',
        status: '',
        dateFrom: '',
        dateTo: ''
    }
};

/* ============================================
   INITIALISATION
   ============================================ */

document.addEventListener('DOMContentLoaded', function() {
    console.log('🎯 Audit.js loaded');
    
    loadAuditLogs();
    setupEventListeners();
    initializeDateFilters();
});

/* ============================================
   CHARGEMENT DES DONNÉES
   ============================================ */

async function loadAuditLogs() {
    try {
        showLoader();
        
        const response = await fetch('/user-manager/api/audit.php');
        if (!response.ok) throw new Error('Failed to load audit logs');
        
        const data = await response.json();
        
        if (data.success) {
            auditState.logs = data.logs || [];
            auditState.stats = data.stats || {};
            auditState.filteredLogs = [...auditState.logs];
            
            renderStats();
            applyFilters();
            renderTable();
            
            console.log('✅ Audit logs loaded:', auditState.logs.length);
        } else {
            throw new Error(data.message || 'Failed to load audit logs');
        }
    } catch (error) {
        console.error('❌ Error loading audit logs:', error);
        showToast('Erreur lors du chargement des logs', 'error');
        renderEmptyState();
    } finally {
        hideLoader();
    }
}

/* ============================================
   RENDU DES STATISTIQUES
   ============================================ */

function renderStats() {
    const stats = auditState.stats;
    
    // Total d'événements
    const totalElement = document.getElementById('totalEvents');
    if (totalElement) {
        totalElement.textContent = stats.total_events || 0;
    }
    
    // Événements aujourd'hui
    const todayElement = document.getElementById('todayEvents');
    if (todayElement) {
        todayElement.textContent = stats.today_events || 0;
    }
    
    // Utilisateurs actifs
    const activeUsersElement = document.getElementById('activeUsers');
    if (activeUsersElement) {
        activeUsersElement.textContent = stats.active_users || 0;
    }
    
    // Actions critiques
    const criticalElement = document.getElementById('criticalActions');
    if (criticalElement) {
        criticalElement.textContent = stats.critical_actions || 0;
    }
}

/* ============================================
   RENDU DU TABLEAU
   ============================================ */

function renderTable() {
    const tbody = document.getElementById('auditTableBody');
    if (!tbody) return;
    
    if (auditState.filteredLogs.length === 0) {
        renderEmptyState();
        return;
    }
    
    // Pagination
    const startIndex = (auditState.currentPage - 1) * auditState.itemsPerPage;
    const endIndex = startIndex + auditState.itemsPerPage;
    const paginatedLogs = auditState.filteredLogs.slice(startIndex, endIndex);
    
    tbody.innerHTML = paginatedLogs.map(log => {
        const timestamp = new Date(log.timestamp);
        const date = formatDate(timestamp);
        const time = formatTime(timestamp);
        
        return `
            <tr onclick="viewLogDetail(${log.id})">
                <td>
                    <div class="log-timestamp">
                        <span class="log-date">${date}</span>
                        <span class="log-time">${time}</span>
                    </div>
                </td>
                <td>
                    <div class="log-user">
                        <div class="log-user-avatar">${getInitials(log.user_name)}</div>
                        <div class="log-user-info">
                            <div class="log-user-name">${escapeHtml(log.user_name)}</div>
                            <div class="log-user-role">${escapeHtml(log.user_role)}</div>
                        </div>
                    </div>
                </td>
                <td>
                    <span class="log-action ${log.action_type}">
                        <i class="fas fa-${getActionIcon(log.action_type)}"></i>
                        ${escapeHtml(log.action_type)}
                    </span>
                </td>
                <td>
                    <div class="log-description">
                        ${escapeHtml(log.description)}
                    </div>
                </td>
                <td>
                    <span class="log-ip">${escapeHtml(log.ip_address)}</span>
                </td>
                <td>
                    <span class="log-status ${log.status}">
                        <i class="fas fa-${log.status === 'success' ? 'check-circle' : log.status === 'error' ? 'times-circle' : 'exclamation-circle'}"></i>
                        ${escapeHtml(log.status)}
                    </span>
                </td>
            </tr>
        `;
    }).join('');
    
    renderPagination();
    updateResultsCount();
}

function renderPagination() {
    const totalPages = Math.ceil(auditState.filteredLogs.length / auditState.itemsPerPage);
    const container = document.getElementById('paginationControls');
    
    if (!container) return;
    
    let buttons = [];
    
    // Previous button
    buttons.push(`
        <button class="pagination-btn" onclick="changePage(${auditState.currentPage - 1})" ${auditState.currentPage === 1 ? 'disabled' : ''}>
            <i class="fas fa-chevron-left"></i> Précédent
        </button>
    `);
    
    // Page numbers
    const maxVisiblePages = 5;
    let startPage = Math.max(1, auditState.currentPage - Math.floor(maxVisiblePages / 2));
    let endPage = Math.min(totalPages, startPage + maxVisiblePages - 1);
    
    if (endPage - startPage < maxVisiblePages - 1) {
        startPage = Math.max(1, endPage - maxVisiblePages + 1);
    }
    
    for (let i = startPage; i <= endPage; i++) {
        buttons.push(`
            <button class="pagination-btn ${i === auditState.currentPage ? 'active' : ''}" onclick="changePage(${i})">
                ${i}
            </button>
        `);
    }
    
    // Next button
    buttons.push(`
        <button class="pagination-btn" onclick="changePage(${auditState.currentPage + 1})" ${auditState.currentPage === totalPages ? 'disabled' : ''}>
            Suivant <i class="fas fa-chevron-right"></i>
        </button>
    `);
    
    container.innerHTML = buttons.join('');
}

function updateResultsCount() {
    const info = document.getElementById('paginationInfo');
    if (!info) return;
    
    const startIndex = (auditState.currentPage - 1) * auditState.itemsPerPage + 1;
    const endIndex = Math.min(auditState.currentPage * auditState.itemsPerPage, auditState.filteredLogs.length);
    const total = auditState.filteredLogs.length;
    
    info.textContent = `Affichage de ${startIndex} à ${endIndex} sur ${total} résultats`;
}

function renderEmptyState() {
    const tbody = document.getElementById('auditTableBody');
    if (!tbody) return;
    
    tbody.innerHTML = `
        <tr>
            <td colspan="6">
                <div class="audit-empty-state">
                    <div class="empty-state-icon">
                        <i class="fas fa-clipboard-list"></i>
                    </div>
                    <h3 class="empty-state-title">Aucun log trouvé</h3>
                    <p class="empty-state-description">
                        Aucun événement ne correspond à vos critères de recherche
                    </p>
                </div>
            </td>
        </tr>
    `;
    
    // Clear pagination
    const controls = document.getElementById('paginationControls');
    if (controls) controls.innerHTML = '';
    
    const info = document.getElementById('paginationInfo');
    if (info) info.textContent = 'Aucun résultat';
}

/* ============================================
   FILTRAGE ET TRI
   ============================================ */

function applyFilters() {
    let filtered = [...auditState.logs];
    
    // Filtre par recherche
    if (auditState.filters.search) {
        const term = auditState.filters.search.toLowerCase();
        filtered = filtered.filter(log => 
            log.user_name.toLowerCase().includes(term) ||
            log.description.toLowerCase().includes(term) ||
            log.ip_address.includes(term)
        );
    }
    
    // Filtre par action
    if (auditState.filters.action) {
        filtered = filtered.filter(log => log.action_type === auditState.filters.action);
    }
    
    // Filtre par utilisateur
    if (auditState.filters.user) {
        filtered = filtered.filter(log => log.user_id === parseInt(auditState.filters.user));
    }
    
    // Filtre par statut
    if (auditState.filters.status) {
        filtered = filtered.filter(log => log.status === auditState.filters.status);
    }
    
    // Filtre par date de début
    if (auditState.filters.dateFrom) {
        const fromDate = new Date(auditState.filters.dateFrom);
        filtered = filtered.filter(log => new Date(log.timestamp) >= fromDate);
    }
    
    // Filtre par date de fin
    if (auditState.filters.dateTo) {
        const toDate = new Date(auditState.filters.dateTo);
        toDate.setHours(23, 59, 59, 999);
        filtered = filtered.filter(log => new Date(log.timestamp) <= toDate);
    }
    
    // Tri
    filtered.sort((a, b) => {
        let aVal = a[auditState.sortColumn];
        let bVal = b[auditState.sortColumn];
        
        if (auditState.sortColumn === 'timestamp') {
            aVal = new Date(aVal).getTime();
            bVal = new Date(bVal).getTime();
        }
        
        if (auditState.sortDirection === 'asc') {
            return aVal > bVal ? 1 : -1;
        } else {
            return aVal < bVal ? 1 : -1;
        }
    });
    
    auditState.filteredLogs = filtered;
    auditState.currentPage = 1;
}

function handleSearch(input) {
    auditState.filters.search = input.value;
    applyFilters();
    renderTable();
}

function handleActionFilter(select) {
    auditState.filters.action = select.value;
    applyFilters();
    renderTable();
}

function handleUserFilter(select) {
    auditState.filters.user = select.value;
    applyFilters();
    renderTable();
}

function handleStatusFilter(select) {
    auditState.filters.status = select.value;
    applyFilters();
    renderTable();
}

function handleDateFromFilter(input) {
    auditState.filters.dateFrom = input.value;
    applyFilters();
    renderTable();
}

function handleDateToFilter(input) {
    auditState.filters.dateTo = input.value;
    applyFilters();
    renderTable();
}

function resetFilters() {
    // Reset form
    document.getElementById('auditFiltersForm')?.reset();
    
    // Reset state
    auditState.filters = {
        search: '',
        action: '',
        user: '',
        status: '',
        dateFrom: '',
        dateTo: ''
    };
    
    applyFilters();
    renderTable();
    
    showToast('Filtres réinitialisés', 'info');
}

function sortTable(column) {
    if (auditState.sortColumn === column) {
        auditState.sortDirection = auditState.sortDirection === 'asc' ? 'desc' : 'asc';
    } else {
        auditState.sortColumn = column;
        auditState.sortDirection = 'desc';
    }
    
    // Update UI
    document.querySelectorAll('.audit-table th.sortable').forEach(th => {
        th.classList.remove('sort-asc', 'sort-desc');
    });
    
    const th = document.querySelector(`[onclick="sortTable('${column}')"]`);
    if (th) {
        th.classList.add(`sort-${auditState.sortDirection}`);
    }
    
    applyFilters();
    renderTable();
}

/* ============================================
   PAGINATION
   ============================================ */

function changePage(page) {
    const totalPages = Math.ceil(auditState.filteredLogs.length / auditState.itemsPerPage);
    
    if (page < 1 || page > totalPages) return;
    
    auditState.currentPage = page;
    renderTable();
    
    // Scroll to top
    window.scrollTo({ top: 0, behavior: 'smooth' });
}

/* ============================================
   DÉTAIL DU LOG
   ============================================ */

function viewLogDetail(logId) {
    const log = auditState.logs.find(l => l.id === logId);
    if (!log) return;
    
    const modal = document.getElementById('logDetailModal');
    if (!modal) return;
    
    // Populate modal
    document.getElementById('logDetailTimestamp').textContent = formatDateTime(new Date(log.timestamp));
    document.getElementById('logDetailUser').textContent = log.user_name;
    document.getElementById('logDetailRole').textContent = log.user_role;
    document.getElementById('logDetailAction').innerHTML = `
        <span class="log-action ${log.action_type}">
            <i class="fas fa-${getActionIcon(log.action_type)}"></i>
            ${escapeHtml(log.action_type)}
        </span>
    `;
    document.getElementById('logDetailDescription').textContent = log.description;
    document.getElementById('logDetailIP').textContent = log.ip_address;
    document.getElementById('logDetailStatus').innerHTML = `
        <span class="log-status ${log.status}">
            <i class="fas fa-${log.status === 'success' ? 'check-circle' : 'times-circle'}"></i>
            ${escapeHtml(log.status)}
        </span>
    `;
    
    // Show changes if available
    const changesContainer = document.getElementById('logDetailChanges');
    if (log.changes && changesContainer) {
        changesContainer.innerHTML = renderChanges(log.changes);
        changesContainer.parentElement.style.display = 'block';
    } else if (changesContainer) {
        changesContainer.parentElement.style.display = 'none';
    }
    
    modal.classList.add('active');
}

function renderChanges(changes) {
    if (!changes || Object.keys(changes).length === 0) {
        return '<p style="color: var(--text-muted);">Aucune modification enregistrée</p>';
    }
    
    return Object.entries(changes).map(([field, values]) => `
        <div class="log-change-item">
            <div class="log-change-field">${escapeHtml(field)}</div>
            <div class="log-change-values">
                <span class="log-change-old">${escapeHtml(String(values.old))}</span>
                <i class="fas fa-arrow-right"></i>
                <span class="log-change-new">${escapeHtml(String(values.new))}</span>
            </div>
        </div>
    `).join('');
}

function closeLogDetailModal() {
    const modal = document.getElementById('logDetailModal');
    if (modal) {
        modal.classList.remove('active');
    }
}

/* ============================================
   EXPORT
   ============================================ */

async function exportAudit(format) {
    try {
        showLoader();
        
        const response = await fetch(`/user-manager/api/audit.php?export=${format}`);
        if (!response.ok) throw new Error('Export failed');
        
        const blob = await response.blob();
        const url = window.URL.createObjectURL(blob);
        const a = document.createElement('a');
        a.href = url;
        a.download = `audit_${Date.now()}.${format}`;
        document.body.appendChild(a);
        a.click();
        document.body.removeChild(a);
        window.URL.revokeObjectURL(url);
        
        showToast('Export réussi', 'success');
    } catch (error) {
        console.error('❌ Error exporting audit:', error);
        showToast('Erreur lors de l\'export', 'error');
    } finally {
        hideLoader();
    }
}

/* ============================================
   UTILITAIRES
   ============================================ */

function initializeDateFilters() {
    const today = new Date();
    const lastWeek = new Date(today);
    lastWeek.setDate(lastWeek.getDate() - 7);
    
    const dateFromInput = document.getElementById('dateFrom');
    const dateToInput = document.getElementById('dateTo');
    
    if (dateFromInput) {
        dateFromInput.value = formatDateInput(lastWeek);
    }
    
    if (dateToInput) {
        dateToInput.value = formatDateInput(today);
    }
}

function formatDate(date) {
    const options = { year: 'numeric', month: 'short', day: 'numeric' };
    return date.toLocaleDateString('fr-FR', options);
}

function formatTime(date) {
    return date.toLocaleTimeString('fr-FR', { hour: '2-digit', minute: '2-digit' });
}

function formatDateTime(date) {
    return date.toLocaleString('fr-FR', {
        year: 'numeric',
        month: 'long',
        day: 'numeric',
        hour: '2-digit',
        minute: '2-digit',
        second: '2-digit'
    });
}

function formatDateInput(date) {
    return date.toISOString().split('T')[0];
}

function getActionIcon(action) {
    const icons = {
        'create': 'plus-circle',
        'update': 'edit',
        'delete': 'trash',
        'login': 'sign-in-alt',
        'logout': 'sign-out-alt',
        'view': 'eye'
    };
    return icons[action] || 'circle';
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
    document.getElementById('logDetailModal')?.addEventListener('click', function(e) {
        if (e.target === this) {
            closeLogDetailModal();
        }
    });
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
