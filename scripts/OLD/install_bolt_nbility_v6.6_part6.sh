
# ═══════════════════════════════════════════════════════════════════════════
# FONCTION: Création du schéma SQL MariaDB
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
