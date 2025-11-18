# Cahier des charges – Bolt.DIY User Manager

**Projet:** BOLT.DIY-INTRANET  
**Module:** User Manager  
**Version:** 1.0  
**Date:** 18 novembre 2025  
**Auteur:** Nbility - Seysses, France

---

## 1. Contexte et objectifs

Bolt.DIY User Manager est un module de gestion et d'authentification des utilisateurs intégré au projet Dockerisé open‑source **BOLT.DIY-INTRANET**, reposant sur Nginx, PHP et une base de données type MariaDB.

Aujourd'hui, la page affichée après authentification mélange un fond animé moderne avec un contenu HTML non stylé, ce qui nuit à la lisibilité et à l'image professionnelle de la solution.

**L'objectif** de ce cahier des charges est de définir une interface d'administration moderne, cohérente avec la page de login existante et adaptée à un usage en entreprise, tout en restant simple à maintenir et à déployer.

### Objectifs spécifiques

- Créer une interface d'administration intuitive avec menu latéral et zone de contenu
- Assurer la cohérence visuelle avec la page de login existante (fond "IA 2025")
- Garantir une expérience responsive (mobile, tablette, desktop)
- Implémenter un module de configuration SMTP avec test intégré
- Respecter les bonnes pratiques de sécurité (sessions, CSRF, XSS)
- Faciliter la maintenance via une architecture modulaire

---

## 2. Environnement technique et contraintes

### Architecture Docker

L'interface devra fonctionner dans l'architecture Docker actuelle décrite dans le dépôt **BOLT.DIY-INTRANET** :

- **Nginx** en frontal (reverse proxy + authentification)
- Conteneur **PHP/Bolt** en backend
- Stockage persistant via volumes **DATA-LOCAL**
- Base de données **MariaDB** pour la gestion des utilisateurs

### Structure des URLs

Les pages du module User Manager seront servies sous le préfixe `/user-manager` :

```
http://VOTRE_IP:8080/user-manager/
```

### ⚠️ CONTRAINTE CRITIQUE : URLs absolues

**Tous les liens vers les ressources statiques** (CSS, JS, images) devront **impérativement** utiliser des URLs absolues :

✅ **CORRECT :**
```html
<link rel="stylesheet" href="/user-manager/assets/css/style.css">
<script src="/user-manager/assets/js/app.js"></script>
<img src="/user-manager/assets/img/logo.png">
```

❌ **INTERDIT :**
```html
<link rel="stylesheet" href="assets/css/style.css">
<script src="assets/js/app.js"></script>
```

**Raison :** Les URLs relatives provoquent des erreurs de chargement lorsque l'utilisateur navigue dans des sous-répertoires ou via des règles de réécriture Nginx.

### Stack technique

- **Frontend:** HTML5, CSS3 (Flexbox/Grid), JavaScript ES6+
- **Backend:** PHP 8.x
- **Base de données:** MariaDB 10.x
- **Bibliothèques JS:** Chart.js (graphiques), Font Awesome (icônes)
- **Serveur:** Nginx + PHP-FPM
- **Conteneurisation:** Docker & Docker Compose

---

## 3. Exigences UX / UI globales

### Identité visuelle

L'interface devra reprendre le **fond animé "IA 2025"** déjà en place sur la page de connexion :

- Dégradés bleu/violet/cyan
- Halos colorés animés (`bg-glow`)
- Points lumineux flottants (`bg-dot`)
- Animation douce et fluide

### Style des composants

**Effet verre (glassmorphism) :**
- Fond sombre semi‑transparent (`rgba(26, 32, 53, 0.85)`)
- Coins arrondis (`border-radius: 16px`)
- Ombres douces (`box-shadow`)
- Bordure subtile (`border: 1px solid rgba(255, 255, 255, 0.1)`)

