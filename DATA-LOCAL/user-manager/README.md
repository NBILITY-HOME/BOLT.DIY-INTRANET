# User Manager - BOLT.DIY Intranet

Système de gestion des utilisateurs, groupes et permissions pour BOLT.DIY Intranet.

## 📋 Table des matières

- [Fonctionnalités](#fonctionnalités)
- [Architecture](#architecture)
- [Installation](#installation)
- [Configuration](#configuration)
- [Structure](#structure)
- [API Endpoints](#api-endpoints)
- [Développement](#développement)
- [Maintenance](#maintenance)

---

## ✨ Fonctionnalités

### Gestion des utilisateurs
- ✅ CRUD complet (Create, Read, Update, Delete)
- ✅ Authentification sécurisée (sessions + CSRF)
- ✅ Gestion des rôles (user, admin, superadmin)
- ✅ Statuts (active, inactive, suspended)
- ✅ Actions en masse (activation, désactivation, suppression)
- ✅ Export CSV

### Gestion des groupes
- ✅ Création et édition de groupes
- ✅ Affectation d'utilisateurs
- ✅ Attribution de permissions par groupe
- ✅ Vue détaillée (membres + permissions)

### Gestion des permissions
- ✅ Permissions granulaires par catégorie
- ✅ Attribution directe ou via groupes
- ✅ Vérification runtime des permissions
- ✅ Affichage conditionnel selon rôle/permission

### Logs d'audit
- ✅ Traçabilité complète des actions
- ✅ Timeline interactive
- ✅ Filtrage avancé (date, action, utilisateur)
- ✅ Export des logs

### Dashboard
- ✅ Statistiques en temps réel
- ✅ Graphiques (rôles, statuts, activité)
- ✅ Activité récente
- ✅ Informations système

---

## 🏗️ Architecture

### Stack technique
- **Backend**: PHP 8.1+ (pur, sans framework)
- **Frontend**: HTML5, CSS3, JavaScript (Vanilla)
- **Base de données**: MySQL 8.0+
- **Conteneurisation**: Docker + Docker Compose

### Pattern MVC
```
app/
├── index.php (Routeur)
├── config/ (Configuration)
├── src/
│   ├── Controllers/ (Logique métier)
│   ├── Models/ (Entités + ORM)
│   ├── Middleware/ (Auth, CSRF, Rate limit)
│   └── Utils/ (Helpers)
└── public/ (Frontend)
```

---

## 🚀 Installation

### Prérequis
- Docker & Docker Compose
- Git

### Étapes

1. **Cloner le repository**
```bash
git clone https://github.com/NBILITY-HOME/BOLT.DIY-INTRANET.git
cd BOLT.DIY-INTRANET/DATA-LOCAL/user-manager
```

2. **Configurer l'environnement**
```bash
cp .env.example .env
nano .env  # Adapter les valeurs
```

3. **Lancer les conteneurs**
```bash
docker-compose up -d
```

4. **Initialiser la base de données**
Les migrations SQL sont exécutées automatiquement au démarrage.

5. **Accéder à l'interface**
```
http://localhost:8080/user-manager
```

**Compte par défaut:**
- Username: `admin`
- Password: `admin123`

⚠️ **Changez le mot de passe par défaut immédiatement !**

---

## ⚙️ Configuration

### Fichier .env

```env
# Database
DB_HOST=user-manager-db
DB_PORT=3306
DB_NAME=user_manager
DB_USER=user_manager
DB_PASSWORD=changeme

# Security
JWT_SECRET=your-secret-key-here
SESSION_LIFETIME=3600
CSRF_TOKEN_LIFETIME=3600

# Rate Limiting
RATE_LIMIT_REQUESTS=100
RATE_LIMIT_WINDOW=60

# Logging
LOG_LEVEL=info
LOG_FILE=/var/log/user-manager/app.log
```

---

## 📁 Structure du projet

```
user-manager/
├── Dockerfile
├── php.ini
├── docker-compose.yml
├── .env.example
├── .gitignore
├── composer.json
├── README.md
└── app/
    ├── index.php
    ├── config/
    │   ├── database.php
    │   ├── security.php
    │   └── app.php
    ├── src/
    │   ├── Controllers/
    │   │   ├── AuthController.php
    │   │   ├── UserController.php
    │   │   ├── GroupController.php
    │   │   ├── PermissionController.php
    │   │   └── AuditController.php
    │   ├── Models/
    │   │   ├── User.php
    │   │   ├── Group.php
    │   │   ├── Permission.php
    │   │   └── AuditLog.php
    │   ├── Middleware/
    │   │   ├── AuthMiddleware.php
    │   │   ├── CsrfMiddleware.php
    │   │   └── RateLimitMiddleware.php
    │   └── Utils/
    │       ├── Response.php
    │       ├── Logger.php
    │       ├── Database.php
    │       └── Validator.php
    ├── public/
    │   ├── index.html
    │   ├── login.html
    │   ├── users.html
    │   ├── groups.html
    │   ├── permissions.html
    │   ├── audit.html
    │   └── assets/
    │       ├── css/
    │       │   └── style.css
    │       └── js/
    │           ├── api.js
    │           ├── auth.js
    │           ├── utils.js
    │           ├── login.js
    │           ├── dashboard.js
    │           ├── users.js
    │           ├── groups.js
    │           ├── permissions.js
    │           └── audit.js
    ├── scripts/
    │   ├── backup.sh
    │   └── maintenance.sh
    └── database/
        ├── migrations/
        │   ├── 01-schema.sql
        │   └── 02-seed.sql
        └── init.sql
```

---

## 🔌 API Endpoints

### Authentification
- `POST /auth/login` - Connexion
- `POST /auth/logout` - Déconnexion
- `GET /auth/me` - Utilisateur courant

### Utilisateurs
- `GET /users` - Liste des utilisateurs
- `GET /users/:id` - Détail d'un utilisateur
- `POST /users` - Créer un utilisateur
- `PUT /users/:id` - Modifier un utilisateur
- `DELETE /users/:id` - Supprimer un utilisateur
- `POST /users/bulk` - Actions en masse
- `GET /users/export` - Export CSV

### Groupes
- `GET /groups` - Liste des groupes
- `GET /groups/:id` - Détail d'un groupe
- `POST /groups` - Créer un groupe
- `PUT /groups/:id` - Modifier un groupe
- `DELETE /groups/:id` - Supprimer un groupe
- `GET /groups/:id/members` - Membres d'un groupe
- `POST /groups/:id/members` - Ajouter des membres
- `DELETE /groups/:id/members/:userId` - Retirer un membre
- `GET /groups/:id/permissions` - Permissions d'un groupe
- `POST /groups/:id/permissions` - Attribuer des permissions

### Permissions
- `GET /permissions` - Liste des permissions
- `GET /permissions/:id` - Détail d'une permission
- `POST /permissions` - Créer une permission
- `PUT /permissions/:id` - Modifier une permission
- `DELETE /permissions/:id` - Supprimer une permission

### Audit
- `GET /audit` - Logs d'audit
- `GET /audit/:id` - Détail d'un log
- `GET /audit/export` - Export CSV

### Dashboard
- `GET /dashboard/stats` - Statistiques
- `GET /dashboard/recent-activity` - Activité récente

---

## 🛠️ Développement

### Lancer en mode développement
```bash
docker-compose up
# Logs en temps réel
```

### Accéder aux logs
```bash
# Logs application
docker-compose logs -f user-manager-app

# Logs base de données
docker-compose logs -f user-manager-db
```

### Exécuter des commandes dans le conteneur
```bash
docker exec -it user-manager-app bash
```

---

## 🔧 Maintenance

### Backup automatique
```bash
# Exécuter le script de backup
./app/scripts/backup.sh

# Ajouter dans crontab (backup quotidien à 2h)
0 2 * * * /path/to/backup.sh
```

### Maintenance de la base
```bash
# Exécuter le script de maintenance
./app/scripts/maintenance.sh

# Ajouter dans crontab (maintenance hebdomadaire dimanche 3h)
0 3 * * 0 /path/to/maintenance.sh
```

### Restaurer un backup
```bash
# Restaurer depuis un fichier SQL
docker exec -i user-manager-db mysql -uuser_manager -pchangeme user_manager < backup.sql
```

---

## 🔐 Sécurité

### Protection CSRF
Toutes les requêtes POST/PUT/DELETE nécessitent un token CSRF valide.

### Rate Limiting
- 100 requêtes par minute par IP
- Configurable via `.env`

### Sessions
- Durée: 1 heure (configurable)
- Stockage: Base de données
- Nettoyage automatique des sessions expirées

### Mots de passe
- Hashage: bcrypt
- Politique: 8 caractères minimum

---

## 📝 Licence

© 2025 Nbility - Tous droits réservés

---

## 👥 Support

- **Email**: contact@nbility.fr
- **GitHub Issues**: https://github.com/NBILITY-HOME/BOLT.DIY-INTRANET/issues
- **Documentation**: https://github.com/NBILITY-HOME/BOLT.DIY-INTRANET/wiki

---

## 🚀 Roadmap

- [ ] Authentification 2FA
- [ ] Import CSV utilisateurs
- [ ] Notifications email
- [ ] API REST complète avec authentification JWT
- [ ] Interface responsive mobile
- [ ] Thèmes personnalisables
- [ ] Multi-langue (i18n)
