<?php
/**
 * ═══════════════════════════════════════════════════════════════════════════
 * BOLT.DIY USER MANAGER v2.0 - Group Model
 * © Copyright Nbility 2025 - contact@nbility.fr
 * 
 * Model pour la gestion des groupes
 * ═══════════════════════════════════════════════════════════════════════════
 */

declare(strict_types=1);

namespace App\Models;

use App\Utils\Database;

/**
 * Classe Group - Model groupe
 */
class Group
{
    private Database $db;
    private string $table = 'groups';

    /**
     * Propriétés du groupe
     */
    public ?int $id = null;
    public ?string $name = null;
    public ?string $slug = null;
    public ?string $description = null;
    public ?string $created_at = null;
    public ?string $updated_at = null;
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
     * @param array $data Données du groupe
     * @return self
     */
    public static function fromArray(array $data): self
    {
        $group = new self();

        foreach ($data as $key => $value) {
            if (property_exists($group, $key)) {
                $group->{$key} = $value;
            }
        }

        return $group;
    }

    /**
     * Trouver un groupe par ID
     * 
     * @param int $id ID du groupe
     * @return self|null
     */
    public static function find(int $id): ?self
    {
        $db = new Database();
        $data = $db->findById('groups', $id);

        return $data ? self::fromArray($data) : null;
    }

    /**
     * Trouver un groupe par slug
     * 
     * @param string $slug Slug du groupe
     * @return self|null
     */
    public static function findBySlug(string $slug): ?self
    {
        $db = new Database();
        $data = $db->fetchOne(
            "SELECT * FROM um_groups WHERE slug = :slug",
            ['slug' => $slug]
        );

        return $data ? self::fromArray($data) : null;
    }

    /**
     * Trouver un groupe par nom
     * 
     * @param string $name Nom du groupe
     * @return self|null
     */
    public static function findByName(string $name): ?self
    {
        $db = new Database();
        $data = $db->fetchOne(
            "SELECT * FROM um_groups WHERE name = :name",
            ['name' => $name]
        );

        return $data ? self::fromArray($data) : null;
    }

    /**
     * Récupérer tous les groupes
     * 
     * @param array $where Conditions WHERE
     * @param string|null $orderBy ORDER BY
     * @param int|null $limit LIMIT
     * @return array
     */
    public static function all(array $where = [], ?string $orderBy = 'name ASC', ?int $limit = null): array
    {
        $db = new Database();
        $data = $db->select('groups', ['*'], $where, $orderBy, $limit);

        $groups = [];
        foreach ($data as $row) {
            $groups[] = self::fromArray($row);
        }

        return $groups;
    }

    /**
     * Créer un nouveau groupe
     * 
     * @param array $data Données du groupe
     * @return self
     */
    public static function create(array $data): self
    {
        $db = new Database();

        // Ajouter created_at
        $data['created_at'] = date('Y-m-d H:i:s');

        // Insérer
        $id = $db->insert('groups', $data);

        // Retourner le groupe créé
        return self::find($id);
    }

    /**
     * Compter les groupes
     * 
     * @param array $where Conditions WHERE
     * @return int
     */
    public static function count(array $where = []): int
    {
        $db = new Database();
        return $db->count('groups', $where);
    }

    /**
     * Rechercher des groupes
     * 
     * @param string $search Terme de recherche
     * @param int $limit Limite
     * @return array
     */
    public static function search(string $search, int $limit = 50): array
    {
        $db = new Database();
        $searchPattern = '%' . $search . '%';

        $sql = "SELECT * FROM um_groups
                WHERE (name LIKE :search OR slug LIKE :search OR description LIKE :search)
                ORDER BY name ASC LIMIT {$limit}";

        $data = $db->fetchAll($sql, ['search' => $searchPattern]);

        $groups = [];
        foreach ($data as $row) {
            $groups[] = self::fromArray($row);
        }

        return $groups;
    }

    // ═══════════════════════════════════════════════════════════════════════
    // MÉTHODES D'INSTANCE
    // ═══════════════════════════════════════════════════════════════════════

