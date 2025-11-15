/**
 * ═══════════════════════════════════════════════════════════════════════════
 * BOLT.DIY USER MANAGER v2.0 - API HELPER
 * © Copyright Nbility 2025 - contact@nbility.fr
 * 
 * Helper pour les appels API avec fetch, CSRF, et gestion d'erreurs
 * ═══════════════════════════════════════════════════════════════════════════
 */

const API = {
    // Base URL de l'API
    baseUrl: '/api',

    /**
     * Récupérer le token CSRF depuis le meta tag
     * @returns {string} Token CSRF
     */
    getCsrfToken() {
        const meta = document.querySelector('meta[name="csrf-token"]');
        return meta ? meta.getAttribute('content') : '';
    },

    /**
     * Mettre à jour le token CSRF dans le meta tag
     * @param {string} token - Nouveau token CSRF
     */
    setCsrfToken(token) {
        const meta = document.querySelector('meta[name="csrf-token"]');
        if (meta) {
            meta.setAttribute('content', token);
        }
    },

    /**
     * Construire les headers pour les requêtes
     * @param {Object} customHeaders - Headers personnalisés
     * @returns {Object} Headers complets
     */
    buildHeaders(customHeaders = {}) {
        const headers = {
            'Content-Type': 'application/json',
            'Accept': 'application/json',
            ...customHeaders
        };

        // Ajouter le token CSRF pour les requêtes POST, PUT, DELETE
        const csrfToken = this.getCsrfToken();
        if (csrfToken) {
            headers['X-CSRF-Token'] = csrfToken;
        }

        return headers;
    },

    /**
     * Effectuer une requête API
     * @param {string} url - URL de l'endpoint
     * @param {Object} options - Options fetch
     * @returns {Promise<Object>} Response JSON
     */
    async request(url, options = {}) {
        try {
            // Construire l'URL complète
            const fullUrl = url.startsWith('http') ? url : `${this.baseUrl}${url}`;

            // Construire les headers
            const headers = this.buildHeaders(options.headers || {});

            // Options par défaut
            const defaultOptions = {
                credentials: 'same-origin',
                headers
            };

            // Fusionner les options
            const requestOptions = { ...defaultOptions, ...options };

            // Effectuer la requête
            const response = await fetch(fullUrl, requestOptions);

            // Extraire le nouveau token CSRF si présent
            const newCsrfToken = response.headers.get('X-CSRF-Token');
            if (newCsrfToken) {
                this.setCsrfToken(newCsrfToken);
            }

            // Parser la réponse JSON
            let data;
            const contentType = response.headers.get('content-type');
            if (contentType && contentType.includes('application/json')) {
                data = await response.json();
            } else {
                // Si ce n'est pas du JSON, retourner le texte
                data = { message: await response.text() };
            }

            // Vérifier le statut de la réponse
            if (!response.ok) {
                throw {
                    status: response.status,
                    statusText: response.statusText,
                    message: data.message || 'Une erreur est survenue',
                    errors: data.errors || {},
                    data: data
                };
            }

            return data;

        } catch (error) {
            // Gérer les erreurs réseau
            if (error instanceof TypeError) {
                throw {
                    status: 0,
                    message: 'Erreur réseau. Vérifiez votre connexion.',
                    error
                };
            }

            // Réthrow l'erreur pour la gestion dans les appelants
            throw error;
        }
    },

    /**
     * Requête GET
     * @param {string} url - URL de l'endpoint
     * @param {Object} params - Paramètres query string
     * @returns {Promise<Object>} Response JSON
     */
    async get(url, params = {}) {
        // Construire la query string
        const queryString = new URLSearchParams(params).toString();
        const fullUrl = queryString ? `${url}?${queryString}` : url;

        return this.request(fullUrl, {
            method: 'GET'
        });
    },

    /**
     * Requête POST
     * @param {string} url - URL de l'endpoint
     * @param {Object} data - Données à envoyer
     * @returns {Promise<Object>} Response JSON
     */
    async post(url, data = {}) {
        return this.request(url, {
            method: 'POST',
            body: JSON.stringify(data)
        });
    },

    /**
     * Requête PUT
     * @param {string} url - URL de l'endpoint
     * @param {Object} data - Données à envoyer
     * @returns {Promise<Object>} Response JSON
     */
    async put(url, data = {}) {
        return this.request(url, {
            method: 'PUT',
            body: JSON.stringify(data)
        });
    },

    /**
     * Requête DELETE
     * @param {string} url - URL de l'endpoint
     * @returns {Promise<Object>} Response JSON
     */
    async delete(url) {
        return this.request(url, {
            method: 'DELETE'
        });
    },

    /**
     * Upload de fichier
     * @param {string} url - URL de l'endpoint
     * @param {FormData} formData - FormData avec le fichier
     * @returns {Promise<Object>} Response JSON
     */
    async upload(url, formData) {
        // Ne pas définir Content-Type pour FormData (ajouté automatiquement)
        const headers = {
            'Accept': 'application/json'
        };

        const csrfToken = this.getCsrfToken();
        if (csrfToken) {
            headers['X-CSRF-Token'] = csrfToken;
        }

        return this.request(url, {
            method: 'POST',
            body: formData,
            headers
        });
    },

    /**
     * Télécharger un fichier
     * @param {string} url - URL de l'endpoint
     * @param {string} filename - Nom du fichier à télécharger
     */
    async download(url, filename) {
        try {
            const response = await fetch(`${this.baseUrl}${url}`, {
                credentials: 'same-origin',
                headers: this.buildHeaders()
            });

            if (!response.ok) {
                throw new Error('Erreur lors du téléchargement');
            }

            const blob = await response.blob();
            const downloadUrl = window.URL.createObjectURL(blob);
            const a = document.createElement('a');
            a.href = downloadUrl;
            a.download = filename || 'download';
            document.body.appendChild(a);
            a.click();
            document.body.removeChild(a);
            window.URL.revokeObjectURL(downloadUrl);

        } catch (error) {
            console.error('Erreur de téléchargement:', error);
            throw error;
        }
    }
};

