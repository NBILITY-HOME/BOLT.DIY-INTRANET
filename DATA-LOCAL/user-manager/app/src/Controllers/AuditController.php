<?php
/**
 * ═══════════════════════════════════════════════════════════════════════════
 * BOLT.DIY USER MANAGER v2.0 - AuditController
 * © Copyright Nbility 2025 - contact@nbility.fr
 * 
 * Contrôleur de consultation des logs d'audit
 * Endpoints: /api/audit (GET)
 * ═══════════════════════════════════════════════════════════════════════════
 */

declare(strict_types=1);

namespace App\Controllers;

use App\Utils\Response;
use App\Utils\Logger;
use App\Utils\Database;

/**
 * Classe AuditController - Consultation des logs d'audit
 */
class AuditController
{
    private Database $db;

    public function __construct()
    {
        $this->db = new Database();
        initSecureSession();
    }

    /**
     * Router principal pour les requêtes /api/audit/*
     * 
     * @param string $method Méthode HTTP
     * @param string|null $id ID du log ou action
     */
    public function handle(string $method, ?string $id): void
    {
        // Vérifier l'authentification
        if (!$this->isAuthenticated()) {
            Response::unauthorized();
        }

        // Vérifier les permissions (seuls admin et superadmin)
        if (!$this->hasRole(['admin', 'superadmin'])) {
            Response::forbidden('Accès refusé');
        }

        // Router selon la méthode HTTP
        switch ($method) {
            case 'GET':
                if ($id === null) {
                    $this->list(); // Liste des logs
                } elseif ($id === 'stats') {
                    $this->stats(); // Statistiques
                } else {
                    $this->show((int)$id); // Détails d'un log
                }
                break;

            default:
                Response::error('Méthode non autorisée', 405);
        }
    }

    // ═══════════════════════════════════════════════════════════════════════
    // LIST - GET /api/audit
    // ═══════════════════════════════════════════════════════════════════════

    /**
     * Liste des logs d'audit avec filtres
     * 
     * GET /api/audit?page=1&per_page=50&user_id=1&action=login&date_from=2025-01-01&date_to=2025-12-31
     */
    private function list(): void
    {
        // Paramètres de pagination
        $page = (int)($_GET['page'] ?? 1);
        $perPage = (int)($_GET['per_page'] ?? 50);

        // Filtres
        $userId = isset($_GET['user_id']) ? (int)$_GET['user_id'] : null;
        $action = $_GET['action'] ?? null;
        $search = $_GET['search'] ?? null;
        $dateFrom = $_GET['date_from'] ?? null;
        $dateTo = $_GET['date_to'] ?? null;
        $ipAddress = $_GET['ip_address'] ?? null;

        // Limites
        $perPage = min(max($perPage, PAGINATION_CONFIG['min_per_page']), PAGINATION_CONFIG['max_per_page']);

        // Construire la requête
        $sql = "SELECT a.*, u.username, u.email, u.first_name, u.last_name
                FROM um_audit_logs a
                LEFT JOIN um_users u ON a.user_id = u.id
                WHERE 1=1";

        $params = [];
        $countSql = "SELECT COUNT(*) FROM um_audit_logs WHERE 1=1";

        // Filtre par utilisateur
        if ($userId !== null) {
            $sql .= " AND a.user_id = :user_id";
            $countSql .= " AND user_id = :user_id";
            $params['user_id'] = $userId;
        }

        // Filtre par action
        if ($action !== null && $action !== '') {
            $sql .= " AND a.action = :action";
            $countSql .= " AND action = :action";
            $params['action'] = $action;
        }

        // Recherche
        if ($search !== null && $search !== '') {
            $searchPattern = '%' . $search . '%';
            $sql .= " AND (a.description LIKE :search OR a.metadata LIKE :search)";
            $countSql .= " AND (description LIKE :search OR metadata LIKE :search)";
            $params['search'] = $searchPattern;
        }

        // Filtre par date début
        if ($dateFrom !== null && $dateFrom !== '') {
            $sql .= " AND a.created_at >= :date_from";
            $countSql .= " AND created_at >= :date_from";
            $params['date_from'] = $dateFrom . ' 00:00:00';
        }

        // Filtre par date fin
        if ($dateTo !== null && $dateTo !== '') {
            $sql .= " AND a.created_at <= :date_to";
            $countSql .= " AND created_at <= :date_to";
            $params['date_to'] = $dateTo . ' 23:59:59';
        }

        // Filtre par IP
        if ($ipAddress !== null && $ipAddress !== '') {
            $sql .= " AND a.ip_address = :ip_address";
            $countSql .= " AND ip_address = :ip_address";
            $params['ip_address'] = $ipAddress;
        }

        // Compter le total
        $total = (int)$this->db->fetchColumn($countSql, $params);

        // Pagination
        $offset = ($page - 1) * $perPage;
        $sql .= " ORDER BY a.created_at DESC LIMIT {$perPage} OFFSET {$offset}";

        // Récupérer les logs
        $logs = $this->db->fetchAll($sql, $params);

        // Décoder les metadata JSON
        foreach ($logs as &$log) {
            if (isset($log['metadata']) && $log['metadata'] !== null) {
                $log['metadata'] = json_decode($log['metadata'], true);
            }
        }

        // Récupérer les actions disponibles
        $actions = $this->db->fetchAll(
            "SELECT DISTINCT action FROM um_audit_logs ORDER BY action ASC"
        );

        Logger::info('Audit logs retrieved', [
            'user_id' => $_SESSION['user_id'],
            'total' => $total
        ]);

        Response::success([
            'logs' => $logs,
            'actions' => array_column($actions, 'action'),
            'pagination' => [
                'current_page' => $page,
                'per_page' => $perPage,
                'total_items' => $total,
                'total_pages' => (int)ceil($total / $perPage),
            ]
        ]);
    }

