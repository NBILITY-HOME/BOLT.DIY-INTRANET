<?php
/**
 * ═══════════════════════════════════════════════════════════════════════════
 * BOLT.DIY USER MANAGER v2.0 - UserController
 * © Copyright Nbility 2025 - contact@nbility.fr
 * 
 * Contrôleur de gestion des utilisateurs (CRUD complet)
 * Endpoints: /api/users (GET, POST, PUT, DELETE)
 * ═══════════════════════════════════════════════════════════════════════════
 */

declare(strict_types=1);

namespace App\Controllers;

use App\Utils\Response;
use App\Utils\Logger;
use App\Utils\Database;
use App\Utils\Validator;

/**
 * Classe UserController - Gestion des utilisateurs
 */
class UserController
{
    private Database $db;

    public function __construct()
    {
        $this->db = new Database();
        initSecureSession();
    }

    /**
     * Router principal pour les requêtes /api/users/*
     * 
     * @param string $method Méthode HTTP
     * @param string|null $id ID de l'utilisateur
     */
    public function handle(string $method, ?string $id): void
    {
        // Vérifier l'authentification pour toutes les opérations
        if (!$this->isAuthenticated()) {
            Response::unauthorized();
        }

        // Router selon la méthode HTTP
        switch ($method) {
            case 'GET':
                if ($id === null) {
                    $this->list(); // Liste des utilisateurs
                } else {
                    $this->show((int)$id); // Détails d'un utilisateur
                }
                break;

            case 'POST':
                $this->create(); // Créer un utilisateur
                break;

            case 'PUT':
                if ($id === null) {
                    Response::error('ID utilisateur requis', 400);
                }
                $this->update((int)$id); // Mettre à jour un utilisateur
                break;

            case 'DELETE':
                if ($id === null) {
                    Response::error('ID utilisateur requis', 400);
                }
                $this->delete((int)$id); // Supprimer un utilisateur
                break;

            default:
                Response::error('Méthode non autorisée', 405);
        }
    }

    // ═══════════════════════════════════════════════════════════════════════
    // LIST - GET /api/users
    // ═══════════════════════════════════════════════════════════════════════

    /**
     * Liste des utilisateurs avec pagination, recherche et filtres
     * 
     * GET /api/users?page=1&per_page=20&search=john&role=admin&status=active
     */
    private function list(): void
    {
        // Vérifier les permissions (seuls admin et superadmin)
        if (!$this->hasRole(['admin', 'superadmin'])) {
            Response::forbidden('Accès refusé');
        }

        // Paramètres de pagination
        $page = (int)($_GET['page'] ?? 1);
        $perPage = (int)($_GET['per_page'] ?? 20);

        // Limites de pagination
        $perPage = min(max($perPage, PAGINATION_CONFIG['min_per_page']), PAGINATION_CONFIG['max_per_page']);

        // Paramètres de recherche
        $search = $_GET['search'] ?? null;
        $role = $_GET['role'] ?? null;
        $status = $_GET['status'] ?? null;
        $orderBy = $_GET['order_by'] ?? 'created_at';
        $orderDir = strtoupper($_GET['order_dir'] ?? 'DESC');

        // Sécuriser ORDER BY
        $allowedOrderBy = ['id', 'username', 'email', 'first_name', 'last_name', 'role', 'status', 'created_at', 'last_login'];
        if (!in_array($orderBy, $allowedOrderBy, true)) {
            $orderBy = 'created_at';
        }

        if (!in_array($orderDir, ['ASC', 'DESC'], true)) {
            $orderDir = 'DESC';
        }

        // Construire la requête SQL
        $sql = "SELECT id, username, email, first_name, last_name, role, status, created_at, last_login, last_ip
                FROM um_users
                WHERE 1=1";

        $params = [];
        $countSql = "SELECT COUNT(*) FROM um_users WHERE 1=1";

        // Filtre de recherche
        if ($search !== null && $search !== '') {
            $searchPattern = '%' . $search . '%';
            $sql .= " AND (username LIKE :search OR email LIKE :search OR first_name LIKE :search OR last_name LIKE :search)";
            $countSql .= " AND (username LIKE :search OR email LIKE :search OR first_name LIKE :search OR last_name LIKE :search)";
            $params['search'] = $searchPattern;
        }

        // Filtre par rôle
        if ($role !== null && $role !== '') {
            $sql .= " AND role = :role";
            $countSql .= " AND role = :role";
            $params['role'] = $role;
        }

        // Filtre par statut
        if ($status !== null && $status !== '') {
            $sql .= " AND status = :status";
            $countSql .= " AND status = :status";
            $params['status'] = $status;
        }

        // Compter le total
        $total = (int)$this->db->fetchColumn($countSql, $params);

        // Pagination
        $offset = ($page - 1) * $perPage;
        $sql .= " ORDER BY {$orderBy} {$orderDir} LIMIT {$perPage} OFFSET {$offset}";

        // Récupérer les utilisateurs
        $users = $this->db->fetchAll($sql, $params);

        // Logger
        Logger::info('Users list retrieved', [
            'user_id' => $_SESSION['user_id'],
            'page' => $page,
            'total' => $total
        ]);

        // Retourner la réponse paginée
        Response::paginated($users, $total, $page, $perPage);
    }

