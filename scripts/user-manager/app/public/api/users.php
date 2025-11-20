<?php
/**
 * Bolt.DIY User Manager - Users API
 * Endpoint CRUD pour la gestion des utilisateurs
 * Version: 1.0
 * Date: 19 novembre 2025
 */

// Démarrer la session
session_start();

// Définir la constante d'application
define('USER_MANAGER_APP', true);

// Charger la configuration
require_once __DIR__ . '/../../config/config.php';
require_once __DIR__ . '/../../src/helpers.php';

// En-têtes JSON
header('Content-Type: application/json');
header('X-Content-Type-Options: nosniff');

// Vérifier l'authentification (temporaire - sera implémenté plus tard)
// require_auth();

// ============================================
// ROUTAGE
// ============================================

$method = $_SERVER['REQUEST_METHOD'];
$userId = $_GET['id'] ?? null;

try {
    switch ($method) {
        case 'GET':
            if ($userId) {
                getUser($userId);
            } else {
                getUsers();
            }
            break;

        case 'POST':
            createUser();
            break;

        case 'PUT':
            if (!$userId) {
                throw new Exception('ID utilisateur requis');
            }
            updateUser($userId);
            break;

        case 'DELETE':
            if (!$userId) {
                throw new Exception('ID utilisateur requis');
            }
            deleteUser($userId);
            break;

        default:
            http_response_code(405);
            throw new Exception('Méthode non autorisée');
    }

} catch (Exception $e) {
    http_response_code(400);
    echo json_encode([
        'success' => false,
        'error' => $e->getMessage(),
        'timestamp' => date('Y-m-d H:i:s')
    ], JSON_UNESCAPED_UNICODE);

    if (function_exists('log_error')) {
        log_error('Users API Error: ' . $e->getMessage());
    }
}

// ============================================
// FONCTIONS CRUD
// ============================================

/**
 * Récupérer tous les utilisateurs
 */
function getUsers() {
    $users = generateUsersData();

    echo json_encode([
        'success' => true,
        'users' => $users,
        'total' => count($users),
        'timestamp' => date('Y-m-d H:i:s')
    ], JSON_UNESCAPED_UNICODE | JSON_PRETTY_PRINT);

    if (function_exists('log_audit')) {
        log_audit('users_list_viewed');
    }
}

/**
 * Récupérer un utilisateur spécifique
 */
function getUser($id) {
    $users = generateUsersData();
    $user = array_values(array_filter($users, function($u) use ($id) {
        return $u['id'] == $id;
    }))[0] ?? null;

    if (!$user) {
        http_response_code(404);
        throw new Exception('Utilisateur non trouvé');
    }

    echo json_encode([
        'success' => true,
        'user' => $user,
        'timestamp' => date('Y-m-d H:i:s')
    ], JSON_UNESCAPED_UNICODE | JSON_PRETTY_PRINT);
}

/**
 * Créer un nouvel utilisateur
 */
function createUser() {
    $input = json_decode(file_get_contents('php://input'), true);

    // Validation
    $errors = validateUserData($input);
    if (!empty($errors)) {
        throw new Exception('Données invalides: ' . implode(', ', $errors));
    }

    // Simuler la création
    $newUser = [
        'id' => rand(1000, 9999),
        'username' => $input['username'],
        'email' => $input['email'],
        'firstName' => $input['firstName'] ?? '',
        'lastName' => $input['lastName'] ?? '',
        'role' => $input['role'] ?? 'user',
        'status' => $input['status'] ?? 'active',
        'createdAt' => date('Y-m-d H:i:s'),
        'lastLogin' => null,
        'avatar' => null
    ];

    echo json_encode([
        'success' => true,
        'message' => 'Utilisateur créé avec succès',
        'user' => $newUser,
        'timestamp' => date('Y-m-d H:i:s')
    ], JSON_UNESCAPED_UNICODE | JSON_PRETTY_PRINT);

    if (function_exists('log_audit')) {
        log_audit('user_created', [
            'user_id' => $newUser['id'],
            'username' => $newUser['username']
        ]);
    }
}

