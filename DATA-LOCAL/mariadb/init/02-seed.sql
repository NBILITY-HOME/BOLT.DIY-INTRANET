-- ═══════════════════════════════════════════════════════════════════════════
-- BOLT.DIY USER MANAGER v2.0 - Initial Data (Seed) v6.7 FINAL
-- © Copyright Nbility 2025 - contact@nbility.fr
-- 
-- CORRECTIONS v6.7 FINAL:
-- ✅ SET FOREIGN_KEY_CHECKS = 0 au début
-- ✅ um_users créé EN PREMIER (ligne 17)
-- ✅ um_groups créé APRÈS (ligne 30)  
-- ✅ Syntaxe SQL corrigée (pas de double INSERT INTO)
-- ═══════════════════════════════════════════════════════════════════════════

USE bolt_usermanager;

-- Désactiver temporairement les contraintes FK
SET FOREIGN_KEY_CHECKS = 0;

-- ═══════════════════════════════════════════════════════════════════════════
-- 1. CRÉER LE SUPER ADMIN EN PREMIER (important pour les FK created_by)
-- ═══════════════════════════════════════════════════════════════════════════

INSERT INTO `um_users` (`id`, `username`, `email`, `password_hash`, `role`, `status`, `quota_bolt_users`, `theme`, `locale`, `timezone`, `created_at`) 
VALUES (1, '$ADMIN_USERNAME', '$ADMIN_EMAIL', '$HASHED_PASSWORD', 'superadmin', 'active', 999, 'dark', 'fr_FR', 'Europe/Paris', NOW())
ON DUPLICATE KEY UPDATE 
    email = VALUES(email), 
    password_hash = VALUES(password_hash),
    role = 'superadmin',
    status = 'active',
    quota_bolt_users = 999;

-- ═══════════════════════════════════════════════════════════════════════════
-- 2. PUIS CRÉER LES GROUPES (qui référencent created_by=1)
-- ═══════════════════════════════════════════════════════════════════════════

INSERT INTO `um_groups` (`id`, `name`, `description`, `color`, `icon`, `quota_bolt_users`, `created_by`, `created_at`) VALUES
(1, 'Administrateurs', 'Groupe par défaut pour tous les administrateurs', '#667eea', 'shield', NULL, 1, NOW()),
(2, 'Utilisateurs', 'Groupe par défaut pour tous les utilisateurs', '#4299e1', 'users', NULL, 1, NOW()),
(3, 'Invités', 'Groupe avec permissions limitées', '#718096', 'user', 5, 1, NOW())
ON DUPLICATE KEY UPDATE 
    description = VALUES(description), 
    color = VALUES(color),
    icon = VALUES(icon),
    quota_bolt_users = VALUES(quota_bolt_users);

-- ═══════════════════════════════════════════════════════════════════════════
-- 3. PARAMÈTRES SYSTÈME PAR DÉFAUT
-- ═══════════════════════════════════════════════════════════════════════════

INSERT INTO `um_settings` (`setting_key`, `setting_value`, `setting_type`) VALUES
-- Sécurité
('session_lifetime', '1800', 'integer'),
('session_remember_lifetime', '604800', 'integer'),
('max_login_attempts', '5', 'integer'),
('lockout_duration', '900', 'integer'),
('password_min_length', '8', 'integer'),
('password_require_uppercase', '1', 'boolean'),
('password_require_lowercase', '1', 'boolean'),
('password_require_number', '1', 'boolean'),
('password_require_special', '1', 'boolean'),
('password_expiry_days', '0', 'integer'),
('password_history', '0', 'integer'),

-- Quotas
('default_user_quota', '10', 'integer'),
('default_group_quota', '0', 'integer'),
('global_bolt_users_limit', '0', 'integer'),

-- Notifications
('notifications_enabled', '1', 'boolean'),
('smtp_configured', '0', 'boolean'),
('smtp_host', '', 'string'),
('smtp_port', '587', 'integer'),
('smtp_encryption', 'tls', 'string'),
('smtp_auth_required', '1', 'boolean'),
('smtp_username', '', 'string'),
('smtp_password', '', 'string'),
('smtp_from_email', 'noreply@nbility.fr', 'string'),
('smtp_from_name', 'Bolt.DIY Nbility', 'string'),
('smtp_timeout', '30', 'integer'),
('email_digest_frequency', 'immediate', 'string'),

