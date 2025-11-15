<?php
/**
 * ═══════════════════════════════════════════════════════════════════════════
 * BOLT.DIY USER MANAGER v2.0 - User Model
 * © Copyright Nbility 2025 - contact@nbility.fr
 * 
 * Model pour la gestion des utilisateurs
 * ═══════════════════════════════════════════════════════════════════════════
 */

declare(strict_types=1);

namespace App\Models;

use App\Utils\Database;

/**
 * Classe User - Model utilisateur
 */
class User
{
    private Database $db;
    private string $table = 'users';

    /**
     * Propriétés de l'utilisateur
     */
    public ?int $id = null;
    public ?string $username = null;
    public ?string $email = null;
    public ?string $password = null;
    public ?string $first_name = null;
    public ?string $last_name = null;
    public ?string $role = null;
    public ?string $status = null;
    public ?string $created_at = null;
    public ?string $updated_at = null;
    public ?string $last_login = null;
    public ?string $last_ip = null;
    public ?int $created_by = null;
    public ?int $updated_by = null;

    /**
     * Constructeur
     */
    public function __construct()
    {
        $this->db = new Database();
    }

    // ═══════════════════════════════════════════════════════════════════════
    // MÉTHODES STATIQUES (Factory)
    // ═══════════════════════════════════════════════════════════════════════

    /**
     * Créer une instance depuis un tableau
     * 
     * @param array $data Données utilisateur
     * @return self
     */
    public static function fromArray(array $data): self
    {
        $user = new self();

        foreach ($data as $key => $value) {
            if (property_exists($user, $key)) {
                $user->{$key} = $value;
            }
        }

        return $user;
    }

    /**
     * Trouver un utilisateur par ID
     * 
     * @param int $id ID de l'utilisateur
     * @return self|null
     */
    public static function find(int $id): ?self
    {
        $db = new Database();
        $data = $db->findById('users', $id);

        return $data ? self::fromArray($data) : null;
    }

    /**
     * Trouver un utilisateur par username
     * 
     * @param string $username Username
     * @return self|null
     */
    public static function findByUsername(string $username): ?self
    {
        $db = new Database();
        $data = $db->fetchOne(
            "SELECT * FROM um_users WHERE username = :username",
            ['username' => $username]
        );

        return $data ? self::fromArray($data) : null;
    }

    /**
     * Trouver un utilisateur par email
     * 
     * @param string $email Email
     * @return self|null
     */
    public static function findByEmail(string $email): ?self
    {
        $db = new Database();
        $data = $db->fetchOne(
            "SELECT * FROM um_users WHERE email = :email",
            ['email' => $email]
        );

        return $data ? self::fromArray($data) : null;
    }

    /**
     * Récupérer tous les utilisateurs
     * 
     * @param array $where Conditions WHERE
     * @param string|null $orderBy ORDER BY
     * @param int|null $limit LIMIT
     * @return array
     */
    public static function all(array $where = [], ?string $orderBy = null, ?int $limit = null): array
    {
        $db = new Database();
        $data = $db->select('users', ['*'], $where, $orderBy, $limit);

        $users = [];
        foreach ($data as $row) {
            $users[] = self::fromArray($row);
        }

        return $users;
    }

    /**
     * Créer un nouvel utilisateur
     * 
     * @param array $data Données utilisateur
     * @return self
     */
    public static function create(array $data): self
    {
        $db = new Database();

        // Ajouter created_at
        $data['created_at'] = date('Y-m-d H:i:s');

        // Insérer
        $id = $db->insert('users', $data);

        // Retourner l'utilisateur créé
        return self::find($id);
    }

    // ═══════════════════════════════════════════════════════════════════════
    // MÉTHODES D'INSTANCE
    // ═══════════════════════════════════════════════════════════════════════

    /**
     * Sauvegarder l'utilisateur
     * 
     * @return bool
     */
    public function save(): bool
    {
        $data = $this->toArray();

        // Retirer l'ID et les champs non modifiables
        unset($data['id'], $data['created_at'], $data['created_by']);

        if ($this->id !== null) {
            // Mise à jour
            $data['updated_at'] = date('Y-m-d H:i:s');
            return $this->db->updateById($this->table, $this->id, $data) > 0;
        } else {
            // Création
            $data['created_at'] = date('Y-m-d H:i:s');
            $this->id = $this->db->insert($this->table, $data);
            return $this->id > 0;
        }
    }

