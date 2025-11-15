
# ═══════════════════════════════════════════════════════════════════════════
# FONCTION: Création du schéma SQL et données
# ═══════════════════════════════════════════════════════════════════════════
create_sql_files() {
    print_section "CRÉATION DU SCHÉMA SQL MARIADB"

    cat > "$MARIADB_DIR/init/01_schema.sql" << 'SQL_SCHEMA_EOF'
CREATE DATABASE IF NOT EXISTS bolt_usermanager CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
USE bolt_usermanager;

CREATE TABLE IF NOT EXISTS users (
    id INT AUTO_INCREMENT PRIMARY KEY,
    username VARCHAR(50) UNIQUE NOT NULL,
    email VARCHAR(100) UNIQUE NOT NULL,
    password_hash VARCHAR(255) NOT NULL,
    first_name VARCHAR(50),
    last_name VARCHAR(50),
    is_active BOOLEAN DEFAULT 1,
    is_superadmin BOOLEAN DEFAULT 0,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    last_login TIMESTAMP NULL,
    INDEX idx_username (username),
    INDEX idx_email (email),
    INDEX idx_active (is_active)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS groups (
    id INT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(100) UNIQUE NOT NULL,
    description TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    INDEX idx_name (name)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS user_groups (
    id INT AUTO_INCREMENT PRIMARY KEY,
    user_id INT NOT NULL,
    group_id INT NOT NULL,
    assigned_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
    FOREIGN KEY (group_id) REFERENCES groups(id) ON DELETE CASCADE,
    UNIQUE KEY unique_user_group (user_id, group_id),
    INDEX idx_user_id (user_id),
    INDEX idx_group_id (group_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS permissions (
    id INT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(100) UNIQUE NOT NULL,
    description TEXT,
    resource VARCHAR(50),
    action VARCHAR(50),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    INDEX idx_name (name),
    INDEX idx_resource_action (resource, action)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS group_permissions (
    id INT AUTO_INCREMENT PRIMARY KEY,
    group_id INT NOT NULL,
    permission_id INT NOT NULL,
    assigned_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (group_id) REFERENCES groups(id) ON DELETE CASCADE,
    FOREIGN KEY (permission_id) REFERENCES permissions(id) ON DELETE CASCADE,
    UNIQUE KEY unique_group_permission (group_id, permission_id),
    INDEX idx_group_id (group_id),
    INDEX idx_permission_id (permission_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS user_sessions (
    id INT AUTO_INCREMENT PRIMARY KEY,
    user_id INT NOT NULL,
    session_token VARCHAR(255) UNIQUE NOT NULL,
    ip_address VARCHAR(45),
    user_agent TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    expires_at TIMESTAMP NOT NULL,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
    INDEX idx_session_token (session_token),
    INDEX idx_user_id (user_id),
    INDEX idx_expires_at (expires_at)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS audit_logs (
    id INT AUTO_INCREMENT PRIMARY KEY,
    user_id INT,
    action VARCHAR(100) NOT NULL,
    resource_type VARCHAR(50),
    resource_id INT,
    details TEXT,
    ip_address VARCHAR(45),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE SET NULL,
    INDEX idx_user_id (user_id),
    INDEX idx_action (action),
    INDEX idx_created_at (created_at)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
SQL_SCHEMA_EOF

    print_success "Schéma SQL créé (7 tables principales)"

    print_step "Création des données initiales..."

    HASHED_PASSWORD=$(php -r "echo password_hash('$ADMIN_PASSWORD', PASSWORD_BCRYPT);")

    cat > "$MARIADB_DIR/init/02_seed.sql" << SQL_SEED_EOF
USE bolt_usermanager;

-- 1. CRÉER L'UTILISATEUR EN PREMIER (important pour les FK)
INSERT INTO users (username, email, password_hash, first_name, last_name, is_active, is_superadmin)
VALUES ('$ADMIN_USERNAME', '$ADMIN_EMAIL', '$HASHED_PASSWORD', 'Super', 'Admin', 1, 1)
ON DUPLICATE KEY UPDATE email=VALUES(email);

-- 2. PUIS CRÉER LES GROUPES
INSERT INTO groups (name, description) VALUES


INSERT INTO groups (name, description) VALUES 
('Administrateurs', 'Groupe des administrateurs système'),
('Développeurs', 'Équipe de développement'),
('Utilisateurs', 'Utilisateurs standards'),
('Invités', 'Accès lecture seule')
ON DUPLICATE KEY UPDATE description=VALUES(description);

INSERT INTO permissions (name, description, resource, action) VALUES
('user.create', 'Créer un utilisateur', 'user', 'create'),
('user.read', 'Lire un utilisateur', 'user', 'read'),
('user.update', 'Modifier un utilisateur', 'user', 'update'),
('user.delete', 'Supprimer un utilisateur', 'user', 'delete'),
('group.manage', 'Gérer les groupes', 'group', 'manage'),
('permission.manage', 'Gérer les permissions', 'permission', 'manage'),
('system.admin', 'Administration système', 'system', 'admin')
ON DUPLICATE KEY UPDATE description=VALUES(description);

INSERT INTO user_groups (user_id, group_id) 
SELECT u.id, g.id FROM users u, groups g 
WHERE u.username = '$ADMIN_USERNAME' AND g.name = 'Administrateurs'
ON DUPLICATE KEY UPDATE user_id=VALUES(user_id);

INSERT INTO group_permissions (group_id, permission_id)
SELECT g.id, p.id FROM groups g, permissions p
WHERE g.name = 'Administrateurs'
ON DUPLICATE KEY UPDATE group_id=VALUES(group_id);
SQL_SEED_EOF

    print_success "Données initiales créées"
    echo ""
}
