/**
 * Bolt.DIY User Manager - Users JavaScript
 * Version: 1.0
 * Date: 19 novembre 2025
 */

'use strict';

// ============================================
// CLASSE USERS MANAGER
// ============================================

class UsersManager {
    constructor() {
        this.users = [];
        this.filteredUsers = [];
        this.currentPage = 1;
        this.perPage = 10;
        this.sortBy = 'username';
        this.sortOrder = 'asc';
        this.filters = {
            search: '',
            role: '',
            status: ''
        };
        
        this.init();
    }

    async init() {
        console.log('👥 Initialisation Users Manager...');
        
        // Charger les utilisateurs
        await this.loadUsers();
        
        // Initialiser les événements
        this.initEvents();
        
        // Afficher les utilisateurs
        this.renderUsers();
        
        console.log('✅ Users Manager initialisé');
    }

    // ============================================
    // CHARGEMENT DES DONNÉES
    // ============================================

    async loadUsers() {
        try {
            const response = await fetch('/user-manager/api/users.php');
            
            if (!response.ok) {
                throw new Error('Erreur de chargement');
            }
            
            const data = await response.json();
            this.users = data.users || [];
            this.filteredUsers = [...this.users];
            
        } catch (error) {
            console.error('Erreur:', error);
            UserManager.Toast.error('Erreur de chargement des utilisateurs');
        }
    }

    // ============================================
    // ÉVÉNEMENTS
    // ============================================

    initEvents() {
        // Bouton ajouter
        const addBtn = document.getElementById('add-user-btn');
        if (addBtn) {
            addBtn.addEventListener('click', () => this.openModal());
        }

        // Recherche
        const searchInput = document.getElementById('search-users');
        if (searchInput) {
            searchInput.addEventListener('input', UserManager.debounce((e) => {
                this.filters.search = e.target.value;
                this.applyFilters();
            }, 300));
        }

        // Filtres
        const roleFilter = document.getElementById('filter-role');
        if (roleFilter) {
            roleFilter.addEventListener('change', (e) => {
                this.filters.role = e.target.value;
                this.applyFilters();
            });
        }

        const statusFilter = document.getElementById('filter-status');
        if (statusFilter) {
            statusFilter.addEventListener('change', (e) => {
                this.filters.status = e.target.value;
                this.applyFilters();
            });
        }

        // Reset filters
        const resetBtn = document.getElementById('reset-filters');
        if (resetBtn) {
            resetBtn.addEventListener('click', () => this.resetFilters());
        }

        // Fermeture modale
        const modalClose = document.getElementById('modal-close');
        if (modalClose) {
            modalClose.addEventListener('click', () => this.closeModal());
        }

        const modalCancel = document.getElementById('modal-cancel');
        if (modalCancel) {
            modalCancel.addEventListener('click', () => this.closeModal());
        }

        // Overlay modale
        const modalOverlay = document.getElementById('user-modal');
        if (modalOverlay) {
            modalOverlay.addEventListener('click', (e) => {
                if (e.target === modalOverlay) {
                    this.closeModal();
                }
            });
        }

        // Formulaire
        const form = document.getElementById('user-form');
        if (form) {
            form.addEventListener('submit', (e) => {
                e.preventDefault();
                this.saveUser();
            });
        }
    }

    // ============================================
    // FILTRES ET TRI
    // ============================================

    applyFilters() {
        this.filteredUsers = this.users.filter(user => {
            // Recherche
            if (this.filters.search) {
                const search = this.filters.search.toLowerCase();
                const matchesSearch = 
                    user.username.toLowerCase().includes(search) ||
                    user.email.toLowerCase().includes(search) ||
                    (user.firstName && user.firstName.toLowerCase().includes(search)) ||
                    (user.lastName && user.lastName.toLowerCase().includes(search));
                
                if (!matchesSearch) return false;
            }

            // Rôle
            if (this.filters.role && user.role !== this.filters.role) {
                return false;
            }

            // Statut
            if (this.filters.status && user.status !== this.filters.status) {
                return false;
            }

            return true;
        });

        this.currentPage = 1;
        this.renderUsers();
    }

    resetFilters() {
        this.filters = {
            search: '',
            role: '',
            status: ''
        };

        // Reset UI
        const searchInput = document.getElementById('search-users');
        if (searchInput) searchInput.value = '';

        const roleFilter = document.getElementById('filter-role');
        if (roleFilter) roleFilter.value = '';

        const statusFilter = document.getElementById('filter-status');
        if (statusFilter) statusFilter.value = '';

        this.applyFilters();
    }

