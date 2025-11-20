# 🔒 Bolt.DIY User Manager - Security Documentation

## Vue d'ensemble

Ce document décrit toutes les mesures de sécurité implémentées dans le Bolt.DIY User Manager.

## 📋 Table des matières

1. [Protection CSRF](#protection-csrf)
2. [Gestion des sessions](#gestion-des-sessions)
3. [Validation des données](#validation-des-données)
4. [Protection des mots de passe](#protection-des-mots-de-passe)
5. [Rate Limiting](#rate-limiting)
6. [Headers de sécurité](#headers-de-sécurité)
7. [Protection XSS](#protection-xss)
8. [Protection SQL Injection](#protection-sql-injection)
9. [Sécurité des fichiers](#sécurité-des-fichiers)
10. [Configuration](#configuration)

---

## 🛡️ Protection CSRF

### Implémentation

La protection CSRF est implémentée via la classe `Security` :

```php
use App\Security\Security;

$security = Security::getInstance();
$token = $security->generateCsrfToken('form_name');
```

### Utilisation dans les formulaires

```html
<form method="POST">
    <?php echo csrf_field(); ?>
    <!-- ou -->
    <input type="hidden" name="csrf_token" value="<?php echo csrf_token(); ?>">
    
    <!-- Autres champs du formulaire -->
</form>
```

### Validation côté serveur

```php
$token = $_POST['csrf_token'];
if (!$security->validateCsrfToken($token, 'form_name')) {
    die('CSRF validation failed');
}
```

### Caractéristiques

- Tokens uniques par formulaire
- Expiration après 1 heure
- Usage unique (token supprimé après validation)
- Génération automatique si absent

---

## 🔐 Gestion des sessions

### Initialisation

```php
use App\Security\Session;

$session = Session::getInstance();
```

### Configuration

- Timeout : 30 minutes d'inactivité
- Régénération automatique de l'ID toutes les 30 minutes
- Cookies sécurisés (HttpOnly, Secure, SameSite)
- Fingerprinting pour détecter le vol de session

### Méthodes principales

```php
// Connexion utilisateur
$session->login($userId, $userData);

// Vérifier si connecté
if ($session->isLoggedIn()) {
    // ...
}

// Récupérer l'utilisateur
$userId = $session->getUserId();
$userData = $session->getUserData();

// Déconnexion
$session->logout();

// Données de session
$session->set('key', 'value');
$value = $session->get('key', 'default');
$session->remove('key');

// Flash messages
$session->flash('message', 'Opération réussie');
$message = $session->flash('message');
```

### Protection

- Validation du fingerprint (User-Agent + IP)
- Expiration automatique après inactivité
- Régénération d'ID à la connexion
- Destruction complète à la déconnexion

---

## ✅ Validation des données

### Utilisation du Validator

```php
use App\Security\Validator;

$validator = Validator::make($_POST);

$validator
    ->required('email', 'Email requis')
    ->email('email', 'Email invalide')
    ->required('password')
    ->min('password', 8, 'Minimum 8 caractères')
    ->password('password', 8, true);

if ($validator->fails()) {
    $errors = $validator->getErrors();
    // Gérer les erreurs
}
```

### Règles disponibles

- `required($field)` - Champ obligatoire
- `email($field)` - Format email valide
- `url($field)` - Format URL valide
- `min($field, $min)` - Longueur minimale
- `max($field, $max)` - Longueur maximale
- `between($field, $min, $max)` - Longueur entre min et max
- `numeric($field)` - Valeur numérique
- `integer($field)` - Valeur entière
- `alpha($field)` - Lettres uniquement
- `alphaNum($field)` - Lettres et chiffres
- `regex($field, $pattern)` - Expression régulière
- `in($field, $values)` - Valeur dans une liste
- `same($field, $otherField)` - Même valeur qu'un autre champ
- `password($field, $minLength, $requireSpecial)` - Mot de passe fort
- `date($field, $format)` - Format de date
- `file($field)` - Fichier requis
- `fileSize($field, $maxSize)` - Taille maximale
- `fileMime($field, $mimeTypes)` - Types MIME autorisés

### Validation personnalisée

```php
$validator->custom('username', function($value, $data) {
    if (strlen($value) < 3) {
        return 'Username trop court';
    }
    return true;
}, 'Username invalide');
```

---

## 🔑 Protection des mots de passe

### Hashing

```php
$security = Security::getInstance();

// Hash un mot de passe
$hash = $security->hashPassword($password);

// Vérifier un mot de passe
if ($security->verifyPassword($password, $hash)) {
    // Mot de passe correct
}

// Vérifier si le hash doit être mis à jour
if ($security->needsRehash($hash)) {
    $newHash = $security->hashPassword($password);
    // Mettre à jour en base
}
```

### Politique de mot de passe

Configuration dans `config/security.php` :

```php
'password' => [
    'min_length' => 8,
    'require_uppercase' => true,
    'require_lowercase' => true,
    'require_numbers' => true,
    'require_special' => true,
    'hash_algorithm' => PASSWORD_ARGON2ID
]
```

### Validation

```php
$validator->password('password', 8, true);
```

Vérifie :
- Longueur minimale (8 caractères)
- Au moins une majuscule
- Au moins une minuscule
- Au moins un chiffre
- Au moins un caractère spécial

---

## ⏱️ Rate Limiting

### Protection contre le brute force

```php
$security = Security::getInstance();

// Vérifier le rate limit
if (!$security->checkRateLimit('login_' . $ip, 5, 900)) {
    die('Trop de tentatives. Réessayez plus tard.');
}

// Obtenir les tentatives restantes
$remaining = $security->getRemainingAttempts('login_' . $ip, 5);

// Réinitialiser le compteur
$security->resetRateLimit('login_' . $ip);
```

### Configuration

```php
'rate_limit' => [
    'login' => [
        'max_attempts' => 5,
        'time_window' => 900, // 15 minutes
    ],
    'api' => [
        'max_requests' => 60,
        'time_window' => 60 // 1 minute
    ]
]
```

---

## 🔒 Headers de sécurité

### Headers implémentés

- `X-Content-Type-Options: nosniff` - Empêche le MIME sniffing
- `X-XSS-Protection: 1; mode=block` - Protection XSS
- `X-Frame-Options: SAMEORIGIN` - Protection contre le clickjacking
- `Content-Security-Policy` - Politique de sécurité du contenu
- `Referrer-Policy` - Politique de referrer
- `Strict-Transport-Security` - Force HTTPS
- `Permissions-Policy` - Contrôle des permissions

### Application automatique

```php
$security = Security::getInstance();
$security->setSecurityHeaders();
```

---

## 🚫 Protection XSS

### Échappement HTML

```php
$security = Security::getInstance();

// Échapper pour HTML
$safe = $security->escapeHtml($userInput);

// Échapper pour JavaScript
$safe = $security->escapeJs($userInput);

// Échapper pour URL
$safe = $security->escapeUrl($userInput);
```

### Sanitization

```php
// Nettoyer une chaîne
$clean = $security->sanitizeString($input);

// Nettoyer un email
$clean = $security->sanitizeEmail($email);

// Nettoyer une URL
$clean = $security->sanitizeUrl($url);

// Nettoyer un tableau
$clean = $security->sanitizeArray($array);
```

---

## 💉 Protection SQL Injection

### Requêtes préparées

```php
// TOUJOURS utiliser des requêtes préparées
$stmt = $pdo->prepare("SELECT * FROM users WHERE email = ?");
$stmt->execute([$email]);
```

### Validation

```php
$validator = Validator::make($_POST);
$validator
    ->required('id')
    ->integer('id')
    ->exists('id', 'users', 'id', $pdo);
```

---

## 📁 Sécurité des fichiers

### Upload sécurisé

```php
$security = Security::getInstance();

// Valider l'upload
$result = $security->validateFileUpload(
    $_FILES['file'],
    ['image/jpeg', 'image/png'],
    5242880 // 5 MB
);

if (!$result['valid']) {
    die($result['message']);
}

// Générer un nom de fichier sécurisé
$filename = $security->generateSecureFilename($_FILES['file']['name']);
```

### Protection des fichiers sensibles

Le fichier `.htaccess` bloque l'accès à :
- `.env`
- `composer.json/lock`
- `.git`
- Fichiers `.log`
- Fichiers `.config`
- Fichiers de backup

---

## ⚙️ Configuration

### Fichier de configuration

Éditer `app/config/security.php` pour personnaliser :

```php
return [
    'session' => [...],
    'password' => [...],
    'rate_limit' => [...],
    'csrf' => [...],
    'upload' => [...],
    'headers' => [...],
    '2fa' => [...],
    'audit' => [...],
    'features' => [...]
];
```

### Bootstrap

Le fichier `app/bootstrap/security.php` initialise toutes les mesures de sécurité automatiquement.

### Inclusion dans votre application

```php
require_once __DIR__ . '/app/bootstrap/security.php';

// Toutes les protections sont maintenant actives
```

---

## 🔍 Audit et logging

### Événements audités

- Connexions/Déconnexions
- Créations/Modifications/Suppressions d'utilisateurs
- Changements de permissions
- Tentatives de connexion échouées
- Modifications de paramètres

### Configuration

```php
'audit' => [
    'enabled' => true,
    'retention_days' => 90,
    'events' => [
        'user_login' => true,
        'user_logout' => true,
        'failed_login' => true
    ]
]
```

---

## 🚀 Checklist de déploiement

Avant le déploiement en production :

- [ ] Activer HTTPS
- [ ] Configurer les headers de sécurité
- [ ] Activer le rate limiting
- [ ] Configurer les logs d'audit
- [ ] Tester la protection CSRF
- [ ] Valider la politique de mots de passe
- [ ] Configurer les restrictions IP si nécessaire
- [ ] Activer la 2FA pour les admins
- [ ] Vérifier les permissions des fichiers
- [ ] Mettre à jour les secrets et clés
- [ ] Tester le système de session
- [ ] Configurer les backups automatiques

---

## 📞 Support

Pour toute question de sécurité, contactez l'équipe de développement.

**Version :** 1.0  
**Date :** 19 novembre 2025  
**Projet :** Bolt.DIY User Manager
