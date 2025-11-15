/**
 * BOLT.DIY USER MANAGER v2.0 - UTILS MODULE
 * © Copyright Nbility 2025
 */

// ═══════════════════════════════════════════════════════════════════════════
// MODAL MANAGEMENT
// ═══════════════════════════════════════════════════════════════════════════

function openModal(modalId) {
    const modal = document.getElementById(modalId);
    if (modal) {
        modal.classList.add('show');
        document.body.style.overflow = 'hidden';
    }
}

function closeModal(modalId) {
    const modal = document.getElementById(modalId);
    if (modal) {
        modal.classList.remove('show');
        document.body.style.overflow = '';
    }
}

// Close modal on backdrop click
document.addEventListener('click', (e) => {
    if (e.target.classList.contains('modal') && e.target.classList.contains('show')) {
        closeModal(e.target.id);
    }
});

// Close modal on ESC key
document.addEventListener('keydown', (e) => {
    if (e.key === 'Escape') {
        const openModals = document.querySelectorAll('.modal.show');
        openModals.forEach(modal => closeModal(modal.id));
    }
});

// ═══════════════════════════════════════════════════════════════════════════
// TOAST NOTIFICATIONS
// ═══════════════════════════════════════════════════════════════════════════

let toastCounter = 0;

function showToast(message, type = 'success', duration = 5000) {
    const toastContainer = document.getElementById('toastContainer');
    if (!toastContainer) return;

    const toastId = `toast-${++toastCounter}`;
    const icons = {
        success: 'fa-check-circle',
        danger: 'fa-exclamation-circle',
        warning: 'fa-exclamation-triangle',
        info: 'fa-info-circle'
    };

    const toast = document.createElement('div');
    toast.id = toastId;
    toast.className = `toast toast-${type}`;
    toast.innerHTML = `
        <i class="fas ${icons[type] || icons.info}"></i>
        <span>${message}</span>
        <button onclick="closeToast('${toastId}')" style="background:none;border:none;color:inherit;cursor:pointer;margin-left:auto;">
            <i class="fas fa-times"></i>
        </button>
    `;

    toastContainer.appendChild(toast);

    // Trigger animation
    setTimeout(() => toast.classList.add('show'), 10);

    // Auto remove
    if (duration > 0) {
        setTimeout(() => closeToast(toastId), duration);
    }
}

function closeToast(toastId) {
    const toast = document.getElementById(toastId);
    if (toast) {
        toast.classList.remove('show');
        setTimeout(() => toast.remove(), 300);
    }
}

// Export to window
window.showToast = showToast;
window.closeToast = closeToast;

// ═══════════════════════════════════════════════════════════════════════════
// SIDEBAR MANAGEMENT
// ═══════════════════════════════════════════════════════════════════════════

function initSidebar() {
    const sidebar = document.getElementById('sidebar');
    const sidebarToggle = document.getElementById('sidebarToggle');
    const btnMobileToggle = document.getElementById('btnMobileToggle');

    if (sidebarToggle) {
        sidebarToggle.addEventListener('click', () => {
            sidebar?.classList.toggle('collapsed');
        });
    }

    if (btnMobileToggle) {
        btnMobileToggle.addEventListener('click', () => {
            sidebar?.classList.toggle('open');
        });
    }

    // Close sidebar on mobile when clicking outside
    document.addEventListener('click', (e) => {
        if (window.innerWidth <= 768) {
            if (sidebar?.classList.contains('open') && 
                !sidebar.contains(e.target) && 
                e.target.id !== 'btnMobileToggle') {
                sidebar.classList.remove('open');
            }
        }
    });

    // Update active nav item
    updateActiveNavItem();
}

function updateActiveNavItem() {
    const currentPath = window.location.pathname;
    document.querySelectorAll('.nav-item').forEach(item => {
        const href = item.getAttribute('href');
        if (href && currentPath.includes(href.replace('/', ''))) {
            item.classList.add('active');
        } else {
            item.classList.remove('active');
        }
    });
}

// ═══════════════════════════════════════════════════════════════════════════
// DATE & TIME FORMATTING
// ═══════════════════════════════════════════════════════════════════════════