    // ═══════════════════════════════════════════════════════════════════════
    // SHOW - GET /api/audit/{id}
    // ═══════════════════════════════════════════════════════════════════════

    /**
     * Afficher les détails d'un log
     * 
     * GET /api/audit/123
     */
    private function show(int $id): void
    {
        // Récupérer le log
        $log = $this->db->fetchOne(
            "SELECT a.*, u.username, u.email, u.first_name, u.last_name, u.role
             FROM um_audit_logs a
             LEFT JOIN um_users u ON a.user_id = u.id
             WHERE a.id = :id",
            ['id' => $id]
        );

        if (!$log) {
            Response::notFound('Log non trouvé');
        }

        // Décoder les metadata
        if (isset($log['metadata']) && $log['metadata'] !== null) {
            $log['metadata'] = json_decode($log['metadata'], true);
        }

        Logger::info('Audit log details retrieved', [
            'user_id' => $_SESSION['user_id'],
            'log_id' => $id
        ]);

        Response::success([
            'log' => $log
        ]);
    }

    // ═══════════════════════════════════════════════════════════════════════
    // STATS - GET /api/audit/stats
    // ═══════════════════════════════════════════════════════════════════════

    /**
     * Statistiques des logs d'audit
     * 
     * GET /api/audit/stats?period=7d
     */
    private function stats(): void
    {
        $period = $_GET['period'] ?? '7d'; // 7d, 30d, 90d, all

        // Calculer la date de début selon la période
        $dateFrom = null;
        switch ($period) {
            case '7d':
                $dateFrom = date('Y-m-d H:i:s', strtotime('-7 days'));
                break;
            case '30d':
                $dateFrom = date('Y-m-d H:i:s', strtotime('-30 days'));
                break;
            case '90d':
                $dateFrom = date('Y-m-d H:i:s', strtotime('-90 days'));
                break;
            case 'all':
            default:
                $dateFrom = null;
        }

        // Total des logs
        $totalSql = "SELECT COUNT(*) FROM um_audit_logs";
        $totalParams = [];
        if ($dateFrom !== null) {
            $totalSql .= " WHERE created_at >= :date_from";
            $totalParams['date_from'] = $dateFrom;
        }
        $totalLogs = (int)$this->db->fetchColumn($totalSql, $totalParams);

        // Logs par action
        $actionsSql = "SELECT action, COUNT(*) as count FROM um_audit_logs";
        if ($dateFrom !== null) {
            $actionsSql .= " WHERE created_at >= :date_from";
        }
        $actionsSql .= " GROUP BY action ORDER BY count DESC";
        $logsByAction = $this->db->fetchAll($actionsSql, $totalParams);

        // Logs par utilisateur (top 10)
        $usersSql = "SELECT a.user_id, u.username, COUNT(*) as count
                     FROM um_audit_logs a
                     LEFT JOIN um_users u ON a.user_id = u.id";
        if ($dateFrom !== null) {
            $usersSql .= " WHERE a.created_at >= :date_from";
        }
        $usersSql .= " GROUP BY a.user_id ORDER BY count DESC LIMIT 10";
        $logsByUser = $this->db->fetchAll($usersSql, $totalParams);

        // Logs par jour (derniers 30 jours)
        $dailySql = "SELECT DATE(created_at) as date, COUNT(*) as count
                     FROM um_audit_logs
                     WHERE created_at >= :date_from
                     GROUP BY DATE(created_at)
                     ORDER BY date DESC
                     LIMIT 30";
        $dailyParams = ['date_from' => date('Y-m-d H:i:s', strtotime('-30 days'))];
        $logsByDay = $this->db->fetchAll($dailySql, $dailyParams);

        Logger::info('Audit stats retrieved', [
            'user_id' => $_SESSION['user_id'],
            'period' => $period
        ]);

        Response::success([
            'period' => $period,
            'total_logs' => $totalLogs,
            'logs_by_action' => $logsByAction,
            'logs_by_user' => $logsByUser,
            'logs_by_day' => $logsByDay,
        ]);
    }

    // ═══════════════════════════════════════════════════════════════════════
    // MÉTHODES UTILITAIRES
    // ═══════════════════════════════════════════════════════════════════════

    /**
     * Vérifier si l'utilisateur est authentifié
     */
    private function isAuthenticated(): bool
    {
        return isset($_SESSION['logged_in']) && $_SESSION['logged_in'] === true;
    }

    /**
     * Vérifier si l'utilisateur a un rôle spécifique
     */
    private function hasRole(array $roles): bool
    {
        return isset($_SESSION['role']) && in_array($_SESSION['role'], $roles, true);
    }
}

/**
 * ═══════════════════════════════════════════════════════════════════════════
 * FIN DU AUDITCONTROLLER
 * ═══════════════════════════════════════════════════════════════════════════
 */
