# Bolt.DIY User Manager

Module de gestion et d'authentification des utilisateurs pour BOLT.DIY-INTRANET.

## Version 1.0 - Niveau 2 Complété

**Date:** 18 novembre 2025  
**Développé par:** Nbility - Seysses, France

---

## 📋 Ce qui a été implémenté

### ✅ Niveau 1 : Structure de base et assets CSS/JS
- Architecture complète des dossiers
- Fond animé "IA 2025" avec glassmorphism
- Fichier CSS complet (1100+ lignes)
- Fichier JavaScript avec utilitaires (600+ lignes)

### ✅ Niveau 2 : Layout principal et navigation
- Template de base PHP avec sidebar et topbar
- Système de navigation complet et responsive
- Routing simple basé sur les URLs
- Configuration centralisée
- Helpers PHP (300+ lignes)
- Gestion des messages flash
- Menu hamburger mobile
- Protection Apache (.htaccess)

---

## 📁 Structure du projet

```
user-manager/
├── app/
│   ├── public/                      # Racine web accessible
│   │   ├── index.php               # Point d'entrée principal ✅
│   │   ├── .htaccess               # Configuration Apache ✅
│   │   ├── assets/
│   │   │   ├── css/
│   │   │   │   └── style.css       # Styles complets ✅
│   │   │   ├── js/
│   │   │   │   └── app.js          # JavaScript ✅
│   │   │   └── img/
│   │   └── api/                     # API REST (futur)
│   └── src/
│       ├── Controllers/             # Contrôleurs (futur)
│       ├── Models/                  # Modèles (futur)
│       ├── Services/                # Services (futur)
│       ├── Templates/
│       │   └── base.php            # Template principal ✅
│       └── helpers.php              # Fonctions utilitaires ✅
├── config/
│   └── config.php                   # Configuration ✅
└── logs/                            # Fichiers de logs
```

---

## 🚀 Installation

### Prérequis

- **PHP 8.0+**
- **Apache 2.4+** avec mod_rewrite activé
- **MariaDB 10.x** (pour les niveaux futurs)
- **Docker** (optionnel, pour déploiement containerisé)

### Étapes d'installation

1. **Extraire l'archive** dans le dossier approprié :
   ```bash
   unzip user-manager-niveau2.zip -d /chemin/vers/web/
   ```

2. **Configurer Apache** pour servir l'application sous `/user-manager` :
   ```apache
   Alias /user-manager /chemin/vers/user-manager/app/public
   <Directory /chemin/vers/user-manager/app/public>
       AllowOverride All
       Require all granted
   </Directory>
   ```

3. **Vérifier les permissions** :
   ```bash
   chmod -R 755 user-manager/
   chmod -R 777 user-manager/logs/
   ```

4. **Accéder à l'application** :
   ```
   http://votre-domaine.com/user-manager/
   ```

---

## 🎯 URLs disponibles

| URL | Page | Statut |
|-----|------|--------|
| `/user-manager/` | Dashboard | ✅ Layout prêt |
| `/user-manager/users` | Utilisateurs | ✅ Layout prêt |
| `/user-manager/groups` | Groupes | ✅ Layout prêt |
| `/user-manager/permissions` | Permissions | ✅ Layout prêt |
| `/user-manager/audit` | Audit | ✅ Layout prêt |
| `/user-manager/settings` | Paramètres | ✅ Layout prêt |

*Note : Les contenus des pages seront développés aux niveaux 3-7.*

---

## 🎨 Caractéristiques de l'interface

