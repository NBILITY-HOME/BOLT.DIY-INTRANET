<?php
/* ============================================
   Bolt.DIY User Manager - Audit API
   Version: 1.0
   Date: 19 novembre 2025
   ============================================ */

header('Content-Type: application/json');
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: GET, POST');
header('Access-Control-Allow-Headers: Content-Type');

// Handle preflight
if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    http_response_code(200);
    exit();
}

/* ============================================
   DONNÉES SIMULÉES - LOGS D'AUDIT
   ============================================ */

$auditLogs = generateAuditLogs();

/* ============================================
   ROUTING
   ============================================ */

$method = $_SERVER['REQUEST_METHOD'];

// Export handling
if (isset($_GET['export'])) {
    $format = $_GET['export'];
    handleExport($auditLogs, $format);
    exit();
}

switch ($method) {
    case 'GET':
        handleGet($auditLogs);
        break;
    
    case 'POST':
        handlePost();
        break;
    
    default:
        sendResponse(['success' => false, 'message' => 'Method not allowed'], 405);
}

/* ============================================
   HANDLERS
   ============================================ */

function handleGet($logs) {
    $stats = calculateStats($logs);
    
    sendResponse([
        'success' => true,
        'logs' => $logs,
        'stats' => $stats
    ]);
}

function handlePost() {
    $input = json_decode(file_get_contents('php://input'), true);
    
    // Create new audit log
    $newLog = [
        'id' => rand(1000, 9999),
        'timestamp' => date('Y-m-d H:i:s'),
        'user_id' => $input['user_id'] ?? 1,
        'user_name' => $input['user_name'] ?? 'Unknown User',
        'user_role' => $input['user_role'] ?? 'User',
        'action_type' => $input['action_type'] ?? 'view',
        'description' => $input['description'] ?? 'Action performed',
        'ip_address' => $_SERVER['REMOTE_ADDR'] ?? '127.0.0.1',
        'status' => $input['status'] ?? 'success',
        'changes' => $input['changes'] ?? null
    ];
    
    sendResponse([
        'success' => true,
        'message' => 'Log d\'audit créé',
        'log' => $newLog
    ], 201);
}

function handleExport($logs, $format) {
    if ($format === 'csv') {
        header('Content-Type: text/csv');
        header('Content-Disposition: attachment; filename="audit_' . date('Y-m-d') . '.csv"');
        
        $output = fopen('php://output', 'w');
        
        // Headers
        fputcsv($output, ['Timestamp', 'User', 'Role', 'Action', 'Description', 'IP Address', 'Status']);
        
        // Data
        foreach ($logs as $log) {
            fputcsv($output, [
                $log['timestamp'],
                $log['user_name'],
                $log['user_role'],
                $log['action_type'],
                $log['description'],
                $log['ip_address'],
                $log['status']
            ]);
        }
        
        fclose($output);
    } else {
        sendResponse(['success' => false, 'message' => 'Format non supporté'], 400);
    }
}

/* ============================================
   GÉNÉRATION DES LOGS
   ============================================ */

