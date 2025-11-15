<?php
/**
 * ═══════════════════════════════════════════════════════════════════════════
 * BOLT.DIY USER MANAGER v2.0 - PermissionController
 * © Copyright Nbility 2025 - contact@nbility.fr
 * 
 * Contrôleur de gestion des permissions
 * Endpoints: /api/permissions (GET, POST)
 * ═══════════════════════════════════════════════════════════════════════════
 */

declare(strict_types=1);

namespace App\Controllers;

use App\Utils\Response;
use App\Utils\Logger;
use App\Utils\Database;
use App\Utils\Validator;

/**
 * Classe PermissionController - Gestion des permissions
 */
class PermissionController
{
    private Database $db;

    public function __construct()
    {
        $this->db = new Database();
        initSecureSession();
    }

    /**
     * Router principal pour les requêtes /api/permissions/*
     * 
     * @param string $method Méthode HTTP
     * @param string|null $id ID de la permission ou action
     */
    public function handle(string $method, ?string $id): void
    {
        // Vérifier l'authentification
        if (!$this->isAuthenticated()) {
            Response::unauthorized();
        }

        // Vérifier les permissions (seuls admin et superadmin)
        if (!$this->hasRole(['admin', 'superadmin'])) {
            Response::forbidden('Accès refusé');
        }

        // Router selon la méthode HTTP
        switch ($method) {
            case 'GET':
                if ($id === null) {
                    $this->list(); // Liste des permissions
                } else {
                    $this->show((int)$id); // Détails d'une permission
                }
                break;

            case 'POST':
                if ($id !== null && $id === 'assign') {
                    $this->assignToGroup(); // Assigner des permissions à un groupe
                } elseif ($id !== null && $id === 'remove') {
                    $this->removeFromGroup(); // Retirer des permissions d'un groupe
                } else {
                    Response::error('Action non supportée', 400);
                }
                break;

            default:
                Response::error('Méthode non autorisée', 405);
        }
    }

    // ═══════════════════════════════════════════════════════════════════════
    // LIST - GET /api/permissions
    // ═══════════════════════════════════════════════════════════════════════

    /**
     * Liste des permissions avec pagination et recherche
     * 
     * GET /api/permissions?page=1&per_page=50&search=users
     */
    private function list(): void
    {
        // Paramètres de pagination
        $page = (int)($_GET['page'] ?? 1);
        $perPage = (int)($_GET['per_page'] ?? 50);
        $search = $_GET['search'] ?? null;
        $category = $_GET['category'] ?? null;

        // Limites
        $perPage = min(max($perPage, PAGINATION_CONFIG['min_per_page']), PAGINATION_CONFIG['max_per_page']);

        // Construire la requête
        $sql = "SELECT p.*,
                       COUNT(DISTINCT gp.group_id) as group_count
                FROM um_permissions p
                LEFT JOIN um_group_permissions gp ON p.id = gp.permission_id
                WHERE 1=1";

        $params = [];
        $countSql = "SELECT COUNT(*) FROM um_permissions WHERE 1=1";

        // Recherche
        if ($search !== null && $search !== '') {
            $searchPattern = '%' . $search . '%';
            $sql .= " AND (p.name LIKE :search OR p.description LIKE :search)";
            $countSql .= " AND (name LIKE :search OR description LIKE :search)";
            $params['search'] = $searchPattern;
        }

        // Filtre par catégorie
        if ($category !== null && $category !== '') {
            $sql .= " AND p.category = :category";
            $countSql .= " AND category = :category";
            $params['category'] = $category;
        }

        // Grouper
        $sql .= " GROUP BY p.id";

        // Compter le total
        $total = (int)$this->db->fetchColumn($countSql, $params);

        // Pagination
        $offset = ($page - 1) * $perPage;
        $sql .= " ORDER BY p.category ASC, p.name ASC LIMIT {$perPage} OFFSET {$offset}";

        // Récupérer les permissions
        $permissions = $this->db->fetchAll($sql, $params);

        // Récupérer les catégories disponibles
        $categories = $this->db->fetchAll(
            "SELECT DISTINCT category FROM um_permissions WHERE category IS NOT NULL ORDER BY category ASC"
        );

        Logger::info('Permissions list retrieved', [
            'user_id' => $_SESSION['user_id'],
            'total' => $total
        ]);

        Response::success([
            'permissions' => $permissions,
            'categories' => array_column($categories, 'category'),
            'pagination' => [
                'current_page' => $page,
                'per_page' => $perPage,
                'total_items' => $total,
                'total_pages' => (int)ceil($total / $perPage),
            ]
        ]);
    }

