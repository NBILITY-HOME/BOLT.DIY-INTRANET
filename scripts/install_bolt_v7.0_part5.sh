
#═══════════════════════════════════════════════════════════════════════════
# FONCTION: Création des fichiers SQL
#═══════════════════════════════════════════════════════════════════════════
create_sql_files() {
    print_section "GÉNÉRATION FICHIERS SQL"

    # Vérifier si les fichiers SQL existent déjà dans le clone
    if [ -f "$USERMANAGER_DIR/app/database/migrations/01-schema.sql" ] && \
       [ -f "$USERMANAGER_DIR/app/database/migrations/02-seed.sql" ]; then
        print_success "Fichiers SQL déjà présents depuis GitHub"

        # Copier vers mariadb/init
        print_step "Copie des fichiers SQL vers mariadb/init..."
        cp "$USERMANAGER_DIR/app/database/migrations/01-schema.sql" "$MARIADB_DIR/init/"
        cp "$USERMANAGER_DIR/app/database/migrations/02-seed.sql" "$MARIADB_DIR/init/"
        print_success "Fichiers SQL copiés"
    else
        print_warning "Fichiers SQL non trouvés dans GitHub, génération locale..."

        # 01-schema.sql
        print_step "Création de 01-schema.sql..."
        cat > "$MARIADB_DIR/init/01-schema.sql" << 'SCHEMA_SQL_EOF'
-- ═══════════════════════════════════════════════════════════════════════════
-- USER MANAGER v2.0 - Database Schema
-- © Copyright Nbility 2025
-- ═══════════════════════════════════════════════════════════════════════════

USE bolt_usermanager;

-- Table: users
CREATE TABLE IF NOT EXISTS users (
    id INT AUTO_INCREMENT PRIMARY KEY,
    username VARCHAR(50) UNIQUE NOT NULL,
    email VARCHAR(255) UNIQUE NOT NULL,
    password VARCHAR(255) NOT NULL,
    first_name VARCHAR(100),
    last_name VARCHAR(100),
    role ENUM('super_admin', 'admin', 'user') DEFAULT 'user',
    status ENUM('active', 'inactive', 'suspended') DEFAULT 'active',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    last_login TIMESTAMP NULL,
    INDEX idx_username (username),
    INDEX idx_email (email),
    INDEX idx_status (status),
    INDEX idx_role (role)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Table: groups
CREATE TABLE IF NOT EXISTS groups (
    id INT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(100) UNIQUE NOT NULL,
    description TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    INDEX idx_name (name)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Table: user_groups (relation many-to-many)
CREATE TABLE IF NOT EXISTS user_groups (
    user_id INT NOT NULL,
    group_id INT NOT NULL,
    assigned_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (user_id, group_id),
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
    FOREIGN KEY (group_id) REFERENCES groups(id) ON DELETE CASCADE,
    INDEX idx_user_id (user_id),
    INDEX idx_group_id (group_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Table: permissions
CREATE TABLE IF NOT EXISTS permissions (
    id INT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(100) UNIQUE NOT NULL,
    slug VARCHAR(100) UNIQUE NOT NULL,
    description TEXT,
    category VARCHAR(50),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    INDEX idx_slug (slug),
    INDEX idx_category (category)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Table: group_permissions (relation many-to-many)
CREATE TABLE IF NOT EXISTS group_permissions (
    group_id INT NOT NULL,
    permission_id INT NOT NULL,
    granted_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (group_id, permission_id),
    FOREIGN KEY (group_id) REFERENCES groups(id) ON DELETE CASCADE,
    FOREIGN KEY (permission_id) REFERENCES permissions(id) ON DELETE CASCADE,
    INDEX idx_group_id (group_id),
    INDEX idx_permission_id (permission_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Table: user_permissions (permissions directes, override groups)
CREATE TABLE IF NOT EXISTS user_permissions (
    user_id INT NOT NULL,
    permission_id INT NOT NULL,
    granted_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (user_id, permission_id),
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
    FOREIGN KEY (permission_id) REFERENCES permissions(id) ON DELETE CASCADE,
    INDEX idx_user_id (user_id),
    INDEX idx_permission_id (permission_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Table: sessions
CREATE TABLE IF NOT EXISTS sessions (
    id VARCHAR(128) PRIMARY KEY,
    user_id INT NOT NULL,
    ip_address VARCHAR(45),
    user_agent TEXT,
    metadata JSON,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    expires_at TIMESTAMP NOT NULL,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
    INDEX idx_user_id (user_id),
    INDEX idx_expires_at (expires_at)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Table: audit_logs
CREATE TABLE IF NOT EXISTS audit_logs (
    id INT AUTO_INCREMENT PRIMARY KEY,
    user_id INT,
    action VARCHAR(100) NOT NULL,
    entity_type VARCHAR(50),
    entity_id INT,
    metadata JSON,
    ip_address VARCHAR(45),
    user_agent TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE SET NULL,
    INDEX idx_user_id (user_id),
    INDEX idx_action (action),
    INDEX idx_entity (entity_type, entity_id),
    INDEX idx_created_at (created_at)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Optimisations
ANALYZE TABLE users;
ANALYZE TABLE groups;
ANALYZE TABLE permissions;
SCHEMA_SQL_EOF
        print_success "01-schema.sql créé"

        # 02-seed.sql
        print_step "Création de 02-seed.sql..."

        # Générer hash password admin
        ADMIN_PASSWORD_HASH=$(php -r "echo password_hash('$ADMIN_PASSWORD', PASSWORD_BCRYPT);")

        cat > "$MARIADB_DIR/init/02-seed.sql" << SEED_SQL_EOF
-- ═══════════════════════════════════════════════════════════════════════════
-- USER MANAGER v2.0 - Seed Data
-- © Copyright Nbility 2025
-- ═══════════════════════════════════════════════════════════════════════════

USE bolt_usermanager;

-- Utilisateur admin
INSERT INTO users (username, email, password, first_name, last_name, role, status) 
VALUES ('$ADMIN_USER', 'admin@localhost', '$ADMIN_PASSWORD_HASH', 'Admin', 'System', 'super_admin', 'active')
ON DUPLICATE KEY UPDATE 
    email = VALUES(email),
    password = VALUES(password),
    role = VALUES(role),
    status = VALUES(status);

-- Groupes par défaut
INSERT INTO groups (name, description) VALUES
('Administrators', 'Administrateurs système avec tous les droits'),
('Developers', 'Développeurs avec accès Bolt.DIY'),
('Users', 'Utilisateurs standards')
ON DUPLICATE KEY UPDATE description = VALUES(description);

-- Permissions système
INSERT INTO permissions (name, slug, description, category) VALUES
-- User management
('Voir les utilisateurs', 'users.view', 'Consulter la liste des utilisateurs', 'users'),
('Créer des utilisateurs', 'users.create', 'Créer de nouveaux utilisateurs', 'users'),
('Modifier des utilisateurs', 'users.edit', 'Modifier les utilisateurs existants', 'users'),
('Supprimer des utilisateurs', 'users.delete', 'Supprimer des utilisateurs', 'users'),
-- Group management
('Voir les groupes', 'groups.view', 'Consulter la liste des groupes', 'groups'),
('Créer des groupes', 'groups.create', 'Créer de nouveaux groupes', 'groups'),
('Modifier des groupes', 'groups.edit', 'Modifier les groupes existants', 'groups'),
('Supprimer des groupes', 'groups.delete', 'Supprimer des groupes', 'groups'),
-- Permission management
('Voir les permissions', 'permissions.view', 'Consulter les permissions', 'permissions'),
('Gérer les permissions', 'permissions.manage', 'Attribuer/retirer des permissions', 'permissions'),
-- Audit
('Voir les logs', 'audit.view', 'Consulter les logs d\'audit', 'audit'),
-- System
('Accès système', 'system.access', 'Accès aux paramètres système', 'system')
ON DUPLICATE KEY UPDATE 
    name = VALUES(name),
    description = VALUES(description);

-- Assigner admin au groupe Administrators
INSERT INTO user_groups (user_id, group_id)
SELECT u.id, g.id 
FROM users u, groups g 
WHERE u.username = '$ADMIN_USER' AND g.name = 'Administrators'
ON DUPLICATE KEY UPDATE assigned_at = CURRENT_TIMESTAMP;

-- Donner toutes les permissions au groupe Administrators
INSERT INTO group_permissions (group_id, permission_id)
SELECT g.id, p.id
FROM groups g, permissions p
WHERE g.name = 'Administrators'
ON DUPLICATE KEY UPDATE granted_at = CURRENT_TIMESTAMP;
SEED_SQL_EOF
        print_success "02-seed.sql créé"
    fi

    echo ""
}
