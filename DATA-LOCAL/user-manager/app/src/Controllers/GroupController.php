<?php
/**
 * ═══════════════════════════════════════════════════════════════════════════
 * BOLT.DIY USER MANAGER v2.0 - GroupController
 * © Copyright Nbility 2025 - contact@nbility.fr
 * 
 * Contrôleur de gestion des groupes (CRUD + assignation utilisateurs)
 * Endpoints: /api/groups (GET, POST, PUT, DELETE)
 * ═══════════════════════════════════════════════════════════════════════════
 */

declare(strict_types=1);

namespace App\Controllers;

use App\Utils\Response;
use App\Utils\Logger;
use App\Utils\Database;
use App\Utils\Validator;

/**
 * Classe GroupController - Gestion des groupes
 */
class GroupController
{
    private Database $db;

    public function __construct()
    {
        $this->db = new Database();
        initSecureSession();
    }

    /**
     * Router principal pour les requêtes /api/groups/*
     * 
     * @param string $method Méthode HTTP
     * @param string|null $id ID du groupe ou action
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
                    $this->list(); // Liste des groupes
                } else {
                    $this->show((int)$id); // Détails d'un groupe
                }
                break;

            case 'POST':
                if ($id !== null && $id === 'assign') {
                    $this->assignUsers(); // Assigner des utilisateurs à un groupe
                } elseif ($id !== null && $id === 'remove') {
                    $this->removeUsers(); // Retirer des utilisateurs d'un groupe
                } else {
                    $this->create(); // Créer un groupe
                }
                break;

            case 'PUT':
                if ($id === null) {
                    Response::error('ID groupe requis', 400);
                }
                $this->update((int)$id); // Mettre à jour un groupe
                break;

            case 'DELETE':
                if ($id === null) {
                    Response::error('ID groupe requis', 400);
                }
                $this->delete((int)$id); // Supprimer un groupe
                break;

            default:
                Response::error('Méthode non autorisée', 405);
        }
    }

    // ═══════════════════════════════════════════════════════════════════════
    // LIST - GET /api/groups
    // ═══════════════════════════════════════════════════════════════════════

    /**
     * Liste des groupes avec pagination et recherche
     * 
     * GET /api/groups?page=1&per_page=20&search=dev
     */
    private function list(): void
    {
        // Paramètres de pagination
        $page = (int)($_GET['page'] ?? 1);
        $perPage = (int)($_GET['per_page'] ?? 20);
        $search = $_GET['search'] ?? null;

        // Limites
        $perPage = min(max($perPage, PAGINATION_CONFIG['min_per_page']), PAGINATION_CONFIG['max_per_page']);

        // Construire la requête
        $sql = "SELECT g.*, 
                       COUNT(DISTINCT ug.user_id) as user_count,
                       COUNT(DISTINCT gp.permission_id) as permission_count
                FROM um_groups g
                LEFT JOIN um_user_groups ug ON g.id = ug.group_id
                LEFT JOIN um_group_permissions gp ON g.id = gp.group_id
                WHERE 1=1";

        $params = [];
        $countSql = "SELECT COUNT(*) FROM um_groups WHERE 1=1";

        // Recherche
        if ($search !== null && $search !== '') {
            $searchPattern = '%' . $search . '%';
            $sql .= " AND (g.name LIKE :search OR g.slug LIKE :search OR g.description LIKE :search)";
            $countSql .= " AND (name LIKE :search OR slug LIKE :search OR description LIKE :search)";
            $params['search'] = $searchPattern;
        }

        // Grouper par groupe
        $sql .= " GROUP BY g.id";

        // Compter le total
        $total = (int)$this->db->fetchColumn($countSql, $params);

        // Pagination
        $offset = ($page - 1) * $perPage;
        $sql .= " ORDER BY g.name ASC LIMIT {$perPage} OFFSET {$offset}";

        // Récupérer les groupes
        $groups = $this->db->fetchAll($sql, $params);

        Logger::info('Groups list retrieved', [
            'user_id' => $_SESSION['user_id'],
            'total' => $total
        ]);

        Response::paginated($groups, $total, $page, $perPage);
    }