    /**
     * Supprimer l'utilisateur
     * 
     * @return bool
     */
    public function delete(): bool
    {
        if ($this->id === null) {
            return false;
        }

        return $this->db->deleteById($this->table, $this->id) > 0;
    }

    /**
     * Rafraîchir les données depuis la DB
     * 
     * @return self
     */
    public function refresh(): self
    {
        if ($this->id !== null) {
            $data = $this->db->findById($this->table, $this->id);
            if ($data) {
                foreach ($data as $key => $value) {
                    if (property_exists($this, $key)) {
                        $this->{$key} = $value;
                    }
                }
            }
        }

        return $this;
    }

    /**
     * Convertir en tableau
     * 
     * @param bool $hidePassword Cacher le mot de passe
     * @return array
     */
    public function toArray(bool $hidePassword = true): array
    {
        $data = [
            'id' => $this->id,
            'username' => $this->username,
            'email' => $this->email,
            'password' => $this->password,
            'first_name' => $this->first_name,
            'last_name' => $this->last_name,
            'role' => $this->role,
            'status' => $this->status,
            'created_at' => $this->created_at,
            'updated_at' => $this->updated_at,
            'last_login' => $this->last_login,
            'last_ip' => $this->last_ip,
            'created_by' => $this->created_by,
            'updated_by' => $this->updated_by,
        ];

        if ($hidePassword) {
            unset($data['password']);
        }

        return $data;
    }

    // ═══════════════════════════════════════════════════════════════════════
    // RELATIONS
    // ═══════════════════════════════════════════════════════════════════════

    /**
     * Récupérer les groupes de l'utilisateur
     * 
     * @return array
     */
    public function groups(): array
    {
        if ($this->id === null) {
            return [];
        }

        return $this->db->fetchAll(
            "SELECT g.* FROM um_groups g
             INNER JOIN um_user_groups ug ON g.id = ug.group_id
             WHERE ug.user_id = :user_id
             ORDER BY g.name ASC",
            ['user_id' => $this->id]
        );
    }

    /**
     * Récupérer les permissions de l'utilisateur (via ses groupes)
     * 
     * @return array
     */
    public function permissions(): array
    {
        if ($this->id === null) {
            return [];
        }

        return $this->db->fetchAll(
            "SELECT DISTINCT p.* FROM um_permissions p
             INNER JOIN um_group_permissions gp ON p.id = gp.permission_id
             INNER JOIN um_user_groups ug ON gp.group_id = ug.group_id
             WHERE ug.user_id = :user_id
             ORDER BY p.name ASC",
            ['user_id' => $this->id]
        );
    }

    /**
     * Assigner l'utilisateur à un groupe
     * 
     * @param int $groupId ID du groupe
     * @return bool
     */
    public function assignToGroup(int $groupId): bool
    {
        if ($this->id === null) {
            return false;
        }

        // Vérifier si déjà assigné
        $existing = $this->db->fetchOne(
            "SELECT * FROM um_user_groups WHERE user_id = :user_id AND group_id = :group_id",
            ['user_id' => $this->id, 'group_id' => $groupId]
        );

        if ($existing) {
            return true; // Déjà assigné
        }

        // Assigner
        $this->db->insert('user_groups', [
            'user_id' => $this->id,
            'group_id' => $groupId,
            'created_at' => date('Y-m-d H:i:s'),
        ]);

        return true;
    }

    /**
     * Retirer l'utilisateur d'un groupe
     * 
     * @param int $groupId ID du groupe
     * @return bool
     */
    public function removeFromGroup(int $groupId): bool
    {
        if ($this->id === null) {
            return false;
        }

        return $this->db->delete('user_groups', [
            'user_id' => $this->id,
            'group_id' => $groupId
        ]) > 0;
    }

    /**
     * Vérifier si l'utilisateur appartient à un groupe
     * 
     * @param int $groupId ID du groupe
     * @return bool
     */
    public function belongsToGroup(int $groupId): bool
    {
        if ($this->id === null) {
            return false;
        }

        $result = $this->db->fetchOne(
            "SELECT * FROM um_user_groups WHERE user_id = :user_id AND group_id = :group_id",
            ['user_id' => $this->id, 'group_id' => $groupId]
        );

        return $result !== null;
    }

