/**
 * Bolt.DIY User Manager - Dashboard JavaScript
 * Version: 1.0
 * Date: 19 novembre 2025
 */

'use strict';

// ============================================
// CONFIGURATION DASHBOARD
// ============================================

const DashboardConfig = {
    refreshInterval: 60000, // 1 minute
    animationDuration: 750,
    chartColors: {
        primary: '#4776ff',
        success: '#32ffe2',
        warning: '#fff748',
        danger: '#fd65ff',
        neutral: '#9c56ff',
        gradient: {
            primary: ['rgba(71, 118, 255, 0.8)', 'rgba(71, 118, 255, 0.1)'],
            success: ['rgba(50, 255, 226, 0.8)', 'rgba(50, 255, 226, 0.1)'],
        }
    }
};

// ============================================
// CLASSE DASHBOARD
// ============================================

class Dashboard {
    constructor() {
        this.charts = {};
        this.currentPeriod = '7days';
        this.init();
    }

    async init() {
        console.log('📊 Initialisation du Dashboard...');
        
        // Charger les données
        await this.loadDashboardData();
        
        // Initialiser les graphiques
        this.initCharts();
        
        // Initialiser les contrôles
        this.initControls();
        
        // Auto-refresh
        this.startAutoRefresh();
        
        console.log('✅ Dashboard initialisé');
    }

    // ============================================
    // CHARGEMENT DES DONNÉES
    // ============================================

    async loadDashboardData() {
        try {
            const response = await fetch('/user-manager/api/dashboard.php', {
                method: 'GET',
                headers: {
                    'Content-Type': 'application/json',
                }
            });

            if (!response.ok) {
                throw new Error('Erreur de chargement des données');
            }

            this.data = await response.json();
            this.updateStats();
            this.updateActivity();
            
        } catch (error) {
            console.error('Erreur:', error);
            UserManager.Toast.error('Erreur de chargement des données du dashboard');
        }
    }

    // ============================================
    // MISE À JOUR DES STATISTIQUES
    // ============================================

    updateStats() {
        if (!this.data || !this.data.stats) return;

        const stats = this.data.stats;

        // Mettre à jour les valeurs avec animation
        this.animateValue('total-users', 0, stats.totalUsers, 1000);
        this.animateValue('active-users', 0, stats.activeUsers, 1000);
        this.animateValue('total-groups', 0, stats.totalGroups, 1000);
        this.animateValue('total-permissions', 0, stats.totalPermissions, 1000);

        // Mettre à jour les tendances
        this.updateTrend('users-trend', stats.usersTrend);
        this.updateTrend('active-trend', stats.activeTrend);
    }

    animateValue(elementId, start, end, duration) {
        const element = document.getElementById(elementId);
        if (!element) return;

        const range = end - start;
        const increment = range / (duration / 16);
        let current = start;

        const timer = setInterval(() => {
            current += increment;
            if ((increment > 0 && current >= end) || (increment < 0 && current <= end)) {
                current = end;
                clearInterval(timer);
            }
            element.textContent = Math.floor(current);
        }, 16);
    }

    updateTrend(elementId, value) {
        const element = document.getElementById(elementId);
        if (!element) return;

        element.className = 'stat-card-trend';
        
        if (value > 0) {
            element.classList.add('up');
            element.innerHTML = `<i class="fas fa-arrow-up"></i> +${value}%`;
        } else if (value < 0) {
            element.classList.add('down');
            element.innerHTML = `<i class="fas fa-arrow-down"></i> ${value}%`;
        } else {
            element.classList.add('neutral');
            element.innerHTML = `<i class="fas fa-minus"></i> ${value}%`;
        }
    }

    // ============================================
    // GRAPHIQUES CHART.JS
    // ============================================

    initCharts() {
        this.initActivityChart();
        this.initRoleChart();
    }

