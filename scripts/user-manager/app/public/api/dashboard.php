<?php
/**
 * Bolt.DIY User Manager - Dashboard API
 * Endpoint pour les données du dashboard
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
// PARAMÈTRES
// ============================================

$period = $_GET['period'] ?? '7days';

// ============================================
// GÉNÉRATION DES DONNÉES SIMULÉES
// ============================================

/**
 * Générer des statistiques
 */
function generateStats() {
    return [
        'totalUsers' => 142,
        'activeUsers' => 128,
        'totalGroups' => 8,
        'totalPermissions' => 24,
        'usersTrend' => 12,      // +12%
        'activeTrend' => 8,      // +8%
        'groupsTrend' => 0,      // 0%
        'permissionsTrend' => 0  // 0%
    ];
}

/**
 * Générer les données d'activité selon la période
 */
function generateActivityData($period) {
    switch ($period) {
        case '7days':
            return [
                'labels' => ['Lun', 'Mar', 'Mer', 'Jeu', 'Ven', 'Sam', 'Dim'],
                'data' => [45, 52, 38, 65, 42, 28, 15]
            ];
            
        case '30days':
            $labels = [];
            $data = [];
            for ($i = 29; $i >= 0; $i--) {
                $date = date('d/m', strtotime("-$i days"));
                $labels[] = $date;
                $data[] = rand(20, 70);
            }
            return [
                'labels' => $labels,
                'data' => $data
            ];
            
        case '90days':
            $labels = [];
            $data = [];
            for ($i = 89; $i >= 0; $i -= 7) {
                $date = date('d/m', strtotime("-$i days"));
                $labels[] = $date;
                $data[] = rand(100, 400);
            }
            return [
                'labels' => $labels,
                'data' => $data
            ];
            
        default:
            return [
                'labels' => ['Lun', 'Mar', 'Mer', 'Jeu', 'Ven', 'Sam', 'Dim'],
                'data' => [45, 52, 38, 65, 42, 28, 15]
            ];
    }
}

/**
 * Générer la répartition par rôle
 */
function generateRoleData() {
    return [
        'labels' => ['Admin', 'Utilisateur', 'Modérateur', 'Invité', 'Développeur'],
        'data' => [8, 95, 15, 12, 12]
    ];
}

/**
 * Générer l'activité récente
 */
function generateRecentActivity() {
    $activities = [
        [
            'type' => 'login',
            'user' => 'admin',
            'action' => 's\'est connecté',
            'time' => 'Il y a 2 min'
        ],
        [
            'type' => 'create',
            'user' => 'jdoe',
            'action' => 'a créé un nouvel utilisateur "msmith"',
            'time' => 'Il y a 15 min'
        ],
        [
            'type' => 'update',
            'user' => 'admin',
            'action' => 'a modifié les permissions du groupe "Modérateurs"',
            'time' => 'Il y a 1h'
        ],
        [
            'type' => 'delete',
            'user' => 'admin',
            'action' => 'a supprimé l\'utilisateur "testuser"',
            'time' => 'Il y a 2h'
        ],
        [
            'type' => 'settings',
            'user' => 'admin',
            'action' => 'a modifié les paramètres SMTP',
            'time' => 'Il y a 3h'
        ]
    ];

    return $activities;
}

/**
 * Générer des données supplémentaires
 */
function generateAdditionalStats() {
    return [
        'newUsersToday' => 5,
        'newUsersWeek' => 18,
        'loginCountToday' => 245,
        'loginCountWeek' => 1532,
        'systemHealth' => 'excellent',
        'diskUsage' => 45, // en %
        'memoryUsage' => 62, // en %
        'activeSessionsCount' => 38
    ];
}

// ============================================
// CONSTRUCTION DE LA RÉPONSE
// ============================================

try {
    $response = [
        'success' => true,
        'timestamp' => date('Y-m-d H:i:s'),
        'period' => $period,
        'stats' => generateStats(),
        'activity' => generateActivityData($period),
        'roles' => generateRoleData(),
        'recentActivity' => generateRecentActivity(),
        'additional' => generateAdditionalStats()
    ];

    // Logger l'accès à l'API (optionnel)
    if (function_exists('log_audit')) {
        log_audit('dashboard_api_access', [
            'period' => $period,
            'ip' => $_SERVER['REMOTE_ADDR'] ?? 'unknown'
        ]);
    }

    echo json_encode($response, JSON_UNESCAPED_UNICODE | JSON_PRETTY_PRINT);

} catch (Exception $e) {
    http_response_code(500);
    echo json_encode([
        'success' => false,
        'error' => APP_DEBUG ? $e->getMessage() : 'Erreur serveur',
        'timestamp' => date('Y-m-d H:i:s')
    ], JSON_UNESCAPED_UNICODE);

    if (function_exists('log_error')) {
        log_error('Dashboard API Error: ' . $e->getMessage());
    }
}
