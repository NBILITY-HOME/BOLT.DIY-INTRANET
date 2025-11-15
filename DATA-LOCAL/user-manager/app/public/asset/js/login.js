/**
 * BOLT.DIY USER MANAGER v2.0 - LOGIN MODULE
 * © Copyright Nbility 2025
 */

// Initialisation
document.addEventListener('DOMContentLoaded', () => {
    // Vérifier si déjà connecté
    if (Auth.isAuthenticated()) {
        window.location.href = '/dashboard';
        return;
    }

    initEventListeners();
    checkRememberMe();
});

// Event listeners
function initEventListeners() {
    const loginForm = document.getElementById('loginForm');
    if (loginForm) {
        loginForm.addEventListener('submit', handleLogin);
    }

    // Toggle password visibility
    const togglePassword = document.querySelector('.btn-toggle-password');
    if (togglePassword) {
        togglePassword.addEventListener('click', () => {
            const passwordInput = document.getElementById('password');
            const icon = togglePassword.querySelector('i');

            if (passwordInput.type === 'password') {
                passwordInput.type = 'text';
                icon.classList.replace('fa-eye', 'fa-eye-slash');
            } else {
                passwordInput.type = 'password';
                icon.classList.replace('fa-eye-slash', 'fa-eye');
            }
        });
    }

    // Enter key sur le formulaire
    document.getElementById('username')?.addEventListener('keypress', (e) => {
        if (e.key === 'Enter') {
            document.getElementById('password')?.focus();
        }
    });

    document.getElementById('password')?.addEventListener('keypress', (e) => {
        if (e.key === 'Enter') {
            handleLogin(e);
        }
    });
}

// Gestion de la connexion
async function handleLogin(e) {
    e.preventDefault();

    // Récupérer les valeurs
    const username = document.getElementById('username').value.trim();
    const password = document.getElementById('password').value;
    const rememberMe = document.getElementById('rememberMe')?.checked || false;

    // Validation
    if (!username || !password) {
        showError('Veuillez remplir tous les champs');
        return;
    }

    // Désactiver le bouton
    const submitBtn = document.getElementById('btnLogin');
    const originalText = submitBtn?.innerHTML;
    if (submitBtn) {
        submitBtn.disabled = true;
        submitBtn.innerHTML = '<i class="fas fa-spinner fa-spin"></i> Connexion...';
    }

    try {
        // Appeler Auth.login (qui utilise API.post)
        const response = await Auth.login(username, password, rememberMe);

        // Success
        showSuccess('Connexion réussie ! Redirection...');

        // Rediriger après un court délai
        setTimeout(() => {
            window.location.href = Auth.getRedirectUrl();
        }, 500);

    } catch (error) {
        // Erreur
        let errorMessage = 'Erreur de connexion';

        if (error.status === 401) {
            errorMessage = 'Identifiants incorrects';
        } else if (error.status === 403) {
            errorMessage = 'Compte suspendu ou désactivé';
        } else if (error.status === 429) {
            errorMessage = 'Trop de tentatives. Réessayez plus tard.';
        } else if (error.message) {
            errorMessage = error.message;
        }

        showError(errorMessage);

        // Réactiver le bouton
        if (submitBtn) {
            submitBtn.disabled = false;
            submitBtn.innerHTML = originalText;
        }

        // Vider le mot de passe
        document.getElementById('password').value = '';
        document.getElementById('password').focus();
    }
}

// Vérifier "Remember me" au chargement
function checkRememberMe() {
    const rememberMeCheckbox = document.getElementById('rememberMe');
    const usernameInput = document.getElementById('username');

    if (rememberMeCheckbox && Auth.hasRememberMe()) {
        rememberMeCheckbox.checked = true;

        // Pré-remplir le nom d'utilisateur si stocké
        const savedUsername = localStorage.getItem('user_manager_username');
        if (savedUsername && usernameInput) {
            usernameInput.value = savedUsername;
            document.getElementById('password')?.focus();
        }
    }
}

// Afficher un message d'erreur
function showError(message) {
    const alertContainer = document.getElementById('alertContainer');
    if (!alertContainer) {
        alert(message);
        return;
    }

    alertContainer.innerHTML = `
        <div class="alert alert-danger" role="alert">
            <i class="fas fa-exclamation-circle"></i>
            ${message}
        </div>
    `;

    // Auto-hide après 5 secondes
    setTimeout(() => {
        alertContainer.innerHTML = '';
    }, 5000);
}

// Afficher un message de succès
function showSuccess(message) {
    const alertContainer = document.getElementById('alertContainer');
    if (!alertContainer) {
        return;
    }

    alertContainer.innerHTML = `
        <div class="alert alert-success" role="alert">
            <i class="fas fa-check-circle"></i>
            ${message}
        </div>
    `;
}

// Sauvegarder le username si "Remember me"
function saveUsername(username) {
    const rememberMe = document.getElementById('rememberMe')?.checked;
    if (rememberMe) {
        localStorage.setItem('user_manager_username', username);
    } else {
        localStorage.removeItem('user_manager_username');
    }
}
