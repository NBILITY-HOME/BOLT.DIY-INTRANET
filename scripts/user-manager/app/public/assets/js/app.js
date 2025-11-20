/**
 * Bolt.DIY User Manager - JavaScript Principal
 * Version: 1.0
 * Date: 18 novembre 2025
 */

'use strict';

// ============================================
// 1. CONFIGURATION GLOBALE
// ============================================

const CONFIG = {
    baseUrl: '/user-manager',
    apiUrl: '/user-manager/api',
    animationDuration: 300,
    toastDuration: 3000,
    debounceDelay: 300
};

// ============================================
// 2. INITIALISATION
// ============================================

document.addEventListener('DOMContentLoaded', function() {
    initializeApp();
});

function initializeApp() {
    // Initialiser le fond animé
    initializeAnimatedBackground();
    
    // Initialiser le menu responsive
    initializeMobileMenu();
    
    // Initialiser les composants
    initializeComponents();
    
    console.log('✅ Bolt.DIY User Manager initialized');
}

// ============================================
// 3. FOND ANIMÉ
// ============================================

function initializeAnimatedBackground() {
    const background = document.querySelector('.animated-background');
    if (!background) return;
    
    // Ajouter les points lumineux supplémentaires
    for (let i = 0; i < 20; i++) {
        const dot = document.createElement('div');
        dot.className = 'bg-dot';
        dot.style.top = Math.random() * 100 + '%';
        dot.style.left = Math.random() * 100 + '%';
        dot.style.animationDelay = Math.random() * 3 + 's';
        background.appendChild(dot);
    }
}

// ============================================
// 4. MENU RESPONSIVE
// ============================================

function initializeMobileMenu() {
    const menuToggle = document.querySelector('.mobile-menu-toggle');
    const sidebar = document.querySelector('.sidebar');
    const overlay = document.querySelector('.sidebar-overlay');
    
    if (!menuToggle || !sidebar) return;
    
    // Toggle menu mobile
    menuToggle.addEventListener('click', function() {
        sidebar.classList.toggle('open');
        if (overlay) {
            overlay.classList.toggle('active');
        }
    });
    
    // Fermer avec overlay
    if (overlay) {
        overlay.addEventListener('click', function() {
            sidebar.classList.remove('open');
            overlay.classList.remove('active');
        });
    }
    
    // Fermer automatiquement après sélection (mobile)
    if (window.innerWidth < 768) {
        const navItems = sidebar.querySelectorAll('.nav-item');
        navItems.forEach(item => {
            item.addEventListener('click', function() {
                setTimeout(() => {
                    sidebar.classList.remove('open');
                    if (overlay) {
                        overlay.classList.remove('active');
                    }
                }, 150);
            });
        });
    }
}

// ============================================
// 5. COMPOSANTS UI
// ============================================

function initializeComponents() {
    // Initialiser les tooltips
    initializeTooltips();
    
    // Initialiser les confirmations
    initializeConfirmations();
    
    // Initialiser le système de recherche
    initializeSearch();
}

// Tooltips
function initializeTooltips() {
    const tooltipElements = document.querySelectorAll('[data-tooltip]');
    tooltipElements.forEach(element => {
        element.addEventListener('mouseenter', showTooltip);
        element.addEventListener('mouseleave', hideTooltip);
    });
}

function showTooltip(event) {
    const text = event.target.getAttribute('data-tooltip');
    const tooltip = document.createElement('div');
    tooltip.className = 'tooltip';
    tooltip.textContent = text;
    tooltip.style.position = 'absolute';
    tooltip.style.background = 'rgba(0, 0, 0, 0.9)';
    tooltip.style.color = 'white';
    tooltip.style.padding = '8px 12px';
    tooltip.style.borderRadius = '8px';
    tooltip.style.fontSize = '12px';
    tooltip.style.zIndex = '9999';
    tooltip.style.pointerEvents = 'none';
    
    document.body.appendChild(tooltip);
    
    const rect = event.target.getBoundingClientRect();
    tooltip.style.top = (rect.top - tooltip.offsetHeight - 8) + 'px';
    tooltip.style.left = (rect.left + (rect.width / 2) - (tooltip.offsetWidth / 2)) + 'px';
}

function hideTooltip() {
    const tooltip = document.querySelector('.tooltip');
    if (tooltip) {
        tooltip.remove();
    }
}

// Confirmations
function initializeConfirmations() {
    const confirmButtons = document.querySelectorAll('[data-confirm]');
    confirmButtons.forEach(button => {
        button.addEventListener('click', function(event) {
            const message = this.getAttribute('data-confirm');
            if (!confirm(message)) {
                event.preventDefault();
                return false;
            }
        });
    });
}

// Recherche avec debounce
function initializeSearch() {
    const searchInputs = document.querySelectorAll('.search-bar input');
    searchInputs.forEach(input => {
        input.addEventListener('input', debounce(function(event) {
            const query = event.target.value;
            console.log('Recherche:', query);
            // La logique de recherche sera implémentée selon la page
        }, CONFIG.debounceDelay));
    });
}

