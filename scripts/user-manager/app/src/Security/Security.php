<?php
/* ============================================
   Bolt.DIY User Manager - Security Class
   Version: 1.0
   Date: 19 novembre 2025
   ============================================ */

namespace App\Security;

class Security {
    
    private static $instance = null;
    private $csrfTokens = [];
    
    private function __construct() {
        if (session_status() === PHP_SESSION_NONE) {
            session_start();
        }
        
        if (!isset($_SESSION['csrf_tokens'])) {
            $_SESSION['csrf_tokens'] = [];
        }
        
        $this->csrfTokens = &$_SESSION['csrf_tokens'];
    }
    
    public static function getInstance() {
        if (self::$instance === null) {
            self::$instance = new self();
        }
        return self::$instance;
    }
    
    /* ============================================
       CSRF TOKEN MANAGEMENT
       ============================================ */
    
    public function generateCsrfToken($formName = 'default') {
        $token = bin2hex(random_bytes(32));
        $this->csrfTokens[$formName] = [
            'token' => $token,
            'expires' => time() + 3600 // 1 hour
        ];
        return $token;
    }
    
    public function getCsrfToken($formName = 'default') {
        if (!isset($this->csrfTokens[$formName])) {
            return $this->generateCsrfToken($formName);
        }
        
        // Check if token is expired
        if ($this->csrfTokens[$formName]['expires'] < time()) {
            return $this->generateCsrfToken($formName);
        }
        
        return $this->csrfTokens[$formName]['token'];
    }
    
    public function validateCsrfToken($token, $formName = 'default') {
        if (!isset($this->csrfTokens[$formName])) {
            return false;
        }
        
        $storedToken = $this->csrfTokens[$formName];
        
        // Check expiration
        if ($storedToken['expires'] < time()) {
            unset($this->csrfTokens[$formName]);
            return false;
        }
        
        // Compare tokens
        if (!hash_equals($storedToken['token'], $token)) {
            return false;
        }
        
        // Token is valid, remove it (one-time use)
        unset($this->csrfTokens[$formName]);
        return true;
    }
    
    public function getCsrfField($formName = 'default') {
        $token = $this->getCsrfToken($formName);
        return sprintf(
            '<input type="hidden" name="csrf_token" value="%s">',
            htmlspecialchars($token, ENT_QUOTES, 'UTF-8')
        );
    }
    
    /* ============================================
       INPUT SANITIZATION
       ============================================ */
    
    public function sanitizeString($input) {
        return htmlspecialchars(strip_tags(trim($input)), ENT_QUOTES, 'UTF-8');
    }
    
    public function sanitizeEmail($email) {
        return filter_var(trim($email), FILTER_SANITIZE_EMAIL);
    }
    
    public function sanitizeUrl($url) {
        return filter_var(trim($url), FILTER_SANITIZE_URL);
    }
    
    public function sanitizeInt($input) {
        return filter_var($input, FILTER_SANITIZE_NUMBER_INT);
    }
    
    public function sanitizeArray($array) {
        $sanitized = [];
        foreach ($array as $key => $value) {
            if (is_array($value)) {
                $sanitized[$key] = $this->sanitizeArray($value);
            } else {
                $sanitized[$key] = $this->sanitizeString($value);
            }
        }
        return $sanitized;
    }
    
    /* ============================================
       VALIDATION
       ============================================ */
    
    public function validateEmail($email) {
        return filter_var($email, FILTER_VALIDATE_EMAIL) !== false;
    }
    
    public function validateUrl($url) {
        return filter_var($url, FILTER_VALIDATE_URL) !== false;
    }
    
    public function validatePassword($password, $minLength = 8) {
        if (strlen($password) < $minLength) {
            return false;
        }
        return true;
    }
    
    public function validateStrongPassword($password) {
        // At least 8 characters, 1 uppercase, 1 lowercase, 1 number, 1 special char
        $pattern = '/^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)(?=.*[@$!%*?&])[A-Za-z\d@$!%*?&]{8,}$/';
        return preg_match($pattern, $password) === 1;
    }
    
    /* ============================================
       PASSWORD HASHING
       ============================================ */
    
    public function hashPassword($password) {
        return password_hash($password, PASSWORD_ARGON2ID, [
            'memory_cost' => 65536,
            'time_cost' => 4,
            'threads' => 3
        ]);
    }
    
    public function verifyPassword($password, $hash) {
        return password_verify($password, $hash);
    }
    
    public function needsRehash($hash) {
        return password_needs_rehash($hash, PASSWORD_ARGON2ID, [
            'memory_cost' => 65536,
            'time_cost' => 4,
            'threads' => 3
        ]);
    }
    
    /* ============================================
       XSS PROTECTION
       ============================================ */
    
    public function escapeHtml($text) {
        return htmlspecialchars($text, ENT_QUOTES | ENT_HTML5, 'UTF-8');
    }
    
    public function escapeJs($text) {
        return json_encode($text, JSON_HEX_TAG | JSON_HEX_AMP | JSON_HEX_APOS | JSON_HEX_QUOT);
    }
    
    public function escapeUrl($url) {
        return rawurlencode($url);
    }
    
    /* ============================================
       SQL INJECTION PROTECTION
       ============================================ */
    
    public function prepareSqlString($pdo, $value) {
        return $pdo->quote($value);
    }
    
    /* ============================================
       RATE LIMITING
       ============================================ */
    
