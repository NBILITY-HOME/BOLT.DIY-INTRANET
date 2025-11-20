<?php
/* ============================================
   Bolt.DIY User Manager - Groups API
   Version: 1.0
   Date: 19 novembre 2025
   ============================================ */

header('Content-Type: application/json');
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: GET, POST, PUT, DELETE');
header('Access-Control-Allow-Headers: Content-Type');

// Handle preflight
if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    http_response_code(200);
    exit();
}

/* ============================================
   DONNÉES SIMULÉES
   ============================================ */

// Liste des permissions disponibles
$availablePermissions = [
    ['id' => 1, 'name' => 'users.view', 'label' => 'Voir les utilisateurs', 'description' => 'Accès en lecture à la liste des utilisateurs'],
    ['id' => 2, 'name' => 'users.create', 'label' => 'Créer des utilisateurs', 'description' => 'Créer de nouveaux utilisateurs'],
    ['id' => 3, 'name' => 'users.edit', 'label' => 'Modifier les utilisateurs', 'description' => 'Modifier les informations des utilisateurs'],
    ['id' => 4, 'name' => 'users.delete', 'label' => 'Supprimer des utilisateurs', 'description' => 'Supprimer des utilisateurs du système'],
    ['id' => 5, 'name' => 'groups.view', 'label' => 'Voir les groupes', 'description' => 'Accès en lecture aux groupes'],
    ['id' => 6, 'name' => 'groups.manage', 'label' => 'Gérer les groupes', 'description' => 'Créer, modifier et supprimer des groupes'],
    ['id' => 7, 'name' => 'audit.view', 'label' => 'Voir les audits', 'description' => 'Accès aux logs d\'audit'],
    ['id' => 8, 'name' => 'settings.manage', 'label' => 'Gérer les paramètres', 'description' => 'Modifier les paramètres système'],
];

// Groupes simulés
$groups = [
    [
        'id' => 1,
        'name' => 'Administrateurs',
        'description' => 'Accès complet au système',
        'permissions' => [1, 2, 3, 4, 5, 6, 7, 8],
        'members' => [1, 2],
        'created_at' => '2025-01-15 10:00:00',
        'updated_at' => '2025-01-15 10:00:00'
    ],
    [
        'id' => 2,
        'name' => 'Managers',
        'description' => 'Gestion des utilisateurs et consultation des audits',
        'permissions' => [1, 2, 3, 5, 7],
        'members' => [3, 4],
        'created_at' => '2025-01-20 14:30:00',
        'updated_at' => '2025-01-20 14:30:00'
    ],
    [
        'id' => 3,
        'name' => 'Développeurs',
        'description' => 'Accès technique et consultation des utilisateurs',
        'permissions' => [1, 5, 7],
        'members' => [5, 6, 7],
        'created_at' => '2025-02-01 09:00:00',
        'updated_at' => '2025-02-01 09:00:00'
    ],
    [
        'id' => 4,
        'name' => 'Support',
        'description' => 'Assistance utilisateurs',
        'permissions' => [1, 3],
        'members' => [8, 9],
        'created_at' => '2025-02-10 11:15:00',
        'updated_at' => '2025-02-10 11:15:00'
    ],
    [
        'id' => 5,
        'name' => 'Invités',
        'description' => 'Accès en lecture seule',
        'permissions' => [1],
        'members' => [10],
        'created_at' => '2025-03-01 16:00:00',
        'updated_at' => '2025-03-01 16:00:00'
    ]
];

/* ============================================
   ROUTING
   ============================================ */

$method = $_SERVER['REQUEST_METHOD'];
$id = isset($_GET['id']) ? intval($_GET['id']) : null;

switch ($method) {
    case 'GET':
        handleGet($groups, $availablePermissions, $id);
        break;
    
    case 'POST':
        handlePost($groups);
        break;
    
    case 'PUT':
        handlePut($groups, $id);
        break;
    
    case 'DELETE':
        handleDelete($groups, $id);
        break;
    
    default:
        sendResponse(['success' => false, 'message' => 'Method not allowed'], 405);
}

/* ============================================
   HANDLERS
   ============================================ */