-- Webhooks
('webhooks_enabled', '1', 'boolean'),
('webhook_global_timeout', '10', 'integer'),
('webhook_global_retry', '3', 'integer'),

-- Maintenance
('logs_retention_days', '90', 'integer'),
('reports_retention_days', '90', 'integer'),
('email_queue_retention_days', '30', 'integer'),
('backup_frequency', 'daily', 'string'),
('backup_retention_count', '7', 'integer'),

-- Application
('app_name', 'Bolt.DIY User Manager', 'string'),
('app_version', '2.0.0', 'string'),
('app_timezone', 'Europe/Paris', 'string'),
('app_locale', 'fr_FR', 'string'),
('maintenance_mode', '0', 'boolean')
ON DUPLICATE KEY UPDATE 
    setting_value = VALUES(setting_value);

-- ═══════════════════════════════════════════════════════════════════════════
-- 4. THÈMES SYSTÈME
-- ═══════════════════════════════════════════════════════════════════════════

INSERT INTO `um_themes` (`name`, `display_name`, `is_system`, `is_active`, `config`, `created_by`) VALUES
('dark', 'Dark Mode', 1, 1, '{
  "colors": {
    "primary": "#667eea",
    "secondary": "#764ba2",
    "accent": "#f56565",
    "success": "#48bb78",
    "error": "#f56565",
    "warning": "#ed8936",
    "info": "#4299e1",
    "background": "#1a202c",
    "surface": "#2d3748",
    "text": "#e2e8f0",
    "textSecondary": "#a0aec0"
  },
  "typography": {
    "fontFamily": "Segoe UI, Roboto, sans-serif",
    "fontSize": "16px"
  },
  "spacing": {
    "borderRadius": "8px",
    "padding": "16px"
  }
}', 1),
('light', 'Light Mode', 1, 1, '{
  "colors": {
    "primary": "#667eea",
    "secondary": "#764ba2",
    "accent": "#f56565",
    "success": "#48bb78",
    "error": "#f56565",
    "warning": "#ed8936",
    "info": "#4299e1",
    "background": "#ffffff",
    "surface": "#f7fafc",
    "text": "#2d3748",
    "textSecondary": "#718096"
  },
  "typography": {
    "fontFamily": "Segoe UI, Roboto, sans-serif",
    "fontSize": "16px"
  },
  "spacing": {
    "borderRadius": "8px",
    "padding": "16px"
  }
}', 1),
('high-contrast', 'High Contrast', 1, 1, '{
  "colors": {
    "primary": "#000000",
    "secondary": "#ffffff",
    "accent": "#ffff00",
    "success": "#00ff00",
    "error": "#ff0000",
    "warning": "#ff8800",
    "info": "#00ffff",
    "background": "#000000",
    "surface": "#1a1a1a",
    "text": "#ffffff",
    "textSecondary": "#cccccc"
  },
  "typography": {
    "fontFamily": "Segoe UI, Roboto, sans-serif",
    "fontSize": "18px"
  },
  "spacing": {
    "borderRadius": "4px",
    "padding": "20px"
  }
}', 1),
('nbility-corporate', 'Nbility Corporate', 1, 1, '{
  "colors": {
    "primary": "#667eea",
    "secondary": "#764ba2",
    "accent": "#e53e3e",
    "success": "#38a169",
    "error": "#e53e3e",
    "warning": "#d69e2e",
    "info": "#3182ce",
    "background": "#f7fafc",
    "surface": "#ffffff",
    "text": "#2d3748",
    "textSecondary": "#4a5568"
  },
  "typography": {
    "fontFamily": "Segoe UI, Roboto, sans-serif",
    "fontSize": "16px"
  },
  "spacing": {
    "borderRadius": "8px",
    "padding": "16px"
  }
}', 1)
ON DUPLICATE KEY UPDATE 
    display_name = VALUES(display_name), 
    config = VALUES(config),
    is_active = VALUES(is_active);

-- Réactiver les contraintes FK
SET FOREIGN_KEY_CHECKS = 1;

-- ═══════════════════════════════════════════════════════════════════════════
-- Fin des données initiales v6.7 FINAL
-- ═══════════════════════════════════════════════════════════════════════════
