<?php
/**
 * ═══════════════════════════════════════════════════════════════════════════
 * BOLT.DIY USER MANAGER v2.0 - Classe Database
 * © Copyright Nbility 2025 - contact@nbility.fr
 * 
 * Wrapper PDO avec Query Builder simple
 * ═══════════════════════════════════════════════════════════════════════════
 */

declare(strict_types=1);

namespace App\Utils;

use PDO;
use PDOException;
use PDOStatement;

/**
 * Classe Database - Wrapper PDO avec Query Builder
 */
class Database
{
    /**
     * Instance PDO
     */
    private PDO $pdo;

    /**
     * Préfixe des tables
     */
    private string $prefix;

    /**
     * Constructeur
     */
    public function __construct()
    {
        $this->pdo = getDbConnection();
        $this->prefix = DB_CONFIG['prefix'] ?? 'um_';
    }

    /**
     * Obtenir l'instance PDO
     * 
     * @return PDO
     */
    public function getPdo(): PDO
    {
        return $this->pdo;
    }

    // ═══════════════════════════════════════════════════════════════════════
    // MÉTHODES DE REQUÊTES DIRECTES
    // ═══════════════════════════════════════════════════════════════════════

    /**
     * Exécuter une requête SQL
     * 
     * @param string $sql Requête SQL
     * @param array $params Paramètres
     * @return PDOStatement
     * @throws PDOException
     */
    public function query(string $sql, array $params = []): PDOStatement
    {
        try {
            $stmt = $this->pdo->prepare($sql);
            $stmt->execute($params);
            return $stmt;
        } catch (PDOException $e) {
            Logger::error('Database query failed', [
                'sql' => $sql,
                'error' => $e->getMessage()
            ]);
            throw $e;
        }
    }

    /**
     * Récupérer tous les résultats
     * 
     * @param string $sql Requête SQL
     * @param array $params Paramètres
     * @return array
     */
    public function fetchAll(string $sql, array $params = []): array
    {
        $stmt = $this->query($sql, $params);
        return $stmt->fetchAll();
    }

    /**
     * Récupérer un seul résultat
     * 
     * @param string $sql Requête SQL
     * @param array $params Paramètres
     * @return array|null
     */
    public function fetchOne(string $sql, array $params = []): ?array
    {
        $stmt = $this->query($sql, $params);
        $result = $stmt->fetch();
        return $result ?: null;
    }

    /**
     * Récupérer une seule colonne
     * 
     * @param string $sql Requête SQL
     * @param array $params Paramètres
     * @return mixed
     */
    public function fetchColumn(string $sql, array $params = [])
    {
        $stmt = $this->query($sql, $params);
        return $stmt->fetchColumn();
    }

    // ═══════════════════════════════════════════════════════════════════════
    // QUERY BUILDER - SELECT
    // ═══════════════════════════════════════════════════════════════════════

    /**
     * SELECT simple
     * 
     * @param string $table Nom de la table (sans préfixe)
     * @param array $columns Colonnes à récupérer
     * @param array $where Conditions WHERE
     * @param string|null $orderBy ORDER BY
     * @param int|null $limit LIMIT
     * @param int|null $offset OFFSET
     * @return array
     */
    public function select(
        string $table,
        array $columns = ['*'],
        array $where = [],
        ?string $orderBy = null,
        ?int $limit = null,
        ?int $offset = null
    ): array {
        $table = $this->prefix . $table;
        $cols = implode(', ', $columns);

        $sql = "SELECT {$cols} FROM {$table}";
        $params = [];

        // WHERE
        if (!empty($where)) {
            $conditions = [];
            foreach ($where as $key => $value) {
                $conditions[] = "{$key} = :{$key}";
                $params[$key] = $value;
            }
            $sql .= " WHERE " . implode(' AND ', $conditions);
        }

        // ORDER BY
        if ($orderBy !== null) {
            $sql .= " ORDER BY {$orderBy}";
        }

        // LIMIT
        if ($limit !== null) {
            $sql .= " LIMIT {$limit}";
        }

        // OFFSET
        if ($offset !== null) {
            $sql .= " OFFSET {$offset}";
        }

        return $this->fetchAll($sql, $params);
    }

    /**
     * SELECT avec pagination
     * 
     * @param string $table Nom de la table
     * @param int $page Page (1-indexed)
     * @param int $perPage Items par page
     * @param array $where Conditions WHERE
     * @param string|null $orderBy ORDER BY
     * @return array ['items' => array, 'total' => int, 'page' => int, 'per_page' => int]
     */
    public function paginate(
        string $table,
        int $page = 1,
        int $perPage = 20,
        array $where = [],
        ?string $orderBy = null
    ): array {
        // Compter le total
        $total = $this->count($table, $where);

        // Calculer l'offset
        $offset = ($page - 1) * $perPage;

        // Récupérer les items
        $items = $this->select($table, ['*'], $where, $orderBy, $perPage, $offset);

        return [
            'items' => $items,
            'total' => $total,
            'page' => $page,
            'per_page' => $perPage,
            'total_pages' => (int)ceil($total / $perPage),
        ];
    }

