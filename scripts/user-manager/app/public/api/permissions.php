<?php
/* ============================================
   Bolt.DIY User Manager - Permissions API
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
   DONNÉES SIMULÉES - CATÉGORIES ET PERMISSIONS
   ============================================ */

$categories = [
    [
        'id' => 1,
        'name' => 'Utilisateurs',
        'description' => 'Gestion des comptes utilisateurs',
        'icon' => 'users',
        'permissions' => [
            [
                'id' => 1,
                'name' => 'Voir les utilisateurs',
                'code' => 'users.view',
                'description' => 'Accès en lecture à la liste des utilisateurs et leurs informations'
            ],
            [
                'id' => 2,
                'name' => 'Créer des utilisateurs',
                'code' => 'users.create',
                'description' => 'Créer de nouveaux comptes utilisateurs dans le système'
            ],
            [
                'id' => 3,
                'name' => 'Modifier les utilisateurs',
                'code' => 'users.edit',
                'description' => 'Modifier les informations et paramètres des utilisateurs existants'
            ],
            [
                'id' => 4,
                'name' => 'Supprimer des utilisateurs',
                'code' => 'users.delete',
                'description' => 'Supprimer définitivement des comptes utilisateurs du système'
            ],
            [
                'id' => 5,
                'name' => 'Réinitialiser les mots de passe',
                'code' => 'users.reset_password',
                'description' => 'Forcer la réinitialisation du mot de passe d\'un utilisateur'
            ]
        ]
    ],
    [
        'id' => 2,
        'name' => 'Groupes',
        'description' => 'Gestion des groupes d\'utilisateurs',
        'icon' => 'user-friends',
        'permissions' => [
            [
                'id' => 6,
                'name' => 'Voir les groupes',
                'code' => 'groups.view',
                'description' => 'Accès en lecture aux groupes et leurs membres'
            ],
            [
                'id' => 7,
                'name' => 'Créer des groupes',
                'code' => 'groups.create',
                'description' => 'Créer de nouveaux groupes d\'utilisateurs'
            ],
            [
                'id' => 8,
                'name' => 'Modifier les groupes',
                'code' => 'groups.edit',
                'description' => 'Modifier les groupes et leurs permissions'
            ],
            [
                'id' => 9,
                'name' => 'Supprimer des groupes',
                'code' => 'groups.delete',
                'description' => 'Supprimer des groupes du système'
            ],
            [
                'id' => 10,
                'name' => 'Gérer les membres',
                'code' => 'groups.manage_members',
                'description' => 'Ajouter ou retirer des utilisateurs dans les groupes'
            ]
        ]
    ],
    [
        'id' => 3,
        'name' => 'Permissions',
        'description' => 'Gestion des permissions et accès',
        'icon' => 'key',
        'permissions' => [
            [
                'id' => 11,
                'name' => 'Voir les permissions',
                'code' => 'permissions.view',
                'description' => 'Consulter la liste des permissions disponibles'
            ],
            [
                'id' => 12,
                'name' => 'Assigner des permissions',
                'code' => 'permissions.assign',
                'description' => 'Attribuer des permissions aux groupes et utilisateurs'
            ],
            [
                'id' => 13,
                'name' => 'Créer des permissions',
                'code' => 'permissions.create',
                'description' => 'Créer de nouvelles permissions personnalisées'
            ],
            [
                'id' => 14,
                'name' => 'Modifier les permissions',
                'code' => 'permissions.edit',
                'description' => 'Modifier les permissions existantes'
            ]
        ]
    ],
    [
        'id' => 4,
        'name' => 'Audit & Logs',
        'description' => 'Consultation des journaux système',
        'icon' => 'clipboard-list',
        'permissions' => [
            [
                'id' => 15,
                'name' => 'Voir les audits',
                'code' => 'audit.view',
                'description' => 'Consulter les logs d\'audit et l\'historique des actions'
            ],
            [
                'id' => 16,
                'name' => 'Exporter les audits',
                'code' => 'audit.export',
                'description' => 'Exporter les logs d\'audit au format CSV/PDF'
            ],
            [
                'id' => 17,
                'name' => 'Purger les audits',
                'code' => 'audit.purge',
                'description' => 'Supprimer les anciens logs d\'audit'
            ]
        ]
    ],
    [
        'id' => 5,
        'name' => 'Paramètres',
        'description' => 'Configuration du système',
        'icon' => 'cog',
        'permissions' => [
            [
                'id' => 18,
                'name' => 'Voir les paramètres',
                'code' => 'settings.view',
                'description' => 'Consulter les paramètres système'
            ],
            [
                'id' => 19,
                'name' => 'Modifier les paramètres',
                'code' => 'settings.edit',
                'description' => 'Modifier la configuration du système'
            ],
            [
                'id' => 20,
                'name' => 'Gérer SMTP',
                'code' => 'settings.smtp',
                'description' => 'Configurer les paramètres d\'envoi d\'emails'
            ],
            [
                'id' => 21,
                'name' => 'Gérer la sécurité',
                'code' => 'settings.security',
                'description' => 'Configurer les paramètres de sécurité avancés'
            ]
        ]
    ],
    [
        'id' => 6,
        'name' => 'Dashboard',
        'description' => 'Accès au tableau de bord',
        'icon' => 'chart-line',
        'permissions' => [
            [
                'id' => 22,
                'name' => 'Voir le dashboard',
                'code' => 'dashboard.view',
                'description' => 'Accès au tableau de bord et statistiques'
            ],
            [
                'id' => 23,
                'name' => 'Exporter les statistiques',
                'code' => 'dashboard.export',
                'description' => 'Exporter les rapports et statistiques'
            ]
        ]
    ]
];

/* ============================================
   ROUTING
   ============================================ */

$method = $_SERVER['REQUEST_METHOD'];

switch ($method) {
    case 'GET':
        handleGet($categories);
        break;
    
    case 'POST':
        handlePost($categories);
        break;
    
    default:
        sendResponse(['success' => false, 'message' => 'Method not allowed'], 405);
}

/* ============================================
   HANDLERS
   ============================================ */

function handleGet($categories) {
    sendResponse([
        'success' => true,
        'categories' => $categories,
        'total_permissions' => countTotalPermissions($categories)
    ]);
}

function handlePost($categories) {
    $input = json_decode(file_get_contents('php://input'), true);
    
    // Action: assigner une permission à un groupe
    if (isset($input['action']) && $input['action'] === 'assign') {
        $groupId = $input['group_id'] ?? null;
        $permissionId = $input['permission_id'] ?? null;
        $assign = $input['assign'] ?? true;
        
        if (!$groupId || !$permissionId) {
            sendResponse([
                'success' => false,
                'message' => 'Group ID et Permission ID requis'
            ], 400);
            return;
        }
        
        sendResponse([
            'success' => true,
            'message' => $assign ? 'Permission assignée' : 'Permission retirée'
        ]);
        return;
    }
    
    sendResponse([
        'success' => false,
        'message' => 'Action non reconnue'
    ], 400);
}

/* ============================================
   UTILITAIRES
   ============================================ */

function countTotalPermissions($categories) {
    $total = 0;
    foreach ($categories as $category) {
        $total += count($category['permissions']);
    }
    return $total;
}

function sendResponse($data, $statusCode = 200) {
    http_response_code($statusCode);
    echo json_encode($data, JSON_PRETTY_PRINT | JSON_UNESCAPED_UNICODE);
    exit();
}