    sortUsers(column) {
        if (this.sortBy === column) {
            this.sortOrder = this.sortOrder === 'asc' ? 'desc' : 'asc';
        } else {
            this.sortBy = column;
            this.sortOrder = 'asc';
        }

        this.filteredUsers.sort((a, b) => {
            let aVal = a[column] || '';
            let bVal = b[column] || '';

            if (typeof aVal === 'string') {
                aVal = aVal.toLowerCase();
                bVal = bVal.toLowerCase();
            }

            if (this.sortOrder === 'asc') {
                return aVal > bVal ? 1 : -1;
            } else {
                return aVal < bVal ? 1 : -1;
            }
        });

        this.renderUsers();
    }

    // ============================================
    // AFFICHAGE
    // ============================================

    renderUsers() {
        const tbody = document.getElementById('users-tbody');
        if (!tbody) return;

        // Pagination
        const start = (this.currentPage - 1) * this.perPage;
        const end = start + this.perPage;
        const paginatedUsers = this.filteredUsers.slice(start, end);

        // Vider le tableau
        tbody.innerHTML = '';

        // Empty state
        if (paginatedUsers.length === 0) {
            tbody.innerHTML = `
                <tr>
                    <td colspan="6" class="empty-state">
                        <div class="empty-state-icon">
                            <i class="fas fa-users"></i>
                        </div>
                        <div class="empty-state-title">Aucun utilisateur trouvé</div>
                        <div class="empty-state-text">
                            ${this.filters.search || this.filters.role || this.filters.status 
                                ? 'Essayez de modifier vos filtres' 
                                : 'Commencez par créer un nouvel utilisateur'}
                        </div>
                    </td>
                </tr>
            `;
            return;
        }

        // Afficher les utilisateurs
        paginatedUsers.forEach(user => {
            const row = this.createUserRow(user);
            tbody.appendChild(row);
        });

        // Mettre à jour la pagination
        this.updatePagination();
    }

    createUserRow(user) {
        const tr = document.createElement('tr');
        tr.innerHTML = `
            <td>
                <div class="user-info">
                    <div class="user-avatar">
                        ${user.avatar 
                            ? `<img src="${user.avatar}" alt="${user.username}">` 
                            : user.username.substring(0, 2).toUpperCase()}
                    </div>
                    <div class="user-details">
                        <div class="user-name">${this.escapeHtml(user.username)}</div>
                        <div class="user-email">${this.escapeHtml(user.email)}</div>
                    </div>
                </div>
            </td>
            <td>
                ${user.firstName ? this.escapeHtml(user.firstName + ' ' + user.lastName) : '-'}
            </td>
            <td>
                <span class="role-badge ${user.role}">${this.escapeHtml(user.role)}</span>
            </td>
            <td>
                <span class="status-badge ${user.status}">${user.status === 'active' ? 'Actif' : 'Inactif'}</span>
            </td>
            <td>${user.lastLogin || 'Jamais'}</td>
            <td>
                <div class="table-actions">
                    <button class="action-btn view" onclick="usersManager.viewUser(${user.id})" title="Voir">
                        <i class="fas fa-eye"></i>
                    </button>
                    <button class="action-btn edit" onclick="usersManager.editUser(${user.id})" title="Modifier">
                        <i class="fas fa-edit"></i>
                    </button>
                    <button class="action-btn delete" onclick="usersManager.deleteUser(${user.id})" title="Supprimer">
                        <i class="fas fa-trash"></i>
                    </button>
                </div>
            </td>
        `;
        return tr;
    }

    updatePagination() {
        const totalPages = Math.ceil(this.filteredUsers.length / this.perPage);
        
        // Info
        const paginationInfo = document.getElementById('pagination-info');
        if (paginationInfo) {
            const start = (this.currentPage - 1) * this.perPage + 1;
            const end = Math.min(this.currentPage * this.perPage, this.filteredUsers.length);
            paginationInfo.textContent = `${start}-${end} sur ${this.filteredUsers.length} utilisateurs`;
        }

        // Boutons
        const prevBtn = document.getElementById('pagination-prev');
        const nextBtn = document.getElementById('pagination-next');

        if (prevBtn) {
            prevBtn.disabled = this.currentPage === 1;
            prevBtn.onclick = () => this.changePage(this.currentPage - 1);
        }

        if (nextBtn) {
            nextBtn.disabled = this.currentPage === totalPages;
            nextBtn.onclick = () => this.changePage(this.currentPage + 1);
        }
    }

    changePage(page) {
        this.currentPage = page;
        this.renderUsers();
    }

    // ============================================
    // MODAL
    // ============================================

