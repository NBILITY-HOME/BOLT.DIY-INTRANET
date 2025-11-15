/**
 * BOLT.DIY USER MANAGER v2.0 - DASHBOARD MODULE
 * © Copyright Nbility 2025
 */

let statsInterval = null;

// Initialisation
document.addEventListener('DOMContentLoaded', () => {
    loadDashboardStats();
    loadRecentActivity();
    initRefreshInterval();
    initEventListeners();
});

// Event listeners
function initEventListeners() {
    document.getElementById('btnRefreshStats')?.addEventListener('click', () => {
        loadDashboardStats();
        loadRecentActivity();
    });
}

// Charger les statistiques du dashboard
async function loadDashboardStats() {
    try {
        const response = await API.get('/dashboard/stats');
        const stats = response.data;

        updateStatsCards(stats);
        updateCharts(stats);
        updateSystemInfo(stats);

    } catch (error) {
        console.error('Erreur chargement stats:', error);
        handleApiError(error);
    }
}

// Mettre à jour les cartes de statistiques
function updateStatsCards(stats) {
    // Utilisateurs
    const userCount = document.getElementById('statUserCount');
    const userChange = document.getElementById('statUserChange');
    if (userCount) userCount.textContent = stats.users?.total || 0;
    if (userChange) {
        const change = stats.users?.change || 0;
        userChange.textContent = (change >= 0 ? '+' : '') + change;
        userChange.className = 'stat-change ' + (change >= 0 ? 'positive' : 'negative');
    }

    // Groupes
    const groupCount = document.getElementById('statGroupCount');
    const groupChange = document.getElementById('statGroupChange');
    if (groupCount) groupCount.textContent = stats.groups?.total || 0;
    if (groupChange) {
        const change = stats.groups?.change || 0;
        groupChange.textContent = (change >= 0 ? '+' : '') + change;
        groupChange.className = 'stat-change ' + (change >= 0 ? 'positive' : 'negative');
    }

    // Permissions
    const permissionCount = document.getElementById('statPermissionCount');
    if (permissionCount) permissionCount.textContent = stats.permissions?.total || 0;

    // Sessions actives
    const sessionCount = document.getElementById('statSessionCount');
    if (sessionCount) sessionCount.textContent = stats.sessions?.active || 0;

    // Utilisateurs actifs (dernières 24h)
    const activeUsers = document.getElementById('statActiveUsers');
    if (activeUsers) activeUsers.textContent = stats.users?.active_24h || 0;

    // Logs d'audit (dernières 24h)
    const auditLogs = document.getElementById('statAuditLogs');
    if (auditLogs) auditLogs.textContent = stats.audit?.today || 0;
}

// Mettre à jour les graphiques
function updateCharts(stats) {
    // Graphique répartition des rôles
    if (stats.users?.by_role) {
        renderRoleChart(stats.users.by_role);
    }

    // Graphique statut des utilisateurs
    if (stats.users?.by_status) {
        renderStatusChart(stats.users.by_status);
    }

    // Graphique activité (7 derniers jours)
    if (stats.activity?.last_7_days) {
        renderActivityChart(stats.activity.last_7_days);
    }
}

// Graphique répartition des rôles (Pie Chart)
function renderRoleChart(data) {
    const canvas = document.getElementById('roleChart');
    if (!canvas) return;

    const ctx = canvas.getContext('2d');
    const colors = {
        'superadmin': '#ef4444',
        'admin': '#4f46e5',
        'user': '#10b981'
    };

    const total = Object.values(data).reduce((sum, val) => sum + val, 0);
    let currentAngle = -Math.PI / 2;

    // Effacer le canvas
    ctx.clearRect(0, 0, canvas.width, canvas.height);

    // Dessiner les parts
    Object.entries(data).forEach(([role, count]) => {
        const sliceAngle = (count / total) * 2 * Math.PI;

        ctx.beginPath();
        ctx.fillStyle = colors[role] || '#6b7280';
        ctx.moveTo(100, 100);
        ctx.arc(100, 100, 80, currentAngle, currentAngle + sliceAngle);
        ctx.closePath();
        ctx.fill();

        currentAngle += sliceAngle;
    });

    // Légende
    const legend = document.getElementById('roleLegend');
    if (legend) {
        legend.innerHTML = Object.entries(data).map(([role, count]) => `
            <div class="legend-item">
                <span class="legend-color" style="background: ${colors[role] || '#6b7280'}"></span>
                <span>${capitalize(role)}: ${count}</span>
            </div>
        `).join('');
    }
}

// Graphique statut des utilisateurs (Bar Chart)
function renderStatusChart(data) {
    const canvas = document.getElementById('statusChart');
    if (!canvas) return;

    const ctx = canvas.getContext('2d');
    const colors = {
        'active': '#10b981',
        'inactive': '#6b7280',
        'suspended': '#f59e0b'
    };

    const maxValue = Math.max(...Object.values(data));
    const barWidth = 60;
    const spacing = 40;
    const chartHeight = 150;

    // Effacer le canvas
    ctx.clearRect(0, 0, canvas.width, canvas.height);

    // Dessiner les barres
    Object.entries(data).forEach(([status, count], index) => {
        const barHeight = (count / maxValue) * chartHeight;
        const x = index * (barWidth + spacing) + 20;
        const y = chartHeight - barHeight;

        ctx.fillStyle = colors[status] || '#6b7280';
        ctx.fillRect(x, y, barWidth, barHeight);

        // Valeur
        ctx.fillStyle = '#1f2937';
        ctx.font = '14px sans-serif';
        ctx.textAlign = 'center';
        ctx.fillText(count, x + barWidth / 2, y - 5);

        // Label
        ctx.fillText(capitalize(status), x + barWidth / 2, chartHeight + 20);
    });
}