    // ═══════════════════════════════════════════════════════════════════════
    // SHOW - GET /api/users/{id}
    // ═══════════════════════════════════════════════════════════════════════

    /**
     * Afficher les détails d'un utilisateur
     * 
     * GET /api/users/123
     */
    private function show(int $id): void
    {
        // Vérifier les permissions
        if (!$this->canAccessUser($id)) {
            Response::forbidden('Accès refusé');
        }

        // Récupérer l'utilisateur
        $user = $this->db->findById('users', $id);

        if (!$user) {
            Response::notFound('Utilisateur non trouvé');
        }

        // Retirer le mot de passe
        unset($user['password']);

        // Récupérer les groupes de l'utilisateur
        $groups = $this->db->fetchAll(
            "SELECT g.* FROM um_groups g
             INNER JOIN um_user_groups ug ON g.id = ug.group_id
             WHERE ug.user_id = :user_id",
            ['user_id' => $id]
        );

        // Récupérer les permissions
        $permissions = $this->db->fetchAll(
            "SELECT DISTINCT p.* FROM um_permissions p
             INNER JOIN um_group_permissions gp ON p.id = gp.permission_id
             INNER JOIN um_user_groups ug ON gp.group_id = ug.group_id
             WHERE ug.user_id = :user_id",
            ['user_id' => $id]
        );

        Logger::info('User details retrieved', [
            'viewer_id' => $_SESSION['user_id'],
            'target_user_id' => $id
        ]);

        Response::success([
            'user' => $user,
            'groups' => $groups,
            'permissions' => $permissions,
        ]);
    }

    // ═══════════════════════════════════════════════════════════════════════
    // CREATE - POST /api/users
    // ═══════════════════════════════════════════════════════════════════════