function generateAuditLogs() {
    $users = [
        ['id' => 1, 'name' => 'Jean Dupont', 'role' => 'Administrateur'],
        ['id' => 2, 'name' => 'Marie Martin', 'role' => 'Administrateur'],
        ['id' => 3, 'name' => 'Pierre Bernard', 'role' => 'Manager'],
        ['id' => 4, 'name' => 'Sophie Dubois', 'role' => 'Manager'],
        ['id' => 5, 'name' => 'Lucas Thomas', 'role' => 'Développeur'],
        ['id' => 6, 'name' => 'Emma Robert', 'role' => 'Développeur'],
        ['id' => 7, 'name' => 'Hugo Petit', 'role' => 'Développeur'],
        ['id' => 8, 'name' => 'Léa Richard', 'role' => 'Support'],
        ['id' => 9, 'name' => 'Louis Durand', 'role' => 'Support'],
        ['id' => 10, 'name' => 'Chloé Moreau', 'role' => 'Invité']
    ];
    
    $actions = [
        ['type' => 'login', 'desc' => 'Connexion à l\'application'],
        ['type' => 'logout', 'desc' => 'Déconnexion de l\'application'],
        ['type' => 'create', 'desc' => 'Création d\'un nouvel utilisateur'],
        ['type' => 'update', 'desc' => 'Modification des informations utilisateur'],
        ['type' => 'delete', 'desc' => 'Suppression d\'un utilisateur'],
        ['type' => 'view', 'desc' => 'Consultation de la liste des utilisateurs'],
        ['type' => 'create', 'desc' => 'Création d\'un nouveau groupe'],
        ['type' => 'update', 'desc' => 'Modification d\'un groupe'],
        ['type' => 'delete', 'desc' => 'Suppression d\'un groupe'],
        ['type' => 'update', 'desc' => 'Modification des permissions'],
        ['type' => 'view', 'desc' => 'Consultation des logs d\'audit'],
        ['type' => 'update', 'desc' => 'Modification des paramètres SMTP']
    ];
    
    $statuses = ['success', 'success', 'success', 'success', 'error', 'warning'];
    
    $ips = [
        '192.168.1.10',
        '192.168.1.15',
        '192.168.1.20',
        '10.0.0.5',
        '10.0.0.10',
        '172.16.0.5'
    ];
    
    $logs = [];
    $now = time();
    
    // Generate 150 logs over the last 30 days
    for ($i = 0; $i < 150; $i++) {
        $user = $users[array_rand($users)];
        $action = $actions[array_rand($actions)];
        $status = $statuses[array_rand($statuses)];
        $ip = $ips[array_rand($ips)];
        
        // Random timestamp in the last 30 days
        $timestamp = $now - rand(0, 30 * 24 * 60 * 60);
        
        $changes = null;
        if (in_array($action['type'], ['update', 'create'])) {
            $changes = generateChanges($action['type']);
        }
        
        $logs[] = [
            'id' => $i + 1,
            'timestamp' => date('Y-m-d H:i:s', $timestamp),
            'user_id' => $user['id'],
            'user_name' => $user['name'],
            'user_role' => $user['role'],
            'action_type' => $action['type'],
            'description' => $action['desc'],
            'ip_address' => $ip,
            'status' => $status,
            'changes' => $changes
        ];
    }
    
    // Sort by timestamp desc
    usort($logs, function($a, $b) {
        return strtotime($b['timestamp']) - strtotime($a['timestamp']);
    });
    
    return $logs;
}

function generateChanges($actionType) {
    $changeTypes = [
        'update' => [
            ['field' => 'email', 'old' => 'ancien@email.com', 'new' => 'nouveau@email.com'],
            ['field' => 'role', 'old' => 'Utilisateur', 'new' => 'Manager'],
            ['field' => 'statut', 'old' => 'Inactif', 'new' => 'Actif'],
            ['field' => 'nom', 'old' => 'Ancien Nom', 'new' => 'Nouveau Nom']
        ],
        'create' => [
            ['field' => 'email', 'old' => '-', 'new' => 'nouveau@email.com'],
            ['field' => 'role', 'old' => '-', 'new' => 'Utilisateur'],
            ['field' => 'statut', 'old' => '-', 'new' => 'Actif']
        ]
    ];
    
    $possibleChanges = $changeTypes[$actionType] ?? [];
    if (empty($possibleChanges)) return null;
    
    // Return 1-3 random changes
    $numChanges = rand(1, min(3, count($possibleChanges)));
    $selectedChanges = array_rand($possibleChanges, $numChanges);
    
    if (!is_array($selectedChanges)) {
        $selectedChanges = [$selectedChanges];
    }
    
    $changes = [];
    foreach ($selectedChanges as $index) {
        $change = $possibleChanges[$index];
        $changes[$change['field']] = [
            'old' => $change['old'],
            'new' => $change['new']
        ];
    }
    
    return $changes;
}

/* ============================================
   STATISTIQUES
   ============================================ */

function calculateStats($logs) {
    $today = date('Y-m-d');
    $todayEvents = 0;
    $criticalActions = 0;
    $activeUsers = [];
    
    foreach ($logs as $log) {
        $logDate = date('Y-m-d', strtotime($log['timestamp']));
        
        if ($logDate === $today) {
            $todayEvents++;
        }
        
        if (in_array($log['action_type'], ['delete', 'update']) && $log['status'] === 'success') {
            $criticalActions++;
        }
        
        if ($logDate === $today) {
            $activeUsers[$log['user_id']] = true;
        }
    }
    
    return [
        'total_events' => count($logs),
        'today_events' => $todayEvents,
        'active_users' => count($activeUsers),
        'critical_actions' => $criticalActions
    ];
}

/* ============================================
   UTILITAIRES
   ============================================ */

function sendResponse($data, $statusCode = 200) {
    http_response_code($statusCode);
    echo json_encode($data, JSON_PRETTY_PRINT | JSON_UNESCAPED_UNICODE);
    exit();
}
