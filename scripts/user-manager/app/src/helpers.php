<?php
/**
 * Bolt.DIY User Manager - Helpers
 * Fonctions utilitaires globales
 * Version: 1.0
 * Date: 18 novembre 2025
 */

// ============================================
// HELPERS D'URLS ET ASSETS
// ============================================

/**
 * Générer une URL vers un asset
 */
function asset($path) {
    return ASSETS_URL . '/' . ltrim($path, '/');
}

/**
 * Générer une URL de l'application
 */
function url($path = '') {
    return BASE_URL . '/' . ltrim($path, '/');
}

/**
 * Générer une URL d'API
 */
function api_url($path = '') {
    return API_URL . '/' . ltrim($path, '/');
}

/**
 * Redirection vers une URL
 */
function redirect($url, $statusCode = 302) {
    header('Location: ' . $url, true, $statusCode);
    exit;
}

/**
 * Redirection vers une route de l'application
 */
function redirect_to($path = '', $statusCode = 302) {
    redirect(url($path), $statusCode);
}

// ============================================
// HELPERS DE SÉCURITÉ
// ============================================

/**
 * Générer un token CSRF
 */
function csrf_token() {
    if (!isset($_SESSION[CSRF_TOKEN_NAME])) {
        $_SESSION[CSRF_TOKEN_NAME] = bin2hex(random_bytes(32));
    }
    return $_SESSION[CSRF_TOKEN_NAME];
}

/**
 * Générer un champ de formulaire CSRF
 */
function csrf_field() {
    return '<input type="hidden" name="' . CSRF_TOKEN_NAME . '" value="' . csrf_token() . '">';
}

/**
 * Vérifier un token CSRF
 */
function verify_csrf($token) {
    if (!isset($_SESSION[CSRF_TOKEN_NAME])) {
        return false;
    }
    return hash_equals($_SESSION[CSRF_TOKEN_NAME], $token);
}

/**
 * Échapper une chaîne HTML
 */
function e($string) {
    return htmlspecialchars($string, ENT_QUOTES, 'UTF-8');
}

/**
 * Vérifier si l'utilisateur est connecté
 */
function is_logged_in() {
    return isset($_SESSION['user_id']) && !empty($_SESSION['user_id']);
}

/**
 * Obtenir l'utilisateur courant
 */
function current_user() {
    if (!is_logged_in()) {
        return null;
    }
    return [
        'id' => $_SESSION['user_id'] ?? null,
        'username' => $_SESSION['username'] ?? null,
        'email' => $_SESSION['email'] ?? null,
        'role' => $_SESSION['role'] ?? 'user',
    ];
}

/**
 * Vérifier si l'utilisateur a un rôle
 */
function has_role($role) {
    $user = current_user();
    return $user && $user['role'] === $role;
}

/**
 * Exiger une authentification
 */
function require_auth() {
    if (!is_logged_in()) {
        redirect_to('login');
    }
}

/**
 * Exiger un rôle spécifique
 */
function require_role($role) {
    require_auth();
    if (!has_role($role)) {
        http_response_code(403);
        die('Accès refusé');
    }
}

// ============================================
// HELPERS DE VUES
// ============================================

/**
 * Inclure une vue
 */
function view($template, $data = []) {
    extract($data);
    $templatePath = SRC_ROOT . '/Templates/' . $template . '.php';
    
    if (!file_exists($templatePath)) {
        die("Template introuvable : $template");
    }
    
    include $templatePath;
}

/**
 * Inclure une vue et retourner le contenu
 */
function render($template, $data = []) {
    ob_start();
    view($template, $data);
    return ob_get_clean();
}

/**
 * Inclure le layout principal
 */
function layout($template, $data = []) {
    $data['content_template'] = $template;
    view('base', $data);
}

// ============================================
// HELPERS DE NAVIGATION
// ============================================

/**
 * Vérifier si un élément de menu est actif
 */
function is_active($id) {
    global $current_page;
    return isset($current_page) && $current_page === $id;
}

/**
 * Obtenir la classe CSS active
 */
function active_class($id, $class = 'active') {
    return is_active($id) ? $class : '';
}

/**
 * Rendre le menu de navigation
 */
function render_nav_item($item) {
    $activeClass = is_active($item['id']) ? ' active' : '';
    $badge = $item['badge'] ? '<span class="nav-item-badge">' . e($item['badge']) . '</span>' : '';
    
    return sprintf(
        '<a href="%s" class="nav-item%s">
            <i class="fas %s"></i>
            <span class="nav-item-text">%s</span>
            %s
        </a>',
        e($item['url']),
        $activeClass,
        e($item['icon']),
        e($item['label']),
        $badge
    );
}

// ============================================
// HELPERS DE FORMATAGE
// ============================================

/**
 * Formater une date
 */
function format_date($date, $format = 'd/m/Y H:i') {
    if (empty($date)) {
        return '';
    }
    
    if (is_string($date)) {
        $date = new DateTime($date);
    }
    
    return $date->format($format);
}

/**
 * Formater une date relative
 */