/**
 * Mettre à jour un utilisateur
 */
function updateUser($id) {
    $input = json_decode(file_get_contents('php://input'), true);

    // Validation
    $errors = validateUserData($input, $id);
    if (!empty($errors)) {
        throw new Exception('Données invalides: ' . implode(', ', $errors));
    }

    // Vérifier l'existence
    $users = generateUsersData();
    $user = array_values(array_filter($users, function($u) use ($id) {
        return $u['id'] == $id;
    }))[0] ?? null;

    if (!$user) {
        http_response_code(404);
        throw new Exception('Utilisateur non trouvé');
    }

    // Simuler la mise à jour
    $updatedUser = array_merge($user, [
        'username' => $input['username'],
        'email' => $input['email'],
        'firstName' => $input['firstName'] ?? '',
        'lastName' => $input['lastName'] ?? '',
        'role' => $input['role'] ?? 'user',
        'status' => $input['status'] ?? 'active',
        'updatedAt' => date('Y-m-d H:i:s')
    ]);

    echo json_encode([
        'success' => true,
        'message' => 'Utilisateur modifié avec succès',
        'user' => $updatedUser,
        'timestamp' => date('Y-m-d H:i:s')
    ], JSON_UNESCAPED_UNICODE | JSON_PRETTY_PRINT);

    if (function_exists('log_audit')) {
        log_audit('user_updated', [
            'user_id' => $id,
            'username' => $updatedUser['username']
        ]);
    }
}

/**
 * Supprimer un utilisateur
 */
function deleteUser($id) {
    // Vérifier l'existence
    $users = generateUsersData();
    $user = array_values(array_filter($users, function($u) use ($id) {
        return $u['id'] == $id;
    }))[0] ?? null;

    if (!$user) {
        http_response_code(404);
        throw new Exception('Utilisateur non trouvé');
    }

    // Ne pas permettre la suppression de l'admin principal
    if ($user['id'] === 1) {
        http_response_code(403);
        throw new Exception('Impossible de supprimer l\'administrateur principal');
    }

    echo json_encode([
        'success' => true,
        'message' => 'Utilisateur supprimé avec succès',
        'timestamp' => date('Y-m-d H:i:s')
    ], JSON_UNESCAPED_UNICODE | JSON_PRETTY_PRINT);

    if (function_exists('log_audit')) {
        log_audit('user_deleted', [
            'user_id' => $id,
            'username' => $user['username']
        ]);
    }
}

// ============================================
// VALIDATION
// ============================================

/**
 * Valider les données utilisateur
 */
function validateUserData($data, $userId = null) {
    $errors = [];

    // Username
    if (empty($data['username'])) {
        $errors[] = 'Le nom d\'utilisateur est requis';
    } elseif (strlen($data['username']) < 3) {
        $errors[] = 'Le nom d\'utilisateur doit contenir au moins 3 caractères';
    } elseif (!preg_match('/^[a-zA-Z0-9_-]+$/', $data['username'])) {
        $errors[] = 'Le nom d\'utilisateur ne peut contenir que des lettres, chiffres, _ et -';
    }

    // Email
    if (empty($data['email'])) {
        $errors[] = 'L\'email est requis';
    } elseif (!filter_var($data['email'], FILTER_VALIDATE_EMAIL)) {
        $errors[] = 'L\'email est invalide';
    }

    // Role
    $validRoles = ['admin', 'user', 'moderator', 'guest'];
    if (isset($data['role']) && !in_array($data['role'], $validRoles)) {
        $errors[] = 'Le rôle est invalide';
    }

    // Status
    $validStatuses = ['active', 'inactive'];
    if (isset($data['status']) && !in_array($data['status'], $validStatuses)) {
        $errors[] = 'Le statut est invalide';
    }

    return $errors;
}