    /**
     * Compter les enregistrements
     * 
     * @param string $table Nom de la table
     * @param array $where Conditions WHERE
     * @return int
     */
    public function count(string $table, array $where = []): int
    {
        $table = $this->prefix . $table;
        $sql = "SELECT COUNT(*) FROM {$table}";
        $params = [];

        if (!empty($where)) {
            $conditions = [];
            foreach ($where as $key => $value) {
                $conditions[] = "{$key} = :{$key}";
                $params[$key] = $value;
            }
            $sql .= " WHERE " . implode(' AND ', $conditions);
        }

        return (int)$this->fetchColumn($sql, $params);
    }

    /**
     * Récupérer un enregistrement par ID
     * 
     * @param string $table Nom de la table
     * @param int $id ID
     * @return array|null
     */
    public function findById(string $table, int $id): ?array
    {
        return $this->fetchOne(
            "SELECT * FROM {$this->prefix}{$table} WHERE id = :id",
            ['id' => $id]
        );
    }

    // ═══════════════════════════════════════════════════════════════════════
    // QUERY BUILDER - INSERT
    // ═══════════════════════════════════════════════════════════════════════

    /**
     * INSERT
     * 
     * @param string $table Nom de la table
     * @param array $data Données à insérer
     * @return int ID inséré
     */
    public function insert(string $table, array $data): int
    {
        $table = $this->prefix . $table;
        $columns = array_keys($data);
        $placeholders = array_map(fn($col) => ":{$col}", $columns);

        $cols = implode(', ', $columns);
        $vals = implode(', ', $placeholders);

        $sql = "INSERT INTO {$table} ({$cols}) VALUES ({$vals})";

        $this->query($sql, $data);

        return (int)$this->pdo->lastInsertId();
    }

    // ═══════════════════════════════════════════════════════════════════════
    // QUERY BUILDER - UPDATE
    // ═══════════════════════════════════════════════════════════════════════

    /**
     * UPDATE
     * 
     * @param string $table Nom de la table
     * @param array $data Données à mettre à jour
     * @param array $where Conditions WHERE
     * @return int Nombre de lignes affectées
     */
    public function update(string $table, array $data, array $where): int
    {
        $table = $this->prefix . $table;

        // SET
        $set = [];
        $params = [];
        foreach ($data as $key => $value) {
            $set[] = "{$key} = :set_{$key}";
            $params["set_{$key}"] = $value;
        }

        // WHERE
        $conditions = [];
        foreach ($where as $key => $value) {
            $conditions[] = "{$key} = :where_{$key}";
            $params["where_{$key}"] = $value;
        }

        $sql = "UPDATE {$table} SET " . implode(', ', $set) . " WHERE " . implode(' AND ', $conditions);

        $stmt = $this->query($sql, $params);

        return $stmt->rowCount();
    }

    /**
     * UPDATE par ID
     * 
     * @param string $table Nom de la table
     * @param int $id ID
     * @param array $data Données
     * @return int Nombre de lignes affectées
     */
    public function updateById(string $table, int $id, array $data): int
    {
        return $this->update($table, $data, ['id' => $id]);
    }

    // ═══════════════════════════════════════════════════════════════════════
    // QUERY BUILDER - DELETE
    // ═══════════════════════════════════════════════════════════════════════

    /**
     * DELETE
     * 
     * @param string $table Nom de la table
     * @param array $where Conditions WHERE
     * @return int Nombre de lignes supprimées
     */
    public function delete(string $table, array $where): int
    {
        $table = $this->prefix . $table;

        $conditions = [];
        $params = [];
        foreach ($where as $key => $value) {
            $conditions[] = "{$key} = :{$key}";
            $params[$key] = $value;
        }

        $sql = "DELETE FROM {$table} WHERE " . implode(' AND ', $conditions);

        $stmt = $this->query($sql, $params);

        return $stmt->rowCount();
    }

    /**
     * DELETE par ID
     * 
     * @param string $table Nom de la table
     * @param int $id ID
     * @return int Nombre de lignes supprimées
     */
    public function deleteById(string $table, int $id): int
    {
        return $this->delete($table, ['id' => $id]);
    }

    // ═══════════════════════════════════════════════════════════════════════
    // TRANSACTIONS
    // ═══════════════════════════════════════════════════════════════════════

    /**
     * Démarrer une transaction
     */
    public function beginTransaction(): void
    {
        $this->pdo->beginTransaction();
    }

    /**
     * Valider une transaction
     */
    public function commit(): void
    {
        $this->pdo->commit();
    }

    /**
     * Annuler une transaction
     */
    public function rollback(): void
    {
        $this->pdo->rollBack();
    }

    /**
     * Exécuter dans une transaction
     * 
     * @param callable $callback Fonction à exécuter
     * @return mixed Résultat de la fonction
     * @throws \Throwable
     */
    public function transaction(callable $callback)
    {
        $this->beginTransaction();

        try {
            $result = $callback($this);
            $this->commit();
            return $result;
        } catch (\Throwable $e) {
            $this->rollback();
            throw $e;
        }
    }
}

/**
 * ═══════════════════════════════════════════════════════════════════════════
 * FIN DE LA CLASSE DATABASE
 * ═══════════════════════════════════════════════════════════════════════════
 */