function format_relative_date($date) {
    if (empty($date)) {
        return '';
    }
    
    if (is_string($date)) {
        $date = new DateTime($date);
    }
    
    $now = new DateTime();
    $diff = $now->diff($date);
    
    if ($diff->days == 0) {
        if ($diff->h == 0) {
            if ($diff->i == 0) {
                return "À l'instant";
            }
            return $diff->i . ' min';
        }
        return $diff->h . 'h';
    }
    
    if ($diff->days < 7) {
        return $diff->days . 'j';
    }
    
    return format_date($date, 'd/m/Y');
}

/**
 * Formater un nombre
 */
function format_number($number, $decimals = 0) {
    return number_format($number, $decimals, ',', ' ');
}

/**
 * Formater une taille de fichier
 */
function format_file_size($bytes) {
    $units = ['o', 'Ko', 'Mo', 'Go', 'To'];
    $i = 0;
    
    while ($bytes >= 1024 && $i < count($units) - 1) {
        $bytes /= 1024;
        $i++;
    }
    
    return round($bytes, 2) . ' ' . $units[$i];
}

// ============================================
// HELPERS DE VALIDATION
// ============================================

/**
 * Valider un email
 */
function is_valid_email($email) {
    return filter_var($email, FILTER_VALIDATE_EMAIL) !== false;
}

/**
 * Valider un nom d'utilisateur
 */
function is_valid_username($username) {
    return preg_match('/^[a-zA-Z0-9_-]{3,20}$/', $username) === 1;
}

/**
 * Valider un mot de passe
 */
function is_valid_password($password) {
    return strlen($password) >= PASSWORD_MIN_LENGTH;
}

// ============================================
// HELPERS DE LOGS
// ============================================

/**
 * Logger un message
 */
function log_message($message, $level = 'INFO', $file = LOG_FILE) {
    $timestamp = date('Y-m-d H:i:s');
    $logLine = "[$timestamp] [$level] $message" . PHP_EOL;
    
    if (!file_exists(dirname($file))) {
        mkdir(dirname($file), 0755, true);
    }
    
    file_put_contents($file, $logLine, FILE_APPEND | LOCK_EX);
}

/**
 * Logger une erreur
 */
function log_error($message) {
    log_message($message, 'ERROR', ERROR_LOG_FILE);
}

/**
 * Logger un audit
 */
function log_audit($action, $details = []) {
    $user = current_user();
    $logData = [
        'timestamp' => date('Y-m-d H:i:s'),
        'user' => $user ? $user['username'] : 'anonymous',
        'user_id' => $user ? $user['id'] : null,
        'ip' => $_SERVER['REMOTE_ADDR'] ?? 'unknown',
        'action' => $action,
        'details' => $details
    ];
    
    $logLine = json_encode($logData, JSON_UNESCAPED_UNICODE) . PHP_EOL;
    
    if (!file_exists(LOGS_ROOT)) {
        mkdir(LOGS_ROOT, 0755, true);
    }
    
    file_put_contents(AUDIT_LOG_FILE, $logLine, FILE_APPEND | LOCK_EX);
}

// ============================================
// HELPERS DE MESSAGES FLASH
// ============================================

/**
 * Définir un message flash
 */
function flash($key, $message) {
    if (!isset($_SESSION['flash'])) {
        $_SESSION['flash'] = [];
    }
    $_SESSION['flash'][$key] = $message;
}

/**
 * Obtenir un message flash
 */
function get_flash($key) {
    if (!isset($_SESSION['flash'][$key])) {
        return null;
    }
    
    $message = $_SESSION['flash'][$key];
    unset($_SESSION['flash'][$key]);
    
    return $message;
}

/**
 * Vérifier si un message flash existe
 */
function has_flash($key) {
    return isset($_SESSION['flash'][$key]);
}

/**
 * Message de succès
 */
function flash_success($message) {
    flash('success', $message);
}

/**
 * Message d'erreur
 */
function flash_error($message) {
    flash('error', $message);
}

/**
 * Message d'avertissement
 */
function flash_warning($message) {
    flash('warning', $message);
}

/**
 * Message d'information
 */
function flash_info($message) {
    flash('info', $message);
}

// ============================================
// HELPERS DIVERS
// ============================================

/**
 * Dumper une variable (debug)
 */
function dd(...$vars) {
    echo '<pre>';
    foreach ($vars as $var) {
        var_dump($var);
    }
    echo '</pre>';
    die();
}

/**
 * Obtenir une valeur de tableau avec valeur par défaut
 */
function array_get($array, $key, $default = null) {
    return $array[$key] ?? $default;
}

/**
 * Générer un UUID v4
 */
function generate_uuid() {
    $data = random_bytes(16);
    $data[6] = chr(ord($data[6]) & 0x0f | 0x40);
    $data[8] = chr(ord($data[8]) & 0x3f | 0x80);
    return vsprintf('%s%s-%s-%s-%s-%s%s%s', str_split(bin2hex($data), 4));
}

/**
 * Obtenir l'extension d'un fichier
 */
function get_file_extension($filename) {
    return strtolower(pathinfo($filename, PATHINFO_EXTENSION));
}

/**
 * Tronquer un texte
 */
function truncate($text, $length = 100, $suffix = '...') {
    if (mb_strlen($text) <= $length) {
        return $text;
    }
    
    return mb_substr($text, 0, $length) . $suffix;
}
