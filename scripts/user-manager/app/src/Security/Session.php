<?php
/* ============================================
   Bolt.DIY User Manager - Session Class
   Version: 1.0
   Date: 19 novembre 2025
   ============================================ */

namespace App\Security;

class Session {
    
    private static $instance = null;
    private $sessionTimeout = 1800; // 30 minutes
    private $sessionName = 'USERMGR_SESSION';
    
    private function __construct() {
        $this->configureSession();
        $this->startSession();
        $this->validateSession();
    }
    
    public static function getInstance() {
        if (self::$instance === null) {
            self::$instance = new self();
        }
        return self::$instance;
    }
    
    /* ============================================
       SESSION CONFIGURATION
       ============================================ */
    
    private function configureSession() {
        // Session name
        session_name($this->sessionName);
        
        // Session cookie parameters
        $cookieParams = [
            'lifetime' => 0, // Session cookie (expires when browser closes)
            'path' => '/',
            'domain' => $_SERVER['HTTP_HOST'] ?? '',
            'secure' => isset($_SERVER['HTTPS']) && $_SERVER['HTTPS'] === 'on',
            'httponly' => true,
            'samesite' => 'Lax'
        ];
        
        session_set_cookie_params($cookieParams);
        
        // Use strict mode
        ini_set('session.use_strict_mode', 1);
        
        // Use only cookies
        ini_set('session.use_cookies', 1);
        ini_set('session.use_only_cookies', 1);
        
        // Prevent session ID in URL
        ini_set('session.use_trans_sid', 0);
        
        // Strong session ID
        ini_set('session.entropy_length', 32);
        ini_set('session.hash_function', 'sha256');
        ini_set('session.hash_bits_per_character', 5);
    }
    
    private function startSession() {
        if (session_status() === PHP_SESSION_NONE) {
            session_start();
        }
    }
    
    /* ============================================
       SESSION VALIDATION
       ============================================ */
    
    private function validateSession() {
        // Check if session is expired
        if ($this->isExpired()) {
            $this->destroy();
            return;
        }
        
        // Update last activity
        $this->updateActivity();
        
        // Regenerate session ID periodically (every 30 minutes)
        if ($this->shouldRegenerateId()) {
            $this->regenerateId();
        }
    }
    
    public function isExpired() {
        if (!isset($_SESSION['last_activity'])) {
            return false;
        }
        
        $inactiveTime = time() - $_SESSION['last_activity'];
        return $inactiveTime > $this->sessionTimeout;
    }
    
    private function updateActivity() {
        $_SESSION['last_activity'] = time();
    }
    
    private function shouldRegenerateId() {
        if (!isset($_SESSION['created_at'])) {
            $_SESSION['created_at'] = time();
            return false;
        }
        
        $age = time() - $_SESSION['created_at'];
        return $age > 1800; // 30 minutes
    }
    
    /* ============================================
       SESSION DATA MANAGEMENT
       ============================================ */
    
    public function set($key, $value) {
        $_SESSION[$key] = $value;
    }
    
    public function get($key, $default = null) {
        return $_SESSION[$key] ?? $default;
    }
    
    public function has($key) {
        return isset($_SESSION[$key]);
    }
    
    public function remove($key) {
        unset($_SESSION[$key]);
    }
    
    public function all() {
        return $_SESSION;
    }
    
    public function flash($key, $value = null) {
        if ($value === null) {
            // Get flash message
            $message = $this->get('flash_' . $key);
            $this->remove('flash_' . $key);
            return $message;
        } else {
            // Set flash message
            $this->set('flash_' . $key, $value);
        }
    }
    
    /* ============================================
       USER AUTHENTICATION
       ============================================ */
    
    public function login($userId, $userData = []) {
        // Regenerate session ID on login
        $this->regenerateId();
        
        // Store user data
        $_SESSION['user_id'] = $userId;
        $_SESSION['user_data'] = $userData;
        $_SESSION['logged_in'] = true;
        $_SESSION['login_time'] = time();
        
        // Store fingerprint
        $_SESSION['fingerprint'] = $this->generateFingerprint();
    }
    
    public function logout() {
        // Clear user data
        unset($_SESSION['user_id']);
        unset($_SESSION['user_data']);
        unset($_SESSION['logged_in']);
        unset($_SESSION['login_time']);
        
        // Destroy session
        $this->destroy();
    }
    
    public function isLoggedIn() {
        return isset($_SESSION['logged_in']) && $_SESSION['logged_in'] === true;
    }
    
    public function getUserId() {
        return $_SESSION['user_id'] ?? null;
    }
    