function handleGet($groups, $permissions, $id) {
    if ($id !== null) {
        // Récupérer un groupe spécifique
        $group = findGroupById($groups, $id);
        
        if ($group) {
            sendResponse([
                'success' => true,
                'group' => $group
            ]);
        } else {
            sendResponse([
                'success' => false,
                'message' => 'Groupe non trouvé'
            ], 404);
        }
    } else {
        // Récupérer tous les groupes
        sendResponse([
            'success' => true,
            'groups' => $groups,
            'permissions' => $permissions
        ]);
    }
}

function handlePost($groups) {
    $input = json_decode(file_get_contents('php://input'), true);
    
    // Validation
    $validation = validateGroupData($input);
    if (!$validation['valid']) {
        sendResponse([
            'success' => false,
            'message' => $validation['message']
        ], 400);
        return;
    }
    
    // Création du nouveau groupe
    $newGroup = [
        'id' => count($groups) + 1,
        'name' => $input['name'],
        'description' => $input['description'] ?? '',
        'permissions' => $input['permissions'] ?? [],
        'members' => $input['members'] ?? [],
        'created_at' => date('Y-m-d H:i:s'),
        'updated_at' => date('Y-m-d H:i:s')
    ];
    
    sendResponse([
        'success' => true,
        'message' => 'Groupe créé avec succès',
        'group' => $newGroup
    ], 201);
}

function handlePut($groups, $id) {
    if ($id === null) {
        sendResponse([
            'success' => false,
            'message' => 'ID du groupe requis'
        ], 400);
        return;
    }
    
    $group = findGroupById($groups, $id);
    if (!$group) {
        sendResponse([
            'success' => false,
            'message' => 'Groupe non trouvé'
        ], 404);
        return;
    }
    
    $input = json_decode(file_get_contents('php://input'), true);
    
    // Validation
    $validation = validateGroupData($input);
    if (!$validation['valid']) {
        sendResponse([
            'success' => false,
            'message' => $validation['message']
        ], 400);
        return;
    }
    
    // Mise à jour du groupe
    $updatedGroup = [
        'id' => $id,
        'name' => $input['name'],
        'description' => $input['description'] ?? '',
        'permissions' => $input['permissions'] ?? [],
        'members' => $input['members'] ?? [],
        'created_at' => $group['created_at'],
        'updated_at' => date('Y-m-d H:i:s')
    ];
    
    sendResponse([
        'success' => true,
        'message' => 'Groupe mis à jour avec succès',
        'group' => $updatedGroup
    ]);
}

function handleDelete($groups, $id) {
    if ($id === null) {
        sendResponse([
            'success' => false,
            'message' => 'ID du groupe requis'
        ], 400);
        return;
    }
    
    $group = findGroupById($groups, $id);
    if (!$group) {
        sendResponse([
            'success' => false,
            'message' => 'Groupe non trouvé'
        ], 404);
        return;
    }
    
    // Vérifier si le groupe peut être supprimé
    if (in_array($id, [1])) { // Administrateurs ne peut pas être supprimé
        sendResponse([
            'success' => false,
            'message' => 'Ce groupe système ne peut pas être supprimé'
        ], 403);
        return;
    }
    
    sendResponse([
        'success' => true,
        'message' => 'Groupe supprimé avec succès'
    ]);
}

/* ============================================
   UTILITAIRES
   ============================================ */

function findGroupById($groups, $id) {
    foreach ($groups as $group) {
        if ($group['id'] === $id) {
            return $group;
        }
    }
    return null;
}

function validateGroupData($data) {
    if (empty($data['name']) || strlen(trim($data['name'])) < 2) {
        return [
            'valid' => false,
            'message' => 'Le nom du groupe doit contenir au moins 2 caractères'
        ];
    }
    
    if (isset($data['permissions']) && !is_array($data['permissions'])) {
        return [
            'valid' => false,
            'message' => 'Les permissions doivent être un tableau'
        ];
    }
    
    if (isset($data['members']) && !is_array($data['members'])) {
        return [
            'valid' => false,
            'message' => 'Les membres doivent être un tableau'
        ];
    }
    
    return ['valid' => true];
}

function sendResponse($data, $statusCode = 200) {
    http_response_code($statusCode);
    echo json_encode($data, JSON_PRETTY_PRINT | JSON_UNESCAPED_UNICODE);
    exit();
}