    initActivityChart() {
        const canvas = document.getElementById('activityChart');
        if (!canvas) return;

        const ctx = canvas.getContext('2d');
        
        // Gradient
        const gradient = ctx.createLinearGradient(0, 0, 0, 300);
        gradient.addColorStop(0, DashboardConfig.chartColors.gradient.primary[0]);
        gradient.addColorStop(1, DashboardConfig.chartColors.gradient.primary[1]);

        this.charts.activity = new Chart(ctx, {
            type: 'line',
            data: {
                labels: this.data?.activity?.labels || [],
                datasets: [{
                    label: 'Connexions',
                    data: this.data?.activity?.data || [],
                    backgroundColor: gradient,
                    borderColor: DashboardConfig.chartColors.primary,
                    borderWidth: 3,
                    fill: true,
                    tension: 0.4,
                    pointBackgroundColor: DashboardConfig.chartColors.primary,
                    pointBorderColor: '#fff',
                    pointBorderWidth: 2,
                    pointRadius: 4,
                    pointHoverRadius: 6,
                }]
            },
            options: {
                responsive: true,
                maintainAspectRatio: false,
                plugins: {
                    legend: {
                        display: false
                    },
                    tooltip: {
                        backgroundColor: 'rgba(26, 32, 53, 0.95)',
                        titleColor: '#fff',
                        bodyColor: '#e0e0e0',
                        borderColor: 'rgba(255, 255, 255, 0.1)',
                        borderWidth: 1,
                        padding: 12,
                        displayColors: false,
                        callbacks: {
                            label: function(context) {
                                return context.parsed.y + ' connexions';
                            }
                        }
                    }
                },
                scales: {
                    y: {
                        beginAtZero: true,
                        ticks: {
                            color: '#a0a0a0',
                            font: {
                                size: 12
                            }
                        },
                        grid: {
                            color: 'rgba(255, 255, 255, 0.05)',
                            drawBorder: false
                        }
                    },
                    x: {
                        ticks: {
                            color: '#a0a0a0',
                            font: {
                                size: 12
                            }
                        },
                        grid: {
                            display: false
                        }
                    }
                },
                animation: {
                    duration: DashboardConfig.animationDuration
                }
            }
        });
    }

    initRoleChart() {
        const canvas = document.getElementById('roleChart');
        if (!canvas) return;

        const ctx = canvas.getContext('2d');

        this.charts.role = new Chart(ctx, {
            type: 'doughnut',
            data: {
                labels: this.data?.roles?.labels || [],
                datasets: [{
                    data: this.data?.roles?.data || [],
                    backgroundColor: [
                        DashboardConfig.chartColors.primary,
                        DashboardConfig.chartColors.success,
                        DashboardConfig.chartColors.warning,
                        DashboardConfig.chartColors.danger,
                        DashboardConfig.chartColors.neutral
                    ],
                    borderWidth: 0,
                    hoverOffset: 10
                }]
            },
            options: {
                responsive: true,
                maintainAspectRatio: false,
                plugins: {
                    legend: {
                        position: 'bottom',
                        labels: {
                            color: '#e0e0e0',
                            padding: 15,
                            font: {
                                size: 13
                            },
                            usePointStyle: true,
                            pointStyle: 'circle'
                        }
                    },
                    tooltip: {
                        backgroundColor: 'rgba(26, 32, 53, 0.95)',
                        titleColor: '#fff',
                        bodyColor: '#e0e0e0',
                        borderColor: 'rgba(255, 255, 255, 0.1)',
                        borderWidth: 1,
                        padding: 12,
                        callbacks: {
                            label: function(context) {
                                const label = context.label || '';
                                const value = context.parsed || 0;
                                const total = context.dataset.data.reduce((a, b) => a + b, 0);
                                const percentage = ((value / total) * 100).toFixed(1);
                                return `${label}: ${value} (${percentage}%)`;
                            }
                        }
                    }
                },
                animation: {
                    duration: DashboardConfig.animationDuration
                }
            }
        });
    }

    // ============================================
    // ACTIVITÉ RÉCENTE
    // ============================================

