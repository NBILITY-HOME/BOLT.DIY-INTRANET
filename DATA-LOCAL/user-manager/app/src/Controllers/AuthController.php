<?php
/**
 * ═══════════════════════════════════════════════════════════════════════════
 * BOLT.DIY USER MANAGER v2.0 - AuthController
 * © Copyright Nbility 2025 - contact@nbility.fr
 * 
 * Contrôleur d'authentification
 * Endpoints: /api/auth/login, /api/auth/logout, /api/auth/register, /api/auth/me
 * ═══════════════════════════════════════════════════════════════════════════
 */

declare(strict_types=1);

namespace App\Controllers;

use App\Utils\Response;
use App\Utils\Logger;
use App\Utils\Database;
use App\Utils\Validator;

/**
 * Classe AuthController - Gestion de l'authentification
 */
class AuthController
{
    private Database $db;

    public function __construct()
    {
        $this->db = new Database();

        // Initialiser les sessions sécurisées
        initSecureSession();
    }

    /**
     * Router principal pour les requêtes /api/auth/*
     * 
     * @param string $method Méthode HTTP
     * @param string|null $action Action (login, logout, me, etc.)
     */
    public function handle(string $method, ?string $action): void
    {
        // Récupérer l'action (login, logout, register, me, etc.)
        if ($action === null) {
            Response::error('Action non spécifiée', 400);
        }

        switch ($action) {
            case 'login':
                $this->login($method);
                break;

            case 'logout':
                $this->logout($method);
                break;

            case 'register':
                $this->register($method);
                break;

            case 'me':
                $this->me($method);
                break;

            case 'refresh':
                $this->refresh($method);
                break;

            case 'forgot-password':
                $this->forgotPassword($method);
                break;

            case 'reset-password':
                $this->resetPassword($method);
                break;

            case 'change-password':
                $this->changePassword($method);
                break;

            default:
                Response::notFound('Action non trouvée');
        }
    }

    // ═══════════════════════════════════════════════════════════════════════
    // LOGIN - POST /api/auth/login
    // ═══════════════════════════════════════════════════════════════════════

    /**
     * Authentifier un utilisateur
     * 
     * POST /api/auth/login
     * Body: {"username": "admin", "password": "password123"}
     */
    private function login(string $method): void
    {
        if ($method !== 'POST') {
            Response::error('Méthode non autorisée', 405);
        }

        // Récupérer les données POST
        $data = json_decode(file_get_contents('php://input'), true) ?? [];

        // Rate limiting
        $ip = $_SERVER['REMOTE_ADDR'] ?? '0.0.0.0';
        if (isRateLimited($ip, 'login')) {
            Logger::warning('Login rate limit exceeded', ['ip' => $ip]);
            Response::tooManyRequests('Trop de tentatives. Réessayez dans 15 minutes.', 900);
        }

        // Validation
        $validator = new Validator($data);
        if (!$validator->validate([
            'username' => 'required',
            'password' => 'required',
        ])) {
            Response::validationError($validator->getErrors());
        }

        $username = $data['username'];
        $password = $data['password'];

        // Chercher l'utilisateur (par username OU email)
        $user = $this->db->fetchOne(
            "SELECT * FROM um_users WHERE username = :username OR email = :username",
            ['username' => $username]
        );

        // Vérifier si l'utilisateur existe
        if (!$user) {
            recordFailedAttempt($ip, 'login');
            Logger::warning('Login failed: user not found', ['username' => $username, 'ip' => $ip]);
            Response::error('Identifiants incorrects', 401);
        }

        // Vérifier le mot de passe
        if (!verifyPassword($password, $user['password'])) {
            recordFailedAttempt($ip, 'login');
            Logger::warning('Login failed: invalid password', ['username' => $username, 'ip' => $ip]);
            Response::error('Identifiants incorrects', 401);
        }

        // Vérifier si le compte est actif
        if ($user['status'] !== 'active') {
            Logger::warning('Login failed: account inactive', ['username' => $username]);
            Response::error('Compte inactif. Contactez l\'administrateur.', 403);
        }

        // Réinitialiser le rate limit après succès
        resetRateLimit($ip, 'login');

        // Créer la session
        $_SESSION['user_id'] = $user['id'];
        $_SESSION['username'] = $user['username'];
        $_SESSION['role'] = $user['role'];
        $_SESSION['logged_in'] = true;
        $_SESSION['login_time'] = time();

        // Mettre à jour last_login
        $this->db->updateById('users', $user['id'], [
            'last_login' => date('Y-m-d H:i:s'),
            'last_ip' => $ip,
        ]);

        // Logger l'événement
        Logger::info('User logged in', [
            'user_id' => $user['id'],
            'username' => $user['username'],
            'ip' => $ip
        ]);

        // Audit log
        $this->logAudit($user['id'], 'login', 'User logged in', ['ip' => $ip]);

        // Retourner les informations utilisateur (sans le mot de passe)
        unset($user['password']);

        Response::success([
            'user' => $user,
            'session_expires' => time() + SESSION_CONFIG['lifetime'],
        ], 'Connexion réussie');
    }

