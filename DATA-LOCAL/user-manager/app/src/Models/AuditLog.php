<?php
/**
 * ═══════════════════════════════════════════════════════════════════════════
 * BOLT.DIY USER MANAGER v2.0 - AuditLog Model
 * © Copyright Nbility 2025 - contact@nbility.fr
 * 
 * Model pour la consultation des logs d'audit
 * ═══════════════════════════════════════════════════════════════════════════
 */

declare(strict_types=1);

namespace App\Models;

use App\Utils\Database;

/**
 * Classe AuditLog - Model log d'audit
 */
class AuditLog
{
    private Database $db;
    private string $table = 'audit_logs';

    /**
     * Propriétés du log
     */
    public ?int $id = null;
    public ?int $user_id = null;
    public ?string $action = null;
    public ?string $description = null;
    public ?string $metadata = null;
    public ?string $ip_address = null;
    public ?string $user_agent = null;
    public ?string $created_at = null;

    /**
     * Constructeur
     */
    public function __construct()
    {
        $this->db = new Database();
    }

    // ═══════════════════════════════════════════════════════════════════════
    // MÉTHODES STATIQUES (Factory)
    // ═══════════════════════════════════════════════════════════════════════

    /**
     * Créer une instance depuis un tableau
     * 
     * @param array $data Données du log
     * @return self
     */
    public static function fromArray(array $data): self
    {
        $log = new self();

        foreach ($data as $key => $value) {
            if (property_exists($log, $key)) {
                $log->{$key} = $value;
            }
        }

        return $log;
    }

    /**
     * Trouver un log par ID
     * 
     * @param int $id ID du log
     * @return self|null
     */
    public static function find(int $id): ?self
    {
        $db = new Database();
        $data = $db->findById('audit_logs', $id);

        return $data ? self::fromArray($data) : null;
    }

    /**
     * Créer un nouveau log
     * 
     * @param array $data Données du log
     * @return self
     */
    public static function create(array $data): self
    {
        $db = new Database();

        // Ajouter created_at et informations automatiques
        $data['created_at'] = date('Y-m-d H:i:s');

        if (!isset($data['ip_address'])) {
            $data['ip_address'] = $_SERVER['REMOTE_ADDR'] ?? null;
        }

        if (!isset($data['user_agent'])) {
            $data['user_agent'] = $_SERVER['HTTP_USER_AGENT'] ?? null;
        }

        // Encoder metadata si c'est un tableau
        if (isset($data['metadata']) && is_array($data['metadata'])) {
            $data['metadata'] = json_encode($data['metadata']);
        }

        // Insérer
        $id = $db->insert('audit_logs', $data);

        // Retourner le log créé
        return self::find($id);
    }

    /**
     * Logger une action
     * 
     * @param int $userId ID de l'utilisateur
     * @param string $action Action effectuée
     * @param string $description Description
     * @param array $metadata Métadonnées additionnelles
     * @return self
     */
    public static function log(int $userId, string $action, string $description, array $metadata = []): self
    {
        return self::create([
            'user_id' => $userId,
            'action' => $action,
            'description' => $description,
            'metadata' => $metadata,
        ]);
    }

    /**
     * Récupérer les logs avec filtres
     * 
     * @param array $filters Filtres (user_id, action, date_from, date_to, ip_address)
     * @param string $orderBy Tri
     * @param int $limit Limite
     * @return array
     */
    public static function filter(array $filters = [], string $orderBy = 'created_at DESC', int $limit = 50): array
    {
        $db = new Database();

        $sql = "SELECT * FROM um_audit_logs WHERE 1=1";
        $params = [];

        // Filtre par user_id
        if (isset($filters['user_id'])) {
            $sql .= " AND user_id = :user_id";
            $params['user_id'] = $filters['user_id'];
        }

        // Filtre par action
        if (isset($filters['action'])) {
            $sql .= " AND action = :action";
            $params['action'] = $filters['action'];
        }

        // Filtre par date début
        if (isset($filters['date_from'])) {
            $sql .= " AND created_at >= :date_from";
            $params['date_from'] = $filters['date_from'];
        }

        // Filtre par date fin
        if (isset($filters['date_to'])) {
            $sql .= " AND created_at <= :date_to";
            $params['date_to'] = $filters['date_to'];
        }

        // Filtre par IP
        if (isset($filters['ip_address'])) {
            $sql .= " AND ip_address = :ip_address";
            $params['ip_address'] = $filters['ip_address'];
        }

        // Recherche
        if (isset($filters['search']) && $filters['search'] !== '') {
            $searchPattern = '%' . $filters['search'] . '%';
            $sql .= " AND (description LIKE :search OR metadata LIKE :search)";
            $params['search'] = $searchPattern;
        }

        $sql .= " ORDER BY {$orderBy} LIMIT {$limit}";

        $data = $db->fetchAll($sql, $params);

        $logs = [];
        foreach ($data as $row) {
            $logs[] = self::fromArray($row);
        }

        return $logs;
    }