    // ═══════════════════════════════════════════════════════════════════════
    // SHOW - GET /api/permissions/{id}
    // ═══════════════════════════════════════════════════════════════════════

    /**
     * Afficher les détails d'une permission
     * 
     * GET /api/permissions/123
     */
    private function show(int $id): void
    {
        // Récupérer la permission
        $permission = $this->db->findById('permissions', $id);

        if (!$permission) {
            Response::notFound('Permission non trouvée');
        }

        // Récupérer les groupes ayant cette permission
        $groups = $this->db->fetchAll(
            "SELECT g.id, g.name, g.slug, g.description
             FROM um_groups g
             INNER JOIN um_group_permissions gp ON g.id = gp.group_id
             WHERE gp.permission_id = :permission_id
             ORDER BY g.name ASC",
            ['permission_id' => $id]
        );

        Logger::info('Permission details retrieved', [
            'user_id' => $_SESSION['user_id'],
            'permission_id' => $id
        ]);

        Response::success([
            'permission' => $permission,
            'groups' => $groups,
            'stats' => [
                'group_count' => count($groups)
            ]
        ]);
    }

    // ═══════════════════════════════════════════════════════════════════════
    // ASSIGN TO GROUP - POST /api/permissions/assign
    // ═══════════════════════════════════════════════════════════════════════

    /**
     * Assigner des permissions à un groupe
     * 
     * POST /api/permissions/assign
     * Body: {"group_id": 1, "permission_ids": [1, 2, 3]}
     */
    private function assignToGroup(): void
    {
        // Récupérer les données
        $data = json_decode(file_get_contents('php://input'), true) ?? [];

        // Validation
        $validator = new Validator($data);
        if (!$validator->validate([
            'group_id' => 'required|integer|exists:groups,id',
            'permission_ids' => 'required',
        ])) {
            Response::validationError($validator->getErrors());
        }

        $groupId = (int)$data['group_id'];
        $permissionIds = $data['permission_ids'];

        // Vérifier que permission_ids est un tableau
        if (!is_array($permissionIds) || empty($permissionIds)) {
            Response::error('permission_ids doit être un tableau non vide', 400);
        }

        try {
            $assigned = 0;
            $skipped = 0;

            // Assigner chaque permission
            foreach ($permissionIds as $permissionId) {
                $permissionId = (int)$permissionId;

                // Vérifier que la permission existe
                $permission = $this->db->findById('permissions', $permissionId);
                if (!$permission) {
                    $skipped++;
                    continue;
                }

                // Vérifier si déjà assignée
                $existing = $this->db->fetchOne(
                    "SELECT * FROM um_group_permissions WHERE group_id = :group_id AND permission_id = :permission_id",
                    ['group_id' => $groupId, 'permission_id' => $permissionId]
                );

                if ($existing) {
                    $skipped++;
                    continue;
                }

                // Assigner
                $this->db->insert('group_permissions', [
                    'group_id' => $groupId,
                    'permission_id' => $permissionId,
                    'created_at' => date('Y-m-d H:i:s'),
                ]);

                $assigned++;
            }

            Logger::info('Permissions assigned to group', [
                'assigner_id' => $_SESSION['user_id'],
                'group_id' => $groupId,
                'assigned' => $assigned,
                'skipped' => $skipped
            ]);

            $this->logAudit($_SESSION['user_id'], 'permission_assign', "Assigned {$assigned} permissions to group ID: {$groupId}");

            Response::success([
                'assigned' => $assigned,
                'skipped' => $skipped,
                'total' => count($permissionIds)
            ], "Assignation terminée : {$assigned} ajoutées, {$skipped} ignorées");

        } catch (\Exception $e) {
            Logger::error('Permission assignment failed', [
                'error' => $e->getMessage(),
                'group_id' => $groupId
            ]);
            Response::serverError('Erreur lors de l\'assignation des permissions');
        }
    }