### Design
- **Fond animé "IA 2025"** : Halos colorés et points lumineux
- **Glassmorphism** : Effet verre sur tous les composants
- **Palette moderne** : Bleu (#4776ff), Cyan (#32ffe2), Magenta (#fd65ff)
- **Responsive** : Mobile, tablette et desktop

### Navigation
- **Sidebar fixe** (280px) avec menu complet
- **Topbar** avec recherche, notifications et profil
- **Menu mobile** avec hamburger et overlay
- **6 sections principales** + 2 raccourcis

### Fonctionnalités JavaScript
- Système de notifications Toast
- Gestion des modales
- Validation de formulaires
- Utilitaires (debounce, throttle, formatage)
- API helper pour requêtes AJAX

---

## ⚙️ Configuration

### Fichier config/config.php

Personnalisez les constantes selon votre environnement :

```php
// URLs
define('BASE_URL', '/user-manager');

// Base de données
define('DB_HOST', 'localhost');
define('DB_NAME', 'user_manager');
define('DB_USER', 'root');
define('DB_PASS', '');

// Environnement
define('APP_ENV', 'development'); // production, development
define('APP_DEBUG', true);

// SMTP (pour niveau 7)
define('SMTP_HOST', 'smtp.example.com');
define('SMTP_PORT', 587);
```

---

## 🔧 Helpers PHP disponibles

### URLs et Assets
- `asset($path)` - URL vers un asset
- `url($path)` - URL de l'application
- `redirect_to($path)` - Redirection

### Sécurité
- `csrf_token()` - Générer token CSRF
- `csrf_field()` - Champ formulaire CSRF
- `e($string)` - Échapper HTML
- `is_logged_in()` - Vérifier authentification

### Vues
- `view($template, $data)` - Inclure une vue
- `render($template, $data)` - Rendre une vue
- `layout($template, $data)` - Utiliser le layout

### Messages flash
- `flash_success($msg)` - Message de succès
- `flash_error($msg)` - Message d'erreur
- `flash_warning($msg)` - Message d'avertissement
- `flash_info($msg)` - Message d'information

### Formatage
- `format_date($date)` - Formater une date
- `format_relative_date($date)` - Date relative
- `format_number($number)` - Formater un nombre
- `format_file_size($bytes)` - Taille de fichier

---

## 🎓 Utilisation

### Créer une nouvelle page

1. **Ajouter la route** dans `config/config.php` :
   ```php
   $routes = [
       'ma-page' => 'ma_page',
   ];
   ```

2. **Ajouter au menu** dans `config/config.php` :
   ```php
   $navigation['main'][] = [
       'id' => 'ma-page',
       'icon' => 'fa-star',
       'label' => 'Ma Page',
       'url' => BASE_URL . '/ma-page',
   ];
   ```

3. **Créer le template** `src/Templates/ma_page.php` :
   ```php
   <div class="glass-card">
       <h1>Ma Page</h1>
       <p>Contenu de ma page...</p>
   </div>
   ```

4. **Accéder** : `http://votre-site.com/user-manager/ma-page`

---

## 🔒 Sécurité

### Implémenté
- ✅ Protection XSS (échappement HTML)
- ✅ En-têtes de sécurité HTTP
- ✅ Protection des fichiers sensibles
- ✅ Désactivation de l'indexation
- ✅ CSRF tokens (helpers prêts)

### À implémenter (niveaux futurs)
- 🔲 Authentification complète
- 🔲 Validation CSRF sur formulaires
- 🔲 Hash des mots de passe (Argon2id)
- 🔲 Rate limiting
- 🔲 Logs d'audit

---

## 📊 Statistiques du code

| Fichier | Lignes | Description |
|---------|--------|-------------|
| `style.css` | 1100+ | Styles complets + animations |
| `app.js` | 600+ | JavaScript + utilitaires |
| `helpers.php` | 350+ | Fonctions PHP |
| `config.php` | 180+ | Configuration |
| `base.php` | 250+ | Template principal |
| `index.php` | 120+ | Point d'entrée |
| **TOTAL** | **2600+** | Lignes de code |

---

## 🐛 Dépannage

### Erreur 404 sur toutes les pages
- Vérifiez que `mod_rewrite` est activé dans Apache
- Vérifiez le fichier `.htaccess` dans `app/public/`
- Vérifiez la directive `AllowOverride All` dans la configuration Apache

### Assets (CSS/JS) non chargés
- Vérifiez que les URLs utilisent le préfixe `/user-manager/`
- Vérifiez les permissions des fichiers (755)
- Consultez la console du navigateur (F12)

### Page blanche
- Activez `display_errors` dans `config.php`
- Vérifiez les logs : `logs/error.log`
- Vérifiez les permissions du dossier `logs/` (777)

---

## 🚀 Prochaines étapes

### Niveau 3 : Page Dashboard (prochainement)
- Tuiles statistiques avec données réelles
- Graphiques Chart.js (activité, répartition)
- Activité récente
- API de données

### Niveaux 4-7 : Fonctionnalités complètes
- Gestion CRUD des utilisateurs
- Gestion des groupes et permissions
- Journal d'audit avec filtres
- Configuration SMTP avec test
- Sécurité complète (CSRF, sessions)

---

## 📞 Support

**Repository :** https://github.com/NBILITY-HOME/BOLT.DIY-INTRANET  
**Documentation :** Consultez les fichiers `.md` du projet  
**Logs :** Vérifiez `logs/error.log` et `logs/app.log`

---

## 📝 Licence

Ce projet fait partie de BOLT.DIY-INTRANET développé par Nbility.

**Version actuelle :** 1.0 (Niveau 2 complété)  
**Dernière mise à jour :** 18 novembre 2025