    // ═══════════════════════════════════════════════════════════════════════
    // SHOW - GET /api/groups/{id}
    // ═══════════════════════════════════════════════════════════════════════

    /**
     * Afficher les détails d'un groupe
     * 
     * GET /api/groups/123
     */
    private function show(int $id): void
    {
        // Récupérer le groupe
        $group = $this->db->findById('groups', $id);

        if (!$group) {
            Response::notFound('Groupe non trouvé');
        }

        // Récupérer les utilisateurs du groupe
        $users = $this->db->fetchAll(
            "SELECT u.id, u.username, u.email, u.first_name, u.last_name, u.role, u.status
             FROM um_users u
             INNER JOIN um_user_groups ug ON u.id = ug.user_id
             WHERE ug.group_id = :group_id
             ORDER BY u.username ASC",
            ['group_id' => $id]
        );

        // Récupérer les permissions du groupe
        $permissions = $this->db->fetchAll(
            "SELECT p.*
             FROM um_permissions p
             INNER JOIN um_group_permissions gp ON p.id = gp.permission_id
             WHERE gp.group_id = :group_id
             ORDER BY p.name ASC",
            ['group_id' => $id]
        );

        Logger::info('Group details retrieved', [
            'user_id' => $_SESSION['user_id'],
            'group_id' => $id
        ]);

        Response::success([
            'group' => $group,
            'users' => $users,
            'permissions' => $permissions,
            'stats' => [
                'user_count' => count($users),
                'permission_count' => count($permissions),
            ]
        ]);
    }

    // ═══════════════════════════════════════════════════════════════════════
    // CREATE - POST /api/groups
    // ═══════════════════════════════════════════════════════════════════════

    /**
     * Créer un nouveau groupe
     * 
     * POST /api/groups
     * Body: {"name": "Developers", "slug": "developers", "description": "Development team"}
     */
    private function create(): void
    {
        // Récupérer les données
        $data = json_decode(file_get_contents('php://input'), true) ?? [];

        // Validation
        $validator = new Validator($data);
        if (!$validator->validate([
            'name' => 'required|min:2|max:100|unique:groups,name',
            'slug' => 'required|regex:/^[a-z0-9-]+$/|unique:groups,slug',
            'description' => 'max:255',
        ])) {
            Response::validationError($validator->getErrors());
        }

        // Préparer les données
        $groupData = [
            'name' => sanitizeString($data['name']),
            'slug' => strtolower(trim($data['slug'])),
            'description' => isset($data['description']) ? sanitizeString($data['description']) : null,
            'created_at' => date('Y-m-d H:i:s'),
            'created_by' => $_SESSION['user_id'],
        ];

        try {
            // Insérer le groupe
            $groupId = $this->db->insert('groups', $groupData);

            Logger::info('Group created', [
                'creator_id' => $_SESSION['user_id'],
                'group_id' => $groupId,
                'name' => $groupData['name']
            ]);

            $this->logAudit($_SESSION['user_id'], 'group_create', "Created group: {$groupData['name']}", ['group_id' => $groupId]);

            // Récupérer le groupe créé
            $group = $this->db->findById('groups', $groupId);

            Response::success([
                'group' => $group
            ], 'Groupe créé avec succès', 201);

        } catch (\Exception $e) {
            Logger::error('Group creation failed', [
                'error' => $e->getMessage(),
                'name' => $data['name']
            ]);
            Response::serverError('Erreur lors de la création du groupe');
        }
    }

    // ═══════════════════════════════════════════════════════════════════════
    // UPDATE - PUT /api/groups/{id}
    // ═══════════════════════════════════════════════════════════════════════

