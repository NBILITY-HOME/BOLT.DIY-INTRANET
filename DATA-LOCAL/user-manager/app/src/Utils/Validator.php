<?php
/**
 * ═══════════════════════════════════════════════════════════════════════════
 * BOLT.DIY USER MANAGER v2.0 - Classe Validator
 * © Copyright Nbility 2025 - contact@nbility.fr
 * 
 * Validation de données avec règles personnalisables
 * ═══════════════════════════════════════════════════════════════════════════
 */

declare(strict_types=1);

namespace App\Utils;

/**
 * Classe Validator - Validation de données
 */
class Validator
{
    /**
     * Données à valider
     */
    private array $data;

    /**
     * Erreurs de validation
     */
    private array $errors = [];

    /**
     * Constructeur
     * 
     * @param array $data Données à valider
     */
    public function __construct(array $data)
    {
        $this->data = $data;
    }

    /**
     * Valider selon des règles
     * 
     * @param array $rules Règles de validation
     * @return bool
     */
    public function validate(array $rules): bool
    {
        $this->errors = [];

        foreach ($rules as $field => $ruleString) {
            $this->validateField($field, $ruleString);
        }

        return empty($this->errors);
    }

    /**
     * Obtenir les erreurs
     * 
     * @return array
     */
    public function getErrors(): array
    {
        return $this->errors;
    }

    /**
     * Obtenir les données validées
     * 
     * @return array
     */
    public function getData(): array
    {
        return $this->data;
    }

    /**
     * Valider un champ
     * 
     * @param string $field Nom du champ
     * @param string $ruleString Règles séparées par |
     */
    private function validateField(string $field, string $ruleString): void
    {
        $rules = explode('|', $ruleString);
        $value = $this->data[$field] ?? null;

        foreach ($rules as $rule) {
            // Extraire la règle et les paramètres
            if (strpos($rule, ':') !== false) {
                [$ruleName, $params] = explode(':', $rule, 2);
                $params = explode(',', $params);
            } else {
                $ruleName = $rule;
                $params = [];
            }

            // Appliquer la règle
            $this->applyRule($field, $value, $ruleName, $params);
        }
    }