// Graphique activité (Line Chart)
function renderActivityChart(data) {
    const canvas = document.getElementById('activityChart');
    if (!canvas) return;

    const ctx = canvas.getContext('2d');
    const chartWidth = canvas.width - 40;
    const chartHeight = canvas.height - 40;
    const maxValue = Math.max(...data.map(d => d.count), 1);

    // Effacer le canvas
    ctx.clearRect(0, 0, canvas.width, canvas.height);

    // Dessiner les axes
    ctx.strokeStyle = '#e5e7eb';
    ctx.beginPath();
    ctx.moveTo(30, 20);
    ctx.lineTo(30, chartHeight + 20);
    ctx.lineTo(chartWidth + 30, chartHeight + 20);
    ctx.stroke();

    // Dessiner la courbe
    ctx.strokeStyle = '#4f46e5';
    ctx.lineWidth = 2;
    ctx.beginPath();

    data.forEach((point, index) => {
        const x = 30 + (index / (data.length - 1)) * chartWidth;
        const y = 20 + chartHeight - (point.count / maxValue) * chartHeight;

        if (index === 0) {
            ctx.moveTo(x, y);
        } else {
            ctx.lineTo(x, y);
        }

        // Points
        ctx.fillStyle = '#4f46e5';
        ctx.fillRect(x - 3, y - 3, 6, 6);
    });

    ctx.stroke();

    // Labels
    ctx.fillStyle = '#6b7280';
    ctx.font = '10px sans-serif';
    ctx.textAlign = 'center';
    data.forEach((point, index) => {
        if (index % 2 === 0) {
            const x = 30 + (index / (data.length - 1)) * chartWidth;
            const date = new Date(point.date);
            ctx.fillText(date.getDate() + '/' + (date.getMonth() + 1), x, chartHeight + 35);
        }
    });
}

// Mettre à jour les infos système
function updateSystemInfo(stats) {
    const systemInfo = document.getElementById('systemInfo');
    if (!systemInfo) return;

    systemInfo.innerHTML = `
        <div class="info-item">
            <span class="info-label">Version:</span>
            <span class="info-value">${stats.system?.version || '2.0'}</span>
        </div>
        <div class="info-item">
            <span class="info-label">Base de données:</span>
            <span class="info-value">${stats.system?.db_size || '-'}</span>
        </div>
        <div class="info-item">
            <span class="info-label">Dernier backup:</span>
            <span class="info-value">${stats.system?.last_backup ? formatDateRelative(stats.system.last_backup) : '-'}</span>
        </div>
        <div class="info-item">
            <span class="info-label">Uptime:</span>
            <span class="info-value">${stats.system?.uptime || '-'}</span>
        </div>
    `;
}

// Charger l'activité récente
async function loadRecentActivity() {
    try {
        const response = await API.get('/dashboard/recent-activity', { limit: 10 });
        renderRecentActivity(response.data);
    } catch (error) {
        console.error('Erreur chargement activité:', error);
    }
}

// Afficher l'activité récente
function renderRecentActivity(activities) {
    const container = document.getElementById('recentActivity');
    if (!container) return;

    if (!activities || activities.length === 0) {
        container.innerHTML = '<p class="text-muted text-center">Aucune activité récente</p>';
        return;
    }

    container.innerHTML = activities.map(activity => `
        <div class="activity-item">
            <div class="activity-icon">
                <i class="fas ${getActivityIcon(activity.action)}"></i>
            </div>
            <div class="activity-content">
                <div class="activity-title">${activity.description}</div>
                <div class="activity-meta">
                    <span>${activity.user_username || 'Système'}</span>
                    <span>•</span>
                    <span>${formatDateRelative(activity.created_at)}</span>
                </div>
            </div>
        </div>
    `).join('');
}

// Auto-refresh
function initRefreshInterval() {
    // Rafraîchir toutes les 30 secondes
    statsInterval = setInterval(() => {
        loadDashboardStats();
        loadRecentActivity();
    }, 30000);
}

// Cleanup au déchargement
window.addEventListener('beforeunload', () => {
    if (statsInterval) clearInterval(statsInterval);
});

// Helpers
function getActivityIcon(action) {
    const icons = {
        'login': 'fa-sign-in-alt',
        'logout': 'fa-sign-out-alt',
        'create': 'fa-plus-circle',
        'update': 'fa-edit',
        'delete': 'fa-trash',
        'view': 'fa-eye'
    };
    return icons[action.toLowerCase()] || 'fa-info-circle';
}

function capitalize(str) {
    if (!str) return '';
    return str.charAt(0).toUpperCase() + str.slice(1).toLowerCase();
}

function formatDateRelative(dateString) {
    if (!dateString) return '-';

    const date = new Date(dateString);
    const now = new Date();
    const diff = now - date;

    const seconds = Math.floor(diff / 1000);
    const minutes = Math.floor(seconds / 60);
    const hours = Math.floor(minutes / 60);
    const days = Math.floor(hours / 24);

    if (days > 7) return date.toLocaleDateString('fr-FR');
    if (days > 0) return `Il y a ${days} jour${days > 1 ? 's' : ''}`;
    if (hours > 0) return `Il y a ${hours} heure${hours > 1 ? 's' : ''}`;
    if (minutes > 0) return `Il y a ${minutes} minute${minutes > 1 ? 's' : ''}`;
    return 'À l\'instant';
}
