<?php
/* ============================================
   Bolt.DIY User Manager - Validator Class
   Version: 1.0
   Date: 19 novembre 2025
   ============================================ */

namespace App\Security;

class Validator {
    
    private $errors = [];
    private $data = [];
    
    public function __construct($data = []) {
        $this->data = $data;
    }
    
    /* ============================================
       VALIDATION METHODS
       ============================================ */
    
    public function required($field, $message = null) {
        if (!isset($this->data[$field]) || trim($this->data[$field]) === '') {
            $this->addError($field, $message ?? "Le champ {$field} est requis");
        }
        return $this;
    }
    
    public function email($field, $message = null) {
        if (isset($this->data[$field]) && !filter_var($this->data[$field], FILTER_VALIDATE_EMAIL)) {
            $this->addError($field, $message ?? "Le champ {$field} doit être une adresse email valide");
        }
        return $this;
    }
    
    public function url($field, $message = null) {
        if (isset($this->data[$field]) && !filter_var($this->data[$field], FILTER_VALIDATE_URL)) {
            $this->addError($field, $message ?? "Le champ {$field} doit être une URL valide");
        }
        return $this;
    }
    
    public function min($field, $min, $message = null) {
        if (isset($this->data[$field]) && strlen($this->data[$field]) < $min) {
            $this->addError($field, $message ?? "Le champ {$field} doit contenir au moins {$min} caractères");
        }
        return $this;
    }
    
    public function max($field, $max, $message = null) {
        if (isset($this->data[$field]) && strlen($this->data[$field]) > $max) {
            $this->addError($field, $message ?? "Le champ {$field} ne doit pas dépasser {$max} caractères");
        }
        return $this;
    }
    
    public function between($field, $min, $max, $message = null) {
        $length = strlen($this->data[$field] ?? '');
        if ($length < $min || $length > $max) {
            $this->addError($field, $message ?? "Le champ {$field} doit contenir entre {$min} et {$max} caractères");
        }
        return $this;
    }
    
    public function numeric($field, $message = null) {
        if (isset($this->data[$field]) && !is_numeric($this->data[$field])) {
            $this->addError($field, $message ?? "Le champ {$field} doit être un nombre");
        }
        return $this;
    }
    
    public function integer($field, $message = null) {
        if (isset($this->data[$field]) && !filter_var($this->data[$field], FILTER_VALIDATE_INT)) {
            $this->addError($field, $message ?? "Le champ {$field} doit être un entier");
        }
        return $this;
    }
    
    public function alpha($field, $message = null) {
        if (isset($this->data[$field]) && !ctype_alpha($this->data[$field])) {
            $this->addError($field, $message ?? "Le champ {$field} ne doit contenir que des lettres");
        }
        return $this;
    }
    
    public function alphaNum($field, $message = null) {
        if (isset($this->data[$field]) && !ctype_alnum($this->data[$field])) {
            $this->addError($field, $message ?? "Le champ {$field} ne doit contenir que des lettres et des chiffres");
        }
        return $this;
    }
    
    public function regex($field, $pattern, $message = null) {
        if (isset($this->data[$field]) && !preg_match($pattern, $this->data[$field])) {
            $this->addError($field, $message ?? "Le champ {$field} ne correspond pas au format requis");
        }
        return $this;
    }
    
    public function in($field, $values, $message = null) {
        if (isset($this->data[$field]) && !in_array($this->data[$field], $values)) {
            $this->addError($field, $message ?? "Le champ {$field} doit être l'une des valeurs autorisées");
        }
        return $this;
    }
    
    public function notIn($field, $values, $message = null) {
        if (isset($this->data[$field]) && in_array($this->data[$field], $values)) {
            $this->addError($field, $message ?? "Le champ {$field} ne peut pas être l'une de ces valeurs");
        }
        return $this;
    }
    
    public function same($field, $otherField, $message = null) {
        if (isset($this->data[$field], $this->data[$otherField]) && 
            $this->data[$field] !== $this->data[$otherField]) {
            $this->addError($field, $message ?? "Le champ {$field} doit correspondre au champ {$otherField}");
        }
        return $this;
    }
    
    public function different($field, $otherField, $message = null) {
        if (isset($this->data[$field], $this->data[$otherField]) && 
            $this->data[$field] === $this->data[$otherField]) {
            $this->addError($field, $message ?? "Le champ {$field} doit être différent du champ {$otherField}");
        }
        return $this;
    }
    
    public function unique($field, $table, $column, $pdo, $message = null) {
        if (!isset($this->data[$field])) {
            return $this;
        }
        
        $stmt = $pdo->prepare("SELECT COUNT(*) FROM {$table} WHERE {$column} = ?");
        $stmt->execute([$this->data[$field]]);
        $count = $stmt->fetchColumn();
        
        if ($count > 0) {
            $this->addError($field, $message ?? "La valeur du champ {$field} existe déjà");
        }
        return $this;
    }
    
    public function exists($field, $table, $column, $pdo, $message = null) {
        if (!isset($this->data[$field])) {
            return $this;
        }
        
        $stmt = $pdo->prepare("SELECT COUNT(*) FROM {$table} WHERE {$column} = ?");
        $stmt->execute([$this->data[$field]]);
        $count = $stmt->fetchColumn();
        
        if ($count === 0) {
            $this->addError($field, $message ?? "La valeur du champ {$field} n'existe pas");
        }
        return $this;
    }
    