    // ═══════════════════════════════════════════════════════════════════════
    // LOGOUT - POST /api/auth/logout
    // ═══════════════════════════════════════════════════════════════════════

    /**
     * Déconnecter l'utilisateur
     * 
     * POST /api/auth/logout
     */
    private function logout(string $method): void
    {
        if ($method !== 'POST') {
            Response::error('Méthode non autorisée', 405);
        }

        // Vérifier si l'utilisateur est connecté
        if (!$this->isAuthenticated()) {
            Response::error('Non authentifié', 401);
        }

        $userId = $_SESSION['user_id'] ?? null;
        $username = $_SESSION['username'] ?? null;

        // Logger l'événement
        if ($userId) {
            Logger::info('User logged out', [
                'user_id' => $userId,
                'username' => $username
            ]);

            $this->logAudit($userId, 'logout', 'User logged out');
        }

        // Détruire la session
        session_unset();
        session_destroy();

        Response::success(null, 'Déconnexion réussie');
    }

    // ═══════════════════════════════════════════════════════════════════════
    // REGISTER - POST /api/auth/register
    // ═══════════════════════════════════════════════════════════════════════

    /**
     * Créer un nouveau compte utilisateur
     * 
     * POST /api/auth/register
     * Body: {"username": "john", "email": "john@example.com", "password": "Secret123!", "password_confirmation": "Secret123!"}
     */
    private function register(string $method): void
    {
        if ($method !== 'POST') {
            Response::error('Méthode non autorisée', 405);
        }

        // Récupérer les données
        $data = json_decode(file_get_contents('php://input'), true) ?? [];

        // Validation
        $validator = new Validator($data);
        if (!$validator->validate([
            'username' => 'required|username|unique:users,username',
            'email' => 'required|email|unique:users,email',
            'password' => 'required|password|confirmed',
            'first_name' => 'required|min:2|max:50',
            'last_name' => 'required|min:2|max:50',
        ])) {
            Response::validationError($validator->getErrors());
        }

        // Préparer les données
        $userData = [
            'username' => sanitizeString($data['username']),
            'email' => strtolower(trim($data['email'])),
            'password' => hashPassword($data['password']),
            'first_name' => sanitizeString($data['first_name']),
            'last_name' => sanitizeString($data['last_name']),
            'role' => 'user', // Rôle par défaut
            'status' => 'active',
            'created_at' => date('Y-m-d H:i:s'),
        ];

        try {
            // Insérer l'utilisateur
            $userId = $this->db->insert('users', $userData);

            // Logger l'événement
            Logger::info('New user registered', [
                'user_id' => $userId,
                'username' => $userData['username']
            ]);

            $this->logAudit($userId, 'register', 'User registered');

            // Récupérer l'utilisateur créé
            $user = $this->db->findById('users', $userId);
            unset($user['password']);

            Response::success([
                'user' => $user
            ], 'Compte créé avec succès', 201);

        } catch (\Exception $e) {
            Logger::error('Registration failed', [
                'error' => $e->getMessage(),
                'username' => $data['username']
            ]);
            Response::serverError('Erreur lors de la création du compte');
        }
    }

    // ═══════════════════════════════════════════════════════════════════════
    // ME - GET /api/auth/me
    // ═══════════════════════════════════════════════════════════════════════

    /**
     * Obtenir les informations de l'utilisateur connecté
     * 
     * GET /api/auth/me
     */
    private function me(string $method): void
    {
        if ($method !== 'GET') {
            Response::error('Méthode non autorisée', 405);
        }

        // Vérifier l'authentification
        if (!$this->isAuthenticated()) {
            Response::unauthorized();
        }

        $userId = $_SESSION['user_id'];

        // Récupérer l'utilisateur
        $user = $this->db->findById('users', $userId);

        if (!$user) {
            Response::error('Utilisateur non trouvé', 404);
        }

        // Retirer le mot de passe
        unset($user['password']);

        // Récupérer les groupes de l'utilisateur
        $groups = $this->db->fetchAll(
            "SELECT g.* FROM um_groups g
             INNER JOIN um_user_groups ug ON g.id = ug.group_id
             WHERE ug.user_id = :user_id",
            ['user_id' => $userId]
        );

        Response::success([
            'user' => $user,
            'groups' => $groups,
            'session_expires' => $_SESSION['login_time'] + SESSION_CONFIG['lifetime'],
        ]);
    }

    // ═══════════════════════════════════════════════════════════════════════
    // REFRESH - POST /api/auth/refresh
    // ═══════════════════════════════════════════════════════════════════════

    /**
     * Rafraîchir la session
     * 
     * POST /api/auth/refresh
     */
    private function refresh(string $method): void
    {
        if ($method !== 'POST') {
            Response::error('Méthode non autorisée', 405);
        }

        if (!$this->isAuthenticated()) {
            Response::unauthorized();
        }

        // Régénérer l'ID de session
        session_regenerate_id(true);
        $_SESSION['last_regeneration'] = time();

        Response::success([
            'session_expires' => time() + SESSION_CONFIG['lifetime']
        ], 'Session rafraîchie');
    }