// ============================================
// 6. SYSTÈME DE NOTIFICATIONS (TOAST)
// ============================================

const Toast = {
    container: null,
    
    init() {
        if (!this.container) {
            this.container = document.createElement('div');
            this.container.id = 'toast-container';
            this.container.style.position = 'fixed';
            this.container.style.top = '20px';
            this.container.style.right = '20px';
            this.container.style.zIndex = '10000';
            this.container.style.display = 'flex';
            this.container.style.flexDirection = 'column';
            this.container.style.gap = '10px';
            document.body.appendChild(this.container);
        }
    },
    
    show(message, type = 'info', duration = CONFIG.toastDuration) {
        this.init();
        
        const toast = document.createElement('div');
        toast.className = 'toast toast-' + type;
        toast.style.background = 'rgba(26, 32, 53, 0.95)';
        toast.style.backdropFilter = 'blur(20px)';
        toast.style.padding = '16px 20px';
        toast.style.borderRadius = '12px';
        toast.style.border = '1px solid rgba(255, 255, 255, 0.1)';
        toast.style.color = 'white';
        toast.style.fontSize = '14px';
        toast.style.minWidth = '300px';
        toast.style.maxWidth = '500px';
        toast.style.boxShadow = '0 8px 32px rgba(0, 0, 0, 0.4)';
        toast.style.animation = 'slideInRight 0.3s ease';
        toast.style.display = 'flex';
        toast.style.alignItems = 'center';
        toast.style.gap = '12px';
        
        // Icône selon le type
        const icons = {
            success: '✓',
            error: '✕',
            warning: '⚠',
            info: 'ℹ'
        };
        
        const colors = {
            success: '#32ffe2',
            error: '#fd65ff',
            warning: '#fff748',
            info: '#4776ff'
        };
        
        const icon = document.createElement('span');
        icon.textContent = icons[type] || icons.info;
        icon.style.fontSize = '18px';
        icon.style.color = colors[type] || colors.info;
        
        const text = document.createElement('span');
        text.textContent = message;
        text.style.flex = '1';
        
        toast.appendChild(icon);
        toast.appendChild(text);
        this.container.appendChild(toast);
        
        // Auto-suppression
        setTimeout(() => {
            toast.style.animation = 'slideOutRight 0.3s ease';
            setTimeout(() => {
                toast.remove();
            }, 300);
        }, duration);
        
        return toast;
    },
    
    success(message, duration) {
        return this.show(message, 'success', duration);
    },
    
    error(message, duration) {
        return this.show(message, 'error', duration);
    },
    
    warning(message, duration) {
        return this.show(message, 'warning', duration);
    },
    
    info(message, duration) {
        return this.show(message, 'info', duration);
    }
};

// Ajouter les animations CSS pour les toasts
const toastStyles = document.createElement('style');
toastStyles.textContent = `
@keyframes slideInRight {
    from {
        transform: translateX(400px);
        opacity: 0;
    }
    to {
        transform: translateX(0);
        opacity: 1;
    }
}
@keyframes slideOutRight {
    from {
        transform: translateX(0);
        opacity: 1;
    }
    to {
        transform: translateX(400px);
        opacity: 0;
    }
}
`;
document.head.appendChild(toastStyles);

// ============================================
// 7. UTILITAIRES
// ============================================

// Debounce
function debounce(func, wait) {
    let timeout;
    return function executedFunction(...args) {
        const later = () => {
            clearTimeout(timeout);
            func(...args);
        };
        clearTimeout(timeout);
        timeout = setTimeout(later, wait);
    };
}

// Throttle
function throttle(func, limit) {
    let inThrottle;
    return function(...args) {
        if (!inThrottle) {
            func.apply(this, args);
            inThrottle = true;
            setTimeout(() => inThrottle = false, limit);
        }
    };
}

// Format date
function formatDate(date, format = 'DD/MM/YYYY HH:mm') {
    const d = new Date(date);
    const day = String(d.getDate()).padStart(2, '0');
    const month = String(d.getMonth() + 1).padStart(2, '0');
    const year = d.getFullYear();
    const hours = String(d.getHours()).padStart(2, '0');
    const minutes = String(d.getMinutes()).padStart(2, '0');
    
    return format
        .replace('DD', day)
        .replace('MM', month)
        .replace('YYYY', year)
        .replace('HH', hours)
        .replace('mm', minutes);
}

// Format date relative
function formatRelativeDate(date) {
    const d = new Date(date);
    const now = new Date();
    const diffMs = now - d;
    const diffMins = Math.floor(diffMs / 60000);
    const diffHours = Math.floor(diffMs / 3600000);
    const diffDays = Math.floor(diffMs / 86400000);
    
    if (diffMins < 1) return 'À l\'instant';
    if (diffMins < 60) return `Il y a ${diffMins} min`;
    if (diffHours < 24) return `Il y a ${diffHours}h`;
    if (diffDays < 7) return `Il y a ${diffDays}j`;
    return formatDate(date, 'DD/MM/YYYY');
}

