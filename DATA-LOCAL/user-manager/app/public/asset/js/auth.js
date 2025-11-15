/**
 * ═══════════════════════════════════════════════════════════════════════════
 * BOLT.DIY USER MANAGER v2.0 - AUTH MODULE
 * © Copyright Nbility 2025 - contact@nbility.fr
 * 
 * Gestion de l'authentification, protection des pages, et session
 * ═══════════════════════════════════════════════════════════════════════════
 */

/**
 * Module Auth - Gestion de l'authentification
 */
const Auth = {
    // Clés localStorage
    STORAGE_KEYS: {
        USER: 'user_manager_user',
        TOKEN: 'user_manager_token',
        REMEMBER_ME: 'user_manager_remember'
    },

    // Pages publiques (pas de protection)
    PUBLIC_PAGES: [
        '/login.html',
        '/forgot-password.html',
        '/reset-password.html',
        '/register.html'
    ],

    /**
     * Vérifier si l'utilisateur est connecté
     * @returns {boolean}
     */
    isAuthenticated() {
        const user = this.getUser();
        return user !== null && user.id > 0;
    },

    /**
     * Récupérer l'utilisateur depuis localStorage
     * @returns {Object|null}
     */
    getUser() {
        try {
            const userJson = localStorage.getItem(this.STORAGE_KEYS.USER);
            return userJson ? JSON.parse(userJson) : null;
        } catch (error) {
            console.error('Erreur lors de la récupération de l'utilisateur:', error);
            return null;
        }
    },

    /**
     * Stocker l'utilisateur dans localStorage
     * @param {Object} user - Données utilisateur
     */
    setUser(user) {
        try {
            localStorage.setItem(this.STORAGE_KEYS.USER, JSON.stringify(user));
        } catch (error) {
            console.error('Erreur lors du stockage de l'utilisateur:', error);
        }
    },

    /**
     * Récupérer le token depuis localStorage
     * @returns {string|null}
     */
    getToken() {
        return localStorage.getItem(this.STORAGE_KEYS.TOKEN);
    },

    /**
     * Stocker le token dans localStorage
     * @param {string} token
     */
    setToken(token) {
        localStorage.setItem(this.STORAGE_KEYS.TOKEN, token);
    },

    /**
     * Vérifier si "Remember me" est activé
     * @returns {boolean}
     */
    hasRememberMe() {
        return localStorage.getItem(this.STORAGE_KEYS.REMEMBER_ME) === 'true';
    },

    /**
     * Définir "Remember me"
     * @param {boolean} remember
     */
    setRememberMe(remember) {
        localStorage.setItem(this.STORAGE_KEYS.REMEMBER_ME, remember ? 'true' : 'false');
    },

    /**
     * Se connecter
     * @param {string} username - Nom d'utilisateur
     * @param {string} password - Mot de passe
     * @param {boolean} rememberMe - Se souvenir de moi
     * @returns {Promise<Object>}
     */
    async login(username, password, rememberMe = false) {
        try {
            const response = await API.post('/auth/login', {
                username,
                password,
                remember_me: rememberMe
            });

            // Stocker l'utilisateur et le token
            if (response.data && response.data.user) {
                this.setUser(response.data.user);

                if (response.data.csrf_token) {
                    this.setToken(response.data.csrf_token);
                    API.setCsrfToken(response.data.csrf_token);
                }

                this.setRememberMe(rememberMe);
            }

            return response;

        } catch (error) {
            console.error('Erreur de connexion:', error);
            throw error;
        }
    },

    /**
     * Se déconnecter
     * @returns {Promise<void>}
     */
    async logout() {
        try {
            // Appeler l'API pour déconnecter côté serveur
            await API.post('/auth/logout');
        } catch (error) {
            console.error('Erreur lors de la déconnexion:', error);
        } finally {
            // Toujours nettoyer le localStorage
            this.clearStorage();

            // Rediriger vers la page de login
            window.location.href = '/login.html';
        }
    },

    /**
     * Nettoyer le localStorage
     */
    clearStorage() {
        localStorage.removeItem(this.STORAGE_KEYS.USER);
        localStorage.removeItem(this.STORAGE_KEYS.TOKEN);
        localStorage.removeItem(this.STORAGE_KEYS.REMEMBER_ME);
    },

    /**
     * Rafraîchir les informations de l'utilisateur
     * @returns {Promise<Object>}
     */
    async refreshUser() {
        try {
            const response = await API.get('/auth/me');

            if (response.data && response.data.user) {
                this.setUser(response.data.user);
                return response.data.user;
            }

            throw new Error('Utilisateur non trouvé');

        } catch (error) {
            console.error('Erreur lors du rafraîchissement de l'utilisateur:', error);

            // Si erreur 401, déconnecter
            if (error.status === 401) {
                this.clearStorage();
                window.location.href = '/login.html';
            }

            throw error;
        }
    },

    /**
     * Vérifier si l'utilisateur a un rôle spécifique
     * @param {string} role - Rôle à vérifier (user, admin, superadmin)
     * @returns {boolean}
     */
    hasRole(role) {
        const user = this.getUser();
        if (!user || !user.role) return false;

        const roles = {
            'user': ['user', 'admin', 'superadmin'],
            'admin': ['admin', 'superadmin'],
            'superadmin': ['superadmin']
        };

        return roles[role] ? roles[role].includes(user.role) : false;
    },

    /**
     * Vérifier si l'utilisateur a une permission spécifique
     * @param {string} permission - Permission à vérifier
     * @returns {boolean}
     */
    hasPermission(permission) {
        const user = this.getUser();
        if (!user || !user.permissions) return false;

        return user.permissions.includes(permission);
    },

    /**
     * Protéger une page (rediriger si non authentifié)
     * @param {string} requiredRole - Rôle requis (optionnel)
     */
    protectPage(requiredRole = null) {
        // Vérifier si la page actuelle est publique
        const currentPage = window.location.pathname;
        const isPublicPage = this.PUBLIC_PAGES.some(page => currentPage.endsWith(page));

        if (isPublicPage) {
            // Si déjà connecté, rediriger vers dashboard
            if (this.isAuthenticated()) {
                window.location.href = '/dashboard';
            }
            return;
        }

        // Vérifier l'authentification
        if (!this.isAuthenticated()) {
            // Sauvegarder l'URL de destination
            sessionStorage.setItem('redirect_after_login', window.location.href);
            window.location.href = '/login.html';
            return;
        }

        // Vérifier le rôle si requis
        if (requiredRole && !this.hasRole(requiredRole)) {
            alert('Accès refusé. Vous n'avez pas les permissions nécessaires.');
            window.location.href = '/dashboard';
            return;
        }

        // Masquer les éléments selon le rôle
        this.hideElementsByRole();
    },

    /**
     * Masquer les éléments HTML selon le rôle de l'utilisateur
     */
    hideElementsByRole() {
        const user = this.getUser();
        if (!user) return;

        // Masquer les éléments avec data-role
        document.querySelectorAll('[data-role]').forEach(element => {
            const requiredRole = element.getAttribute('data-role');
            if (!this.hasRole(requiredRole)) {
                element.style.display = 'none';
            }
        });

        // Masquer les éléments avec data-permission
        document.querySelectorAll('[data-permission]').forEach(element => {
            const requiredPermission = element.getAttribute('data-permission');
            if (!this.hasPermission(requiredPermission)) {
                element.style.display = 'none';
            }
        });
    },

    /**
     * Récupérer l'URL de redirection après login
     * @returns {string}
     */
    getRedirectUrl() {
        const redirect = sessionStorage.getItem('redirect_after_login');
        sessionStorage.removeItem('redirect_after_login');
        return redirect || '/dashboard';
    },

    /**
     * Afficher les informations de l'utilisateur dans l'UI
     */
    displayUserInfo() {
        const user = this.getUser();
        if (!user) return;

        // Afficher le nom
        const userNameElement = document.getElementById('userName');
        if (userNameElement) {
            userNameElement.textContent = user.first_name && user.last_name
                ? `${user.first_name} ${user.last_name}`
                : user.username;
        }

        // Afficher le rôle
        const userRoleElement = document.getElementById('userRole');
        if (userRoleElement) {
            userRoleElement.textContent = user.role;
        }

        // Afficher l'avatar si présent
        const userAvatarElement = document.querySelector('.user-avatar');
        if (userAvatarElement && user.avatar) {
            userAvatarElement.innerHTML = `<img src="${user.avatar}" alt="Avatar">`;
        }
    },

    /**
     * Initialiser l'authentification sur la page
     * @param {string} requiredRole - Rôle requis (optionnel)
     */
    init(requiredRole = null) {
        // Protéger la page
        this.protectPage(requiredRole);

        // Afficher les infos utilisateur
        this.displayUserInfo();

        // Gérer le bouton de déconnexion
        const logoutButton = document.getElementById('btnLogout');
        if (logoutButton) {
            logoutButton.addEventListener('click', (e) => {
                e.preventDefault();
                this.logout();
            });
        }

        // Rafraîchir l'utilisateur toutes les 5 minutes
        if (this.isAuthenticated()) {
            setInterval(() => {
                this.refreshUser().catch(() => {
                    // Ignorer les erreurs silencieuses
                });
            }, 5 * 60 * 1000); // 5 minutes
        }
    }
};

/**
 * Initialisation automatique au chargement de la page
 */
document.addEventListener('DOMContentLoaded', () => {
    // Déterminer le rôle requis selon la page
    const currentPage = window.location.pathname;
    let requiredRole = null;

    if (currentPage.includes('/permissions') || currentPage.includes('/audit')) {
        requiredRole = 'admin';
    }

    // Initialiser l'authentification
    Auth.init(requiredRole);
});

// Export pour utilisation globale
window.Auth = Auth;
