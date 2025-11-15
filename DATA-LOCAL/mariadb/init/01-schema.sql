-- ═══════════════════════════════════════════════════════════════════════════
-- BOLT.DIY USER MANAGER v2.0 - Database Schema v6.7 FINAL
-- MariaDB 10.6+
-- © Copyright Nbility 2025 - contact@nbility.fr
-- ═══════════════════════════════════════════════════════════════════════════

-- Configuration de la base de données
SET NAMES utf8mb4;
SET FOREIGN_KEY_CHECKS = 0;

-- ═══════════════════════════════════════════════════════════════════════════
-- TABLE: um_users (Comptes User Manager)
-- ═══════════════════════════════════════════════════════════════════════════

CREATE TABLE IF NOT EXISTS `um_users` (
    `id` INT AUTO_INCREMENT PRIMARY KEY,
    `username` VARCHAR(32) UNIQUE NOT NULL,
    `email` VARCHAR(255) UNIQUE NOT NULL,
    `password_hash` VARCHAR(255) NOT NULL,
    `role` ENUM('superadmin', 'admin', 'user') NOT NULL DEFAULT 'user',
    `status` ENUM('active', 'inactive', 'locked') NOT NULL DEFAULT 'active',
    `quota_bolt_users` INT NOT NULL DEFAULT 10,
    `failed_attempts` INT NOT NULL DEFAULT 0,
    `locked_until` DATETIME NULL,
    `last_login` DATETIME NULL,
    `last_password_change` DATETIME NULL,
    `preferences` JSON NULL,
    `theme` VARCHAR(50) DEFAULT 'dark',
    `locale` VARCHAR(10) DEFAULT 'fr_FR',
    `timezone` VARCHAR(50) DEFAULT 'Europe/Paris',
    `avatar_url` VARCHAR(500) NULL,
    `two_factor_enabled` BOOLEAN DEFAULT 0,
    `two_factor_secret` VARCHAR(255) NULL,
    `created_by` INT NULL,
    `created_at` DATETIME DEFAULT CURRENT_TIMESTAMP,
    `updated_at` DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    INDEX idx_username (username),
    INDEX idx_email (email),
    INDEX idx_status (status),
    INDEX idx_role (role),
    FOREIGN KEY (`created_by`) REFERENCES `um_users`(`id`) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ═══════════════════════════════════════════════════════════════════════════
-- TABLE: um_groups (Groupes d'utilisateurs)
-- ═══════════════════════════════════════════════════════════════════════════

CREATE TABLE IF NOT EXISTS `um_groups` (
    `id` INT AUTO_INCREMENT PRIMARY KEY,
    `name` VARCHAR(100) UNIQUE NOT NULL,
    `description` TEXT NULL,
    `color` VARCHAR(7) DEFAULT '#667eea',
    `icon` VARCHAR(50) DEFAULT 'users',
    `quota_bolt_users` INT NULL,
    `created_by` INT NOT NULL,
    `created_at` DATETIME DEFAULT CURRENT_TIMESTAMP,
    `updated_at` DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    INDEX idx_name (name),
    FOREIGN KEY (`created_by`) REFERENCES `um_users`(`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ═══════════════════════════════════════════════════════════════════════════
-- TABLE: um_user_groups (Association utilisateurs/groupes)
-- ═══════════════════════════════════════════════════════════════════════════

CREATE TABLE IF NOT EXISTS `um_user_groups` (
    `id` INT AUTO_INCREMENT PRIMARY KEY,
    `user_id` INT NOT NULL,
    `group_id` INT NOT NULL,
    `assigned_at` DATETIME DEFAULT CURRENT_TIMESTAMP,
    `assigned_by` INT NULL,
    UNIQUE KEY unique_user_group (user_id, group_id),
    INDEX idx_user_id (user_id),
    INDEX idx_group_id (group_id),
    FOREIGN KEY (`user_id`) REFERENCES `um_users`(`id`) ON DELETE CASCADE,
    FOREIGN KEY (`group_id`) REFERENCES `um_groups`(`id`) ON DELETE CASCADE,
    FOREIGN KEY (`assigned_by`) REFERENCES `um_users`(`id`) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ═══════════════════════════════════════════════════════════════════════════
-- TABLE: um_permissions (Permissions système)
-- ═══════════════════════════════════════════════════════════════════════════

CREATE TABLE IF NOT EXISTS `um_permissions` (
    `id` INT AUTO_INCREMENT PRIMARY KEY,
    `name` VARCHAR(100) UNIQUE NOT NULL,
    `description` TEXT NULL,
    `resource` VARCHAR(50) NOT NULL,
    `action` VARCHAR(50) NOT NULL,
    `created_at` DATETIME DEFAULT CURRENT_TIMESTAMP,
    INDEX idx_name (name),
    INDEX idx_resource_action (resource, action)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ═══════════════════════════════════════════════════════════════════════════
-- TABLE: um_group_permissions (Permissions des groupes)
-- ═══════════════════════════════════════════════════════════════════════════

CREATE TABLE IF NOT EXISTS `um_group_permissions` (
    `id` INT AUTO_INCREMENT PRIMARY KEY,
    `group_id` INT NOT NULL,
    `permission_id` INT NOT NULL,
    `assigned_at` DATETIME DEFAULT CURRENT_TIMESTAMP,
    UNIQUE KEY unique_group_permission (group_id, permission_id),
    INDEX idx_group_id (group_id),
    INDEX idx_permission_id (permission_id),
    FOREIGN KEY (`group_id`) REFERENCES `um_groups`(`id`) ON DELETE CASCADE,
    FOREIGN KEY (`permission_id`) REFERENCES `um_permissions`(`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ═══════════════════════════════════════════════════════════════════════════
-- TABLE: um_sessions (Sessions utilisateurs)
-- ═══════════════════════════════════════════════════════════════════════════

CREATE TABLE IF NOT EXISTS `um_sessions` (
    `id` INT AUTO_INCREMENT PRIMARY KEY,
    `user_id` INT NOT NULL,
    `session_token` VARCHAR(255) UNIQUE NOT NULL,
    `ip_address` VARCHAR(45) NULL,
    `user_agent` TEXT NULL,
    `last_activity` DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    `created_at` DATETIME DEFAULT CURRENT_TIMESTAMP,
    `expires_at` DATETIME NOT NULL,
    INDEX idx_session_token (session_token),
    INDEX idx_user_id (user_id),
    INDEX idx_expires_at (expires_at),
    FOREIGN KEY (`user_id`) REFERENCES `um_users`(`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ═══════════════════════════════════════════════════════════════════════════
-- TABLE: um_audit_logs (Logs d'audit)
-- ═══════════════════════════════════════════════════════════════════════════

CREATE TABLE IF NOT EXISTS `um_audit_logs` (
    `id` INT AUTO_INCREMENT PRIMARY KEY,
    `user_id` INT NULL,
    `action` VARCHAR(100) NOT NULL,
    `resource_type` VARCHAR(50) NULL,
    `resource_id` INT NULL,
    `details` TEXT NULL,
    `ip_address` VARCHAR(45) NULL,
    `user_agent` TEXT NULL,
    `created_at` DATETIME DEFAULT CURRENT_TIMESTAMP,
    INDEX idx_user_id (user_id),
    INDEX idx_action (action),
    INDEX idx_created_at (created_at),
    INDEX idx_resource (resource_type, resource_id),
    FOREIGN KEY (`user_id`) REFERENCES `um_users`(`id`) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ═══════════════════════════════════════════════════════════════════════════
-- TABLE: um_settings (Paramètres système)
-- ═══════════════════════════════════════════════════════════════════════════

CREATE TABLE IF NOT EXISTS `um_settings` (
    `id` INT AUTO_INCREMENT PRIMARY KEY,
    `setting_key` VARCHAR(100) UNIQUE NOT NULL,
    `setting_value` TEXT NULL,
    `setting_type` ENUM('string', 'integer', 'boolean', 'json') DEFAULT 'string',
    `updated_by` INT NULL,
    `updated_at` DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    INDEX idx_setting_key (setting_key),
    FOREIGN KEY (`updated_by`) REFERENCES `um_users`(`id`) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ═══════════════════════════════════════════════════════════════════════════
-- TABLE: um_password_resets (Réinitialisations de mot de passe)
-- ═══════════════════════════════════════════════════════════════════════════

CREATE TABLE IF NOT EXISTS `um_password_resets` (
    `id` INT AUTO_INCREMENT PRIMARY KEY,
    `user_id` INT NOT NULL,
    `token` VARCHAR(255) UNIQUE NOT NULL,
    `expires_at` DATETIME NOT NULL,
    `used` BOOLEAN DEFAULT 0,
    `created_at` DATETIME DEFAULT CURRENT_TIMESTAMP,
    INDEX idx_token (token),
    INDEX idx_user_id (user_id),
    INDEX idx_expires_at (expires_at),
    FOREIGN KEY (`user_id`) REFERENCES `um_users`(`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ═══════════════════════════════════════════════════════════════════════════
-- TABLE: um_notifications (Notifications)
-- ═══════════════════════════════════════════════════════════════════════════

CREATE TABLE IF NOT EXISTS `um_notifications` (
    `id` INT AUTO_INCREMENT PRIMARY KEY,
    `user_id` INT NOT NULL,
    `type` VARCHAR(50) NOT NULL,
    `title` VARCHAR(255) NOT NULL,
    `message` TEXT NULL,
    `read_at` DATETIME NULL,
    `action_url` VARCHAR(500) NULL,
    `created_at` DATETIME DEFAULT CURRENT_TIMESTAMP,
    INDEX idx_user_id (user_id),
    INDEX idx_read_at (read_at),
    INDEX idx_created_at (created_at),
    FOREIGN KEY (`user_id`) REFERENCES `um_users`(`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ═══════════════════════════════════════════════════════════════════════════
-- TABLE: um_themes (Thèmes d'interface)
-- ═══════════════════════════════════════════════════════════════════════════

CREATE TABLE IF NOT EXISTS `um_themes` (
    `id` INT AUTO_INCREMENT PRIMARY KEY,
    `name` VARCHAR(50) UNIQUE NOT NULL,
    `display_name` VARCHAR(100) NOT NULL,
    `is_system` BOOLEAN DEFAULT 0,
    `is_active` BOOLEAN DEFAULT 1,
    `config` JSON NOT NULL,
    `created_by` INT NULL,
    `created_at` DATETIME DEFAULT CURRENT_TIMESTAMP,
    `updated_at` DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    INDEX idx_name (name),
    INDEX idx_is_active (is_active),
    FOREIGN KEY (`created_by`) REFERENCES `um_users`(`id`) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Réactiver les contraintes de clés étrangères
SET FOREIGN_KEY_CHECKS = 1;

-- ═══════════════════════════════════════════════════════════════════════════
-- Fin du schéma v6.7 FINAL
-- ═══════════════════════════════════════════════════════════════════════════
