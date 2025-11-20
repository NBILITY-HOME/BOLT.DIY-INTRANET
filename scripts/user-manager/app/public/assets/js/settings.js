/* ============================================
   Bolt.DIY User Manager - Settings JS
   Version: 1.0
   Date: 19 novembre 2025
   ============================================ */

// État global des paramètres
let settingsState = {
    smtp: {},
    security: {},
    general: {},
    activeTab: 'smtp'
};

/* ============================================
   INITIALISATION
   ============================================ */

document.addEventListener('DOMContentLoaded', function() {
    console.log('🎯 Settings.js loaded');
    
    loadSettings();
    setupEventListeners();
    
    // Activer le premier onglet
    const firstTab = document.querySelector('.settings-tab');
    if (firstTab) {
        switchTab('smtp');
    }
});

/* ============================================
   CHARGEMENT DES PARAMÈTRES
   ============================================ */

async function loadSettings() {
    try {
        showLoader();
        
        const response = await fetch('/user-manager/api/settings.php');
        if (!response.ok) throw new Error('Failed to load settings');
        
        const data = await response.json();
        
        if (data.success) {
            settingsState.smtp = data.settings.smtp || {};
            settingsState.security = data.settings.security || {};
            settingsState.general = data.settings.general || {};
            
            populateSettings();
            console.log('✅ Settings loaded');
        } else {
            throw new Error(data.message || 'Failed to load settings');
        }
    } catch (error) {
        console.error('❌ Error loading settings:', error);
        showToast('Erreur lors du chargement des paramètres', 'error');
    } finally {
        hideLoader();
    }
}

/* ============================================
   POPULATION DES FORMULAIRES
   ============================================ */

function populateSettings() {
    // SMTP Settings
    const smtp = settingsState.smtp;
    if (smtp) {
        setInputValue('smtpHost', smtp.host);
        setInputValue('smtpPort', smtp.port);
        setInputValue('smtpUsername', smtp.username);
        setInputValue('smtpPassword', smtp.password);
        setInputValue('smtpEncryption', smtp.encryption);
        setInputValue('smtpFromEmail', smtp.from_email);
        setInputValue('smtpFromName', smtp.from_name);
    }
    
    // Security Settings
    const security = settingsState.security;
    if (security) {
        setCheckboxValue('require2FA', security.require_2fa);
        setCheckboxValue('requireStrongPassword', security.require_strong_password);
        setCheckboxValue('sessionTimeout', security.session_timeout_enabled);
        setInputValue('sessionTimeoutMinutes', security.session_timeout_minutes);
        setInputValue('maxLoginAttempts', security.max_login_attempts);
        setInputValue('passwordMinLength', security.password_min_length);
    }
    
    // General Settings
    const general = settingsState.general;
    if (general) {
        setInputValue('appName', general.app_name);
        setInputValue('appUrl', general.app_url);
        setInputValue('defaultLanguage', general.default_language);
        setInputValue('timezone', general.timezone);
    }
}

function setInputValue(id, value) {
    const element = document.getElementById(id);
    if (element && value !== undefined && value !== null) {
        element.value = value;
    }
}

function setCheckboxValue(id, value) {
    const element = document.getElementById(id);
    if (element && value !== undefined && value !== null) {
        element.checked = Boolean(value);
    }
}

/* ============================================
   GESTION DES ONGLETS
   ============================================ */

function switchTab(tabName) {
    // Update tabs
    document.querySelectorAll('.settings-tab').forEach(tab => {
        tab.classList.remove('active');
    });
    
    const activeTab = document.querySelector(`[data-tab="${tabName}"]`);
    if (activeTab) {
        activeTab.classList.add('active');
    }
    
    // Update sections
    document.querySelectorAll('.settings-section').forEach(section => {
        section.classList.remove('active');
    });
    
    const activeSection = document.getElementById(`${tabName}Settings`);
    if (activeSection) {
        activeSection.classList.add('active');
    }
    
    settingsState.activeTab = tabName;
}

/* ============================================
   SMTP SETTINGS
   ============================================ */