    // ═══════════════════════════════════════════════════════════════════════
    // REMOVE FROM GROUP - POST /api/permissions/remove
    // ═══════════════════════════════════════════════════════════════════════

    /**
     * Retirer des permissions d'un groupe
     * 
     * POST /api/permissions/remove
     * Body: {"group_id": 1, "permission_ids": [1, 2, 3]}
     */
    private function removeFromGroup(): void
    {
        // Récupérer les données
        $data = json_decode(file_get_contents('php://input'), true) ?? [];

        // Validation
        $validator = new Validator($data);
        if (!$validator->validate([
            'group_id' => 'required|integer|exists:groups,id',
            'permission_ids' => 'required',
        ])) {
            Response::validationError($validator->getErrors());
        }

        $groupId = (int)$data['group_id'];
        $permissionIds = $data['permission_ids'];

        // Vérifier que permission_ids est un tableau
        if (!is_array($permissionIds) || empty($permissionIds)) {
            Response::error('permission_ids doit être un tableau non vide', 400);
        }

        try {
            $removed = 0;

            // Retirer chaque permission
            foreach ($permissionIds as $permissionId) {
                $permissionId = (int)$permissionId;

                $result = $this->db->delete('group_permissions', [
                    'group_id' => $groupId,
                    'permission_id' => $permissionId
                ]);

                $removed += $result;
            }

            Logger::info('Permissions removed from group', [
                'remover_id' => $_SESSION['user_id'],
                'group_id' => $groupId,
                'removed' => $removed
            ]);

            $this->logAudit($_SESSION['user_id'], 'permission_remove', "Removed {$removed} permissions from group ID: {$groupId}");

            Response::success([
                'removed' => $removed,
                'total' => count($permissionIds)
            ], "{$removed} permission(s) retirée(s) du groupe");

        } catch (\Exception $e) {
            Logger::error('Permission removal failed', [
                'error' => $e->getMessage(),
                'group_id' => $groupId
            ]);
            Response::serverError('Erreur lors du retrait des permissions');
        }
    }

    // ═══════════════════════════════════════════════════════════════════════
    // MÉTHODES UTILITAIRES
    // ═══════════════════════════════════════════════════════════════════════

    /**
     * Vérifier si l'utilisateur est authentifié
     */
    private function isAuthenticated(): bool
    {
        return isset($_SESSION['logged_in']) && $_SESSION['logged_in'] === true;
    }

    /**
     * Vérifier si l'utilisateur a un rôle spécifique
     */
    private function hasRole(array $roles): bool
    {
        return isset($_SESSION['role']) && in_array($_SESSION['role'], $roles, true);
    }

    /**
     * Logger un événement d'audit
     */
    private function logAudit(int $userId, string $action, string $description, array $metadata = []): void
    {
        try {
            $this->db->insert('audit_logs', [
                'user_id' => $userId,
                'action' => $action,
                'description' => $description,
                'metadata' => json_encode($metadata),
                'ip_address' => $_SERVER['REMOTE_ADDR'] ?? null,
                'user_agent' => $_SERVER['HTTP_USER_AGENT'] ?? null,
                'created_at' => date('Y-m-d H:i:s'),
            ]);
        } catch (\Exception $e) {
            Logger::error('Failed to log audit', ['error' => $e->getMessage()]);
        }
    }
}

/**
 * ═══════════════════════════════════════════════════════════════════════════
 * FIN DU PERMISSIONCONTROLLER
 * ═══════════════════════════════════════════════════════════════════════════
 */