**Typographie :**
- Police principale : **Inter** / **Segoe UI**
- Hiérarchie claire : H1 (32px), H2 (24px), H3 (18px), corps (16px)
- Couleurs : blanc (#fff) pour titres, gris clair (#e0e0e0) pour textes

**Palette de couleurs :**
- Primaire : `#4776ff` (bleu)
- Succès : `#32ffe2` (cyan)
- Warning : `#fff748` (jaune)
- Danger : `#fd65ff` (magenta)
- Neutre : `#9c56ff` (violet)

---

## 4. Layout général de la page

### Structure en 3 zones

```
┌──────────────────────────────────────────────┐
│            Topbar (optionnelle)              │
├────────────┬─────────────────────────────────┤
│            │                                 │
│  Sidebar   │     Zone de contenu             │
│  (menu)    │     (Dashboard, Users, etc.)    │
│            │                                 │
│            │                                 │
└────────────┴─────────────────────────────────┘
```

### Zones principales

1. **Sidebar gauche (fixe)** : Navigation principale
2. **Topbar (optionnelle)** : Recherche, notifications, profil utilisateur
3. **Zone de contenu (main)** : Affichage des écrans selon l'entrée de menu

### Responsive behavior

| Écran | Comportement |
|-------|--------------|
| **Desktop (>1200px)** | Sidebar visible en permanence |
| **Tablette (768-1199px)** | Sidebar rétractable avec icônes |
| **Mobile (<768px)** | Sidebar cachée, bouton hamburger |

---

## 5. Navigation et menu latéral

### Structure du menu

**En-tête de la sidebar :**
- Logo/icône "User Manager"
- Titre "User Manager"
- Badge version (optionnel)

**Entrées de menu principales :**

| Icône | Label | Destination |
|-------|-------|-------------|
| `fa-home` | Dashboard | `/user-manager/` |
| `fa-users` | Utilisateurs | `/user-manager/users` |
| `fa-layer-group` | Groupes | `/user-manager/groups` |
| `fa-shield-alt` | Permissions | `/user-manager/permissions` |
| `fa-clipboard-list` | Audit | `/user-manager/audit` |
| `fa-cog` | Paramètres | `/user-manager/settings` |

**Section Raccourcis (en bas) :**
- `fa-plus-circle` "Nouvel utilisateur"
- `fa-calendar` "Programmer export"

### État actif

L'élément de menu actif sera identifié par :
- Fond de couleur (`background: rgba(71, 118, 255, 0.2)`)
- Bordure gauche (`border-left: 3px solid #4776ff`)
- Icône/texte en couleur primaire

### Interactions

- Survol : légère augmentation de luminosité
- Clic : transition fluide (150ms)
- Mobile : fermeture automatique après sélection

---

## 6. Contenu de la zone Dashboard

### Vue d'ensemble

Le Dashboard affiche un résumé de l'activité et des statistiques clés.

### Tuiles statistiques (4 cartes)

```
┌──────────────┬──────────────┬──────────────┬──────────────┐
│ Utilisateurs │   Actifs     │   Groupes    │ Permissions  │
│     142      │     128      │      8       │     24       │
│    +12%      │     +8%      │     0%       │     0%       │
└──────────────┴──────────────┴──────────────┴──────────────┘
```

**Détails par carte :**

1. **Total Utilisateurs**
   - Icône : `fa-users`
   - Couleur : primaire (#4776ff)
   - Évolution : pourcentage par rapport au mois précédent

2. **Utilisateurs Actifs**
   - Icône : `fa-user-check`
   - Couleur : succès (#32ffe2)
   - Évolution : activité 7 derniers jours

3. **Groupes**
   - Icône : `fa-layer-group`
   - Couleur : warning (#fff748)
   - Nombre total de groupes

4. **Permissions**
   - Icône : `fa-shield-alt`
   - Couleur : neutre (#9c56ff)
   - Nombre de permissions configurées

### Graphiques (Chart.js)

**Graphique 1 : Activité utilisateurs (ligne)**
- Axe X : 7 ou 30 derniers jours
- Axe Y : Nombre de connexions
- Légende : 7 jours / 30 jours (toggle)

**Graphique 2 : Répartition par rôle (donut)**
- Segments : Admin, Utilisateur, Invité, etc.
- Pourcentages affichés
- Couleurs cohérentes avec la palette

### Activité récente (liste)

- Derniers 5 événements
- Icône selon type (connexion, création, modification)
- Horodatage relatif ("il y a 5 min")
- Lien vers l'Audit complet

---

## 7. Sections Utilisateurs, Groupes et Permissions

### 7.1 Section Utilisateurs

#### Vue liste

**Affichage tableau responsive :**

| Avatar | Nom d'utilisateur |        Email       |   Rôle   |   Statut   |   Actions   |
|--------|-------------------|--------------------|----------|------------|-------------|
|   👤   |       admin       |    admin@bolt.diy  |    Admin |    Actif   |     ⚙️ 🗑️     |
|   👤   |      jdoe         |   john@example.com |    User  |    Actif   |     ⚙️ 🗑️     |

**Colonnes :**
- Avatar (initiales ou photo)
- Nom d'utilisateur
- Email
- Rôle (badge coloré)
- Statut (badge Actif/Inactif)
- Actions (modifier, désactiver, supprimer)

**En-tête de section :**
- Titre "Utilisateurs"
- Bouton "➕ Nouvel Utilisateur"
- Barre de recherche
- Filtres (rôle, statut)

#### Modale de création/modification

**Champs du formulaire :**

```
┌─────────────────────────────────────┐
│  Nouvel Utilisateur            ❌    │
├─────────────────────────────────────┤
│                                     │
│  Nom d'utilisateur *                │
│  ┌───────────────────────────────┐  │
│  │                               │  │
│  └───────────────────────────────┘  │
│                                     │
│  Email *                            │
│  ┌───────────────────────────────┐  │
│  │                               │  │
│  └───────────────────────────────┘  │
│                                     │
│  Prénom                             │
│  ┌───────────────────────────────┐  │
│  │                               │  │
│  └───────────────────────────────┘  │
│                                     │
│  Nom                                │
│  ┌───────────────────────────────┐  │
│  │                               │  │
│  └───────────────────────────────┘  │
│                                     │
│  Rôle *                             │
│  ┌───────────────────────────────┐  │
│  │ Utilisateur            ▼      │  │
│  └───────────────────────────────┘  │
│                                     │
│  Mot de passe *                     │
│  ┌───────────────────────────────┐  │
│  │                          👁️   │  │
│  └───────────────────────────────┘  │
│                                     │
│  ┌─────────┐  ┌──────────────────┐  │
│  │ Annuler │  │ ✓ Créer          │  │
│  └─────────┘  └──────────────────┘  │
└─────────────────────────────────────┘
```

**Validations :**
- Nom d'utilisateur : 3-32 caractères, alphanumériques
- Email : format valide
- Mot de passe : min 8 caractères, complexité (majuscule, chiffre, symbole)
- Rôle : sélection obligatoire

**Style des champs :**
- Labels flottants (comme page de login)
- Effet focus avec bordure colorée
- Messages d'erreur en rouge sous le champ

### 7.2 Section Groupes

**Fonctionnalités similaires aux utilisateurs :**
- Liste des groupes (nom, description, nombre de membres)
- Création/modification via modale
- Actions : éditer, supprimer
- Affectation d'utilisateurs au groupe

### 7.3 Section Permissions

**Affichage :**
- Liste des permissions (nom, ressource, action)
- Matrice Rôle × Permission (lecture seule ou éditable)
- Actions : créer, modifier, supprimer

---

## 8. Section Audit et activité récente

### Vue Audit complète

**Liste chronologique d'événements :**

|    Horodatage    |   Utilisateur   |      Événement       |     Détails     |      IP      |
|------------------|-----------------|----------------------|-----------------|--------------|
| 2025-11-18 18:30 |      admin      |   Connexion réussie  |       -         | 192.168.1.10 |
| 2025-11-18 18:25 |      jdoe       | Création utilisateur | bob@example.com | 192.168.1.15 |
| 2025-11-18 18:20 |      admin      | Modification rôle    |   jdoe → Admin  | 192.168.1.10 |

**Types d'événements :**
- 🔓 Connexion réussie
- 🚫 Échec de connexion
- ➕ Création utilisateur
- ✏️ Modification utilisateur
- 🗑️ Suppression utilisateur
- 🔒 Déconnexion
- ⚙️ Changement de configuration

### Filtres

**Par période :**
- Boutons : 24h, 7 jours, 30 jours, Personnalisé

**Par type :**
- Menu déroulant : Tous, Connexions, CRUD, Config

**Par utilisateur :**
- Recherche/filtre par nom d'utilisateur

### Pagination

- 50 entrées par page
- Navigation précédent/suivant
- Saut de page

---

## 9. Module de configuration SMTP

### Accès

- Menu : Paramètres → Messagerie SMTP
- Lien direct depuis le Dashboard (optionnel)

### Formulaire de configuration

```
┌────────────────────────────────────────────┐
│  Configuration Serveur SMTP                │
├────────────────────────────────────────────┤
│                                            │
│  Hôte SMTP *                               │
│  ┌──────────────────────────────────────┐  │
│  │ smtp.example.com                     │  │
│  └──────────────────────────────────────┘  │
│                                            │
│  Port *                                    │
│  ┌──────────────────────────────────────┐  │
│  │ 587                                  │  │
│  └──────────────────────────────────────┘  │
│                                            │
│  Sécurité *                                │
│  ┌──────────────────────────────────────┐  │
│  │ TLS                          ▼       │  │
│  └──────────────────────────────────────┘  │
│  (Aucun / TLS / SSL)                       │
│                                            │
│  Nom d'utilisateur *                       │
│  ┌──────────────────────────────────────┐  │
│  │ user@example.com                     │  │
│  └──────────────────────────────────────┘  │
│                                            │
│  Mot de passe *                            │
│  ┌──────────────────────────────────────┐  │
│  │ •••••••••••••••                  👁️  │  │
│  └──────────────────────────────────────┘  │
│                                            │
│  Expéditeur par défaut *                   │
│  ┌──────────────────────────────────────┐  │
│  │ noreply@bolt.diy                     │  │
│  └──────────────────────────────────────┘  │
│                                            │
│  Nom de l'expéditeur                       │
│  ┌──────────────────────────────────────┐  │
│  │ Bolt.DIY User Manager                │  │
│  └──────────────────────────────────────┘  │
│                                            │
│  ┌────────────────┐  ┌─────────────────┐   │
│  │ 🧪 Tester      │  │ ✓ Enregistrer   │   │
│  └────────────────┘  └─────────────────┘   │
└────────────────────────────────────────────┘
```

### Champs obligatoires (*)

1. **Hôte SMTP** : nom du serveur (ex: smtp.gmail.com)
2. **Port** : 25, 465, 587, 2525
3. **Sécurité** : None, TLS, SSL (menu déroulant)
4. **Nom d'utilisateur** : identifiant de connexion
5. **Mot de passe** : avec bouton œil pour afficher/masquer
6. **Expéditeur par défaut** : email utilisé comme From

### Options avancées (repliable)

- Timeout de connexion (secondes)
- Encodage (UTF-8, ISO-8859-1)
- Authentification (Auto, Plain, Login, CRAM-MD5)

### Stockage de la configuration

**Fichier de configuration :**
- Emplacement : `DATA-LOCAL/user-manager/config/smtp.json`
- Format : JSON chiffré (mot de passe)
- Permissions : lecture seule par PHP

**Alternative : base de données**
- Table `smtp_config`
- Chiffrement du mot de passe (AES-256)

---

## 10. Bouton de test SMTP et API associée

### Fonctionnement du bouton "Tester"

**Workflow :**

```
┌────────────┐
│ Utilisateur│
│  clique    │
│  "Tester"  │
└─────┬──────┘
      │
      ▼
┌──────────────────┐
│ app.js           │
│ - Valide form    │
│ - Affiche loader │
│ - Appel AJAX     │
└─────┬────────────┘
      │
      ▼
┌────────────────────────────┐
│ /user-manager/api/         │
│ test-smtp.php              │
│ - Lit config               │
│ - Initialise PHPMailer     │
│ - Envoie email de test     │
│ - Retourne JSON            │
└─────┬──────────────────────┘
      │
      ▼
┌──────────────────┐
│ app.js           │
│ - Cache loader   │
│ - Affiche toast  │
│   (succès/échec) │
└──────────────────┘
```

### Endpoint API : `/user-manager/api/test-smtp.php`

**Requête (POST) :**
```json
{
  "host": "smtp.gmail.com",
  "port": 587,
  "security": "tls",
  "username": "user@gmail.com",
  "password": "app_password",
  "from_email": "noreply@bolt.diy",
  "from_name": "Bolt.DIY",
  "test_recipient": "admin@bolt.diy"
}
```

**Réponse (succès) :**
```json
{
  "success": true,
  "message": "Email de test envoyé avec succès à admin@bolt.diy",
  "details": {
    "server": "smtp.gmail.com:587",
    "security": "TLS",
    "time": "0.85s"
  }
}
```

**Réponse (échec) :**
```json
{
  "success": false,
  "error": "Authentification SMTP échouée",
  "details": {
    "code": 535,
    "message": "Username and Password not accepted",
    "suggestions": [
      "Vérifier le nom d'utilisateur et le mot de passe",
      "Activer l'accès aux applications moins sécurisées",
      "Générer un mot de passe d'application"
    ]
  }
}
```

### Service PHP : `SmtpTestService.php`

**Logique :**
```php
class SmtpTestService {
    public function testConnection($config) {
        // 1. Validation des paramètres
        // 2. Initialisation PHPMailer
        // 3. Configuration serveur SMTP
        // 4. Envoi email de test
        // 5. Capture exceptions
        // 6. Retour résultat formaté
    }
}
```

### Affichage du résultat (toast)

**Toast succès :**
- Icône : ✓
- Couleur : vert (#32ffe2)
- Message : "Configuration SMTP valide !"
- Durée : 5 secondes

**Toast échec :**
- Icône : ✗
- Couleur : rouge (#fd65ff)
- Message : "Erreur : [message détaillé]"
- Bouton "Détails" ouvrant une modale

---

## 11. Exigences de sécurité

### 11.1 Authentification et sessions

**Vérification systématique :**
```php
session_start();
if (empty($_SESSION['user_logged']) || empty($_SESSION['username'])) {
    header('Location: /user-manager/login.php');
    exit;
}
```

**Configuration de session sécurisée :**
```php
ini_set('session.cookie_httponly', 1);
ini_set('session.cookie_secure', 1);
ini_set('session.cookie_samesite', 'Strict');
session_set_cookie_params([
    'lifetime' => 3600,
    'path' => '/user-manager',
    'secure' => true,
    'httponly' => true,
    'samesite' => 'Strict'
]);
```

**Déconnexion :**
- Destruction complète de la session
- Suppression des cookies
- Redirection vers login

### 11.2 Protection CSRF

**Génération du token :**
```php
if (empty($_SESSION['csrf_token'])) {
    $_SESSION['csrf_token'] = bin2hex(random_bytes(32));
}
```

**Injection dans le HTML :**
```html
<meta name="csrf-token" content="<?= $_SESSION['csrf_token'] ?>">
```

**Vérification côté serveur :**
```php
if ($_POST['csrf_token'] !== $_SESSION['csrf_token']) {
    http_response_code(403);
    die('Invalid CSRF token');
}
```

**Intégration AJAX :**
```javascript
const csrfToken = document.querySelector('meta[name="csrf-token"]').content;

fetch('/user-manager/api/endpoint', {
    method: 'POST',
    headers: {
        'Content-Type': 'application/json',
        'X-CSRF-Token': csrfToken
    },
    body: JSON.stringify(data)
});
```

### 11.3 Protection XSS

**Échappement systématique :**
```php
// Affichage de données utilisateur
echo htmlspecialchars($username, ENT_QUOTES, 'UTF-8');

// Insertion dans attributs HTML
echo '<div data-user="' . htmlspecialchars($user, ENT_QUOTES) . '">';
```

**Content Security Policy (CSP) :**
```php
header("Content-Security-Policy: default-src 'self'; script-src 'self' 'unsafe-inline' cdn.jsdelivr.net cdnjs.cloudflare.com; style-src 'self' 'unsafe-inline' cdnjs.cloudflare.com; img-src 'self' data: https:;");
```

### 11.4 Validation des entrées

**Côté client (JavaScript) :**
- Formats, longueurs, types
- Feedback immédiat

**Côté serveur (PHP) :**
- Validation stricte de toutes les entrées
- Filtres adaptés (FILTER_VALIDATE_EMAIL, etc.)
- Reject par défaut (whitelist)

### 11.5 Gestion des mots de passe

**Stockage :**
```php
$hashedPassword = password_hash($password, PASSWORD_ARGON2ID);
```

**Vérification :**
```php
if (password_verify($inputPassword, $hashedPassword)) {
    // Authentification réussie
}
```

**Politique de mot de passe :**
- Minimum 8 caractères
- Au moins 1 majuscule
- Au moins 1 chiffre
- Au moins 1 caractère spécial

### 11.6 Permissions et rôles

**Contrôle d'accès basé sur les rôles (RBAC) :**
```php
function hasPermission($requiredRole) {
    $userRole = $_SESSION['user_role'] ?? 'guest';
    $hierarchy = ['guest' => 0, 'user' => 1, 'admin' => 2];
    return $hierarchy[$userRole] >= $hierarchy[$requiredRole];
}
```

**Vérification avant chaque action sensible :**
```php
if (!hasPermission('admin')) {
    http_response_code(403);
    die('Access denied');
}
```

---

## 12. Responsiveness et accessibilité

### 12.1 Breakpoints responsive

```css
/* Mobile first */
.container {
    padding: 16px;
}

/* Tablette */
@media (min-width: 768px) {
    .container {
        padding: 24px;
    }
    .sidebar {
        width: 80px; /* Icônes seules */
    }
}

/* Desktop */
@media (min-width: 1200px) {
    .container {
        padding: 32px;
    }
    .sidebar {
        width: 260px; /* Pleine largeur */
    }
}
```

### 12.2 Comportements adaptatifs

**Mobile (<768px) :**
- Sidebar cachée par défaut
- Bouton hamburger dans topbar
- Cartes en colonne unique
- Tableaux scrollables horizontalement
- Graphiques redimensionnés

**Tablette (768-1199px) :**
- Sidebar rétractable (icônes seules)
- Cartes en grille 2 colonnes
- Tableaux adaptés

**Desktop (>1200px) :**
- Sidebar pleine largeur permanente
- Grille 4 colonnes pour les cartes
- Tableaux complets

### 12.3 Accessibilité (WCAG 2.1 AA)

**Contrastes :**
- Texte normal : ratio 4.5:1 minimum
- Gros texte : ratio 3:1 minimum
- Utiliser des outils comme WebAIM Contrast Checker

**Navigation au clavier :**
```css
*:focus {
    outline: 2px solid #4776ff;
    outline-offset: 2px;
}

/* Skip to content */
.skip-link {
    position: absolute;
    top: -40px;
    left: 0;
}
.skip-link:focus {
    top: 0;
}
```

**Attributs ARIA :**
```html
<nav aria-label="Menu principal">
    <a href="/dashboard" aria-current="page">Dashboard</a>
</nav>

<button aria-label="Ouvrir le menu" aria-expanded="false">
    <i class="fas fa-bars" aria-hidden="true"></i>
</button>

<div role="alert" aria-live="polite">
    Configuration enregistrée avec succès
</div>
```

**Labels pour icônes :**
```html
<button aria-label="Modifier l'utilisateur">
    <i class="fas fa-edit" aria-hidden="true"></i>
</button>
```

**Ordre de tabulation logique :**
- Menu → Contenu → Actions
- Skip link pour passer le menu

---

## 13. Architecture des fichiers à créer

### Arborescence complète

```
BOLT.DIY-INTRANET/
└── DATA-LOCAL/
    └── user-manager/
        ├── app/
        │   ├── public/                    # Point d'entrée web
        │   │   ├── index.php             # Dashboard principal
        │   │   ├── login.php             # Page de connexion (existant)
        │   │   ├── logout.php            # Script de déconnexion
        │   │   │
        │   │   ├── assets/
        │   │   │   ├── css/
        │   │   │   │   ├── style.css     # Styles communs + login (existant)
        │   │   │   │   ├── dashboard.css # Styles dashboard
        │   │   │   │   └── responsive.css # Media queries
        │   │   │   │
        │   │   │   ├── js/
        │   │   │   │   ├── app.js        # Logique globale
        │   │   │   │   ├── dashboard.js  # Graphiques Dashboard
        │   │   │   │   ├── users.js      # Gestion utilisateurs
        │   │   │   │   ├── smtp.js       # Config SMTP
        │   │   │   │   └── api.js        # Appels API centralisés
        │   │   │   │
        │   │   │   └── img/
        │   │   │       ├── logo.svg
        │   │   │       └── icons/
        │   │   │
        │   │   └── api/                  # Endpoints API
        │   │       ├── users.php         # CRUD utilisateurs
        │   │       ├── groups.php        # CRUD groupes
        │   │       ├── permissions.php   # CRUD permissions
        │   │       ├── audit.php         # Récupération logs
        │   │       ├── test-smtp.php     # Test config SMTP
        │   │       └── settings.php      # Sauvegarde paramètres
        │   │
        │   └── src/                      # Code source PHP
        │       ├── config/
        │       │   ├── config.php        # Configuration globale
        │       │   ├── database.php      # Connexion BDD
        │       │   └── smtp.php          # Lecture/écriture config SMTP
        │       │
        │       ├── controllers/
        │       │   ├── DashboardController.php
        │       │   ├── UserController.php
        │       │   ├── GroupController.php
        │       │   ├── PermissionController.php
        │       │   ├── AuditController.php
        │       │   └── SettingsController.php
        │       │
        │       ├── models/
        │       │   ├── User.php
        │       │   ├── Group.php
        │       │   ├── Permission.php
        │       │   └── AuditLog.php
        │       │
        │       ├── services/
        │       │   ├── AuthService.php       # Gestion authentification
        │       │   ├── SmtpTestService.php   # Test config SMTP
        │       │   ├── ValidationService.php # Validations
        │       │   └── LogService.php        # Enregistrement logs
        │       │
        │       └── templates/
        │           ├── layout/
        │           │   ├── base.php          # Layout principal
        │           │   ├── sidebar.php       # Menu latéral
        │           │   └── topbar.php        # Barre supérieure
        │           │
        │           ├── dashboard/
        │           │   └── home.php          # Vue dashboard
        │           │
        │           ├── users/
        │           │   ├── list.php          # Liste utilisateurs
        │           │   └── form.php          # Formulaire utilisateur
        │           │
        │           ├── groups/
        │           │   ├── list.php
        │           │   └── form.php
        │           │
        │           ├── permissions/
        │           │   └── list.php
        │           │
        │           ├── audit/
        │           │   └── list.php
        │           │
        │           └── settings/
        │               └── smtp.php          # Config SMTP
        │
        ├── config/                       # Fichiers de configuration
        │   ├── smtp.json                # Config SMTP (chiffrée)
        │   └── .env.example             # Exemple de variables
        │
        └── logs/                         # Logs applicatifs
            ├── access.log
            ├── error.log
            └── audit.log
```

### Description des répertoires

**`app/public/`** : Racine web accessible par Nginx
- Tous les fichiers directement accessibles via HTTP
- Contient les assets statiques (CSS, JS, images)
- Points d'entrée PHP (index.php, login.php, API)

**`app/src/`** : Code source PHP (non accessible web)
- Controllers : logique de contrôle
- Models : représentation des entités
- Services : logique métier réutilisable
- Templates : vues HTML/PHP

**`config/`** : Fichiers de configuration
- Hors de la racine web pour sécurité
- Configurations SMTP, BDD, paramètres globaux

**`logs/`** : Fichiers de logs
- Séparés par type (accès, erreur, audit)
- Rotation automatique recommandée

---

## 14. Bonnes pratiques de développement et déploiement

### 14.1 Standards de code

**PHP :**
- Suivre PSR-12 (coding style)
- Utiliser des namespaces
- Typage strict : `declare(strict_types=1);`
- Documentation PHPDoc

**JavaScript :**
- ES6+ (const/let, arrow functions, modules)
- Éviter `var`
- Conventions de nommage : camelCase

**CSS :**
- Méthodologie BEM pour les classes
- Variables CSS pour les couleurs/espacements
- Mobile-first

### 14.2 Gestion des dépendances

**PHP (Composer) :**
```json
{
    "require": {
        "phpmailer/phpmailer": "^6.8",
        "vlucas/phpdotenv": "^5.5"
    }
}
```

**JavaScript (CDN ou npm) :**
- Chart.js
- Font Awesome

### 14.3 Centralisation des URLs

**Dans `base.php` (layout) :**
```php
<?php
define('BASE_URL', '/user-manager');
define('ASSETS_URL', BASE_URL . '/assets');
?>

<link rel="stylesheet" href="<?= ASSETS_URL ?>/css/style.css">
<script src="<?= ASSETS_URL ?>/js/app.js"></script>
```

**Fonction helper :**
```php
function asset($path) {
    return '/user-manager/assets/' . ltrim($path, '/');
}

// Usage
<link rel="stylesheet" href="<?= asset('css/style.css') ?>">
```

### 14.4 Tests dans l'environnement Docker

**Commandes essentielles :**
```bash
# Démarrer les conteneurs
cd BOLT.DIY-INTRANET
docker compose up -d

# Vérifier l'état
docker compose ps

# Voir les logs
docker compose logs -f bolt-nbility-nginx
docker compose logs -f bolt-nbility-core

# Redémarrer après modifications
docker compose restart bolt-nbility-nginx

# Arrêter
docker compose down
```

**Tests fonctionnels :**
1. Vérifier l'accès : `http://VOTRE_IP:8080/user-manager/`
2. Tester le chargement des assets (CSS/JS)
3. Vérifier l'authentification
4. Tester chaque fonctionnalité (CRUD, SMTP, etc.)

### 14.5 Logs et débogage

**Configuration PHP (development) :**
```php
error_reporting(E_ALL);
ini_set('display_errors', 1);
ini_set('log_errors', 1);
ini_set('error_log', '/app/logs/error.log');
```

**Configuration PHP (production) :**
```php
error_reporting(E_ALL);
ini_set('display_errors', 0);
ini_set('log_errors', 1);
ini_set('error_log', '/app/logs/error.log');
```

**Logs applicatifs :**
```php
function logAudit($action, $details = []) {
    $log = [
        'timestamp' => date('Y-m-d H:i:s'),
        'user' => $_SESSION['username'] ?? 'anonymous',
        'ip' => $_SERVER['REMOTE_ADDR'],
        'action' => $action,
        'details' => $details
    ];
    file_put_contents(
        '/app/logs/audit.log',
        json_encode($log) . PHP_EOL,
        FILE_APPEND
    );
}
```

### 14.6 Documentation du module

**README.md dans `user-manager/` :**
```markdown
# Bolt.DIY User Manager

## Installation
...

## Structure des fichiers
...

## Configuration
...

## Maintenance
...

## Dépannage
...
```

**Documentation inline :**
- Commenter les fonctions complexes
- Documenter les endpoints API
- Expliquer les choix techniques

---

## 15. Livrables attendus

### Phase 1 : Interface de base

✅ Layout principal avec sidebar et zone de contenu
✅ Page Dashboard avec tuiles statistiques
✅ Section Utilisateurs (liste + modale)
✅ Intégration du fond animé "IA 2025"
✅ Responsive mobile/tablette/desktop

### Phase 2 : Fonctionnalités avancées

✅ Sections Groupes et Permissions
✅ Section Audit avec filtres
✅ Module de configuration SMTP
✅ Bouton de test SMTP fonctionnel
✅ Graphiques Dashboard (Chart.js)

### Phase 3 : Sécurité et finitions

✅ Protection CSRF sur tous les formulaires
✅ Validation stricte côté serveur
✅ Gestion des rôles et permissions
✅ Tests en environnement Docker
✅ Documentation complète

---

## 16. Planning prévisionnel

| Phase | Durée estimée | Priorité |
|-------|---------------|----------|
| **Phase 1** : Interface de base | 2-3 jours | Haute |
| **Phase 2** : Fonctionnalités | 3-4 jours | Haute |
| **Phase 3** : Sécurité/Tests | 2-3 jours | Critique |
| **Documentation** | 1 jour | Moyenne |
| **Total** | **8-11 jours** | - |

---

## 17. Critères de réussite

### Technique

- ✅ Tous les liens utilisent des URLs absolues `/user-manager/...`
- ✅ Aucune erreur 404 sur les assets
- ✅ Sessions sécurisées et protection CSRF active
- ✅ Responsive sur tous les supports
- ✅ Graphiques Dashboard fonctionnels
- ✅ Test SMTP opérationnel avec retour d'erreur explicite

### UX/UI

- ✅ Interface cohérente avec la page de login
- ✅ Navigation intuitive
- ✅ Feedback immédiat sur les actions (toasts)
- ✅ Temps de chargement < 2 secondes

### Sécurité

- ✅ Authentification requise sur toutes les pages
- ✅ Protection XSS et CSRF
- ✅ Mots de passe chiffrés (Argon2id)
- ✅ Logs d'audit complets

---

## 18. Maintenance et évolution

### Maintenance préventive

- Mise à jour régulière des dépendances PHP (Composer)
- Surveillance des logs d'erreur
- Backup régulier de la base de données
- Rotation des logs applicatifs

### Évolutions futures possibles

1. **Authentification 2FA** (TOTP)
2. **Gestion des sessions actives** (liste, révocation)
3. **Export CSV/Excel** des utilisateurs
4. **Import en masse** via CSV
5. **API REST complète** pour intégrations tierces
6. **Thèmes personnalisables** (dark/light)
7. **Notifications push** (WebSocket)
8. **Intégration LDAP/SSO**

---

## 19. Contacts et support

**Projet:** BOLT.DIY-INTRANET  
**Repository:** https://github.com/NBILITY-HOME/BOLT.DIY-INTRANET  
**Développeur:** Nbility - Seysses, France  
**Date:** 18 novembre 2025

Pour toute question ou problème, consulter :
- Les issues GitHub du projet
- La documentation dans le repository
- Les logs applicatifs dans `DATA-LOCAL/user-manager/logs/`

---

## 20. Validation du cahier des charges

Ce cahier des charges a été établi le **18 novembre 2025** pour guider le développement complet de l'interface Bolt.DIY User Manager.

**Approuvé par :**  
- [ ] Chef de projet
- [ ] Développeur frontend
- [ ] Développeur backend
- [ ] Responsable sécurité

**Date de validation :** ________________

---

**FIN DU CAHIER DES CHARGES**