function formatDate(dateString, includeTime = true) {
    if (!dateString) return '-';

    const date = new Date(dateString);
    if (isNaN(date.getTime())) return '-';

    const dateStr = date.toLocaleDateString('fr-FR', {
        year: 'numeric',
        month: '2-digit',
        day: '2-digit'
    });

    if (!includeTime) return dateStr;

    const timeStr = date.toLocaleTimeString('fr-FR', {
        hour: '2-digit',
        minute: '2-digit'
    });

    return `${dateStr} ${timeStr}`;
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

    if (days > 7) return formatDate(dateString, false);
    if (days > 0) return `Il y a ${days} jour${days > 1 ? 's' : ''}`;
    if (hours > 0) return `Il y a ${hours} heure${hours > 1 ? 's' : ''}`;
    if (minutes > 0) return `Il y a ${minutes} minute${minutes > 1 ? 's' : ''}`;
    return 'À l'instant';
}

function formatTime(dateString) {
    if (!dateString) return '-';

    const date = new Date(dateString);
    if (isNaN(date.getTime())) return '-';

    return date.toLocaleTimeString('fr-FR', {
        hour: '2-digit',
        minute: '2-digit'
    });
}

// ═══════════════════════════════════════════════════════════════════════════
// STRING UTILITIES
// ═══════════════════════════════════════════════════════════════════════════

function truncate(str, maxLength = 50) {
    if (!str || str.length <= maxLength) return str;
    return str.substring(0, maxLength) + '...';
}

function capitalize(str) {
    if (!str) return '';
    return str.charAt(0).toUpperCase() + str.slice(1).toLowerCase();
}

function slugify(str) {
    return str
        .toLowerCase()
        .trim()
        .replace(/[^a-z0-9]+/g, '-')
        .replace(/^-+|-+$/g, '');
}

function escapeHtml(str) {
    const div = document.createElement('div');
    div.textContent = str;
    return div.innerHTML;
}

// ═══════════════════════════════════════════════════════════════════════════
// NUMBER FORMATTING
// ═══════════════════════════════════════════════════════════════════════════

function formatNumber(num) {
    return new Intl.NumberFormat('fr-FR').format(num);
}

function formatPercent(num, decimals = 1) {
    return (num * 100).toFixed(decimals) + '%';
}

function formatBytes(bytes) {
    if (bytes === 0) return '0 B';
    const k = 1024;
    const sizes = ['B', 'KB', 'MB', 'GB', 'TB'];
    const i = Math.floor(Math.log(bytes) / Math.log(k));
    return parseFloat((bytes / Math.pow(k, i)).toFixed(2)) + ' ' + sizes[i];
}

// ═══════════════════════════════════════════════════════════════════════════
// DEBOUNCE & THROTTLE
// ═══════════════════════════════════════════════════════════════════════════

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

// ═══════════════════════════════════════════════════════════════════════════
// LOADING STATES
// ═══════════════════════════════════════════════════════════════════════════

function showLoading(elementId, colspan = 10) {
    const el = document.getElementById(elementId);
    if (!el) return;

    if (el.tagName === 'TBODY') {
        el.innerHTML = `<tr><td colspan="${colspan}" class="text-center"><i class="fas fa-spinner fa-spin"></i> Chargement...</td></tr>`;
    } else {
        el.innerHTML = '<div class="loading"><i class="fas fa-spinner fa-spin"></i> Chargement...</div>';
    }
}

function hideLoading(elementId) {
    const el = document.getElementById(elementId);
    if (el) el.innerHTML = '';
}

function showError(elementId, message, colspan = 10) {
    const el = document.getElementById(elementId);
    if (!el) return;

    if (el.tagName === 'TBODY') {
        el.innerHTML = `<tr><td colspan="${colspan}" class="text-center text-danger"><i class="fas fa-exclamation-triangle"></i> ${message}</td></tr>`;
    } else {
        el.innerHTML = `<div class="text-center text-danger"><i class="fas fa-exclamation-triangle"></i> ${message}</div>`;
    }
}

function showEmpty(elementId, message = 'Aucun résultat', colspan = 10) {
    const el = document.getElementById(elementId);
    if (!el) return;

    if (el.tagName === 'TBODY') {
        el.innerHTML = `<tr><td colspan="${colspan}" class="text-center text-muted">${message}</td></tr>`;
    } else {
        el.innerHTML = `<div class="text-center text-muted">${message}</div>`;
    }
}