    /**
     * Mettre à jour un groupe
     * 
     * PUT /api/groups/123
     * Body: {"name": "New Name", "description": "New description"}
     */
    private function update(int $id): void
    {
        // Vérifier que le groupe existe
        $existingGroup = $this->db->findById('groups', $id);
        if (!$existingGroup) {
            Response::notFound('Groupe non trouvé');
        }

        // Récupérer les données
        $data = json_decode(file_get_contents('php://input'), true) ?? [];

        // Validation
        $validator = new Validator($data);
        $rules = [];

        if (isset($data['name'])) {
            $rules['name'] = "required|min:2|max:100|unique:groups,name,{$id}";
        }
        if (isset($data['slug'])) {
            $rules['slug'] = "required|regex:/^[a-z0-9-]+$/|unique:groups,slug,{$id}";
        }
        if (isset($data['description'])) {
            $rules['description'] = 'max:255';
        }

        if (!empty($rules) && !$validator->validate($rules)) {
            Response::validationError($validator->getErrors());
        }

        // Préparer les données à mettre à jour
        $updateData = [];

        if (isset($data['name'])) {
            $updateData['name'] = sanitizeString($data['name']);
        }
        if (isset($data['slug'])) {
            $updateData['slug'] = strtolower(trim($data['slug']));
        }
        if (isset($data['description'])) {
            $updateData['description'] = $data['description'] !== '' ? sanitizeString($data['description']) : null;
        }

        if (empty($updateData)) {
            Response::error('Aucune donnée à mettre à jour', 400);
        }

        $updateData['updated_at'] = date('Y-m-d H:i:s');
        $updateData['updated_by'] = $_SESSION['user_id'];

        try {
            // Mettre à jour
            $this->db->updateById('groups', $id, $updateData);

            Logger::info('Group updated', [
                'updater_id' => $_SESSION['user_id'],
                'group_id' => $id,
                'fields' => array_keys($updateData)
            ]);

            $this->logAudit($_SESSION['user_id'], 'group_update', "Updated group ID: {$id}", ['fields' => array_keys($updateData)]);

            // Récupérer le groupe mis à jour
            $group = $this->db->findById('groups', $id);

            Response::success([
                'group' => $group
            ], 'Groupe mis à jour avec succès');

        } catch (\Exception $e) {
            Logger::error('Group update failed', [
                'error' => $e->getMessage(),
                'group_id' => $id
            ]);
            Response::serverError('Erreur lors de la mise à jour du groupe');
        }
    }

    // ═══════════════════════════════════════════════════════════════════════
    // DELETE - DELETE /api/groups/{id}
    // ═══════════════════════════════════════════════════════════════════════

    /**
     * Supprimer un groupe
     * 
     * DELETE /api/groups/123
     */
    private function delete(int $id): void
    {
        // Vérifier que le groupe existe
        $group = $this->db->findById('groups', $id);
        if (!$group) {
            Response::notFound('Groupe non trouvé');
        }

        try {
            // Utiliser une transaction
            $this->db->transaction(function($db) use ($id, $group) {
                // Supprimer les relations user_groups
                $db->delete('user_groups', ['group_id' => $id]);

                // Supprimer les relations group_permissions
                $db->delete('group_permissions', ['group_id' => $id]);

                // Supprimer le groupe
                $db->deleteById('groups', $id);
            });

            Logger::info('Group deleted', [
                'deleter_id' => $_SESSION['user_id'],
                'group_id' => $id,
                'name' => $group['name']
            ]);

            $this->logAudit($_SESSION['user_id'], 'group_delete', "Deleted group: {$group['name']}", ['group_id' => $id]);

            Response::success(null, 'Groupe supprimé avec succès');

        } catch (\Exception $e) {
            Logger::error('Group deletion failed', [
                'error' => $e->getMessage(),
                'group_id' => $id
            ]);
            Response::serverError('Erreur lors de la suppression du groupe');
        }
    }

    // ═══════════════════════════════════════════════════════════════════════
    // ASSIGN USERS - POST /api/groups/assign
    // ═══════════════════════════════════════════════════════════════════════