async function saveSmtpSettings(event) {
    event.preventDefault();
    
    const form = event.target;
    const formData = new FormData(form);
    
    const smtpData = {
        host: formData.get('host'),
        port: parseInt(formData.get('port')),
        username: formData.get('username'),
        password: formData.get('password'),
        encryption: formData.get('encryption'),
        from_email: formData.get('from_email'),
        from_name: formData.get('from_name')
    };
    
    // Validation
    if (!smtpData.host || !smtpData.port || !smtpData.from_email) {
        showToast('Veuillez remplir tous les champs obligatoires', 'error');
        return;
    }
    
    try {
        showLoader();
        
        const response = await fetch('/user-manager/api/settings.php', {
            method: 'POST',
            headers: {
                'Content-Type': 'application/json'
            },
            body: JSON.stringify({
                section: 'smtp',
                data: smtpData
            })
        });
        
        if (!response.ok) throw new Error('Request failed');
        
        const data = await response.json();
        
        if (data.success) {
            settingsState.smtp = smtpData;
            showToast('Paramètres SMTP enregistrés avec succès', 'success');
        } else {
            throw new Error(data.message || 'Failed to save settings');
        }
    } catch (error) {
        console.error('❌ Error saving SMTP settings:', error);
        showToast('Erreur lors de l\'enregistrement des paramètres', 'error');
    } finally {
        hideLoader();
    }
}

async function testSmtpConnection(event) {
    event.preventDefault();
    
    const testEmail = document.getElementById('testEmail').value;
    
    if (!testEmail) {
        showToast('Veuillez entrer une adresse email de test', 'error');
        return;
    }
    
    // Validate email
    const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
    if (!emailRegex.test(testEmail)) {
        showToast('Adresse email invalide', 'error');
        return;
    }
    
    const resultDiv = document.getElementById('smtpTestResult');
    resultDiv.style.display = 'none';
    resultDiv.className = 'smtp-test-result';
    
    try {
        showLoader();
        
        const response = await fetch('/user-manager/api/settings.php?action=test_smtp', {
            method: 'POST',
            headers: {
                'Content-Type': 'application/json'
            },
            body: JSON.stringify({
                email: testEmail,
                smtp_config: settingsState.smtp
            })
        });
        
        if (!response.ok) throw new Error('Request failed');
        
        const data = await response.json();
        
        if (data.success) {
            resultDiv.className = 'smtp-test-result success';
            resultDiv.innerHTML = `<i class="fas fa-check-circle"></i> ${data.message}`;
            showToast('Email de test envoyé avec succès', 'success');
        } else {
            resultDiv.className = 'smtp-test-result error';
            resultDiv.innerHTML = `<i class="fas fa-times-circle"></i> ${data.message}`;
            showToast('Échec de l\'envoi de l\'email de test', 'error');
        }
        
        resultDiv.style.display = 'block';
    } catch (error) {
        console.error('❌ Error testing SMTP:', error);
        resultDiv.className = 'smtp-test-result error';
        resultDiv.innerHTML = `<i class="fas fa-times-circle"></i> Erreur lors du test de connexion SMTP`;
        resultDiv.style.display = 'block';
        showToast('Erreur lors du test de connexion', 'error');
    } finally {
        hideLoader();
    }
}

/* ============================================
   SECURITY SETTINGS
   ============================================ */

async function saveSecuritySettings(event) {
    event.preventDefault();
    
    const form = event.target;
    const formData = new FormData(form);
    
    const securityData = {
        require_2fa: formData.get('require_2fa') === 'on',
        require_strong_password: formData.get('require_strong_password') === 'on',
        session_timeout_enabled: formData.get('session_timeout') === 'on',
        session_timeout_minutes: parseInt(formData.get('session_timeout_minutes')) || 30,
        max_login_attempts: parseInt(formData.get('max_login_attempts')) || 5,
        password_min_length: parseInt(formData.get('password_min_length')) || 8
    };
    
    try {
        showLoader();
        
        const response = await fetch('/user-manager/api/settings.php', {
            method: 'POST',
            headers: {
                'Content-Type': 'application/json'
            },
            body: JSON.stringify({
                section: 'security',
                data: securityData
            })
        });
        
        if (!response.ok) throw new Error('Request failed');
        
        const data = await response.json();
        
        if (data.success) {
            settingsState.security = securityData;
            showToast('Paramètres de sécurité enregistrés avec succès', 'success');
        } else {
            throw new Error(data.message || 'Failed to save settings');
        }
    } catch (error) {
        console.error('❌ Error saving security settings:', error);
        showToast('Erreur lors de l\'enregistrement des paramètres', 'error');
    } finally {
        hideLoader();
    }
}

/* ============================================
   GENERAL SETTINGS
   ============================================ */