// ═══════════════════════════════════════════════════════════════════════════
// FORM VALIDATION
// ═══════════════════════════════════════════════════════════════════════════

function validateEmail(email) {
    const re = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
    return re.test(email);
}

function validateUsername(username) {
    const re = /^[a-zA-Z0-9_-]{3,20}$/;
    return re.test(username);
}

function validatePassword(password) {
    return password.length >= 8;
}

function showFieldError(fieldId, message) {
    const field = document.getElementById(fieldId);
    if (!field) return;

    field.classList.add('is-invalid');

    let errorEl = field.nextElementSibling;
    if (!errorEl || !errorEl.classList.contains('form-error')) {
        errorEl = document.createElement('span');
        errorEl.className = 'form-error';
        field.parentNode.insertBefore(errorEl, field.nextSibling);
    }
    errorEl.textContent = message;
}

function clearFieldError(fieldId) {
    const field = document.getElementById(fieldId);
    if (!field) return;

    field.classList.remove('is-invalid');

    const errorEl = field.nextElementSibling;
    if (errorEl && errorEl.classList.contains('form-error')) {
        errorEl.remove();
    }
}

function clearAllFieldErrors() {
    document.querySelectorAll('.is-invalid').forEach(field => {
        field.classList.remove('is-invalid');
    });
    document.querySelectorAll('.form-error').forEach(error => {
        error.remove();
    });
}

// ═══════════════════════════════════════════════════════════════════════════
// CLIPBOARD
// ═══════════════════════════════════════════════════════════════════════════

async function copyToClipboard(text) {
    try {
        await navigator.clipboard.writeText(text);
        showToast('Copié dans le presse-papier', 'success', 2000);
        return true;
    } catch (err) {
        showToast('Erreur de copie', 'danger');
        return false;
    }
}

// ═══════════════════════════════════════════════════════════════════════════
// LOCAL STORAGE
// ═══════════════════════════════════════════════════════════════════════════

function saveToStorage(key, value) {
    try {
        localStorage.setItem(key, JSON.stringify(value));
        return true;
    } catch (err) {
        console.error('Error saving to storage:', err);
        return false;
    }
}

function getFromStorage(key, defaultValue = null) {
    try {
        const item = localStorage.getItem(key);
        return item ? JSON.parse(item) : defaultValue;
    } catch (err) {
        console.error('Error reading from storage:', err);
        return defaultValue;
    }
}

function removeFromStorage(key) {
    try {
        localStorage.removeItem(key);
        return true;
    } catch (err) {
        console.error('Error removing from storage:', err);
        return false;
    }
}

// ═══════════════════════════════════════════════════════════════════════════
// CONFIRMATION DIALOGS
// ═══════════════════════════════════════════════════════════════════════════

function confirm(message, callback) {
    if (window.confirm(message)) {
        callback();
    }
}

// ═══════════════════════════════════════════════════════════════════════════
// INITIALIZATION
// ═══════════════════════════════════════════════════════════════════════════

document.addEventListener('DOMContentLoaded', () => {
    initSidebar();
});

// Export functions to window
window.openModal = openModal;
window.closeModal = closeModal;
window.formatDate = formatDate;
window.formatDateRelative = formatDateRelative;
window.formatTime = formatTime;
window.truncate = truncate;
window.capitalize = capitalize;
window.slugify = slugify;
window.escapeHtml = escapeHtml;
window.formatNumber = formatNumber;
window.formatPercent = formatPercent;
window.formatBytes = formatBytes;
window.debounce = debounce;
window.throttle = throttle;
window.showLoading = showLoading;
window.hideLoading = hideLoading;
window.showError = showError;
window.showEmpty = showEmpty;
window.validateEmail = validateEmail;
window.validateUsername = validateUsername;
window.validatePassword = validatePassword;
window.showFieldError = showFieldError;
window.clearFieldError = clearFieldError;
window.clearAllFieldErrors = clearAllFieldErrors;
window.copyToClipboard = copyToClipboard;
window.saveToStorage = saveToStorage;
window.getFromStorage = getFromStorage;
window.removeFromStorage = removeFromStorage;