    // ═══════════════════════════════════════════════════════════════════════
    // CHANGE PASSWORD - POST /api/auth/change-password
    // ═══════════════════════════════════════════════════════════════════════

    /**
     * Changer le mot de passe de l'utilisateur connecté
     * 
     * POST /api/auth/change-password
     * Body: {"current_password": "old", "password": "new", "password_confirmation": "new"}
     */
    private function changePassword(string $method): void
    {
        if ($method !== 'POST') {
            Response::error('Méthode non autorisée', 405);
        }

        if (!$this->isAuthenticated()) {
            Response::unauthorized();
        }

        $data = json_decode(file_get_contents('php://input'), true) ?? [];
        $userId = $_SESSION['user_id'];

        // Validation
        $validator = new Validator($data);
        if (!$validator->validate([
            'current_password' => 'required',
            'password' => 'required|password|confirmed',
        ])) {
            Response::validationError($validator->getErrors());
        }

        // Récupérer l'utilisateur
        $user = $this->db->findById('users', $userId);

        // Vérifier le mot de passe actuel
        if (!verifyPassword($data['current_password'], $user['password'])) {
            Response::error('Mot de passe actuel incorrect', 400);
        }

        // Mettre à jour le mot de passe
        $this->db->updateById('users', $userId, [
            'password' => hashPassword($data['password']),
            'updated_at' => date('Y-m-d H:i:s'),
        ]);

        Logger::info('Password changed', ['user_id' => $userId]);
        $this->logAudit($userId, 'password_change', 'Password changed');

        Response::success(null, 'Mot de passe modifié avec succès');
    }

    // ═══════════════════════════════════════════════════════════════════════
    // FORGOT PASSWORD - POST /api/auth/forgot-password
    // ═══════════════════════════════════════════════════════════════════════

    /**
     * Demander une réinitialisation de mot de passe
     * 
     * POST /api/auth/forgot-password
     * Body: {"email": "user@example.com"}
     */
    private function forgotPassword(string $method): void
    {
        if ($method !== 'POST') {
            Response::error('Méthode non autorisée', 405);
        }

        $data = json_decode(file_get_contents('php://input'), true) ?? [];

        // Validation
        $validator = new Validator($data);
        if (!$validator->validate(['email' => 'required|email'])) {
            Response::validationError($validator->getErrors());
        }

        $email = strtolower(trim($data['email']));

        // Chercher l'utilisateur
        $user = $this->db->fetchOne(
            "SELECT * FROM um_users WHERE email = :email",
            ['email' => $email]
        );

        // Toujours retourner un succès (sécurité)
        if (!$user) {
            Logger::info('Forgot password: email not found', ['email' => $email]);
            Response::success(null, 'Si cet email existe, un lien de réinitialisation a été envoyé.');
        }

        // Générer un token
        $token = bin2hex(random_bytes(32));
        $expiresAt = date('Y-m-d H:i:s', time() + 3600); // 1 heure

        // Stocker le token
        $this->db->insert('password_resets', [
            'user_id' => $user['id'],
            'token' => $token,
            'expires_at' => $expiresAt,
            'created_at' => date('Y-m-d H:i:s'),
        ]);

        Logger::info('Password reset requested', ['user_id' => $user['id']]);

        // TODO: Envoyer un email avec le lien
        // $resetLink = APP_CONFIG['url'] . "/reset-password?token=" . $token;

        Response::success(null, 'Si cet email existe, un lien de réinitialisation a été envoyé.');
    }

    /**
     * Réinitialiser le mot de passe avec un token
     * 
     * POST /api/auth/reset-password
     * Body: {"token": "abc123", "password": "new", "password_confirmation": "new"}
     */
    private function resetPassword(string $method): void
    {
        if ($method !== 'POST') {
            Response::error('Méthode non autorisée', 405);
        }

        $data = json_decode(file_get_contents('php://input'), true) ?? [];

        // Validation
        $validator = new Validator($data);
        if (!$validator->validate([
            'token' => 'required',
            'password' => 'required|password|confirmed',
        ])) {
            Response::validationError($validator->getErrors());
        }

        // Vérifier le token
        $reset = $this->db->fetchOne(
            "SELECT * FROM um_password_resets 
             WHERE token = :token 
             AND expires_at > NOW() 
             AND used_at IS NULL",
            ['token' => $data['token']]
        );

        if (!$reset) {
            Response::error('Token invalide ou expiré', 400);
        }

        // Mettre à jour le mot de passe
        $this->db->updateById('users', $reset['user_id'], [
            'password' => hashPassword($data['password']),
            'updated_at' => date('Y-m-d H:i:s'),
        ]);

        // Marquer le token comme utilisé
        $this->db->update('password_resets', 
            ['used_at' => date('Y-m-d H:i:s')],
            ['id' => $reset['id']]
        );

        Logger::info('Password reset completed', ['user_id' => $reset['user_id']]);

        Response::success(null, 'Mot de passe réinitialisé avec succès');
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
 * FIN DU AUTHCONTROLLER
 * ═══════════════════════════════════════════════════════════════════════════
 */