    public function getUserData($key = null) {
        if ($key === null) {
            return $_SESSION['user_data'] ?? [];
        }
        return $_SESSION['user_data'][$key] ?? null;
    }
    
    /* ============================================
       SESSION SECURITY
       ============================================ */
    
    public function regenerateId() {
        if (session_status() === PHP_SESSION_ACTIVE) {
            session_regenerate_id(true);
            $_SESSION['created_at'] = time();
        }
    }
    
    public function destroy() {
        $_SESSION = [];
        
        // Delete session cookie
        if (isset($_COOKIE[$this->sessionName])) {
            $params = session_get_cookie_params();
            setcookie(
                $this->sessionName,
                '',
                time() - 3600,
                $params['path'],
                $params['domain'],
                $params['secure'],
                $params['httponly']
            );
        }
        
        session_destroy();
    }
    
    private function generateFingerprint() {
        return hash('sha256', 
            ($_SERVER['HTTP_USER_AGENT'] ?? '') .
            ($_SERVER['REMOTE_ADDR'] ?? '') .
            ($_SERVER['HTTP_ACCEPT_LANGUAGE'] ?? '')
        );
    }
    
    public function validateFingerprint() {
        if (!isset($_SESSION['fingerprint'])) {
            return false;
        }
        
        $currentFingerprint = $this->generateFingerprint();
        return hash_equals($_SESSION['fingerprint'], $currentFingerprint);
    }
    
    /* ============================================
       SESSION TIMEOUT CONFIGURATION
       ============================================ */
    
    public function setTimeout($seconds) {
        $this->sessionTimeout = (int)$seconds;
    }
    
    public function getTimeout() {
        return $this->sessionTimeout;
    }
    
    public function getRemainingTime() {
        if (!isset($_SESSION['last_activity'])) {
            return $this->sessionTimeout;
        }
        
        $elapsed = time() - $_SESSION['last_activity'];
        $remaining = $this->sessionTimeout - $elapsed;
        
        return max(0, $remaining);
    }
    
    /* ============================================
       SESSION LOCKING
       ============================================ */
    
    public function lock($key, $timeout = 60) {
        $lockKey = 'lock_' . $key;
        $lockTime = time();
        
        // Check if already locked
        if (isset($_SESSION[$lockKey])) {
            $existingLock = $_SESSION[$lockKey];
            
            // Check if lock is still valid
            if (time() - $existingLock['time'] < $timeout) {
                return false;
            }
        }
        
        // Set lock
        $_SESSION[$lockKey] = [
            'time' => $lockTime,
            'timeout' => $timeout
        ];
        
        return true;
    }
    
    public function unlock($key) {
        $lockKey = 'lock_' . $key;
        unset($_SESSION[$lockKey]);
    }
    
    public function isLocked($key) {
        $lockKey = 'lock_' . $key;
        
        if (!isset($_SESSION[$lockKey])) {
            return false;
        }
        
        $lock = $_SESSION[$lockKey];
        $elapsed = time() - $lock['time'];
        
        // Lock expired
        if ($elapsed >= $lock['timeout']) {
            $this->unlock($key);
            return false;
        }
        
        return true;
    }
    
    /* ============================================
       REMEMBER ME FUNCTIONALITY
       ============================================ */
    
    public function setRememberMe($userId, $token, $days = 30) {
        $expiry = time() + ($days * 24 * 60 * 60);
        
        setcookie(
            'remember_me',
            json_encode([
                'user_id' => $userId,
                'token' => $token,
                'expiry' => $expiry
            ]),
            $expiry,
            '/',
            $_SERVER['HTTP_HOST'] ?? '',
            isset($_SERVER['HTTPS']) && $_SERVER['HTTPS'] === 'on',
            true
        );
    }
    
    public function getRememberMe() {
        if (!isset($_COOKIE['remember_me'])) {
            return null;
        }
        
        $data = json_decode($_COOKIE['remember_me'], true);
        
        if (!$data || !isset($data['user_id'], $data['token'], $data['expiry'])) {
            $this->clearRememberMe();
            return null;
        }
        
        // Check expiry
        if ($data['expiry'] < time()) {
            $this->clearRememberMe();
            return null;
        }
        
        return $data;
    }
    
    public function clearRememberMe() {
        setcookie(
            'remember_me',
            '',
            time() - 3600,
            '/',
            $_SERVER['HTTP_HOST'] ?? '',
            isset($_SERVER['HTTPS']) && $_SERVER['HTTPS'] === 'on',
            true
        );
    }
}
