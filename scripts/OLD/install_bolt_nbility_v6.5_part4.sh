
# ═══════════════════════════════════════════════════════════════════════════
# FONCTION: Génération fichiers .env
# ═══════════════════════════════════════════════════════════════════════════
generate_env_files() {
    print_section "GÉNÉRATION DES FICHIERS .ENV"

    # Fichier .env principal du projet (pour docker-compose)
    print_step "Création du fichier .env principal..."
    cat > "$INSTALL_DIR/.env" << ENV_MAIN_EOF
# ════════════════════════════════════════════════════════════════
# BOLT.DIY INTRANET - Configuration Docker v6.5
# ════════════════════════════════════════════════════════════════

# Configuration réseau
LOCAL_IP=$LOCAL_IP

# Ports des services
HOST_PORT_BOLT=$HOST_PORT_BOLT
HOST_PORT_HOME=$HOST_PORT_HOME
HOST_PORT_UM=$HOST_PORT_UM
MARIADB_PORT=$MARIADB_PORT

# Authentification NGINX
HTPASSWD_FILE=$HTPASSWD_FILE

# MariaDB Configuration
MARIADB_ROOT_PASSWORD=$MARIADB_ROOT_PASSWORD
MARIADB_USER=bolt_um
MARIADB_PASSWORD=$MARIADB_USER_PASSWORD

# Application Security
APP_SECRET=$APP_SECRET

# API Keys (Optionnel)
ANTHROPIC_API_KEY=$ANTHROPIC_KEY
OPENAI_API_KEY=$OPENAI_KEY
GOOGLE_GENERATIVE_AI_API_KEY=$GEMINI_KEY
GROQ_API_KEY=$GROQ_KEY
MISTRAL_API_KEY=$MISTRAL_KEY
DEEPSEEK_API_KEY=$DEEPSEEK_KEY
HF_API_KEY=$HF_KEY
ENV_MAIN_EOF

    print_success "Fichier .env principal créé"

    # Fichier .env pour Bolt.DIY
    print_step "Création du fichier .env pour Bolt.DIY..."
    cat > "$BOLT_DIR/.env" << ENV_BOLT_EOF
# ════════════════════════════════════════════════════════════════
# BOLT.DIY CONFIGURATION - v6.5
# ════════════════════════════════════════════════════════════════

# URLs et Routing (CRITIQUE: Préservation du port)
BASE_URL=http://$LOCAL_IP:$HOST_PORT_BOLT
APP_URL=http://$LOCAL_IP:$HOST_PORT_BOLT
PUBLIC_URL=http://$LOCAL_IP:$HOST_PORT_BOLT
VITE_BASE_URL=/
VITE_ROUTER_BASE=/
BASE_PATH=/
ROUTER_BASE=/

# API Keys
ANTHROPIC_API_KEY=$ANTHROPIC_KEY
OPENAI_API_KEY=$OPENAI_KEY
GOOGLE_GENERATIVE_AI_API_KEY=$GEMINI_KEY
GROQ_API_KEY=$GROQ_KEY
MISTRAL_API_KEY=$MISTRAL_KEY
DEEPSEEK_API_KEY=$DEEPSEEK_KEY
HF_API_KEY=$HF_KEY

# Développement
NODE_ENV=production
VITE_LOG_LEVEL=info

# Sécurité
SESSION_SECRET=changeme_with_random_string

# Serveur
PORT=5173
HOST=0.0.0.0
ENV_BOLT_EOF

    print_success "Fichier .env Bolt créé"
    echo ""
}