    /**
     * Vérifier si l'utilisateur a une permission
     * 
     * @param string $permissionName Nom de la permission
     * @return bool
     */
    public function hasPermission(string $permissionName): bool
    {
        if ($this->id === null) {
            return false;
        }

        $result = $this->db->fetchOne(
            "SELECT p.* FROM um_permissions p
             INNER JOIN um_group_permissions gp ON p.id = gp.permission_id
             INNER JOIN um_user_groups ug ON gp.group_id = ug.group_id
             WHERE ug.user_id = :user_id AND p.name = :permission_name",
            ['user_id' => $this->id, 'permission_name' => $permissionName]
        );

        return $result !== null;
    }

    // ═══════════════════════════════════════════════════════════════════════
    // MÉTHODES UTILITAIRES
    // ═══════════════════════════════════════════════════════════════════════

    /**
     * Vérifier le mot de passe
     * 
     * @param string $password Mot de passe en clair
     * @return bool
     */
    public function verifyPassword(string $password): bool
    {
        return $this->password !== null && password_verify($password, $this->password);
    }

    /**
     * Hasher et définir le mot de passe
     * 
     * @param string $password Mot de passe en clair
     * @return self
     */
    public function setPassword(string $password): self
    {
        $this->password = password_hash($password, PASSWORD_BCRYPT, ['cost' => 12]);
        return $this;
    }

    /**
     * Obtenir le nom complet
     * 
     * @return string
     */
    public function fullName(): string
    {
        return trim(($this->first_name ?? '') . ' ' . ($this->last_name ?? ''));
    }

    /**
     * Vérifier si l'utilisateur est actif
     * 
     * @return bool
     */
    public function isActive(): bool
    {
        return $this->status === 'active';
    }

    /**
     * Vérifier si l'utilisateur est admin ou superadmin
     * 
     * @return bool
     */
    public function isAdmin(): bool
    {
        return in_array($this->role, ['admin', 'superadmin'], true);
    }

    /**
     * Vérifier si l'utilisateur est superadmin
     * 
     * @return bool
     */
    public function isSuperAdmin(): bool
    {
        return $this->role === 'superadmin';
    }

    /**
     * Mettre à jour le last_login
     * 
     * @param string|null $ipAddress Adresse IP
     * @return bool
     */
    public function updateLastLogin(?string $ipAddress = null): bool
    {
        if ($this->id === null) {
            return false;
        }

        $data = [
            'last_login' => date('Y-m-d H:i:s')
        ];

        if ($ipAddress !== null) {
            $data['last_ip'] = $ipAddress;
        }

        return $this->db->updateById($this->table, $this->id, $data) > 0;
    }

    /**
     * Compter les utilisateurs
     * 
     * @param array $where Conditions WHERE
     * @return int
     */
    public static function count(array $where = []): int
    {
        $db = new Database();
        return $db->count('users', $where);
    }

    /**
     * Rechercher des utilisateurs
     * 
     * @param string $search Terme de recherche
     * @param array $where Conditions additionnelles
     * @param int $limit Limite
     * @return array
     */
    public static function search(string $search, array $where = [], int $limit = 50): array
    {
        $db = new Database();
        $searchPattern = '%' . $search . '%';

        $sql = "SELECT * FROM um_users
                WHERE (username LIKE :search OR email LIKE :search OR first_name LIKE :search OR last_name LIKE :search)";

        $params = ['search' => $searchPattern];

        // Conditions additionnelles
        foreach ($where as $key => $value) {
            $sql .= " AND {$key} = :{$key}";
            $params[$key] = $value;
        }

        $sql .= " ORDER BY username ASC LIMIT {$limit}";

        $data = $db->fetchAll($sql, $params);

        $users = [];
        foreach ($data as $row) {
            $users[] = self::fromArray($row);
        }

        return $users;
    }
}

/**
 * ═══════════════════════════════════════════════════════════════════════════
 * FIN DU MODEL USER
 * ═══════════════════════════════════════════════════════════════════════════
 */
