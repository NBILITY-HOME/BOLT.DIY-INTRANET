<?php
/* ============================================
   Bolt.DIY User Manager - Security Config
   Version: 1.0
   Date: 19 novembre 2025
   ============================================ */

return [
    
    /* ============================================
       SESSION CONFIGURATION
       ============================================ */
    'session' => [
        'name' => 'USERMGR_SESSION',
        'timeout' => 1800, // 30 minutes
        'regenerate_interval' => 1800, // 30 minutes
        'secure' => true, // HTTPS only
        'httponly' => true,
        'samesite' => 'Lax', // Lax, Strict, None
    ],
    
    /* ============================================
       PASSWORD POLICY
       ============================================ */
    'password' => [
        'min_length' => 8,
        'require_uppercase' => true,
        'require_lowercase' => true,
        'require_numbers' => true,
        'require_special' => true,
        'hash_algorithm' => PASSWORD_ARGON2ID,
        'hash_options' => [
            'memory_cost' => 65536,
            'time_cost' => 4,
            'threads' => 3
        ]
    ],
    
    /* ============================================
       RATE LIMITING
       ============================================ */
    'rate_limit' => [
        'login' => [
            'max_attempts' => 5,
            'time_window' => 900, // 15 minutes
            'lockout_duration' => 1800 // 30 minutes
        ],
        'api' => [
            'max_requests' => 60,
            'time_window' => 60 // 1 minute
        ],
        'password_reset' => [
            'max_attempts' => 3,
            'time_window' => 3600 // 1 hour
        ]
    ],
    
    /* ============================================
       CSRF PROTECTION
       ============================================ */
    'csrf' => [
        'enabled' => true,
        'token_length' => 32,
        'token_lifetime' => 3600, // 1 hour
        'regenerate_on_use' => true
    ],
    
    /* ============================================
       FILE UPLOAD SECURITY
       ============================================ */
    'upload' => [
        'max_size' => 5242880, // 5 MB
        'allowed_mime_types' => [
            'image/jpeg',
            'image/png',
            'image/gif',
            'image/webp',
            'application/pdf',
            'application/msword',
            'application/vnd.openxmlformats-officedocument.wordprocessingml.document',
            'application/vnd.ms-excel',
            'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet'
        ],
        'allowed_extensions' => [
            'jpg', 'jpeg', 'png', 'gif', 'webp',
            'pdf', 'doc', 'docx', 'xls', 'xlsx'
        ]
    ],
    
    /* ============================================
       SECURITY HEADERS
       ============================================ */
    'headers' => [
        'X-Content-Type-Options' => 'nosniff',
        'X-Frame-Options' => 'SAMEORIGIN',
        'X-XSS-Protection' => '1; mode=block',
        'Referrer-Policy' => 'strict-origin-when-cross-origin',
        'Permissions-Policy' => 'geolocation=(), microphone=(), camera=()',
        'Content-Security-Policy' => implode('; ', [
            "default-src 'self'",
            "script-src 'self' 'unsafe-inline' https://cdnjs.cloudflare.com",
            "style-src 'self' 'unsafe-inline' https://cdnjs.cloudflare.com",
            "img-src 'self' data: https:",
            "font-src 'self' https://cdnjs.cloudflare.com",
            "connect-src 'self'",
            "frame-ancestors 'self'"
        ])
    ],
    
    /* ============================================
       TWO-FACTOR AUTHENTICATION
       ============================================ */
    '2fa' => [
        'enabled' => false,
        'required' => false,
        'issuer' => 'Bolt.DIY User Manager',
        'qr_code_size' => 200,
        'backup_codes_count' => 10
    ],
    
    /* ============================================
       ENCRYPTION
       ============================================ */
    'encryption' => [
        'cipher' => 'AES-256-CBC',
        'key_length' => 32
    ],
    
    /* ============================================
       AUDIT LOGGING
       ============================================ */
    'audit' => [
        'enabled' => true,
        'log_level' => 'info', // debug, info, warning, error
        'log_sensitive_data' => false,
        'retention_days' => 90,
        'events' => [
            'user_login' => true,
            'user_logout' => true,
            'user_created' => true,
            'user_updated' => true,
            'user_deleted' => true,
            'password_changed' => true,
            'password_reset' => true,
            'permission_changed' => true,
            'settings_changed' => true,
            'failed_login' => true
        ]
    ],
    
    /* ============================================
       IP RESTRICTIONS
       ============================================ */
    'ip' => [
        'whitelist_enabled' => false,
        'whitelist' => [
            // '192.168.1.0/24',
            // '10.0.0.0/8'
        ],
        'blacklist_enabled' => false,
        'blacklist' => [
            // '1.2.3.4'
        ]
    ],
    
    /* ============================================
       REMEMBER ME
       ============================================ */
    'remember_me' => [
        'enabled' => true,
        'lifetime' => 2592000, // 30 days
        'cookie_name' => 'remember_me',
        'secure' => true,
        'httponly' => true
    ],
    
    /* ============================================
       API SECURITY
       ============================================ */
    'api' => [
        'enabled' => true,
        'require_authentication' => true,
        'token_lifetime' => 3600, // 1 hour
        'refresh_token_lifetime' => 2592000, // 30 days
        'cors_enabled' => true,
        'cors_allowed_origins' => [
            // 'https://example.com'
        ],
        'cors_allowed_methods' => ['GET', 'POST', 'PUT', 'DELETE', 'OPTIONS'],
        'cors_allowed_headers' => ['Content-Type', 'Authorization']
    ],
    
    /* ============================================
       DATABASE SECURITY
       ============================================ */
    'database' => [
        'use_prepared_statements' => true,
        'encrypt_sensitive_fields' => true,
        'sensitive_fields' => [
            'password',
            'email',
            'phone',
            'ssn',
            'credit_card'
        ]
    ],
    
    /* ============================================
       SECURITY FEATURES
       ============================================ */
    'features' => [
        'force_https' => true,
        'session_fingerprinting' => true,
        'brute_force_protection' => true,
        'sql_injection_protection' => true,
        'xss_protection' => true,
        'csrf_protection' => true,
        'clickjacking_protection' => true,
        'content_security_policy' => true
    ]
];
