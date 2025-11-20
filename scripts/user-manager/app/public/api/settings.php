<?php
/* ============================================
   Bolt.DIY User Manager - Settings API
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
   DONNÉES SIMULÉES - PARAMÈTRES
   ============================================ */

$defaultSettings = [
    'smtp' => [
        'host' => 'smtp.example.com',
        'port' => 587,
        'username' => 'noreply@example.com',
        'password' => '',
        'encryption' => 'tls',
        'from_email' => 'noreply@example.com',
        'from_name' => 'Bolt.DIY User Manager'
    ],
    'security' => [
        'require_2fa' => false,
        'require_strong_password' => true,
        'session_timeout_enabled' => true,
        'session_timeout_minutes' => 30,
        'max_login_attempts' => 5,
        'password_min_length' => 8
    ],
    'general' => [
        'app_name' => 'Bolt.DIY User Manager',
        'app_url' => 'https://localhost/user-manager',
        'default_language' => 'fr',
        'timezone' => 'Europe/Paris'
    ]
];

/* ============================================
   ROUTING
   ============================================ */

$method = $_SERVER['REQUEST_METHOD'];
$action = $_GET['action'] ?? null;

// Special actions
if ($action) {
    handleAction($action);
    exit();
}

switch ($method) {
    case 'GET':
        handleGet($defaultSettings);
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

function handleGet($settings) {
    sendResponse([
        'success' => true,
        'settings' => $settings
    ]);
}

function handlePost() {
    $input = json_decode(file_get_contents('php://input'), true);
    
    if (!isset($input['section'])) {
        sendResponse([
            'success' => false,
            'message' => 'Section requise'
        ], 400);
        return;
    }
    
    $section = $input['section'];
    $data = $input['data'] ?? [];
    
    // Validation selon la section
    switch ($section) {
        case 'smtp':
            $validation = validateSmtpSettings($data);
            break;
        case 'security':
            $validation = validateSecuritySettings($data);
            break;
        case 'general':
            $validation = validateGeneralSettings($data);
            break;
        default:
            sendResponse([
                'success' => false,
                'message' => 'Section inconnue'
            ], 400);
            return;
    }
    
    if (!$validation['valid']) {
        sendResponse([
            'success' => false,
            'message' => $validation['message']
        ], 400);
        return;
    }
    
    // Simulation de sauvegarde réussie
    sendResponse([
        'success' => true,
        'message' => 'Paramètres enregistrés avec succès',
        'section' => $section,
        'data' => $data
    ]);
}

function handleAction($action) {
    switch ($action) {
        case 'test_smtp':
            handleTestSmtp();
            break;
        
        case 'create_backup':
            handleCreateBackup();
            break;
        
        case 'clear_cache':
            handleClearCache();
            break;
        
        case 'reset_all':
            handleResetAll();
            break;
        
        default:
            sendResponse([
                'success' => false,
                'message' => 'Action inconnue'
            ], 400);
    }
}

function handleTestSmtp() {
    $input = json_decode(file_get_contents('php://input'), true);
    
    $email = $input['email'] ?? null;
    $smtpConfig = $input['smtp_config'] ?? [];
    
    if (!$email) {
        sendResponse([
            'success' => false,
            'message' => 'Adresse email requise'
        ], 400);
        return;
    }
    
    // Validation email
    if (!filter_var($email, FILTER_VALIDATE_EMAIL)) {
        sendResponse([
            'success' => false,
            'message' => 'Adresse email invalide'
        ], 400);
        return;
    }
    
    // Simulation de test SMTP
    // En production, utiliser PHPMailer ou SwiftMailer
    
    // Simuler un succès aléatoire pour le test
    $testSuccess = rand(0, 10) > 2; // 80% de succès
    
    if ($testSuccess) {
        sendResponse([
            'success' => true,
            'message' => "Email de test envoyé avec succès à {$email}"
        ]);
    } else {
        sendResponse([
            'success' => false,
            'message' => 'Échec de la connexion SMTP. Vérifiez vos paramètres.'
        ]);
    }
}

function handleCreateBackup() {
    // Simulation de création de backup
    $backupFile = 'backup_' . date('Y-m-d_H-i-s') . '.sql';
    
    sendResponse([
        'success' => true,
        'message' => 'Sauvegarde créée avec succès',
        'backup_file' => $backupFile,
        'timestamp' => date('Y-m-d H:i:s')
    ]);
}

function handleClearCache() {
    // Simulation de vidage de cache
    sendResponse([
        'success' => true,
        'message' => 'Cache vidé avec succès',
        'cleared_items' => rand(100, 500)
    ]);
}

function handleResetAll() {
    // Simulation de réinitialisation
    sendResponse([
        'success' => true,
        'message' => 'Tous les paramètres ont été réinitialisés'
    ]);
}

/* ============================================
   VALIDATION
   ============================================ */

function validateSmtpSettings($data) {
    if (empty($data['host'])) {
        return [
            'valid' => false,
            'message' => 'L\'hôte SMTP est requis'
        ];
    }
    
    if (empty($data['port']) || !is_numeric($data['port'])) {
        return [
            'valid' => false,
            'message' => 'Le port SMTP doit être un nombre'
        ];
    }
    
    if (!empty($data['from_email']) && !filter_var($data['from_email'], FILTER_VALIDATE_EMAIL)) {
        return [
            'valid' => false,
            'message' => 'L\'adresse email d\'expédition est invalide'
        ];
    }
    
    return ['valid' => true];
}

function validateSecuritySettings($data) {
    if (isset($data['session_timeout_minutes'])) {
        $timeout = $data['session_timeout_minutes'];
        if (!is_numeric($timeout) || $timeout < 5 || $timeout > 1440) {
            return [
                'valid' => false,
                'message' => 'Le délai d\'expiration doit être entre 5 et 1440 minutes'
            ];
        }
    }
    
    if (isset($data['max_login_attempts'])) {
        $attempts = $data['max_login_attempts'];
        if (!is_numeric($attempts) || $attempts < 3 || $attempts > 10) {
            return [
                'valid' => false,
                'message' => 'Le nombre de tentatives doit être entre 3 et 10'
            ];
        }
    }
    
    if (isset($data['password_min_length'])) {
        $length = $data['password_min_length'];
        if (!is_numeric($length) || $length < 6 || $length > 32) {
            return [
                'valid' => false,
                'message' => 'La longueur minimale du mot de passe doit être entre 6 et 32 caractères'
            ];
        }
    }
    
    return ['valid' => true];
}

function validateGeneralSettings($data) {
    if (empty($data['app_name'])) {
        return [
            'valid' => false,
            'message' => 'Le nom de l\'application est requis'
        ];
    }
    
    if (!empty($data['app_url']) && !filter_var($data['app_url'], FILTER_VALIDATE_URL)) {
        return [
            'valid' => false,
            'message' => 'L\'URL de l\'application est invalide'
        ];
    }
    
    return ['valid' => true];
}

/* ============================================
   UTILITAIRES
   ============================================ */

function sendResponse($data, $statusCode = 200) {
    http_response_code($statusCode);
    echo json_encode($data, JSON_PRETTY_PRINT | JSON_UNESCAPED_UNICODE);
    exit();
}