    public function checkRateLimit($identifier, $maxAttempts = 5, $timeWindow = 900) {
        $key = 'rate_limit_' . md5($identifier);
        
        if (!isset($_SESSION[$key])) {
            $_SESSION[$key] = [
                'attempts' => 0,
                'first_attempt' => time()
            ];
        }
        
        $rateLimit = $_SESSION[$key];
        
        // Reset if time window has passed
        if (time() - $rateLimit['first_attempt'] > $timeWindow) {
            $_SESSION[$key] = [
                'attempts' => 1,
                'first_attempt' => time()
            ];
            return true;
        }
        
        // Check if limit exceeded
        if ($rateLimit['attempts'] >= $maxAttempts) {
            return false;
        }
        
        // Increment attempts
        $_SESSION[$key]['attempts']++;
        return true;
    }
    
    public function getRemainingAttempts($identifier, $maxAttempts = 5) {
        $key = 'rate_limit_' . md5($identifier);
        
        if (!isset($_SESSION[$key])) {
            return $maxAttempts;
        }
        
        $remaining = $maxAttempts - $_SESSION[$key]['attempts'];
        return max(0, $remaining);
    }
    
    public function resetRateLimit($identifier) {
        $key = 'rate_limit_' . md5($identifier);
        unset($_SESSION[$key]);
    }
    
    /* ============================================
       HEADERS SECURITY
       ============================================ */
    
    public function setSecurityHeaders() {
        // Prevent MIME type sniffing
        header('X-Content-Type-Options: nosniff');
        
        // Enable XSS filtering
        header('X-XSS-Protection: 1; mode=block');
        
        // Prevent clickjacking
        header('X-Frame-Options: SAMEORIGIN');
        
        // Content Security Policy
        header("Content-Security-Policy: default-src 'self'; script-src 'self' 'unsafe-inline' https://cdnjs.cloudflare.com; style-src 'self' 'unsafe-inline' https://cdnjs.cloudflare.com; img-src 'self' data: https:; font-src 'self' https://cdnjs.cloudflare.com;");
        
        // Referrer Policy
        header('Referrer-Policy: strict-origin-when-cross-origin');
        
        // Permissions Policy
        header('Permissions-Policy: geolocation=(), microphone=(), camera=()');
        
        // Force HTTPS (if on HTTPS)
        if (isset($_SERVER['HTTPS']) && $_SERVER['HTTPS'] === 'on') {
            header('Strict-Transport-Security: max-age=31536000; includeSubDomains');
        }
    }
    
    /* ============================================
       FILE UPLOAD SECURITY
       ============================================ */
    
    public function validateFileUpload($file, $allowedTypes = [], $maxSize = 5242880) {
        // Check if file was uploaded
        if (!isset($file['error']) || is_array($file['error'])) {
            return ['valid' => false, 'message' => 'Invalid file upload'];
        }
        
        // Check for errors
        if ($file['error'] !== UPLOAD_ERR_OK) {
            return ['valid' => false, 'message' => 'File upload error: ' . $file['error']];
        }
        
        // Check file size
        if ($file['size'] > $maxSize) {
            return ['valid' => false, 'message' => 'File too large'];
        }
        
        // Check file type
        $finfo = finfo_open(FILEINFO_MIME_TYPE);
        $mimeType = finfo_file($finfo, $file['tmp_name']);
        finfo_close($finfo);
        
        if (!empty($allowedTypes) && !in_array($mimeType, $allowedTypes)) {
            return ['valid' => false, 'message' => 'Invalid file type'];
        }
        
        // Check if it's a real uploaded file
        if (!is_uploaded_file($file['tmp_name'])) {
            return ['valid' => false, 'message' => 'Not an uploaded file'];
        }
        
        return ['valid' => true, 'mime_type' => $mimeType];
    }
    
    public function generateSecureFilename($originalFilename) {
        $extension = pathinfo($originalFilename, PATHINFO_EXTENSION);
        $basename = pathinfo($originalFilename, PATHINFO_FILENAME);
        $basename = preg_replace('/[^a-zA-Z0-9_-]/', '', $basename);
        $randomString = bin2hex(random_bytes(8));
        return $basename . '_' . $randomString . '.' . $extension;
    }
    
    /* ============================================
       SESSION SECURITY
       ============================================ */
    
    public function regenerateSessionId() {
        if (session_status() === PHP_SESSION_ACTIVE) {
            session_regenerate_id(true);
        }
    }
    
    public function destroySession() {
        $_SESSION = [];
        
        if (isset($_COOKIE[session_name()])) {
            setcookie(session_name(), '', time() - 3600, '/');
        }
        
        session_destroy();
    }
    
    /* ============================================
       IP & USER AGENT VALIDATION
       ============================================ */
    
    public function getClientIp() {
        $ip = $_SERVER['REMOTE_ADDR'] ?? '0.0.0.0';
        
        // Check for proxy headers (be cautious with these)
        if (isset($_SERVER['HTTP_X_FORWARDED_FOR'])) {
            $ips = explode(',', $_SERVER['HTTP_X_FORWARDED_FOR']);
            $ip = trim($ips[0]);
        } elseif (isset($_SERVER['HTTP_CLIENT_IP'])) {
            $ip = $_SERVER['HTTP_CLIENT_IP'];
        }
        
        return filter_var($ip, FILTER_VALIDATE_IP) ? $ip : '0.0.0.0';
    }
    
    public function getUserAgent() {
        return $_SERVER['HTTP_USER_AGENT'] ?? 'Unknown';
    }
    
    public function validateSessionFingerprint() {
        $fingerprint = md5(
            $this->getUserAgent() . 
            $this->getClientIp()
        );
        
        if (!isset($_SESSION['fingerprint'])) {
            $_SESSION['fingerprint'] = $fingerprint;
            return true;
        }
        
        return $_SESSION['fingerprint'] === $fingerprint;
    }
}