    /**
     * Sauvegarder le groupe
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
     * Supprimer le groupe
     * 
     * @param bool $withRelations Supprimer aussi les relations
     * @return bool
     */
    public function delete(bool $withRelations = true): bool
    {
        if ($this->id === null) {
            return false;
        }

        if ($withRelations) {
            // Transaction pour supprimer le groupe et ses relations
            return $this->db->transaction(function($db) {
                // Supprimer les relations user_groups
                $db->delete('user_groups', ['group_id' => $this->id]);

                // Supprimer les relations group_permissions
                $db->delete('group_permissions', ['group_id' => $this->id]);

                // Supprimer le groupe
                return $db->deleteById($this->table, $this->id) > 0;
            });
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
     * @return array
     */
    public function toArray(): array
    {
        return [
            'id' => $this->id,
            'name' => $this->name,
            'slug' => $this->slug,
            'description' => $this->description,
            'created_at' => $this->created_at,
            'updated_at' => $this->updated_at,
            'created_by' => $this->created_by,
            'updated_by' => $this->updated_by,
        ];
    }

    // ═══════════════════════════════════════════════════════════════════════
    // RELATIONS - UTILISATEURS
    // ═══════════════════════════════════════════════════════════════════════

    /**
     * Récupérer les utilisateurs du groupe
     * 
     * @return array
     */
    public function users(): array
    {
        if ($this->id === null) {
            return [];
        }

        return $this->db->fetchAll(
            "SELECT u.* FROM um_users u
             INNER JOIN um_user_groups ug ON u.id = ug.user_id
             WHERE ug.group_id = :group_id
             ORDER BY u.username ASC",
            ['group_id' => $this->id]
        );
    }

    /**
     * Compter les utilisateurs du groupe
     * 
     * @return int
     */
    public function userCount(): int
    {
        if ($this->id === null) {
            return 0;
        }

        return (int)$this->db->fetchColumn(
            "SELECT COUNT(*) FROM um_user_groups WHERE group_id = :group_id",
            ['group_id' => $this->id]
        );
    }

    /**
     * Assigner un utilisateur au groupe
     * 
     * @param int $userId ID de l'utilisateur
     * @return bool
     */
    public function addUser(int $userId): bool
    {
        if ($this->id === null) {
            return false;
        }

        // Vérifier si déjà assigné
        $existing = $this->db->fetchOne(
            "SELECT * FROM um_user_groups WHERE group_id = :group_id AND user_id = :user_id",
            ['group_id' => $this->id, 'user_id' => $userId]
        );

        if ($existing) {
            return true; // Déjà assigné
        }

        // Assigner
        $this->db->insert('user_groups', [
            'group_id' => $this->id,
            'user_id' => $userId,
            'created_at' => date('Y-m-d H:i:s'),
        ]);

        return true;
    }

    /**
     * Retirer un utilisateur du groupe
     * 
     * @param int $userId ID de l'utilisateur
     * @return bool
     */
    public function removeUser(int $userId): bool
    {
        if ($this->id === null) {
            return false;
        }

        return $this->db->delete('user_groups', [
            'group_id' => $this->id,
            'user_id' => $userId
        ]) > 0;
    }

    /**
     * Vérifier si un utilisateur appartient au groupe
     * 
     * @param int $userId ID de l'utilisateur
     * @return bool
     */
    public function hasUser(int $userId): bool
    {
        if ($this->id === null) {
            return false;
        }

        $result = $this->db->fetchOne(
            "SELECT * FROM um_user_groups WHERE group_id = :group_id AND user_id = :user_id",
            ['group_id' => $this->id, 'user_id' => $userId]
        );

        return $result !== null;
    }

    /**
     * Synchroniser les utilisateurs du groupe
     * 
     * @param array $userIds IDs des utilisateurs
     * @return bool
     */
    public function syncUsers(array $userIds): bool
    {
        if ($this->id === null) {
            return false;
        }

        return $this->db->transaction(function($db) use ($userIds) {
            // Supprimer tous les utilisateurs actuels
            $db->delete('user_groups', ['group_id' => $this->id]);

            // Ajouter les nouveaux
            foreach ($userIds as $userId) {
                $db->insert('user_groups', [
                    'group_id' => $this->id,
                    'user_id' => (int)$userId,
                    'created_at' => date('Y-m-d H:i:s'),
                ]);
            }

            return true;
        });
    }

    // ═══════════════════════════════════════════════════════════════════════
    // RELATIONS - PERMISSIONS
    // ═══════════════════════════════════════════════════════════════════════

    /**
     * Récupérer les permissions du groupe
     * 
     * @return array
     */
    public function permissions(): array
    {
        if ($this->id === null) {
            return [];
        }

        return $this->db->fetchAll(
            "SELECT p.* FROM um_permissions p
             INNER JOIN um_group_permissions gp ON p.id = gp.permission_id
             WHERE gp.group_id = :group_id
             ORDER BY p.category ASC, p.name ASC",
            ['group_id' => $this->id]
        );
    }

    /**
     * Compter les permissions du groupe
     * 
     * @return int
     */
    public function permissionCount(): int
    {
        if ($this->id === null) {
            return 0;
        }

        return (int)$this->db->fetchColumn(
            "SELECT COUNT(*) FROM um_group_permissions WHERE group_id = :group_id",
            ['group_id' => $this->id]
        );
    }

    /**
     * Assigner une permission au groupe
     * 
     * @param int $permissionId ID de la permission
     * @return bool
     */
    public function addPermission(int $permissionId): bool
    {
        if ($this->id === null) {
            return false;
        }

        // Vérifier si déjà assignée
        $existing = $this->db->fetchOne(
            "SELECT * FROM um_group_permissions WHERE group_id = :group_id AND permission_id = :permission_id",
            ['group_id' => $this->id, 'permission_id' => $permissionId]
        );

        if ($existing) {
            return true; // Déjà assignée
        }

        // Assigner
        $this->db->insert('group_permissions', [
            'group_id' => $this->id,
            'permission_id' => $permissionId,
            'created_at' => date('Y-m-d H:i:s'),
        ]);

        return true;
    }

    /**
     * Retirer une permission du groupe
     * 
     * @param int $permissionId ID de la permission
     * @return bool
     */
    public function removePermission(int $permissionId): bool
    {
        if ($this->id === null) {
            return false;
        }

        return $this->db->delete('group_permissions', [
            'group_id' => $this->id,
            'permission_id' => $permissionId
        ]) > 0;
    }

    /**
     * Vérifier si le groupe a une permission
     * 
     * @param int|string $permission ID ou nom de la permission
     * @return bool
     */
    public function hasPermission($permission): bool
    {
        if ($this->id === null) {
            return false;
        }

        if (is_int($permission)) {
            // Par ID
            $result = $this->db->fetchOne(
                "SELECT * FROM um_group_permissions WHERE group_id = :group_id AND permission_id = :permission_id",
                ['group_id' => $this->id, 'permission_id' => $permission]
            );
        } else {
            // Par nom
            $result = $this->db->fetchOne(
                "SELECT gp.* FROM um_group_permissions gp
                 INNER JOIN um_permissions p ON gp.permission_id = p.id
                 WHERE gp.group_id = :group_id AND p.name = :permission_name",
                ['group_id' => $this->id, 'permission_name' => $permission]
            );
        }

        return $result !== null;
    }

    /**
     * Synchroniser les permissions du groupe
     * 
     * @param array $permissionIds IDs des permissions
     * @return bool
     */
    public function syncPermissions(array $permissionIds): bool
    {
        if ($this->id === null) {
            return false;
        }

        return $this->db->transaction(function($db) use ($permissionIds) {
            // Supprimer toutes les permissions actuelles
            $db->delete('group_permissions', ['group_id' => $this->id]);

            // Ajouter les nouvelles
            foreach ($permissionIds as $permissionId) {
                $db->insert('group_permissions', [
                    'group_id' => $this->id,
                    'permission_id' => (int)$permissionId,
                    'created_at' => date('Y-m-d H:i:s'),
                ]);
            }

            return true;
        });
    }

    // ═══════════════════════════════════════════════════════════════════════
    // MÉTHODES UTILITAIRES
    // ═══════════════════════════════════════════════════════════════════════

    /**
     * Générer un slug depuis le nom
     * 
     * @param string $name Nom du groupe
     * @return string
     */
    public static function generateSlug(string $name): string
    {
        // Convertir en minuscules
        $slug = strtolower($name);

        // Remplacer les caractères spéciaux
        $slug = preg_replace('/[^a-z0-9-]/', '-', $slug);

        // Supprimer les tirets multiples
        $slug = preg_replace('/-+/', '-', $slug);

        // Supprimer les tirets au début et à la fin
        $slug = trim($slug, '-');

        return $slug;
    }

    /**
     * Obtenir le slug unique (avec suffixe si nécessaire)
     * 
     * @param string $name Nom du groupe
     * @param int|null $excludeId ID à exclure (pour les mises à jour)
     * @return string
     */
    public static function getUniqueSlug(string $name, ?int $excludeId = null): string
    {
        $slug = self::generateSlug($name);
        $originalSlug = $slug;
        $counter = 1;

        $db = new Database();

        while (true) {
            // Vérifier si le slug existe
            $sql = "SELECT * FROM um_groups WHERE slug = :slug";
            $params = ['slug' => $slug];

            if ($excludeId !== null) {
                $sql .= " AND id != :id";
                $params['id'] = $excludeId;
            }

            $existing = $db->fetchOne($sql, $params);

            if (!$existing) {
                return $slug;
            }

            // Slug existe, ajouter un suffixe
            $slug = $originalSlug . '-' . $counter;
            $counter++;
        }
    }
}

/**
 * ═══════════════════════════════════════════════════════════════════════════
 * FIN DU MODEL GROUP
 * ═══════════════════════════════════════════════════════════════════════════
 */