    /**
     * Appliquer une règle de validation
     * 
     * @param string $field Nom du champ
     * @param mixed $value Valeur
     * @param string $rule Nom de la règle
     * @param array $params Paramètres
     */
    private function applyRule(string $field, $value, string $rule, array $params): void
    {
        switch ($rule) {
            case 'required':
                if ($value === null || $value === '') {
                    $this->addError($field, "Le champ {$field} est requis");
                }
                break;

            case 'email':
                if ($value !== null && !filter_var($value, FILTER_VALIDATE_EMAIL)) {
                    $this->addError($field, "Le champ {$field} doit être une adresse email valide");
                }
                break;

            case 'min':
                $min = (int)$params[0];
                if ($value !== null && strlen((string)$value) < $min) {
                    $this->addError($field, "Le champ {$field} doit contenir au moins {$min} caractères");
                }
                break;

            case 'max':
                $max = (int)$params[0];
                if ($value !== null && strlen((string)$value) > $max) {
                    $this->addError($field, "Le champ {$field} ne doit pas dépasser {$max} caractères");
                }
                break;

            case 'numeric':
                if ($value !== null && !is_numeric($value)) {
                    $this->addError($field, "Le champ {$field} doit être numérique");
                }
                break;

            case 'integer':
                if ($value !== null && !filter_var($value, FILTER_VALIDATE_INT)) {
                    $this->addError($field, "Le champ {$field} doit être un entier");
                }
                break;

            case 'alpha':
                if ($value !== null && !ctype_alpha($value)) {
                    $this->addError($field, "Le champ {$field} ne doit contenir que des lettres");
                }
                break;

            case 'alphanumeric':
                if ($value !== null && !ctype_alnum($value)) {
                    $this->addError($field, "Le champ {$field} ne doit contenir que des lettres et chiffres");
                }
                break;

            case 'username':
                if ($value !== null && !preg_match('/^[a-zA-Z0-9_-]{3,32}$/', $value)) {
                    $this->addError($field, "Le champ {$field} doit contenir 3-32 caractères (lettres, chiffres, _ ou -)");
                }
                break;

            case 'password':
                if ($value !== null) {
                    $result = validatePasswordStrength((string)$value);
                    if (!$result['valid']) {
                        foreach ($result['errors'] as $error) {
                            $this->addError($field, $error);
                        }
                    }
                }
                break;

            case 'url':
                if ($value !== null && !filter_var($value, FILTER_VALIDATE_URL)) {
                    $this->addError($field, "Le champ {$field} doit être une URL valide");
                }
                break;

            case 'ip':
                if ($value !== null && !filter_var($value, FILTER_VALIDATE_IP)) {
                    $this->addError($field, "Le champ {$field} doit être une adresse IP valide");
                }
                break;

            case 'in':
                if ($value !== null && !in_array($value, $params, true)) {
                    $allowed = implode(', ', $params);
                    $this->addError($field, "Le champ {$field} doit être l'une des valeurs suivantes: {$allowed}");
                }
                break;

            case 'regex':
                $pattern = $params[0];
                if ($value !== null && !preg_match($pattern, (string)$value)) {
                    $this->addError($field, "Le champ {$field} ne respecte pas le format attendu");
                }
                break;

            case 'date':
                if ($value !== null) {
                    $format = $params[0] ?? 'Y-m-d';
                    $d = \DateTime::createFromFormat($format, (string)$value);
                    if (!$d || $d->format($format) !== $value) {
                        $this->addError($field, "Le champ {$field} doit être une date valide (format: {$format})");
                    }
                }
                break;

            case 'before':
                $date = $params[0];
                if ($value !== null && strtotime((string)$value) >= strtotime($date)) {
                    $this->addError($field, "Le champ {$field} doit être antérieur à {$date}");
                }
                break;

            case 'after':
                $date = $params[0];
                if ($value !== null && strtotime((string)$value) <= strtotime($date)) {
                    $this->addError($field, "Le champ {$field} doit être postérieur à {$date}");
                }
                break;

            case 'confirmed':
                $confirmField = $field . '_confirmation';
                if ($value !== ($this->data[$confirmField] ?? null)) {
                    $this->addError($field, "Le champ {$field} et sa confirmation ne correspondent pas");
                }
                break;

            case 'unique':
                // Format: unique:table,column
                $table = $params[0];
                $column = $params[1] ?? $field;
                $excludeId = $params[2] ?? null;

                $db = new Database();
                $where = [$column => $value];
                $count = $db->count($table, $where);

                // Si on met à jour, exclure l'ID actuel
                if ($excludeId !== null) {
                    $existing = $db->fetchOne(
                        "SELECT id FROM {$table} WHERE {$column} = :value AND id != :id",
                        ['value' => $value, 'id' => $excludeId]
                    );
                    $count = $existing ? 1 : 0;
                }

                if ($count > 0) {
                    $this->addError($field, "Le champ {$field} doit être unique");
                }
                break;

            case 'exists':
                // Format: exists:table,column
                $table = $params[0];
                $column = $params[1] ?? $field;

                $db = new Database();
                $count = $db->count($table, [$column => $value]);

                if ($count === 0) {
                    $this->addError($field, "Le champ {$field} n'existe pas");
                }
                break;
        }
    }

    /**
     * Ajouter une erreur
     * 
     * @param string $field Nom du champ
     * @param string $message Message d'erreur
     */
    private function addError(string $field, string $message): void
    {
        if (!isset($this->errors[$field])) {
            $this->errors[$field] = [];
        }
        $this->errors[$field][] = $message;
    }

    /**
     * Valider rapidement des données
     * 
     * @param array $data Données
     * @param array $rules Règles
     * @return array ['valid' => bool, 'errors' => array, 'data' => array]
     */
    public static function make(array $data, array $rules): array
    {
        $validator = new self($data);
        $valid = $validator->validate($rules);

        return [
            'valid' => $valid,
            'errors' => $validator->getErrors(),
            'data' => $validator->getData(),
        ];
    }
}

/**
 * ═══════════════════════════════════════════════════════════════════════════
 * FIN DE LA CLASSE VALIDATOR
 * ═══════════════════════════════════════════════════════════════════════════
 */