// ============================================
// 8. GESTION DES MODALES
// ============================================

const Modal = {
    open(modalId) {
        const modal = document.getElementById(modalId);
        if (!modal) return;
        
        modal.style.display = 'flex';
        modal.style.opacity = '0';
        
        setTimeout(() => {
            modal.style.opacity = '1';
        }, 10);
        
        // Empêcher le scroll du body
        document.body.style.overflow = 'hidden';
        
        // Fermer avec ESC
        const escHandler = (e) => {
            if (e.key === 'Escape') {
                this.close(modalId);
                document.removeEventListener('keydown', escHandler);
            }
        };
        document.addEventListener('keydown', escHandler);
    },
    
    close(modalId) {
        const modal = document.getElementById(modalId);
        if (!modal) return;
        
        modal.style.opacity = '0';
        
        setTimeout(() => {
            modal.style.display = 'none';
            document.body.style.overflow = '';
        }, 300);
    }
};

// ============================================
// 9. REQUÊTES API
// ============================================

const API = {
    async request(endpoint, options = {}) {
        const url = CONFIG.apiUrl + endpoint;
        
        const defaultOptions = {
            headers: {
                'Content-Type': 'application/json',
                'X-Requested-With': 'XMLHttpRequest'
            }
        };
        
        const config = { ...defaultOptions, ...options };
        
        try {
            const response = await fetch(url, config);
            const data = await response.json();
            
            if (!response.ok) {
                throw new Error(data.message || 'Erreur API');
            }
            
            return data;
        } catch (error) {
            console.error('Erreur API:', error);
            Toast.error(error.message || 'Une erreur est survenue');
            throw error;
        }
    },
    
    get(endpoint) {
        return this.request(endpoint, { method: 'GET' });
    },
    
    post(endpoint, data) {
        return this.request(endpoint, {
            method: 'POST',
            body: JSON.stringify(data)
        });
    },
    
    put(endpoint, data) {
        return this.request(endpoint, {
            method: 'PUT',
            body: JSON.stringify(data)
        });
    },
    
    delete(endpoint) {
        return this.request(endpoint, { method: 'DELETE' });
    }
};

// ============================================
// 10. VALIDATION DE FORMULAIRES
// ============================================

const FormValidator = {
    rules: {
        required: (value) => value.trim() !== '',
        email: (value) => /^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(value),
        minLength: (value, length) => value.length >= length,
        maxLength: (value, length) => value.length <= length,
        username: (value) => /^[a-zA-Z0-9_-]{3,20}$/.test(value),
        password: (value) => value.length >= 8
    },
    
    validate(formId) {
        const form = document.getElementById(formId);
        if (!form) return false;
        
        let isValid = true;
        const inputs = form.querySelectorAll('[data-validate]');
        
        inputs.forEach(input => {
            const rules = input.getAttribute('data-validate').split('|');
            const value = input.value;
            
            for (const rule of rules) {
                const [ruleName, param] = rule.split(':');
                
                if (this.rules[ruleName]) {
                    const valid = param 
                        ? this.rules[ruleName](value, param)
                        : this.rules[ruleName](value);
                    
                    if (!valid) {
                        this.showError(input, this.getErrorMessage(ruleName, param));
                        isValid = false;
                    } else {
                        this.clearError(input);
                    }
                }
            }
        });
        
        return isValid;
    },
    
    showError(input, message) {
        this.clearError(input);
        
        input.classList.add('error');
        input.style.borderColor = '#fd65ff';
        
        const error = document.createElement('div');
        error.className = 'form-error';
        error.textContent = message;
        
        input.parentNode.appendChild(error);
    },
    
    clearError(input) {
        input.classList.remove('error');
        input.style.borderColor = '';
        
        const error = input.parentNode.querySelector('.form-error');
        if (error) {
            error.remove();
        }
    },
    
    getErrorMessage(rule, param) {
        const messages = {
            required: 'Ce champ est requis',
            email: 'Adresse email invalide',
            minLength: `Minimum ${param} caractères`,
            maxLength: `Maximum ${param} caractères`,
            username: 'Nom d\'utilisateur invalide (3-20 caractères, a-z, 0-9, _ -)',
            password: 'Mot de passe trop court (minimum 8 caractères)'
        };
        return messages[rule] || 'Champ invalide';
    }
};

// ============================================
// 11. EXPORT GLOBAL
// ============================================

window.UserManager = {
    CONFIG,
    Toast,
    Modal,
    API,
    FormValidator,
    debounce,
    throttle,
    formatDate,
    formatRelativeDate
};

console.log('📦 UserManager API loaded:', window.UserManager);
