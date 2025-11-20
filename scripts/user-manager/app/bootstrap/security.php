<?php
/* ============================================
   Bolt.DIY User Manager - Security Bootstrap
   Version: 1.0
   Date: 19 novembre 2025
   ============================================ */

// Load security configuration
$securityConfig = require_once __DIR__ . '/../config/security.php';

// Autoload security classes (simple autoloader)
spl_autoload_register(function ($class) {
    $prefix = 'App\\Security\\';
    $baseDir = __DIR__ . '/../src/Security/';
    
    $len = strlen($prefix);
    if (strncmp($prefix, $class, $len) !== 0) {
        return;
    }
    
    $relativeClass = substr($class, $len);
    $file = $baseDir . str_replace('\\', '/', $relativeClass) . '.php';
    
    if (file_exists($file)) {
        require $file;
    }
});

use App\Security\Security;
use App\Security\Session;

/* ============================================
   INITIALIZE SECURITY
   ============================================ */

// Get security instance
$security = Security::getInstance();

// Set security headers
if ($securityConfig['features']['content_security_policy']) {
    $security->setSecurityHeaders();
}

// Force HTTPS
if ($securityConfig['features']['force_https'] && 
    (!isset($_SERVER['HTTPS']) || $_SERVER['HTTPS'] !== 'on')) {
    $redirectUrl = 'https://' . $_SERVER['HTTP_HOST'] . $_SERVER['REQUEST_URI'];
    header('Location: ' . $redirectUrl, true, 301);
    exit;
}

/* ============================================
   INITIALIZE SESSION
   ============================================ */

$session = Session::getInstance();

// Configure session timeout
$session->setTimeout($securityConfig['session']['timeout']);

// Validate session fingerprint
if ($securityConfig['features']['session_fingerprinting'] && 
    $session->isLoggedIn() && 
    !$session->validateFingerprint()) {
    $session->logout();
    header('Location: /user-manager/login?error=session_invalid');
    exit;
}

/* ============================================
   CSRF PROTECTION
   ============================================ */

if ($securityConfig['csrf']['enabled'] && $_SERVER['REQUEST_METHOD'] === 'POST') {
    // Check if it's an API request (skip CSRF for API with token auth)
    $isApiRequest = strpos($_SERVER['REQUEST_URI'], '/api/') !== false;
    
    if (!$isApiRequest) {
        $csrfToken = $_POST['csrf_token'] ?? $_SERVER['HTTP_X_CSRF_TOKEN'] ?? null;
        
        if (!$csrfToken || !$security->validateCsrfToken($csrfToken)) {
            http_response_code(403);
            die(json_encode([
                'success' => false,
                'message' => 'CSRF token validation failed'
            ]));
        }
    }
}

/* ============================================
   RATE LIMITING
   ============================================ */

if ($securityConfig['features']['brute_force_protection']) {
    $requestUri = $_SERVER['REQUEST_URI'];
    $clientIp = $security->getClientIp();
    
    // Check rate limit for login attempts
    if (strpos($requestUri, '/login') !== false && $_SERVER['REQUEST_METHOD'] === 'POST') {
        $maxAttempts = $securityConfig['rate_limit']['login']['max_attempts'];
        $timeWindow = $securityConfig['rate_limit']['login']['time_window'];
        
        if (!$security->checkRateLimit('login_' . $clientIp, $maxAttempts, $timeWindow)) {
            http_response_code(429);
            die(json_encode([
                'success' => false,
                'message' => 'Too many login attempts. Please try again later.'
            ]));
        }
    }
    
    // Check rate limit for API requests
    if (strpos($requestUri, '/api/') !== false) {
        $maxRequests = $securityConfig['rate_limit']['api']['max_requests'];
        $timeWindow = $securityConfig['rate_limit']['api']['time_window'];
        
        if (!$security->checkRateLimit('api_' . $clientIp, $maxRequests, $timeWindow)) {
            http_response_code(429);
            die(json_encode([
                'success' => false,
                'message' => 'Rate limit exceeded. Please try again later.'
            ]));
        }
    }
}

/* ============================================
   IP RESTRICTIONS
   ============================================ */

$clientIp = $security->getClientIp();

// Check IP whitelist
if ($securityConfig['ip']['whitelist_enabled'] && !empty($securityConfig['ip']['whitelist'])) {
    $allowed = false;
    
    foreach ($securityConfig['ip']['whitelist'] as $allowedIp) {
        if (strpos($allowedIp, '/') !== false) {
            // CIDR notation
            if (ipInRange($clientIp, $allowedIp)) {
                $allowed = true;
                break;
            }
        } else {
            // Exact match
            if ($clientIp === $allowedIp) {
                $allowed = true;
                break;
            }
        }
    }
    
    if (!$allowed) {
        http_response_code(403);
        die('Access denied: IP not whitelisted');
    }
}

// Check IP blacklist
if ($securityConfig['ip']['blacklist_enabled'] && !empty($securityConfig['ip']['blacklist'])) {
    if (in_array($clientIp, $securityConfig['ip']['blacklist'])) {
        http_response_code(403);
        die('Access denied: IP blacklisted');
    }
}

/* ============================================
   HELPER FUNCTIONS
   ============================================ */

function ipInRange($ip, $range) {
    list($subnet, $bits) = explode('/', $range);
    
    $ip = ip2long($ip);
    $subnet = ip2long($subnet);
    $mask = -1 << (32 - $bits);
    $subnet &= $mask;
    
    return ($ip & $mask) == $subnet;
}

/* ============================================
   MAKE SECURITY AVAILABLE GLOBALLY
   ============================================ */

// Store in global scope for easy access
$GLOBALS['security'] = $security;
$GLOBALS['session'] = $session;

// Helper functions for templates
function csrf_field() {
    return $GLOBALS['security']->getCsrfField();
}

function csrf_token() {
    return $GLOBALS['security']->getCsrfToken();
}

function old($key, $default = '') {
    return $_SESSION['old_input'][$key] ?? $default;
}

function errors($key = null) {
    if ($key === null) {
        return $_SESSION['errors'] ?? [];
    }
    return $_SESSION['errors'][$key] ?? null;
}

function auth() {
    return $GLOBALS['session'];
}

function user() {
    return $GLOBALS['session']->getUserData();
}

function isLoggedIn() {
    return $GLOBALS['session']->isLoggedIn();
}

// Clear old input and errors after use
if (isset($_SESSION['old_input'])) {
    unset($_SESSION['old_input']);
}

if (isset($_SESSION['errors'])) {
    unset($_SESSION['errors']);
}
