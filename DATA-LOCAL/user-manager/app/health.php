<?php
/**
 * Health Check Endpoint
 * Vérifie que PHP et la base de données sont fonctionnels
 */

header('Content-Type: application/json');

$health = [
    'status' => 'healthy',
    'timestamp' => time(),
    'checks' => []
];

// Test PHP
$health['checks']['php'] = [
    'status' => 'ok',
    'version' => PHP_VERSION
];

// Test connexion base de données
try {
    $host = getenv('DB_HOST') ?: 'bolt-mariadb';
    $port = getenv('DB_PORT') ?: '3306';
    $dbname = getenv('DB_NAME') ?: 'bolt_usermanager';
    $user = getenv('DB_USER') ?: 'bolt_um';
    $pass = getenv('DB_PASSWORD') ?: '';

    $dsn = "mysql:host=$host;port=$port;dbname=$dbname;charset=utf8mb4";
    $pdo = new PDO($dsn, $user, $pass, [
        PDO::ATTR_ERRMODE => PDO::ERRMODE_EXCEPTION,
        PDO::ATTR_TIMEOUT => 2
    ]);

    $health['checks']['database'] = [
        'status' => 'ok',
        'host' => $host,
        'database' => $dbname
    ];
} catch (PDOException $e) {
    $health['status'] = 'degraded';
    $health['checks']['database'] = [
        'status' => 'error',
        'message' => 'Database connection failed'
    ];
}

http_response_code($health['status'] === 'healthy' ? 200 : 503);
echo json_encode($health, JSON_PRETTY_PRINT);
