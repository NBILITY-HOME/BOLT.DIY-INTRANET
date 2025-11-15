-- ═══════════════════════════════════════════════════════════════════════════
-- USER MANAGER v2.0 - Seed Data
-- © Copyright Nbility 2025
-- Données initiales: Admin, Groupes, Permissions
-- ═══════════════════════════════════════════════════════════════════════════

USE bolt_usermanager;

-- ═══════════════════════════════════════════════════════════════════════════
-- Utilisateur administrateur par défaut
-- Password: admin (à changer après installation)
-- ═══════════════════════════════════════════════════════════════════════════
INSERT INTO users (username, email, password, first_name, last_name, role, status) 
VALUES (
    'admin',
    'admin@localhost',
    '$2y$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi', -- password: admin
    'Admin',
    'System',
    'super_admin',
    'active'
) ON DUPLICATE KEY UPDATE 
    email = VALUES(email),
    role = VALUES(role),
    status = VALUES(status);

-- ═══════════════════════════════════════════════════════════════════════════
-- Groupes par défaut
-- ═══════════════════════════════════════════════════════════════════════════
INSERT INTO groups (name, description, color) VALUES
('Administrators', 'Administrateurs système avec tous les droits', '#EF4444'),
('Developers', 'Développeurs avec accès Bolt.DIY et gestion code', '#3B82F6'),
('Managers', 'Responsables avec droits de gestion utilisateurs', '#F59E0B'),
('Users', 'Utilisateurs standards avec accès limité', '#10B981'),
('Guests', 'Invités avec accès en lecture seule', '#6B7280')
ON DUPLICATE KEY UPDATE 
    description = VALUES(description),
    color = VALUES(color);

-- ═══════════════════════════════════════════════════════════════════════════
-- Permissions système
-- ═══════════════════════════════════════════════════════════════════════════
INSERT INTO permissions (name, slug, description, category) VALUES
-- User Management
('Voir utilisateurs', 'users.view', 'Consulter la liste des utilisateurs', 'users'),
('Créer utilisateurs', 'users.create', 'Créer de nouveaux utilisateurs', 'users'),
('Modifier utilisateurs', 'users.edit', 'Modifier les utilisateurs existants', 'users'),
('Supprimer utilisateurs', 'users.delete', 'Supprimer des utilisateurs', 'users'),
('Gérer rôles', 'users.roles', 'Attribuer et modifier les rôles', 'users'),

-- Group Management
('Voir groupes', 'groups.view', 'Consulter la liste des groupes', 'groups'),
('Créer groupes', 'groups.create', 'Créer de nouveaux groupes', 'groups'),
('Modifier groupes', 'groups.edit', 'Modifier les groupes existants', 'groups'),
('Supprimer groupes', 'groups.delete', 'Supprimer des groupes', 'groups'),

-- Permission Management
('Voir permissions', 'permissions.view', 'Consulter les permissions', 'permissions'),
('Gérer permissions', 'permissions.manage', 'Attribuer/retirer des permissions', 'permissions'),

-- Audit & Logs
('Voir logs', 'audit.view', 'Consulter les logs d'audit', 'audit'),
('Exporter logs', 'audit.export', 'Exporter les logs d'audit', 'audit'),

-- System
('Accès système', 'system.access', 'Accès aux paramètres système', 'system'),
('Configuration', 'system.config', 'Modifier la configuration système', 'system'),
('Maintenance', 'system.maintenance', 'Activer le mode maintenance', 'system'),

-- Bolt.DIY Access
('Accès Bolt.DIY', 'bolt.access', 'Accéder à l'application Bolt.DIY', 'bolt'),
('Gérer projets', 'bolt.projects', 'Créer et gérer des projets', 'bolt')
ON DUPLICATE KEY UPDATE 
    name = VALUES(name),
    description = VALUES(description);

-- ═══════════════════════════════════════════════════════════════════════════
-- Assigner admin au groupe Administrators
-- ═══════════════════════════════════════════════════════════════════════════
INSERT INTO user_groups (user_id, group_id)
SELECT u.id, g.id 
FROM users u
CROSS JOIN groups g
WHERE u.username = 'admin' AND g.name = 'Administrators'
ON DUPLICATE KEY UPDATE assigned_at = CURRENT_TIMESTAMP;

-- ═══════════════════════════════════════════════════════════════════════════
-- Donner toutes les permissions au groupe Administrators
-- ═══════════════════════════════════════════════════════════════════════════
INSERT INTO group_permissions (group_id, permission_id)
SELECT g.id, p.id
FROM groups g
CROSS JOIN permissions p
WHERE g.name = 'Administrators'
ON DUPLICATE KEY UPDATE granted_at = CURRENT_TIMESTAMP;

-- ═══════════════════════════════════════════════════════════════════════════
-- Permissions groupe Developers
-- ═══════════════════════════════════════════════════════════════════════════
INSERT INTO group_permissions (group_id, permission_id)
SELECT g.id, p.id
FROM groups g
CROSS JOIN permissions p
WHERE g.name = 'Developers'
  AND p.slug IN (
    'users.view',
    'groups.view',
    'permissions.view',
    'bolt.access',
    'bolt.projects'
  )
ON DUPLICATE KEY UPDATE granted_at = CURRENT_TIMESTAMP;

-- ═══════════════════════════════════════════════════════════════════════════
-- Permissions groupe Users
-- ═══════════════════════════════════════════════════════════════════════════
INSERT INTO group_permissions (group_id, permission_id)
SELECT g.id, p.id
FROM groups g
CROSS JOIN permissions p
WHERE g.name = 'Users'
  AND p.slug IN (
    'users.view',
    'groups.view'
  )
ON DUPLICATE KEY UPDATE granted_at = CURRENT_TIMESTAMP;