    updateActivity() {
        if (!this.data || !this.data.recentActivity) return;

        const container = document.getElementById('activity-feed');
        if (!container) return;

        container.innerHTML = '';

        this.data.recentActivity.forEach((item, index) => {
            const activityItem = this.createActivityItem(item);
            activityItem.style.animationDelay = `${index * 0.1}s`;
            container.appendChild(activityItem);
        });
    }

    createActivityItem(item) {
        const div = document.createElement('div');
        div.className = 'activity-item fade-in';

        const iconClass = this.getActivityIconClass(item.type);
        
        div.innerHTML = `
            <div class="activity-icon ${item.type}">
                <i class="fas ${iconClass}"></i>
            </div>
            <div class="activity-content">
                <div class="activity-text">
                    <strong>${item.user}</strong> ${item.action}
                </div>
                <div class="activity-time">
                    <i class="far fa-clock"></i> ${item.time}
                </div>
            </div>
        `;

        return div;
    }

    getActivityIconClass(type) {
        const icons = {
            login: 'fa-sign-in-alt',
            create: 'fa-plus-circle',
            update: 'fa-edit',
            delete: 'fa-trash-alt',
            settings: 'fa-cog'
        };
        return icons[type] || 'fa-info-circle';
    }

    // ============================================
    // CONTRÔLES
    // ============================================

    initControls() {
        // Boutons de période pour le graphique d'activité
        const periodButtons = document.querySelectorAll('.chart-control-btn[data-period]');
        periodButtons.forEach(btn => {
            btn.addEventListener('click', (e) => {
                this.changePeriod(e.target.dataset.period);
            });
        });

        // Bouton de rafraîchissement
        const refreshBtn = document.getElementById('refresh-dashboard');
        if (refreshBtn) {
            refreshBtn.addEventListener('click', () => {
                this.refresh();
            });
        }
    }

    async changePeriod(period) {
        this.currentPeriod = period;

        // Mettre à jour l'UI
        document.querySelectorAll('.chart-control-btn[data-period]').forEach(btn => {
            btn.classList.remove('active');
        });
        document.querySelector(`[data-period="${period}"]`)?.classList.add('active');

        // Recharger les données avec la nouvelle période
        await this.loadActivityData(period);
    }

    async loadActivityData(period) {
        try {
            const response = await fetch(`/user-manager/api/dashboard.php?period=${period}`);
            const data = await response.json();

            // Mettre à jour le graphique
            if (this.charts.activity && data.activity) {
                this.charts.activity.data.labels = data.activity.labels;
                this.charts.activity.data.datasets[0].data = data.activity.data;
                this.charts.activity.update();
            }
        } catch (error) {
            console.error('Erreur:', error);
        }
    }

    // ============================================
    // RAFRAÎCHISSEMENT
    // ============================================

    async refresh() {
        const refreshBtn = document.getElementById('refresh-dashboard');
        if (refreshBtn) {
            refreshBtn.disabled = true;
            refreshBtn.innerHTML = '<i class="fas fa-sync fa-spin"></i> Rafraîchissement...';
        }

        await this.loadDashboardData();

        if (refreshBtn) {
            refreshBtn.disabled = false;
            refreshBtn.innerHTML = '<i class="fas fa-sync"></i> Rafraîchir';
        }

        UserManager.Toast.success('Dashboard mis à jour');
    }

    startAutoRefresh() {
        setInterval(() => {
            console.log('🔄 Auto-refresh du dashboard');
            this.loadDashboardData();
        }, DashboardConfig.refreshInterval);
    }

    // ============================================
    // DESTRUCTION
    // ============================================

    destroy() {
        Object.values(this.charts).forEach(chart => {
            if (chart) chart.destroy();
        });
    }
}

// ============================================
// INITIALISATION
// ============================================

let dashboardInstance = null;

document.addEventListener('DOMContentLoaded', function() {
    // Vérifier si on est sur la page dashboard
    if (document.getElementById('activityChart') || document.getElementById('roleChart')) {
        dashboardInstance = new Dashboard();
    }
});

// Export pour utilisation globale
window.Dashboard = Dashboard;