async function saveGeneralSettings(event) {
    event.preventDefault();
    
    const form = event.target;
    const formData = new FormData(form);
    
    const generalData = {
        app_name: formData.get('app_name'),
        app_url: formData.get('app_url'),
        default_language: formData.get('default_language'),
        timezone: formData.get('timezone')
    };
    
    try {
        showLoader();
        
        const response = await fetch('/user-manager/api/settings.php', {
            method: 'POST',
            headers: {
                'Content-Type': 'application/json'
            },
            body: JSON.stringify({
                section: 'general',
                data: generalData
            })
        });
        
        if (!response.ok) throw new Error('Request failed');
        
        const data = await response.json();
        
        if (data.success) {
            settingsState.general = generalData;
            showToast('Paramètres généraux enregistrés avec succès', 'success');
        } else {
            throw new Error(data.message || 'Failed to save settings');
        }
    } catch (error) {
        console.error('❌ Error saving general settings:', error);
        showToast('Erreur lors de l\'enregistrement des paramètres', 'error');
    } finally {
        hideLoader();
    }
}

/* ============================================
   BACKUP & MAINTENANCE
   ============================================ */

async function createBackup() {
    if (!confirm('Créer une sauvegarde complète du système ?')) {
        return;
    }
    
    try {
        showLoader();
        
        const response = await fetch('/user-manager/api/settings.php?action=create_backup', {
            method: 'POST'
        });
        
        if (!response.ok) throw new Error('Request failed');
        
        const data = await response.json();
        
        if (data.success) {
            showToast('Sauvegarde créée avec succès', 'success');
        } else {
            throw new Error(data.message || 'Failed to create backup');
        }
    } catch (error) {
        console.error('❌ Error creating backup:', error);
        showToast('Erreur lors de la création de la sauvegarde', 'error');
    } finally {
        hideLoader();
    }
}

async function clearCache() {
    if (!confirm('Vider le cache du système ?')) {
        return;
    }
    
    try {
        showLoader();
        
        const response = await fetch('/user-manager/api/settings.php?action=clear_cache', {
            method: 'POST'
        });
        
        if (!response.ok) throw new Error('Request failed');
        
        const data = await response.json();
        
        if (data.success) {
            showToast('Cache vidé avec succès', 'success');
        } else {
            throw new Error(data.message || 'Failed to clear cache');
        }
    } catch (error) {
        console.error('❌ Error clearing cache:', error);
        showToast('Erreur lors du vidage du cache', 'error');
    } finally {
        hideLoader();
    }
}

async function resetSettings() {
    if (!confirm('⚠️ ATTENTION: Cette action réinitialisera TOUS les paramètres aux valeurs par défaut. Êtes-vous sûr ?')) {
        return;
    }
    
    try {
        showLoader();
        
        const response = await fetch('/user-manager/api/settings.php?action=reset_all', {
            method: 'POST'
        });
        
        if (!response.ok) throw new Error('Request failed');
        
        const data = await response.json();
        
        if (data.success) {
            showToast('Paramètres réinitialisés avec succès', 'success');
            setTimeout(() => {
                window.location.reload();
            }, 1500);
        } else {
            throw new Error(data.message || 'Failed to reset settings');
        }
    } catch (error) {
        console.error('❌ Error resetting settings:', error);
        showToast('Erreur lors de la réinitialisation', 'error');
    } finally {
        hideLoader();
    }
}

/* ============================================
   EVENT LISTENERS
   ============================================ */

function setupEventListeners() {
    // Tab switching
    document.querySelectorAll('.settings-tab').forEach(tab => {
        tab.addEventListener('click', function() {
            const tabName = this.getAttribute('data-tab');
            switchTab(tabName);
        });
    });
    
    // Form submissions
    const smtpForm = document.getElementById('smtpSettingsForm');
    if (smtpForm) {
        smtpForm.addEventListener('submit', saveSmtpSettings);
    }
    
    const securityForm = document.getElementById('securitySettingsForm');
    if (securityForm) {
        securityForm.addEventListener('submit', saveSecuritySettings);
    }
    
    const generalForm = document.getElementById('generalSettingsForm');
    if (generalForm) {
        generalForm.addEventListener('submit', saveGeneralSettings);
    }
    
    const testSmtpForm = document.getElementById('testSmtpForm');
    if (testSmtpForm) {
        testSmtpForm.addEventListener('submit', testSmtpConnection);
    }
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