# ═══════════════════════════════════════════════════════════════════════════
# FONCTION: Création du schéma SQL
# ═══════════════════════════════════════════════════════════════════════════
create_sql_schema() {
    print_section "CRÉATION DU SCHÉMA SQL MARIADB"
    
    mkdir -p "$MARIADB_DIR/init"
    
    cat > "$MARIADB_DIR/init/01-schema.sql" << 'SQL_SCHEMA'
-- ═══════════════════════════════════════════════════════════════════════════
-- BOLT.DIY USER MANAGER v2.0 - Database Schema
-- © Copyright Nbility 2025
-- ═══════════════════════════════════════════════════════════════════════════

SET NAMES utf8mb4;
SET FOREIGN_KEY_CHECKS = 0;

-- ───────────────────────────────────────────────────────────────────────────
-- Table: users
-- ───────────────────────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS `users` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `username` varchar(50) NOT NULL,
  `email` varchar(255) NOT NULL,
  `password_hash` varchar(255) NOT NULL,
  `first_name` varchar(100) DEFAULT NULL,
  `last_name` varchar(100) DEFAULT NULL,
  `phone` varchar(20) DEFAULT NULL,
  `avatar_url` varchar(500) DEFAULT NULL,
  `is_active` tinyint(1) DEFAULT 1,
  `is_super_admin` tinyint(1) DEFAULT 0,
  `email_verified` tinyint(1) DEFAULT 0,
  `email_verification_token` varchar(100) DEFAULT NULL,
  `password_reset_token` varchar(100) DEFAULT NULL,
  `password_reset_expires` datetime DEFAULT NULL,
  `last_login_at` datetime DEFAULT NULL,
  `last_login_ip` varchar(45) DEFAULT NULL,
  `failed_login_attempts` int(11) DEFAULT 0,
  `lockout_until` datetime DEFAULT NULL,
  `created_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  UNIQUE KEY `username` (`username`),
  UNIQUE KEY `email` (`email`),
  KEY `idx_email_verified` (`email_verified`),
  KEY `idx_is_active` (`is_active`),
  KEY `idx_is_super_admin` (`is_super_admin`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ───────────────────────────────────────────────────────────────────────────
-- Table: groups
-- ───────────────────────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS `groups` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `name` varchar(100) NOT NULL,
  `description` text DEFAULT NULL,
  `color` varchar(7) DEFAULT '#3498db',
  `icon` varchar(50) DEFAULT 'users',
  `is_system` tinyint(1) DEFAULT 0,
  `created_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  UNIQUE KEY `name` (`name`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ───────────────────────────────────────────────────────────────────────────
-- Table: user_groups
-- ───────────────────────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS `user_groups` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `user_id` int(11) NOT NULL,
  `group_id` int(11) NOT NULL,
  `created_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  UNIQUE KEY `user_group_unique` (`user_id`, `group_id`),
  KEY `fk_user_groups_user` (`user_id`),
  KEY `fk_user_groups_group` (`group_id`),
  CONSTRAINT `fk_user_groups_user` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`) ON DELETE CASCADE,
  CONSTRAINT `fk_user_groups_group` FOREIGN KEY (`group_id`) REFERENCES `groups` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ───────────────────────────────────────────────────────────────────────────
-- Table: permissions
-- ───────────────────────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS `permissions` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `name` varchar(100) NOT NULL,
  `slug` varchar(100) NOT NULL,
  `description` text DEFAULT NULL,
  `category` varchar(50) DEFAULT 'general',
  `created_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  UNIQUE KEY `slug` (`slug`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ───────────────────────────────────────────────────────────────────────────
-- Table: group_permissions
-- ───────────────────────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS `group_permissions` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `group_id` int(11) NOT NULL,
  `permission_id` int(11) NOT NULL,
  `created_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  UNIQUE KEY `group_permission_unique` (`group_id`, `permission_id`),
  KEY `fk_group_permissions_group` (`group_id`),
  KEY `fk_group_permissions_permission` (`permission_id`),
  CONSTRAINT `fk_group_permissions_group` FOREIGN KEY (`group_id`) REFERENCES `groups` (`id`) ON DELETE CASCADE,
  CONSTRAINT `fk_group_permissions_permission` FOREIGN KEY (`permission_id`) REFERENCES `permissions` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ───────────────────────────────────────────────────────────────────────────
-- Table: sessions
-- ───────────────────────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS `sessions` (
  `id` varchar(128) NOT NULL,
  `user_id` int(11) NOT NULL,
  `ip_address` varchar(45) DEFAULT NULL,
  `user_agent` text DEFAULT NULL,
  `payload` longtext NOT NULL,
  `last_activity` int(11) NOT NULL,
  `created_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  KEY `fk_sessions_user` (`user_id`),
  KEY `idx_last_activity` (`last_activity`),
  CONSTRAINT `fk_sessions_user` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ───────────────────────────────────────────────────────────────────────────
-- Table: audit_logs
-- ───────────────────────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS `audit_logs` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `user_id` int(11) DEFAULT NULL,
  `action` varchar(100) NOT NULL,
  `entity_type` varchar(50) DEFAULT NULL,
  `entity_id` int(11) DEFAULT NULL,
  `old_values` json DEFAULT NULL,
  `new_values` json DEFAULT NULL,
  `ip_address` varchar(45) DEFAULT NULL,
  `user_agent` text DEFAULT NULL,
  `created_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  KEY `fk_audit_logs_user` (`user_id`),
  KEY `idx_action` (`action`),
  KEY `idx_entity` (`entity_type`, `entity_id`),
  KEY `idx_created_at` (`created_at`),
  CONSTRAINT `fk_audit_logs_user` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ───────────────────────────────────────────────────────────────────────────
-- Table: settings
-- ───────────────────────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS `settings` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `key` varchar(100) NOT NULL,
  `value` text DEFAULT NULL,
  `type` varchar(20) DEFAULT 'string',
  `description` text DEFAULT NULL,
  `category` varchar(50) DEFAULT 'general',
  `updated_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  UNIQUE KEY `key` (`key`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ───────────────────────────────────────────────────────────────────────────
-- Table: themes
-- ───────────────────────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS `themes` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `name` varchar(100) NOT NULL,
  `slug` varchar(100) NOT NULL,
  `primary_color` varchar(7) DEFAULT '#3498db',
  `secondary_color` varchar(7) DEFAULT '#2ecc71',
  `background_color` varchar(7) DEFAULT '#ffffff',
  `text_color` varchar(7) DEFAULT '#2c3e50',
  `is_default` tinyint(1) DEFAULT 0,
  `is_active` tinyint(1) DEFAULT 1,
  `created_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  UNIQUE KEY `slug` (`slug`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ───────────────────────────────────────────────────────────────────────────
-- Table: notifications
-- ───────────────────────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS `notifications` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `user_id` int(11) NOT NULL,
  `type` varchar(50) NOT NULL,
  `title` varchar(255) NOT NULL,
  `message` text NOT NULL,
  `data` json DEFAULT NULL,
  `is_read` tinyint(1) DEFAULT 0,
  `read_at` datetime DEFAULT NULL,
  `created_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  KEY `fk_notifications_user` (`user_id`),
  KEY `idx_is_read` (`is_read`),
  CONSTRAINT `fk_notifications_user` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ───────────────────────────────────────────────────────────────────────────
-- Table: webhooks
-- ───────────────────────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS `webhooks` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `name` varchar(100) NOT NULL,
  `url` varchar(500) NOT NULL,
  `secret` varchar(100) DEFAULT NULL,
  `events` json NOT NULL,
  `is_active` tinyint(1) DEFAULT 1,
  `last_triggered_at` datetime DEFAULT NULL,
  `failure_count` int(11) DEFAULT 0,
  `created_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ───────────────────────────────────────────────────────────────────────────
-- Table: webhook_logs
-- ───────────────────────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS `webhook_logs` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `webhook_id` int(11) NOT NULL,
  `event` varchar(100) NOT NULL,
  `payload` json NOT NULL,
  `response_code` int(11) DEFAULT NULL,
  `response_body` text DEFAULT NULL,
  `is_success` tinyint(1) DEFAULT 0,
  `error_message` text DEFAULT NULL,
  `created_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  KEY `fk_webhook_logs_webhook` (`webhook_id`),
  KEY `idx_created_at` (`created_at`),
  CONSTRAINT `fk_webhook_logs_webhook` FOREIGN KEY (`webhook_id`) REFERENCES `webhooks` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ───────────────────────────────────────────────────────────────────────────
-- Table: reports
-- ───────────────────────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS `reports` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `name` varchar(255) NOT NULL,
  `type` varchar(50) NOT NULL,
  `parameters` json DEFAULT NULL,
  `file_path` varchar(500) DEFAULT NULL,
  `file_size` bigint(20) DEFAULT NULL,
  `status` enum('pending','processing','completed','failed') DEFAULT 'pending',
  `generated_by` int(11) DEFAULT NULL,
  `generated_at` datetime DEFAULT NULL,
  `created_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  KEY `fk_reports_user` (`generated_by`),
  KEY `idx_status` (`status`),
  CONSTRAINT `fk_reports_user` FOREIGN KEY (`generated_by`) REFERENCES `users` (`id`) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ───────────────────────────────────────────────────────────────────────────
-- Table: email_templates
-- ───────────────────────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS `email_templates` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `name` varchar(100) NOT NULL,
  `slug` varchar(100) NOT NULL,
  `subject` varchar(255) NOT NULL,
  `body_html` text NOT NULL,
  `body_text` text DEFAULT NULL,
  `variables` json DEFAULT NULL,
  `is_system` tinyint(1) DEFAULT 0,
  `created_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  UNIQUE KEY `slug` (`slug`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

SET FOREIGN_KEY_CHECKS = 1;
SQL_SCHEMA

    print_success "Schéma SQL créé (14 tables)"
}

# ═══════════════════════════════════════════════════════════════════════════
# FONCTION: Création des données initiales SQL
# ═══════════════════════════════════════════════════════════════════════════
create_sql_seed() {
    print_step "Création des données initiales..."
    
    local ADMIN_PASSWORD_HASH
    ADMIN_PASSWORD_HASH=$(php -r "echo password_hash('$ADMIN_PASSWORD', PASSWORD_BCRYPT);")
    
    cat > "$MARIADB_DIR/init/02-seed.sql" << SQL_SEED
-- ═══════════════════════════════════════════════════════════════════════════
-- BOLT.DIY USER MANAGER v2.0 - Initial Data
-- © Copyright Nbility 2025
-- ═══════════════════════════════════════════════════════════════════════════

SET NAMES utf8mb4;

-- ───────────────────────────────────────────────────────────────────────────
-- Insertion du Super Admin
-- ───────────────────────────────────────────────────────────────────────────
INSERT INTO users (username, email, password_hash, first_name, last_name, is_active, is_super_admin, email_verified)
VALUES ('$ADMIN_USERNAME', '$ADMIN_EMAIL', '$ADMIN_PASSWORD_HASH', 'Super', 'Admin', 1, 1, 1);

-- ───────────────────────────────────────────────────────────────────────────
-- Groupes par défaut
-- ───────────────────────────────────────────────────────────────────────────
INSERT INTO \`groups\` (name, description, color, icon, is_system) VALUES
('Administrateurs', 'Accès complet au système', '#e74c3c', 'shield', 1),
('Développeurs', 'Équipe de développement', '#3498db', 'code', 0),
('Support', 'Équipe support client', '#2ecc71', 'headset', 0),
('Utilisateurs', 'Utilisateurs standard', '#95a5a6', 'users', 1);

-- ───────────────────────────────────────────────────────────────────────────
-- Permissions par défaut
-- ───────────────────────────────────────────────────────────────────────────
INSERT INTO permissions (name, slug, description, category) VALUES
('Gérer les utilisateurs', 'manage_users', 'Créer, modifier et supprimer des utilisateurs', 'users'),
('Voir les utilisateurs', 'view_users', 'Consulter la liste des utilisateurs', 'users'),
('Gérer les groupes', 'manage_groups', 'Créer, modifier et supprimer des groupes', 'groups'),
('Voir les groupes', 'view_groups', 'Consulter la liste des groupes', 'groups'),
('Gérer les permissions', 'manage_permissions', 'Attribuer et retirer des permissions', 'permissions'),
('Voir les logs', 'view_audit_logs', 'Consulter les logs d\'audit', 'logs'),
('Gérer les settings', 'manage_settings', 'Modifier les paramètres système', 'settings'),
('Gérer les thèmes', 'manage_themes', 'Créer et modifier des thèmes', 'themes'),
('Gérer les webhooks', 'manage_webhooks', 'Configurer les webhooks', 'webhooks'),
('Générer des rapports', 'generate_reports', 'Créer et exporter des rapports', 'reports');

-- ───────────────────────────────────────────────────────────────────────────
-- Attribution groupe Administrateurs au Super Admin
-- ───────────────────────────────────────────────────────────────────────────
INSERT INTO user_groups (user_id, group_id)
SELECT 1, id FROM \`groups\` WHERE name = 'Administrateurs';

-- ───────────────────────────────────────────────────────────────────────────
-- Attribution de toutes les permissions au groupe Administrateurs
-- ───────────────────────────────────────────────────────────────────────────
INSERT INTO group_permissions (group_id, permission_id)
SELECT g.id, p.id
FROM \`groups\` g
CROSS JOIN permissions p
WHERE g.name = 'Administrateurs';

-- ───────────────────────────────────────────────────────────────────────────
-- Settings par défaut
-- ───────────────────────────────────────────────────────────────────────────
INSERT INTO settings (\`key\`, value, type, description, category) VALUES
('site_name', 'Bolt.DIY User Manager', 'string', 'Nom du site', 'general'),
('site_description', 'Système de gestion des utilisateurs', 'string', 'Description du site', 'general'),
('items_per_page', '20', 'integer', 'Nombre d''éléments par page', 'general'),
('session_lifetime', '7200', 'integer', 'Durée de session en secondes (2h)', 'security'),
('max_login_attempts', '5', 'integer', 'Tentatives de connexion max', 'security'),
('lockout_duration', '900', 'integer', 'Durée de verrouillage en secondes (15min)', 'security'),
('password_min_length', '8', 'integer', 'Longueur minimale du mot de passe', 'security'),
('require_email_verification', '1', 'boolean', 'Vérification email obligatoire', 'security'),
('smtp_host', '', 'string', 'Serveur SMTP', 'email'),
('smtp_port', '587', 'integer', 'Port SMTP', 'email'),
('smtp_username', '', 'string', 'Utilisateur SMTP', 'email'),
('smtp_password', '', 'string', 'Mot de passe SMTP', 'email'),
('smtp_encryption', 'tls', 'string', 'Encryption SMTP (tls/ssl)', 'email'),
('smtp_from_email', 'noreply@example.com', 'string', 'Email expéditeur', 'email'),
('smtp_from_name', 'Bolt.DIY User Manager', 'string', 'Nom expéditeur', 'email');

-- ───────────────────────────────────────────────────────────────────────────
-- Thèmes par défaut
-- ───────────────────────────────────────────────────────────────────────────
INSERT INTO themes (name, slug, primary_color, secondary_color, background_color, text_color, is_default, is_active) VALUES
('Bleu par défaut', 'default-blue', '#3498db', '#2ecc71', '#ffffff', '#2c3e50', 1, 1),
('Sombre', 'dark', '#2c3e50', '#3498db', '#1a1a1a', '#ecf0f1', 0, 1),
('Vert professionnel', 'professional-green', '#27ae60', '#2ecc71', '#ffffff', '#2c3e50', 0, 1);

-- ───────────────────────────────────────────────────────────────────────────
-- Templates d'emails
-- ───────────────────────────────────────────────────────────────────────────
INSERT INTO email_templates (name, slug, subject, body_html, body_text, is_system) VALUES
('Vérification email', 'email_verification', 'Vérifiez votre adresse email', '<h1>Bienvenue!</h1><p>Cliquez sur le lien pour vérifier votre email: {{verification_link}}</p>', 'Bienvenue! Cliquez sur le lien pour vérifier votre email: {{verification_link}}', 1),
('Réinitialisation mot de passe', 'password_reset', 'Réinitialisation de votre mot de passe', '<h1>Réinitialisation</h1><p>Cliquez sur le lien pour réinitialiser votre mot de passe: {{reset_link}}</p>', 'Cliquez sur le lien pour réinitialiser votre mot de passe: {{reset_link}}', 1),
('Nouvel utilisateur', 'new_user', 'Votre compte a été créé', '<h1>Compte créé!</h1><p>Votre nom d''utilisateur: {{username}}</p><p>Mot de passe temporaire: {{temp_password}}</p>', 'Votre compte a été créé. Username: {{username}}, Mot de passe temporaire: {{temp_password}}', 1);
SQL_SEED

    print_success "Données initiales créées"
}

# ═══════════════════════════════════════════════════════════════════════════
# FONCTION: Création du fichier htpasswd
# ═══════════════════════════════════════════════════════════════════════════
create_htpasswd() {
    print_section "CRÉATION DU FICHIER HTPASSWD"

    print_step "Génération du fichier htpasswd pour NGINX..."

    if [ -f "$HTPASSWD_FILE" ]; then
        rm -f "$HTPASSWD_FILE"
        print_info "Ancien fichier htpasswd supprimé"
    fi

    if command -v htpasswd &> /dev/null; then
        if htpasswd -cbB "$HTPASSWD_FILE" "$NGINX_USER" "$NGINX_PASS"; then
            print_success "Fichier htpasswd créé avec bcrypt"
        else
            print_error "Échec de la création du fichier htpasswd"
            exit 1
        fi
    else
        print_error "La commande htpasswd n'est pas disponible"
        echo "Installation de apache2-utils..."
        if command -v apt-get &> /dev/null; then
            sudo apt-get update
            sudo apt-get install -y apache2-utils
            htpasswd -cbB "$HTPASSWD_FILE" "$NGINX_USER" "$NGINX_PASS"
        else
            print_error "Impossible d'installer htpasswd automatiquement"
            exit 1
        fi
    fi

    chmod 644 "$HTPASSWD_FILE"

    if [ -s "$HTPASSWD_FILE" ]; then
        print_success "Fichier htpasswd valide"
    else
        print_error "Fichier htpasswd VIDE"
        exit 1
    fi

    echo ""
}

# ═══════════════════════════════════════════════════════════════════════════
# FONCTION: Création des fichiers User Manager
# ═══════════════════════════════════════════════════════════════════════════
create_usermanager_files() {
    print_section "CRÉATION DES FICHIERS USER MANAGER"

    print_step "Génération de composer.json..."
    cat > "$USERMANAGER_DIR/app/composer.json" << 'COMPOSER_EOF'
{
    "name": "nbility/bolt-user-manager",
    "description": "Bolt.DIY User Manager v2.0 with Authentication and Profiles",
    "type": "project",
    "require": {
        "php": ">=8.2",
        "phpmailer/phpmailer": "^6.9",
        "phpoffice/phpspreadsheet": "^1.29",
        "tecnickcom/tcpdf": "^6.6"
    },
    "autoload": {
        "psr-4": {
            "App\\": "app/",
            "App\\Models\\": "app/models/",
            "App\\Controllers\\": "app/controllers/"
        }
    },
    "config": {
        "optimize-autoloader": true,
        "preferred-install": "dist",
        "sort-packages": true
    },
    "minimum-stability": "stable",
    "prefer-stable": true
}
COMPOSER_EOF

    print_success "composer.json créé"

    print_step "Génération de index.php (page simple de test)..."
    cat > "$USERMANAGER_DIR/app/index.php" << 'PHP_INDEX_EOF'
<?php
/**
 * BOLT.DIY User Manager v2.0 - Entry Point
 * Copyright Nbility 2025
 */

// Configuration
error_reporting(E_ALL);
ini_set('display_errors', 1);

// Récupération des variables d'environnement
\$db_host = getenv('DB_HOST') ?: 'bolt-mariadb';
\$db_port = getenv('DB_PORT') ?: '3306';
\$db_name = getenv('DB_NAME') ?: 'bolt_usermanager';
\$db_user = getenv('DB_USER') ?: 'bolt_um';
\$db_password = getenv('DB_PASSWORD') ?: '';

// Connexion à la base de données
try {
    \$dsn = "mysql:host=\$db_host;port=\$db_port;dbname=\$db_name;charset=utf8mb4";
    \$pdo = new PDO(\$dsn, \$db_user, \$db_password, [
        PDO::ATTR_ERRMODE => PDO::ERRMODE_EXCEPTION,
        PDO::ATTR_DEFAULT_FETCH_MODE => PDO::FETCH_ASSOC,
        PDO::ATTR_EMULATE_PREPARES => false
    ]);
} catch (PDOException \$e) {
    die('Erreur de connexion à la base de données: ' . \$e->getMessage());
}

// Récupérer les statistiques
try {
    \$stmt = \$pdo->query("SELECT COUNT(*) as total FROM users");
    \$stats['total_users'] = \$stmt->fetchColumn();

    \$stmt = \$pdo->query("SELECT COUNT(*) as total FROM users WHERE is_active = 1");
    \$stats['active_users'] = \$stmt->fetchColumn();

    \$stmt = \$pdo->query("SELECT COUNT(*) as total FROM groups");
    \$stats['total_groups'] = \$stmt->fetchColumn();
} catch (PDOException \$e) {
    \$stats = ['total_users' => 0, 'active_users' => 0, 'total_groups' => 0];
}
?>
<!DOCTYPE html>
<html lang="fr">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>User Manager v2.0 - Bolt.DIY</title>
    <style>
        * { margin: 0; padding: 0; box-sizing: border-box; }
        body {
            font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, Oxygen, Ubuntu, sans-serif;
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            min-height: 100vh;
            padding: 20px;
        }
        .container { max-width: 1200px; margin: 0 auto; }
        .header {
            background: white;
            border-radius: 15px;
            padding: 30px;
            margin-bottom: 20px;
            box-shadow: 0 10px 30px rgba(0,0,0,0.2);
        }
        .header h1 { color: #667eea; font-size: 32px; margin-bottom: 5px; }
        .header p { color: #666; font-size: 14px; }
        .stats {
            display: grid;
            grid-template-columns: repeat(auto-fit, minmax(250px, 1fr));
            gap: 20px;
            margin-bottom: 20px;
        }
        .stat-card {
            background: white;
            border-radius: 15px;
            padding: 25px;
            box-shadow: 0 10px 30px rgba(0,0,0,0.2);
            text-align: center;
        }
        .stat-card h3 { color: #667eea; font-size: 36px; margin-bottom: 10px; }
        .stat-card p { color: #666; font-size: 14px; text-transform: uppercase; letter-spacing: 1px; }
        .footer {
            text-align: center;
            color: white;
            margin-top: 30px;
            font-size: 14px;
        }
    </style>
</head>
<body>
    <div class="container">
        <div class="header">
            <h1>🔧 User Manager v2.0</h1>
            <p>Bolt.DIY Intranet Edition - Système de gestion des utilisateurs</p>
        </div>

        <div class="stats">
            <div class="stat-card">
                <h3><?php echo \$stats['total_users']; ?></h3>
                <p>Utilisateurs totaux</p>
            </div>
            <div class="stat-card">
                <h3><?php echo \$stats['active_users']; ?></h3>
                <p>Utilisateurs actifs</p>
            </div>
            <div class="stat-card">
                <h3><?php echo \$stats['total_groups']; ?></h3>
                <p>Groupes</p>
            </div>
        </div>

        <div class="footer">
            © 2025 Nbility - Bolt.DIY Intranet Edition v6.5 - User Manager v2.0
        </div>
    </div>
</body>
</html>
PHP_INDEX_EOF

    print_success "index.php créé"
    echo ""
}
