<?php
/**
 * ═══════════════════════════════════════════════════════════════════════════
 * BOLT.DIY USER MANAGER v2.0 - Permission Model
 * © Copyright Nbility 2025 - contact@nbility.fr
 * 
 * Model pour la gestion des permissions
 * ═══════════════════════════════════════════════════════════════════════════
 */

declare(strict_types=1);

namespace App\Models;

use App\Utils\Database;

/**
 * Classe Permission - Model permission
 */
class Permission
{
    private Database $db;
    private string $table = 'permissions';

    /**
     * Propriétés de la permission
     */
    public ?int $id = null;
    public ?string $name = null;
    public ?string $description = null;
    public ?string $category = null;
    public ?string $created_at = null;

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
     * @param array $data Données de la permission
     * @return self
     */
    public static function fromArray(array $data): self
    {
        $permission = new self();

        foreach ($data as $key => $value) {
            if (property_exists($permission, $key)) {
                $permission->{$key} = $value;
            }
        }

        return $permission;
    }

    /**
     * Trouver une permission par ID
     * 
     * @param int $id ID de la permission
     * @return self|null
     */
    public static function find(int $id): ?self
    {
        $db = new Database();
        $data = $db->findById('permissions', $id);

        return $data ? self::fromArray($data) : null;
    }

    /**
     * Trouver une permission par nom
     * 
     * @param string $name Nom de la permission
     * @return self|null
     */
    public static function findByName(string $name): ?self
    {
        $db = new Database();
        $data = $db->fetchOne(
            "SELECT * FROM um_permissions WHERE name = :name",
            ['name' => $name]
        );

        return $data ? self::fromArray($data) : null;
    }

    /**
     * Récupérer toutes les permissions
     * 
     * @param array $where Conditions WHERE
     * @param string|null $orderBy ORDER BY
     * @param int|null $limit LIMIT
     * @return array
     */
    public static function all(array $where = [], ?string $orderBy = 'category ASC, name ASC', ?int $limit = null): array
    {
        $db = new Database();
        $data = $db->select('permissions', ['*'], $where, $orderBy, $limit);

        $permissions = [];
        foreach ($data as $row) {
            $permissions[] = self::fromArray($row);
        }

        return $permissions;
    }

    /**
     * Créer une nouvelle permission
     * 
     * @param array $data Données de la permission
     * @return self
     */
    public static function create(array $data): self
    {
        $db = new Database();

        // Ajouter created_at
        $data['created_at'] = date('Y-m-d H:i:s');

        // Insérer
        $id = $db->insert('permissions', $data);

        // Retourner la permission créée
        return self::find($id);
    }

    /**
     * Compter les permissions
     * 
     * @param array $where Conditions WHERE
     * @return int
     */
    public static function count(array $where = []): int
    {
        $db = new Database();
        return $db->count('permissions', $where);
    }

    /**
     * Récupérer les permissions par catégorie
     * 
     * @param string $category Catégorie
     * @return array
     */
    public static function byCategory(string $category): array
    {
        $db = new Database();
        $data = $db->select('permissions', ['*'], ['category' => $category], 'name ASC');

        $permissions = [];
        foreach ($data as $row) {
            $permissions[] = self::fromArray($row);
        }

        return $permissions;
    }

    /**
     * Récupérer toutes les catégories
     * 
     * @return array
     */
    public static function categories(): array
    {
        $db = new Database();
        $data = $db->fetchAll(
            "SELECT DISTINCT category FROM um_permissions WHERE category IS NOT NULL ORDER BY category ASC"
        );

        return array_column($data, 'category');
    }

    /**
     * Rechercher des permissions
     * 
     * @param string $search Terme de recherche
     * @param int $limit Limite
     * @return array
     */
    public static function search(string $search, int $limit = 50): array
    {
        $db = new Database();
        $searchPattern = '%' . $search . '%';

        $sql = "SELECT * FROM um_permissions
                WHERE (name LIKE :search OR description LIKE :search OR category LIKE :search)
                ORDER BY category ASC, name ASC LIMIT {$limit}";

        $data = $db->fetchAll($sql, ['search' => $searchPattern]);

        $permissions = [];
        foreach ($data as $row) {
            $permissions[] = self::fromArray($row);
        }

        return $permissions;
    }

    // ═══════════════════════════════════════════════════════════════════════
    // MÉTHODES D'INSTANCE
    // ═══════════════════════════════════════════════════════════════════════

    /**
     * Sauvegarder la permission
     * 
     * @return bool
     */
    public function save(): bool
    {
        $data = $this->toArray();

        // Retirer l'ID et created_at
        unset($data['id'], $data['created_at']);

        if ($this->id !== null) {
            // Mise à jour
            return $this->db->updateById($this->table, $this->id, $data) > 0;
        } else {
            // Création
            $data['created_at'] = date('Y-m-d H:i:s');
            $this->id = $this->db->insert($this->table, $data);
            return $this->id > 0;
        }
    }

    /**
     * Supprimer la permission
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
            // Transaction pour supprimer la permission et ses relations
            return $this->db->transaction(function($db) {
                // Supprimer les relations group_permissions
                $db->delete('group_permissions', ['permission_id' => $this->id]);

                // Supprimer la permission
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
            'description' => $this->description,
            'category' => $this->category,
            'created_at' => $this->created_at,
        ];
    }

    // ═══════════════════════════════════════════════════════════════════════
    // RELATIONS - GROUPES
    // ═══════════════════════════════════════════════════════════════════════

    /**
     * Récupérer les groupes ayant cette permission
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
             INNER JOIN um_group_permissions gp ON g.id = gp.group_id
             WHERE gp.permission_id = :permission_id
             ORDER BY g.name ASC",
            ['permission_id' => $this->id]
        );
    }

    /**
     * Compter les groupes ayant cette permission
     * 
     * @return int
     */
    public function groupCount(): int
    {
        if ($this->id === null) {
            return 0;
        }

        return (int)$this->db->fetchColumn(
            "SELECT COUNT(*) FROM um_group_permissions WHERE permission_id = :permission_id",
            ['permission_id' => $this->id]
        );
    }

    /**
     * Assigner la permission à un groupe
     * 
     * @param int $groupId ID du groupe
     * @return bool
     */
    public function assignToGroup(int $groupId): bool
    {
        if ($this->id === null) {
            return false;
        }

        // Vérifier si déjà assignée
        $existing = $this->db->fetchOne(
            "SELECT * FROM um_group_permissions WHERE permission_id = :permission_id AND group_id = :group_id",
            ['permission_id' => $this->id, 'group_id' => $groupId]
        );

        if ($existing) {
            return true; // Déjà assignée
        }

        // Assigner
        $this->db->insert('group_permissions', [
            'permission_id' => $this->id,
            'group_id' => $groupId,
            'created_at' => date('Y-m-d H:i:s'),
        ]);

        return true;
    }

    /**
     * Retirer la permission d'un groupe
     * 
     * @param int $groupId ID du groupe
     * @return bool
     */
    public function removeFromGroup(int $groupId): bool
    {
        if ($this->id === null) {
            return false;
        }

        return $this->db->delete('group_permissions', [
            'permission_id' => $this->id,
            'group_id' => $groupId
        ]) > 0;
    }
}

/**
 * ═══════════════════════════════════════════════════════════════════════════
 * FIN DU MODEL PERMISSION
 * ═══════════════════════════════════════════════════════════════════════════
 */