    /**
     * Assigner des utilisateurs à un groupe
     * 
     * POST /api/groups/assign
     * Body: {"group_id": 1, "user_ids": [1, 2, 3]}
     */
    private function assignUsers(): void
    {
        // Récupérer les données
        $data = json_decode(file_get_contents('php://input'), true) ?? [];

        // Validation
        $validator = new Validator($data);
        if (!$validator->validate([
            'group_id' => 'required|integer|exists:groups,id',
            'user_ids' => 'required',
        ])) {
            Response::validationError($validator->getErrors());
        }

        $groupId = (int)$data['group_id'];
        $userIds = $data['user_ids'];

        // Vérifier que user_ids est un tableau
        if (!is_array($userIds) || empty($userIds)) {
            Response::error('user_ids doit être un tableau non vide', 400);
        }

        try {
            $assigned = 0;
            $skipped = 0;

            // Assigner chaque utilisateur
            foreach ($userIds as $userId) {
                $userId = (int)$userId;

                // Vérifier que l'utilisateur existe
                $user = $this->db->findById('users', $userId);
                if (!$user) {
                    $skipped++;
                    continue;
                }

                // Vérifier si déjà assigné
                $existing = $this->db->fetchOne(
                    "SELECT * FROM um_user_groups WHERE user_id = :user_id AND group_id = :group_id",
                    ['user_id' => $userId, 'group_id' => $groupId]
                );

                if ($existing) {
                    $skipped++;
                    continue;
                }

                // Assigner
                $this->db->insert('user_groups', [
                    'user_id' => $userId,
                    'group_id' => $groupId,
                    'created_at' => date('Y-m-d H:i:s'),
                ]);

                $assigned++;
            }

            Logger::info('Users assigned to group', [
                'assigner_id' => $_SESSION['user_id'],
                'group_id' => $groupId,
                'assigned' => $assigned,
                'skipped' => $skipped
            ]);

            $this->logAudit($_SESSION['user_id'], 'group_assign_users', "Assigned {$assigned} users to group ID: {$groupId}");

            Response::success([
                'assigned' => $assigned,
                'skipped' => $skipped,
                'total' => count($userIds)
            ], "Assignation terminée : {$assigned} ajoutés, {$skipped} ignorés");

        } catch (\Exception $e) {
            Logger::error('User assignment failed', [
                'error' => $e->getMessage(),
                'group_id' => $groupId
            ]);
            Response::serverError('Erreur lors de l\'assignation des utilisateurs');
        }
    }

    // ═══════════════════════════════════════════════════════════════════════
    // REMOVE USERS - POST /api/groups/remove
    // ═══════════════════════════════════════════════════════════════════════

    /**
     * Retirer des utilisateurs d'un groupe
     * 
     * POST /api/groups/remove
     * Body: {"group_id": 1, "user_ids": [1, 2, 3]}
     */
    private function removeUsers(): void
    {
        // Récupérer les données
        $data = json_decode(file_get_contents('php://input'), true) ?? [];

        // Validation
        $validator = new Validator($data);
        if (!$validator->validate([
            'group_id' => 'required|integer|exists:groups,id',
            'user_ids' => 'required',
        ])) {
            Response::validationError($validator->getErrors());
        }

        $groupId = (int)$data['group_id'];
        $userIds = $data['user_ids'];

        // Vérifier que user_ids est un tableau
        if (!is_array($userIds) || empty($userIds)) {
            Response::error('user_ids doit être un tableau non vide', 400);
        }

        try {
            $removed = 0;

            // Retirer chaque utilisateur
            foreach ($userIds as $userId) {
                $userId = (int)$userId;

                $result = $this->db->delete('user_groups', [
                    'user_id' => $userId,
                    'group_id' => $groupId
                ]);

                $removed += $result;
            }

            Logger::info('Users removed from group', [
                'remover_id' => $_SESSION['user_id'],
                'group_id' => $groupId,
                'removed' => $removed
            ]);

            $this->logAudit($_SESSION['user_id'], 'group_remove_users', "Removed {$removed} users from group ID: {$groupId}");

            Response::success([
                'removed' => $removed,
                'total' => count($userIds)
            ], "{$removed} utilisateur(s) retiré(s) du groupe");

        } catch (\Exception $e) {
            Logger::error('User removal failed', [
                'error' => $e->getMessage(),
                'group_id' => $groupId
            ]);
            Response::serverError('Erreur lors du retrait des utilisateurs');
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
 * FIN DU GROUPCONTROLLER
 * ═══════════════════════════════════════════════════════════════════════════
 */