    /**
     * Créer un nouvel utilisateur
     * 
     * POST /api/users
     * Body: {"username": "john", "email": "john@example.com", "password": "Secret123!", "first_name": "John", "last_name": "Doe", "role": "user", "status": "active"}
     */
    private function create(): void
    {
        // Vérifier les permissions (seuls admin et superadmin)
        if (!$this->hasRole(['admin', 'superadmin'])) {
            Response::forbidden('Accès refusé');
        }

        // Récupérer les données
        $data = json_decode(file_get_contents('php://input'), true) ?? [];

        // Validation
        $validator = new Validator($data);
        if (!$validator->validate([
            'username' => 'required|username|unique:users,username',
            'email' => 'required|email|unique:users,email',
            'password' => 'required|password',
            'first_name' => 'required|min:2|max:50',
            'last_name' => 'required|min:2|max:50',
            'role' => 'required|in:superadmin,admin,user',
            'status' => 'required|in:active,inactive,suspended',
        ])) {
            Response::validationError($validator->getErrors());
        }

        // Vérifier si on peut créer un superadmin (seul superadmin peut le faire)
        if ($data['role'] === 'superadmin' && !$this->hasRole(['superadmin'])) {
            Response::forbidden('Seul un superadmin peut créer un autre superadmin');
        }

        // Préparer les données
        $userData = [
            'username' => sanitizeString($data['username']),
            'email' => strtolower(trim($data['email'])),
            'password' => hashPassword($data['password']),
            'first_name' => sanitizeString($data['first_name']),
            'last_name' => sanitizeString($data['last_name']),
            'role' => $data['role'],
            'status' => $data['status'],
            'created_at' => date('Y-m-d H:i:s'),
            'created_by' => $_SESSION['user_id'],
        ];

        try {
            // Insérer l'utilisateur
            $userId = $this->db->insert('users', $userData);

            // Logger l'événement
            Logger::info('User created', [
                'creator_id' => $_SESSION['user_id'],
                'new_user_id' => $userId,
                'username' => $userData['username']
            ]);

            $this->logAudit($_SESSION['user_id'], 'user_create', "Created user: {$userData['username']}", ['user_id' => $userId]);

            // Récupérer l'utilisateur créé
            $user = $this->db->findById('users', $userId);
            unset($user['password']);

            Response::success([
                'user' => $user
            ], 'Utilisateur créé avec succès', 201);

        } catch (\Exception $e) {
            Logger::error('User creation failed', [
                'error' => $e->getMessage(),
                'username' => $data['username']
            ]);
            Response::serverError('Erreur lors de la création de l\'utilisateur');
        }
    }

    // ═══════════════════════════════════════════════════════════════════════
    // UPDATE - PUT /api/users/{id}
    // ═══════════════════════════════════════════════════════════════════════

    /**
     * Mettre à jour un utilisateur
     * 
     * PUT /api/users/123
     * Body: {"email": "newemail@example.com", "first_name": "John", "last_name": "Doe", "role": "admin", "status": "active"}
     */
    private function update(int $id): void
    {
        // Vérifier les permissions
        if (!$this->canModifyUser($id)) {
            Response::forbidden('Accès refusé');
        }

        // Vérifier que l'utilisateur existe
        $existingUser = $this->db->findById('users', $id);
        if (!$existingUser) {
            Response::notFound('Utilisateur non trouvé');
        }

        // Récupérer les données
        $data = json_decode(file_get_contents('php://input'), true) ?? [];

        // Validation (username n'est pas modifiable, on exclut l'ID actuel pour email)
        $validator = new Validator($data);
        $rules = [];

        if (isset($data['email'])) {
            $rules['email'] = "required|email|unique:users,email,{$id}";
        }
        if (isset($data['first_name'])) {
            $rules['first_name'] = 'required|min:2|max:50';
        }
        if (isset($data['last_name'])) {
            $rules['last_name'] = 'required|min:2|max:50';
        }
        if (isset($data['role'])) {
            $rules['role'] = 'required|in:superadmin,admin,user';
        }
        if (isset($data['status'])) {
            $rules['status'] = 'required|in:active,inactive,suspended';
        }

        if (!empty($rules) && !$validator->validate($rules)) {
            Response::validationError($validator->getErrors());
        }

        // Vérifier si on modifie un superadmin (seul superadmin peut le faire)
        if ($existingUser['role'] === 'superadmin' && !$this->hasRole(['superadmin'])) {
            Response::forbidden('Seul un superadmin peut modifier un autre superadmin');
        }

        // Vérifier si on essaie de promouvoir en superadmin
        if (isset($data['role']) && $data['role'] === 'superadmin' && !$this->hasRole(['superadmin'])) {
            Response::forbidden('Seul un superadmin peut promouvoir un utilisateur en superadmin');
        }

        // Préparer les données à mettre à jour
        $updateData = [];

        if (isset($data['email'])) {
            $updateData['email'] = strtolower(trim($data['email']));
        }
        if (isset($data['first_name'])) {
            $updateData['first_name'] = sanitizeString($data['first_name']);
        }
        if (isset($data['last_name'])) {
            $updateData['last_name'] = sanitizeString($data['last_name']);
        }
        if (isset($data['role'])) {
            $updateData['role'] = $data['role'];
        }
        if (isset($data['status'])) {
            $updateData['status'] = $data['status'];
        }

        // Changement de mot de passe (optionnel)
        if (isset($data['password']) && $data['password'] !== '') {
            $passValidator = new Validator(['password' => $data['password']]);
            if (!$passValidator->validate(['password' => 'password'])) {
                Response::validationError($passValidator->getErrors());
            }
            $updateData['password'] = hashPassword($data['password']);
        }

        $updateData['updated_at'] = date('Y-m-d H:i:s');
        $updateData['updated_by'] = $_SESSION['user_id'];

        try {
            // Mettre à jour
            $this->db->updateById('users', $id, $updateData);

            Logger::info('User updated', [
                'updater_id' => $_SESSION['user_id'],
                'target_user_id' => $id,
                'fields' => array_keys($updateData)
            ]);

            $this->logAudit($_SESSION['user_id'], 'user_update', "Updated user ID: {$id}", ['fields' => array_keys($updateData)]);

            // Récupérer l'utilisateur mis à jour
            $user = $this->db->findById('users', $id);
            unset($user['password']);

            Response::success([
                'user' => $user
            ], 'Utilisateur mis à jour avec succès');

        } catch (\Exception $e) {
            Logger::error('User update failed', [
                'error' => $e->getMessage(),
                'user_id' => $id
            ]);
            Response::serverError('Erreur lors de la mise à jour de l\'utilisateur');
        }
    }