// ============================================
// DONNÉES SIMULÉES
// ============================================

/**
 * Générer des données utilisateurs simulées
 */
function generateUsersData() {
    return [
        [
            'id' => 1,
            'username' => 'admin',
            'email' => 'admin@bolt.diy',
            'firstName' => 'Admin',
            'lastName' => 'System',
            'role' => 'admin',
            'status' => 'active',
            'createdAt' => '2024-01-15 10:30:00',
            'lastLogin' => 'Il y a 5 min',
            'avatar' => null
        ],
        [
            'id' => 2,
            'username' => 'jdoe',
            'email' => 'john.doe@example.com',
            'firstName' => 'John',
            'lastName' => 'Doe',
            'role' => 'user',
            'status' => 'active',
            'createdAt' => '2024-02-10 14:20:00',
            'lastLogin' => 'Il y a 2h',
            'avatar' => null
        ],
        [
            'id' => 3,
            'username' => 'msmith',
            'email' => 'mary.smith@example.com',
            'firstName' => 'Mary',
            'lastName' => 'Smith',
            'role' => 'moderator',
            'status' => 'active',
            'createdAt' => '2024-03-05 09:15:00',
            'lastLogin' => 'Il y a 1 jour',
            'avatar' => null
        ],
        [
            'id' => 4,
            'username' => 'bjones',
            'email' => 'bob.jones@example.com',
            'firstName' => 'Bob',
            'lastName' => 'Jones',
            'role' => 'user',
            'status' => 'inactive',
            'createdAt' => '2024-03-20 16:45:00',
            'lastLogin' => 'Il y a 30 jours',
            'avatar' => null
        ],
        [
            'id' => 5,
            'username' => 'awilson',
            'email' => 'alice.wilson@example.com',
            'firstName' => 'Alice',
            'lastName' => 'Wilson',
            'role' => 'user',
            'status' => 'active',
            'createdAt' => '2024-04-12 11:30:00',
            'lastLogin' => 'Il y a 3h',
            'avatar' => null
        ],
        [
            'id' => 6,
            'username' => 'ctaylor',
            'email' => 'charlie.taylor@example.com',
            'firstName' => 'Charlie',
            'lastName' => 'Taylor',
            'role' => 'user',
            'status' => 'active',
            'createdAt' => '2024-05-08 13:00:00',
            'lastLogin' => 'Il y a 1 jour',
            'avatar' => null
        ],
        [
            'id' => 7,
            'username' => 'dmartin',
            'email' => 'diana.martin@example.com',
            'firstName' => 'Diana',
            'lastName' => 'Martin',
            'role' => 'guest',
            'status' => 'active',
            'createdAt' => '2024-06-15 08:45:00',
            'lastLogin' => 'Il y a 5 jours',
            'avatar' => null
        ],
        [
            'id' => 8,
            'username' => 'ethomas',
            'email' => 'edward.thomas@example.com',
            'firstName' => 'Edward',
            'lastName' => 'Thomas',
            'role' => 'user',
            'status' => 'active',
            'createdAt' => '2024-07-20 15:20:00',
            'lastLogin' => 'Il y a 12h',
            'avatar' => null
        ],
        [
            'id' => 9,
            'username' => 'fjackson',
            'email' => 'fiona.jackson@example.com',
            'firstName' => 'Fiona',
            'lastName' => 'Jackson',
            'role' => 'moderator',
            'status' => 'active',
            'createdAt' => '2024-08-10 10:00:00',
            'lastLogin' => 'Il y a 6h',
            'avatar' => null
        ],
        [
            'id' => 10,
            'username' => 'gwhite',
            'email' => 'george.white@example.com',
            'firstName' => 'George',
            'lastName' => 'White',
            'role' => 'user',
            'status' => 'inactive',
            'createdAt' => '2024-09-01 12:30:00',
            'lastLogin' => 'Il y a 60 jours',
            'avatar' => null
        ]
    ];
}