    public function date($field, $format = 'Y-m-d', $message = null) {
        if (!isset($this->data[$field])) {
            return $this;
        }
        
        $d = \DateTime::createFromFormat($format, $this->data[$field]);
        if (!$d || $d->format($format) !== $this->data[$field]) {
            $this->addError($field, $message ?? "Le champ {$field} n'est pas une date valide");
        }
        return $this;
    }
    
    public function before($field, $date, $message = null) {
        if (!isset($this->data[$field])) {
            return $this;
        }
        
        $fieldDate = strtotime($this->data[$field]);
        $compareDate = strtotime($date);
        
        if ($fieldDate >= $compareDate) {
            $this->addError($field, $message ?? "Le champ {$field} doit être avant {$date}");
        }
        return $this;
    }
    
    public function after($field, $date, $message = null) {
        if (!isset($this->data[$field])) {
            return $this;
        }
        
        $fieldDate = strtotime($this->data[$field]);
        $compareDate = strtotime($date);
        
        if ($fieldDate <= $compareDate) {
            $this->addError($field, $message ?? "Le champ {$field} doit être après {$date}");
        }
        return $this;
    }
    
    public function file($field, $message = null) {
        if (!isset($_FILES[$field]) || $_FILES[$field]['error'] === UPLOAD_ERR_NO_FILE) {
            $this->addError($field, $message ?? "Le fichier {$field} est requis");
        }
        return $this;
    }
    
    public function fileSize($field, $maxSize, $message = null) {
        if (isset($_FILES[$field]) && $_FILES[$field]['size'] > $maxSize) {
            $maxSizeMB = round($maxSize / 1048576, 2);
            $this->addError($field, $message ?? "Le fichier {$field} ne doit pas dépasser {$maxSizeMB} MB");
        }
        return $this;
    }
    
    public function fileMime($field, $mimeTypes, $message = null) {
        if (!isset($_FILES[$field])) {
            return $this;
        }
        
        $finfo = finfo_open(FILEINFO_MIME_TYPE);
        $mimeType = finfo_file($finfo, $_FILES[$field]['tmp_name']);
        finfo_close($finfo);
        
        if (!in_array($mimeType, $mimeTypes)) {
            $this->addError($field, $message ?? "Le type de fichier {$field} n'est pas autorisé");
        }
        return $this;
    }
    
    public function json($field, $message = null) {
        if (!isset($this->data[$field])) {
            return $this;
        }
        
        json_decode($this->data[$field]);
        if (json_last_error() !== JSON_ERROR_NONE) {
            $this->addError($field, $message ?? "Le champ {$field} doit être un JSON valide");
        }
        return $this;
    }
    
    public function ip($field, $message = null) {
        if (isset($this->data[$field]) && !filter_var($this->data[$field], FILTER_VALIDATE_IP)) {
            $this->addError($field, $message ?? "Le champ {$field} doit être une adresse IP valide");
        }
        return $this;
    }
    
    public function password($field, $minLength = 8, $requireSpecial = true, $message = null) {
        if (!isset($this->data[$field])) {
            return $this;
        }
        
        $password = $this->data[$field];
        $errors = [];
        
        if (strlen($password) < $minLength) {
            $errors[] = "au moins {$minLength} caractères";
        }
        
        if (!preg_match('/[A-Z]/', $password)) {
            $errors[] = "au moins une majuscule";
        }
        
        if (!preg_match('/[a-z]/', $password)) {
            $errors[] = "au moins une minuscule";
        }
        
        if (!preg_match('/[0-9]/', $password)) {
            $errors[] = "au moins un chiffre";
        }
        
        if ($requireSpecial && !preg_match('/[^A-Za-z0-9]/', $password)) {
            $errors[] = "au moins un caractère spécial";
        }
        
        if (!empty($errors)) {
            $errorMsg = "Le mot de passe doit contenir " . implode(', ', $errors);
            $this->addError($field, $message ?? $errorMsg);
        }
        
        return $this;
    }
    
    /* ============================================
       CUSTOM VALIDATION
       ============================================ */
    
    public function custom($field, callable $callback, $message = null) {
        if (!isset($this->data[$field])) {
            return $this;
        }
        
        $result = $callback($this->data[$field], $this->data);
        
        if ($result !== true) {
            $this->addError($field, $message ?? $result ?? "Le champ {$field} n'est pas valide");
        }
        
        return $this;
    }
    
    /* ============================================
       ERROR MANAGEMENT
       ============================================ */
    
    private function addError($field, $message) {
        if (!isset($this->errors[$field])) {
            $this->errors[$field] = [];
        }
        $this->errors[$field][] = $message;
    }
    
    public function fails() {
        return !empty($this->errors);
    }
    
    public function passes() {
        return empty($this->errors);
    }
    
    public function getErrors() {
        return $this->errors;
    }
    
    public function getError($field) {
        return $this->errors[$field] ?? null;
    }
    
    public function getFirstError($field = null) {
        if ($field !== null) {
            return $this->errors[$field][0] ?? null;
        }
        
        foreach ($this->errors as $fieldErrors) {
            return $fieldErrors[0];
        }
        
        return null;
    }
    
    public function hasError($field) {
        return isset($this->errors[$field]);
    }
    
    /* ============================================
       HELPER METHODS
       ============================================ */
    
    public static function make($data) {
        return new self($data);
    }
    
    public function validate() {
        if ($this->fails()) {
            return [
                'valid' => false,
                'errors' => $this->getErrors()
            ];
        }
        
        return [
            'valid' => true,
            'data' => $this->data
        ];
    }
}
