<!DOCTYPE html>
<html lang="fr">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Paramètres - Bolt.DIY User Manager</title>
    
    <!-- CSS -->
    <link rel="stylesheet" href="/user-manager/assets/css/style.css">
    <link rel="stylesheet" href="/user-manager/assets/css/settings.css">
    
    <!-- Font Awesome -->
    <link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.4.0/css/all.min.css">
</head>
<body>
    <!-- Sidebar -->
    <aside class="sidebar">
        <div class="sidebar-header">
            <div class="logo">
                <i class="fas fa-shield-alt"></i>
                <span>User Manager</span>
            </div>
        </div>
        
        <nav class="sidebar-nav">
            <a href="/user-manager/" class="nav-link">
                <i class="fas fa-home"></i>
                <span>Dashboard</span>
            </a>
            <a href="/user-manager/users" class="nav-link">
                <i class="fas fa-users"></i>
                <span>Utilisateurs</span>
            </a>
            <a href="/user-manager/groups" class="nav-link">
                <i class="fas fa-user-friends"></i>
                <span>Groupes</span>
            </a>
            <a href="/user-manager/permissions" class="nav-link">
                <i class="fas fa-key"></i>
                <span>Permissions</span>
            </a>
            <a href="/user-manager/audit" class="nav-link">
                <i class="fas fa-clipboard-list"></i>
                <span>Audit</span>
            </a>
            <a href="/user-manager/settings" class="nav-link active">
                <i class="fas fa-cog"></i>
                <span>Paramètres</span>
            </a>
        </nav>
        
        <div class="sidebar-footer">
            <div class="user-info">
                <div class="user-avatar">
                    <i class="fas fa-user"></i>
                </div>
                <div class="user-details">
                    <div class="user-name">Admin User</div>
                    <div class="user-role">Administrateur</div>
                </div>
            </div>
        </div>
    </aside>

    <!-- Main Content -->
    <main class="main-content">
        <div class="settings-container">
            <!-- Page Header -->
            <div class="page-header">
                <h1 class="page-title">Paramètres</h1>
            </div>

            <!-- Settings Tabs -->
            <div class="settings-tabs">
                <button class="settings-tab active" data-tab="smtp">
                    <i class="fas fa-envelope"></i> SMTP
                </button>
                <button class="settings-tab" data-tab="security">
                    <i class="fas fa-shield-alt"></i> Sécurité
                </button>
                <button class="settings-tab" data-tab="general">
                    <i class="fas fa-cog"></i> Général
                </button>
                <button class="settings-tab" data-tab="maintenance">
                    <i class="fas fa-tools"></i> Maintenance
                </button>
            </div>

            <!-- SMTP Settings -->
            <div id="smtpSettings" class="settings-section active">
                <div class="settings-card">
                    <div class="settings-card-header">
                        <div>
                            <h2 class="settings-card-title">Configuration SMTP</h2>
                            <p class="settings-card-description">
                                Configurez les paramètres d'envoi d'emails pour les notifications système
                            </p>
                        </div>
                        <div class="settings-card-icon">
                            <i class="fas fa-envelope"></i>
                        </div>
                    </div>

                    <form id="smtpSettingsForm" onsubmit="saveSmtpSettings(event)">
                        <div class="form-row">
                            <div class="form-group">
                                <label class="form-label">Hôte SMTP <span class="required">*</span></label>
                                <input 
                                    type="text" 
                                    class="form-control" 
                                    id="smtpHost"
                                    name="host"
                                    placeholder="smtp.example.com"
                                    required
                                >
                            </div>
                            <div class="form-group">
                                <label class="form-label">Port <span class="required">*</span></label>
                                <input 
                                    type="number" 
                                    class="form-control" 
                                    id="smtpPort"
                                    name="port"
                                    placeholder="587"
                                    required
                                >
                            </div>
                        </div>

                        <div class="form-row">
                            <div class="form-group">
                                <label class="form-label">Nom d'utilisateur</label>
                                <input 
                                    type="text" 
                                    class="form-control" 
                                    id="smtpUsername"
                                    name="username"
                                    placeholder="user@example.com"
                                >
                            </div>
                            <div class="form-group">
                                <label class="form-label">Mot de passe</label>
                                <input 
                                    type="password" 
                                    class="form-control" 
                                    id="smtpPassword"
                                    name="password"
                                    placeholder="••••••••"
                                >
                            </div>
                        </div>

                        <div class="form-row">
                            <div class="form-group">
                                <label class="form-label">Chiffrement</label>
                                <select class="form-control" id="smtpEncryption" name="encryption">
                                    <option value="">Aucun</option>
                                    <option value="ssl">SSL</option>
                                    <option value="tls" selected>TLS</option>
                                </select>
                            </div>
                        </div>

                        <div class="form-row">
                            <div class="form-group">
                                <label class="form-label">Email d'expédition <span class="required">*</span></label>
                                <input 
                                    type="email" 
                                    class="form-control" 
                                    id="smtpFromEmail"
                                    name="from_email"
                                    placeholder="noreply@example.com"
                                    required
                                >
                            </div>
                            <div class="form-group">
                                <label class="form-label">Nom d'expédition</label>
                                <input 
                                    type="text" 
                                    class="form-control" 
                                    id="smtpFromName"
                                    name="from_name"
                                    placeholder="User Manager"
                                >
                            </div>
                        </div>

                        <div class="settings-actions">
                            <button type="submit" class="btn btn-primary">
                                <i class="fas fa-save"></i> Enregistrer les paramètres
                            </button>
                        </div>
                    </form>

                    <!-- Test SMTP -->
                    <div class="smtp-test-section">
                        <div class="smtp-test-header">
                            <div class="smtp-test-icon">
                                <i class="fas fa-paper-plane"></i>
                            </div>
                            <div>
                                <h3 class="smtp-test-title">Tester la configuration</h3>
                            </div>
                        </div>
                        <p class="smtp-test-description">
                            Envoyez un email de test pour vérifier que votre configuration SMTP fonctionne correctement
                        </p>

                        <form id="testSmtpForm" class="smtp-test-form" onsubmit="testSmtpConnection(event)">
                            <div class="form-group">
                                <label class="form-label">Email de test</label>
                                <input 
                                    type="email" 
                                    class="form-control" 
                                    id="testEmail"
                                    placeholder="test@example.com"
                                    required
                                >
                            </div>
                            <button type="submit" class="btn btn-secondary">
                                <i class="fas fa-paper-plane"></i> Envoyer un test
                            </button>
                        </form>

                        <div id="smtpTestResult" class="smtp-test-result"></div>
                    </div>
                </div>
            </div>

            <!-- Security Settings -->
            <div id="securitySettings" class="settings-section">
                <div class="settings-card">
                    <div class="settings-card-header">
                        <div>
                            <h2 class="settings-card-title">Paramètres de sécurité</h2>
                            <p class="settings-card-description">
                                Configurez les options de sécurité et d'authentification
                            </p>
                        </div>
                        <div class="settings-card-icon">
                            <i class="fas fa-shield-alt"></i>
                        </div>
                    </div>

                    <form id="securitySettingsForm" onsubmit="saveSecuritySettings(event)">
                        <!-- Security Options -->
                        <div class="security-option">
                            <div class="security-option-info">
                                <div class="security-option-title">Authentification à deux facteurs (2FA)</div>
                                <div class="security-option-description">
                                    Exiger l'authentification à deux facteurs pour tous les utilisateurs
                                </div>
                            </div>
                            <div class="security-option-control">
                                <label class="toggle-switch">
                                    <input type="checkbox" id="require2FA" name="require_2fa">
                                    <span class="toggle-slider"></span>
                                </label>
                            </div>
                        </div>

                        <div class="security-option">
                            <div class="security-option-info">
                                <div class="security-option-title">Mots de passe forts requis</div>
                                <div class="security-option-description">
                                    Imposer des règles strictes pour les mots de passe (majuscules, chiffres, caractères spéciaux)
                                </div>
                            </div>
                            <div class="security-option-control">
                                <label class="toggle-switch">
                                    <input type="checkbox" id="requireStrongPassword" name="require_strong_password" checked>
                                    <span class="toggle-slider"></span>
                                </label>
                            </div>
                        </div>

                        <div class="security-option">
                            <div class="security-option-info">
                                <div class="security-option-title">Expiration de session</div>
                                <div class="security-option-description">
                                    Déconnecter automatiquement les utilisateurs après une période d'inactivité
                                </div>
                            </div>
                            <div class="security-option-control">
                                <label class="toggle-switch">
                                    <input type="checkbox" id="sessionTimeout" name="session_timeout" checked>
                                    <span class="toggle-slider"></span>
                                </label>
                            </div>
                        </div>

                        <!-- Password Policy -->
                        <div class="password-policy-item">
                            <label class="password-policy-label">Délai d'expiration de session (minutes)</label>
                            <input 
                                type="number" 
                                class="form-control password-policy-input" 
                                id="sessionTimeoutMinutes"
                                name="session_timeout_minutes"
                                value="30"
                                min="5"
                                max="1440"
                            >
                        </div>

                        <div class="password-policy-item">
                            <label class="password-policy-label">Nombre maximum de tentatives de connexion</label>
                            <input 
                                type="number" 
                                class="form-control password-policy-input" 
                                id="maxLoginAttempts"
                                name="max_login_attempts"
                                value="5"
                                min="3"
                                max="10"
                            >
                        </div>

                        <div class="password-policy-item">
                            <label class="password-policy-label">Longueur minimale du mot de passe</label>
                            <input 
                                type="number" 
                                class="form-control password-policy-input" 
                                id="passwordMinLength"
                                name="password_min_length"
                                value="8"
                                min="6"
                                max="32"
                            >
                        </div>

                        <div class="settings-actions">
                            <button type="submit" class="btn btn-primary">
                                <i class="fas fa-save"></i> Enregistrer les paramètres
                            </button>
                        </div>
                    </form>
                </div>
            </div>

            <!-- General Settings -->
            <div id="generalSettings" class="settings-section">
                <div class="settings-card">
                    <div class="settings-card-header">
                        <div>
                            <h2 class="settings-card-title">Paramètres généraux</h2>
                            <p class="settings-card-description">
                                Configuration de base de l'application
                            </p>
                        </div>
                        <div class="settings-card-icon">
                            <i class="fas fa-cog"></i>
                        </div>
                    </div>

                    <form id="generalSettingsForm" onsubmit="saveGeneralSettings(event)">
                        <div class="form-row">
                            <div class="form-group">
                                <label class="form-label">Nom de l'application</label>
                                <input 
                                    type="text" 
                                    class="form-control" 
                                    id="appName"
                                    name="app_name"
                                    placeholder="Bolt.DIY User Manager"
                                >
                            </div>
                            <div class="form-group">
                                <label class="form-label">URL de l'application</label>
                                <input 
                                    type="url" 
                                    class="form-control" 
                                    id="appUrl"
                                    name="app_url"
                                    placeholder="https://example.com/user-manager"
                                >
                            </div>
                        </div>

                        <div class="form-row">
                            <div class="form-group">
                                <label class="form-label">Langue par défaut</label>
                                <select class="form-control" id="defaultLanguage" name="default_language">
                                    <option value="fr" selected>Français</option>
                                    <option value="en">English</option>
                                    <option value="es">Español</option>
                                    <option value="de">Deutsch</option>
                                </select>
                            </div>
                            <div class="form-group">
                                <label class="form-label">Fuseau horaire</label>
                                <select class="form-control" id="timezone" name="timezone">
                                    <option value="Europe/Paris" selected>Europe/Paris</option>
                                    <option value="Europe/London">Europe/London</option>
                                    <option value="America/New_York">America/New_York</option>
                                    <option value="America/Los_Angeles">America/Los_Angeles</option>
                                    <option value="Asia/Tokyo">Asia/Tokyo</option>
                                </select>
                            </div>
                        </div>

                        <div class="settings-actions">
                            <button type="submit" class="btn btn-primary">
                                <i class="fas fa-save"></i> Enregistrer les paramètres
                            </button>
                        </div>
                    </form>
                </div>
            </div>

            <!-- Maintenance Settings -->
            <div id="maintenanceSettings" class="settings-section">
                <div class="settings-card">
                    <div class="settings-card-header">
                        <div>
                            <h2 class="settings-card-title">Maintenance système</h2>
                            <p class="settings-card-description">
                                Outils de maintenance et de gestion du système
                            </p>
                        </div>
                        <div class="settings-card-icon">
                            <i class="fas fa-tools"></i>
                        </div>
                    </div>

                    <div class="backup-item">
                        <div class="backup-info">
                            <div class="backup-title">Créer une sauvegarde</div>
                            <div class="backup-meta">
                                <span><i class="fas fa-info-circle"></i> Sauvegarde complète de la base de données</span>
                            </div>
                        </div>
                        <div class="backup-actions">
                            <button class="btn btn-secondary" onclick="createBackup()">
                                <i class="fas fa-download"></i> Créer une sauvegarde
                            </button>
                        </div>
                    </div>

                    <div class="backup-item">
                        <div class="backup-info">
                            <div class="backup-title">Vider le cache</div>
                            <div class="backup-meta">
                                <span><i class="fas fa-info-circle"></i> Supprime tous les fichiers temporaires</span>
                            </div>
                        </div>
                        <div class="backup-actions">
                            <button class="btn btn-secondary" onclick="clearCache()">
                                <i class="fas fa-trash"></i> Vider le cache
                            </button>
                        </div>
                    </div>
                </div>

                <!-- Danger Zone -->
                <div class="danger-zone">
                    <div class="danger-zone-header">
                        <div class="danger-zone-icon">
                            <i class="fas fa-exclamation-triangle"></i>
                        </div>
                        <h3 class="danger-zone-title">Zone dangereuse</h3>
                    </div>
                    <p class="danger-zone-description">
                        Les actions suivantes sont irréversibles et peuvent avoir un impact important sur le système. Assurez-vous de bien comprendre les conséquences avant de continuer.
                    </p>
                    <button class="btn btn-danger" onclick="resetSettings()">
                        <i class="fas fa-undo"></i> Réinitialiser tous les paramètres
                    </button>
                </div>
            </div>
        </div>
    </main>

    <!-- JavaScript -->
    <script src="/user-manager/assets/js/app.js"></script>
    <script src="/user-manager/assets/js/settings.js"></script>
</body>
</html>