    openModal(userId = null) {
        const modal = document.getElementById('user-modal');
        const form = document.getElementById('user-form');
        const title = document.getElementById('modal-title-text');
        
        if (!modal || !form) return;

        // Reset form
        form.reset();
        
        if (userId) {
            // Mode édition
            const user = this.users.find(u => u.id === userId);
            if (user) {
                title.textContent = 'Modifier l\'utilisateur';
                document.getElementById('user-id').value = user.id;
                document.getElementById('user-username').value = user.username;
                document.getElementById('user-email').value = user.email;
                document.getElementById('user-firstName').value = user.firstName || '';
                document.getElementById('user-lastName').value = user.lastName || '';
                document.getElementById('user-role').value = user.role;
                document.getElementById('user-status').checked = user.status === 'active';
            }
        } else {
            // Mode création
            title.textContent = 'Nouvel utilisateur';
            document.getElementById('user-id').value = '';
            document.getElementById('user-status').checked = true;
        }

        modal.classList.add('active');
        document.body.style.overflow = 'hidden';
    }

    closeModal() {
        const modal = document.getElementById('user-modal');
        if (modal) {
            modal.classList.remove('active');
            document.body.style.overflow = '';
        }
    }

    // ============================================
    // CRUD OPERATIONS
    // ============================================

    async saveUser() {
        const form = document.getElementById('user-form');
        if (!form) return;

        const formData = new FormData(form);
        const userId = formData.get('id');
        
        const userData = {
            id: userId || null,
            username: formData.get('username'),
            email: formData.get('email'),
            firstName: formData.get('firstName'),
            lastName: formData.get('lastName'),
            role: formData.get('role'),
            status: formData.get('status') === 'on' ? 'active' : 'inactive'
        };

        // Validation
        if (!this.validateUser(userData)) {
            return;
        }

        try {
            const method = userId ? 'PUT' : 'POST';
            const url = userId 
                ? `/user-manager/api/users.php?id=${userId}` 
                : '/user-manager/api/users.php';

            const response = await fetch(url, {
                method: method,
                headers: {
                    'Content-Type': 'application/json',
                },
                body: JSON.stringify(userData)
            });

            if (!response.ok) {
                throw new Error('Erreur de sauvegarde');
            }

            const result = await response.json();

            if (result.success) {
                UserManager.Toast.success(
                    userId ? 'Utilisateur modifié avec succès' : 'Utilisateur créé avec succès'
                );
                this.closeModal();
                await this.loadUsers();
                this.renderUsers();
            } else {
                throw new Error(result.message || 'Erreur de sauvegarde');
            }

        } catch (error) {
            console.error('Erreur:', error);
            UserManager.Toast.error(error.message || 'Erreur lors de la sauvegarde');
        }
    }

    validateUser(user) {
        if (!user.username || user.username.length < 3) {
            UserManager.Toast.error('Le nom d\'utilisateur doit contenir au moins 3 caractères');
            return false;
        }

        if (!user.email || !this.isValidEmail(user.email)) {
            UserManager.Toast.error('L\'adresse email est invalide');
            return false;
        }

        return true;
    }

    isValidEmail(email) {
        return /^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(email);
    }

    viewUser(userId) {
        const user = this.users.find(u => u.id === userId);
        if (user) {
            UserManager.Toast.info(`Affichage de ${user.username}`);
            // TODO: Implémenter la vue détaillée
        }
    }

    editUser(userId) {
        this.openModal(userId);
    }

    async deleteUser(userId) {
        const user = this.users.find(u => u.id === userId);
        if (!user) return;

        if (!confirm(`Êtes-vous sûr de vouloir supprimer l'utilisateur "${user.username}" ?`)) {
            return;
        }

        try {
            const response = await fetch(`/user-manager/api/users.php?id=${userId}`, {
                method: 'DELETE'
            });

            if (!response.ok) {
                throw new Error('Erreur de suppression');
            }

            const result = await response.json();

            if (result.success) {
                UserManager.Toast.success('Utilisateur supprimé avec succès');
                await this.loadUsers();
                this.renderUsers();
            } else {
                throw new Error(result.message || 'Erreur de suppression');
            }

        } catch (error) {
            console.error('Erreur:', error);
            UserManager.Toast.error(error.message || 'Erreur lors de la suppression');
        }
    }

    // ============================================
    // UTILITAIRES
    // ============================================

    escapeHtml(text) {
        const div = document.createElement('div');
        div.textContent = text;
        return div.innerHTML;
    }
}

// ============================================
// INITIALISATION
// ============================================

let usersManager = null;

document.addEventListener('DOMContentLoaded', function() {
    if (document.getElementById('users-tbody')) {
        usersManager = new UsersManager();
    }
});

window.usersManager = usersManager;