    /**
     * Récupérer les logs d'un utilisateur
     * 
     * @param int $userId ID de l'utilisateur
     * @param int $limit Limite
     * @return array
     */
    public static function byUser(int $userId, int $limit = 50): array
    {
        return self::filter(['user_id' => $userId], 'created_at DESC', $limit);
    }

    /**
     * Récupérer les logs par action
     * 
     * @param string $action Action
     * @param int $limit Limite
     * @return array
     */
    public static function byAction(string $action, int $limit = 50): array
    {
        return self::filter(['action' => $action], 'created_at DESC', $limit);
    }

    /**
     * Récupérer les logs récents
     * 
     * @param int $limit Limite
     * @return array
     */
    public static function recent(int $limit = 50): array
    {
        return self::filter([], 'created_at DESC', $limit);
    }

    /**
     * Compter les logs
     * 
     * @param array $filters Filtres
     * @return int
     */
    public static function count(array $filters = []): int
    {
        $db = new Database();

        $sql = "SELECT COUNT(*) FROM um_audit_logs WHERE 1=1";
        $params = [];

        if (isset($filters['user_id'])) {
            $sql .= " AND user_id = :user_id";
            $params['user_id'] = $filters['user_id'];
        }

        if (isset($filters['action'])) {
            $sql .= " AND action = :action";
            $params['action'] = $filters['action'];
        }

        if (isset($filters['date_from'])) {
            $sql .= " AND created_at >= :date_from";
            $params['date_from'] = $filters['date_from'];
        }

        if (isset($filters['date_to'])) {
            $sql .= " AND created_at <= :date_to";
            $params['date_to'] = $filters['date_to'];
        }

        return (int)$db->fetchColumn($sql, $params);
    }

    /**
     * Récupérer toutes les actions uniques
     * 
     * @return array
     */
    public static function actions(): array
    {
        $db = new Database();
        $data = $db->fetchAll("SELECT DISTINCT action FROM um_audit_logs ORDER BY action ASC");
        return array_column($data, 'action');
    }

    // ═══════════════════════════════════════════════════════════════════════
    // MÉTHODES D'INSTANCE
    // ═══════════════════════════════════════════════════════════════════════

    /**
     * Convertir en tableau
     * 
     * @param bool $decodeMetadata Décoder les metadata JSON
     * @return array
     */
    public function toArray(bool $decodeMetadata = true): array
    {
        $data = [
            'id' => $this->id,
            'user_id' => $this->user_id,
            'action' => $this->action,
            'description' => $this->description,
            'metadata' => $this->metadata,
            'ip_address' => $this->ip_address,
            'user_agent' => $this->user_agent,
            'created_at' => $this->created_at,
        ];

        if ($decodeMetadata && $this->metadata !== null) {
            $data['metadata'] = json_decode($this->metadata, true);
        }

        return $data;
    }

    /**
     * Récupérer l'utilisateur associé au log
     * 
     * @return array|null
     */
    public function user(): ?array
    {
        if ($this->user_id === null) {
            return null;
        }

        return $this->db->findById('users', $this->user_id);
    }

    /**
     * Obtenir les metadata décodées
     * 
     * @return array|null
     */
    public function getMetadata(): ?array
    {
        if ($this->metadata === null) {
            return null;
        }

        return json_decode($this->metadata, true);
    }

    /**
     * Vérifier si le log correspond à une action spécifique
     * 
     * @param string $action Action à vérifier
     * @return bool
     */
    public function isAction(string $action): bool
    {
        return $this->action === $action;
    }

    /**
     * Obtenir une représentation humaine de l'ancienneté du log
     * 
     * @return string
     */
    public function timeAgo(): string
    {
        if ($this->created_at === null) {
            return 'Unknown';
        }

        $timestamp = strtotime($this->created_at);
        $diff = time() - $timestamp;

        if ($diff < 60) {
            return $diff . ' seconds ago';
        } elseif ($diff < 3600) {
            return floor($diff / 60) . ' minutes ago';
        } elseif ($diff < 86400) {
            return floor($diff / 3600) . ' hours ago';
        } elseif ($diff < 2592000) {
            return floor($diff / 86400) . ' days ago';
        } else {
            return date('Y-m-d H:i:s', $timestamp);
        }
    }
}

/**
 * ═══════════════════════════════════════════════════════════════════════════
 * FIN DU MODEL AUDITLOG
 * ═══════════════════════════════════════════════════════════════════════════
 */