/**
 * Gestion globale des erreurs API
 * @param {Object} error - Objet d'erreur
 * @param {Function} callback - Fonction de callback optionnelle
 */
function handleApiError(error, callback = null) {
    console.error('API Error:', error);

    let message = 'Une erreur est survenue';
    let details = '';

    if (error.status === 401) {
        message = 'Session expirée';
        details = 'Vous allez être redirigé vers la page de connexion.';

        // Rediriger vers la page de login après 2 secondes
        setTimeout(() => {
            window.location.href = '/login.html';
        }, 2000);

    } else if (error.status === 403) {
        message = 'Accès refusé';
        details = 'Vous n'avez pas les permissions nécessaires.';

    } else if (error.status === 404) {
        message = 'Ressource introuvable';
        details = error.message || 'La ressource demandée n'existe pas.';

    } else if (error.status === 422) {
        message = 'Erreur de validation';
        if (error.errors && Object.keys(error.errors).length > 0) {
            details = Object.values(error.errors).flat().join('\n');
        } else {
            details = error.message || '';
        }

    } else if (error.status === 429) {
        message = 'Trop de requêtes';
        details = error.message || 'Veuillez patienter avant de réessayer.';

    } else if (error.status === 500) {
        message = 'Erreur serveur';
        details = 'Une erreur interne est survenue. Veuillez réessayer.';

    } else if (error.status === 0) {
        message = 'Erreur réseau';
        details = 'Vérifiez votre connexion internet.';

    } else {
        message = error.message || 'Erreur inconnue';
        details = error.statusText || '';
    }

    // Afficher une notification toast
    if (window.showToast) {
        window.showToast(message + (details ? ': ' + details : ''), 'danger');
    } else {
        alert(message + (details ? '\n' + details : ''));
    }

    // Callback personnalisé
    if (callback && typeof callback === 'function') {
        callback(error);
    }

    return { message, details, error };
}

/**
 * Helper pour vérifier l'authentification
 * @returns {Promise<Object>} User object ou redirection
 */
async function checkAuth() {
    try {
        const response = await API.get('/auth/me');
        return response.data;
    } catch (error) {
        // Rediriger vers login si non authentifié
        window.location.href = '/login.html';
        throw error;
    }
}

/**
 * Intercepteur pour toutes les erreurs 401 (session expirée)
 */
window.addEventListener('unhandledrejection', (event) => {
    if (event.reason && event.reason.status === 401) {
        event.preventDefault();
        handleApiError(event.reason);
    }
});

// Export pour utilisation globale
window.API = API;
window.handleApiError = handleApiError;
window.checkAuth = checkAuth;