    // ═══════════════════════════════════════════════════════════════════════
    // DELETE - DELETE /api/users/{id}
    // ═══════════════════════════════════════════════════════════════════════

    /**
     * Supprimer un utilisateur
     * 
     * DELETE /api/users/123
     */
    private function delete(int $id): void
    {
        // Vérifier les permissions (seuls admin et superadmin)
        if (!$this->hasRole(['admin', 'superadmin'])) {
            Response::forbidden('Accès refusé');
        }

        // Empêcher de se supprimer soi-même
        if ($id === $_SESSION['user_id']) {
            Response::error('Vous ne pouvez pas supprimer votre propre compte', 400);
        }

        // Vérifier que l'utilisateur existe
        $user = $this->db->findById('users', $id);
        if (!$user) {
            Response::notFound('Utilisateur non trouvé');
        }

        // Vérifier si on supprime un superadmin (seul superadmin peut le faire)
        if ($user['role'] === 'superadmin' && !$this->hasRole(['superadmin'])) {
            Response::forbidden('Seul un superadmin peut supprimer un autre superadmin');
        }

        try {
            // Utiliser une transaction
            $this->db->transaction(function($db) use ($id, $user) {
                // Supprimer les relations user_groups
                $db->delete('user_groups', ['user_id' => $id]);

                // Supprimer l'utilisateur
                $db->deleteById('users', $id);
            });

            Logger::info('User deleted', [
                'deleter_id' => $_SESSION['user_id'],
                'deleted_user_id' => $id,
                'username' => $user['username']
            ]);

            $this->logAudit($_SESSION['user_id'], 'user_delete', "Deleted user: {$user['username']}", ['user_id' => $id]);

            Response::success(null, 'Utilisateur supprimé avec succès');

        } catch (\Exception $e) {
            Logger::error('User deletion failed', [
                'error' => $e->getMessage(),
                'user_id' => $id
            ]);
            Response::serverError('Erreur lors de la suppression de l\'utilisateur');
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
     * Vérifier si on peut accéder aux infos d'un utilisateur
     */
    private function canAccessUser(int $userId): bool
    {
        // Admin et superadmin peuvent voir tous les utilisateurs
        if ($this->hasRole(['admin', 'superadmin'])) {
            return true;
        }

        // Un utilisateur peut voir son propre profil
        return $userId === $_SESSION['user_id'];
    }

    /**
     * Vérifier si on peut modifier un utilisateur
     */
    private function canModifyUser(int $userId): bool
    {
        // Admin et superadmin peuvent modifier (avec restrictions sur superadmin)
        if ($this->hasRole(['admin', 'superadmin'])) {
            return true;
        }

        // Un utilisateur peut modifier son propre profil (limité)
        return $userId === $_SESSION['user_id'];
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
 * FIN DU USERCONTROLLER
 * ═══════════════════════════════════════════════════════════════════════════
 */
