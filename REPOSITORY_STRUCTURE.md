# 📁 ARBORESCENCE DU REPOSITORY GITHUB
## BOLT.DIY-DOCKER-LOCAL

```
BOLT.DIY-DOCKER-LOCAL/                    ← Repository GitHub (Private)
├── README.md                             ← Documentation principale du projet
├── LICENSE                               ← Licence du projet
├── .gitignore                            ← Fichiers à ignorer par Git
│
├── DATA-LOCAL/                           ← 🎯 TOUS LES FICHIERS DE CONFIGURATION
│   ├── docker-compose.yml                ← Configuration Docker Compose
│   ├── Dockerfile                        ← Image Docker pour User Manager
│   │
│   ├── nginx/                            ← Configuration Nginx
│   │   └── nginx.conf                    ← Configuration du reverse proxy
│   │
│   ├── templates/                        ← Templates HTML à personnaliser
│   │   ├── index.html                    ← Template page normale (Bolt opérationnel)
│   │   ├── index-maintenance.html        ← Template page maintenance (Bolt hors ligne)
│   │   ├── 404.html                      ← Template page d'erreur élégante
│   │   └── README.txt                    ← Documentation des templates
│   │
│   ├── user-manager/                     ← Application de gestion des utilisateurs
│   │   └── app/
│   │       └── index.php                 ← Interface PHP de gestion
│   │
│   └── htpasswd-manager/                 ← Contexte de construction (vide, créé automatiquement)
│
└── scripts/                              ← Scripts d'installation
    └── install_bolt_nbility_v3.sh        ← 🆕 NOUVEAU SCRIPT avec authentification GitHub
```

---

## 🔄 FLUX D'INSTALLATION

### 1️⃣ Installation Initiale

```bash
# L'utilisateur télécharge seulement le script
wget https://raw.githubusercontent.com/NBILITY-HOME/BOLT.DIY-DOCKER-LOCAL/main/scripts/install_bolt_nbility_v3.sh
chmod +x install_bolt_nbility_v3.sh
./install_bolt_nbility_v3.sh
```

### 2️⃣ Le Script Effectue

1. **Vérification de la connexion GitHub**
   - Teste l'accès au repository privé
   - Si échec → Demande login/password
   - Stocke les credentials cryptés en SHA-256 dans `.github_credentials`

2. **Récupération des fichiers**
   - Clone ou met à jour le repository
   - Copie `DATA-LOCAL/` → `DATA/` (dans le répertoire local)

3. **Configuration interactive**
   - Demande les paramètres (IP, ports, etc.)
   - Génère le fichier `.env`
   - Génère le fichier `.htpasswd`
   - Personnalise les templates HTML

4. **Lancement**
   - Clone `bolt.diy` depuis StackBlitz
   - Démarre les conteneurs Docker

---

## 📂 ARBORESCENCE LOCALE APRÈS INSTALLATION

```
/MON_PROJET_RACINE/                       ← Répertoire local de travail
├── install_bolt_nbility_v3.sh            ← Script téléchargé
├── .github_credentials                   ← 🔐 Credentials GitHub cryptés (SHA-256)
├── BOLT.DIY-DOCKER-LOCAL/                ← Repository cloné (mis en cache)
│   └── DATA-LOCAL/                       ← Fichiers sources du repository
│
├── DATA/                                 ← 📋 Copie locale des fichiers de configuration
│   ├── docker-compose.yml
│   ├── Dockerfile
│   ├── nginx/
│   │   ├── nginx.conf
│   │   ├── .htpasswd                     ← Généré par le script
│   │   └── html/                         ← Généré depuis templates
│   │       ├── index.html                ← Page active (personnalisée)
│   │       ├── 404.html                  ← Page d'erreur (personnalisée)
│   │       └── index-maintenance-backup.html ← Backup maintenance
│   ├── templates/                        ← Templates sources (copiés depuis repo)
│   ├── user-manager/
│   └── htpasswd-manager/
│
└── bolt.diy/                             ← Clone de StackBlitz (automatique)
    ├── .env                              ← Généré par le script
    └── ...
```

---

## 🔑 FICHIER .github_credentials

**Format du fichier** :
```bash
# Stocké dans : ./.github_credentials
GITHUB_USER_HASH=<sha256_du_username>
GITHUB_TOKEN_HASH=<sha256_du_token_ou_password>
GITHUB_USER_ENCRYPTED=<username_encodé_base64>
GITHUB_TOKEN_ENCRYPTED=<token_encodé_base64>
```

**Sécurité** :
- Fichier en permissions 600 (lecture/écriture propriétaire uniquement)
- Hash SHA-256 pour vérification d'intégrité
- Encodage Base64 pour stockage
- Ajouté automatiquement au .gitignore

---

## 📝 FICHIERS À CRÉER DANS LE REPOSITORY

### Fichiers obligatoires :
1. ✅ `README.md` - Documentation du projet
2. ✅ `DATA-LOCAL/docker-compose.yml` - Configuration Docker
3. ✅ `DATA-LOCAL/Dockerfile` - Image User Manager
4. ✅ `DATA-LOCAL/nginx/nginx.conf` - Config Nginx
5. ✅ `DATA-LOCAL/templates/index.html` - Template page normale
6. ✅ `DATA-LOCAL/templates/index-maintenance.html` - Template maintenance
7. ✅ `DATA-LOCAL/templates/404.html` - Template erreur
8. ✅ `DATA-LOCAL/templates/README.txt` - Doc templates
9. ✅ `DATA-LOCAL/user-manager/app/index.php` - Interface User Manager
10. ✅ `scripts/install_bolt_nbility_v3.sh` - Nouveau script
11. ✅ `.gitignore` - Fichiers à ignorer

### Fichiers générés localement (NE PAS COMMITER) :
- `.github_credentials` - Credentials cryptés
- `DATA/nginx/.htpasswd` - Fichier d'authentification
- `DATA/nginx/html/*` - Pages HTML générées
- `bolt.diy/.env` - Configuration Bolt.DIY
- `bolt.diy/*` - Code source Bolt.DIY

---

## 🚀 AVANTAGES DE CETTE STRUCTURE

✅ **Séparation claire** : Configuration (repository) vs Exécution (local)  
✅ **Sécurité renforcée** : Credentials cryptés en SHA-256  
✅ **Facilité de mise à jour** : Un simple `git pull` met à jour tous les fichiers  
✅ **Traçabilité** : Toute modification est versionnée dans Git  
✅ **Portabilité** : Installation sur n'importe quel serveur avec le même script  
✅ **Maintenance simplifiée** : Modifications centralisées dans le repository  

---

## 📌 NOTES IMPORTANTES

1. **Le repository est PRIVATE** : Nécessite une authentification GitHub
2. **Un seul script à distribuer** : `install_bolt_nbility_v3.sh`
3. **Credentials stockés localement** : Pas besoin de re-saisir à chaque fois
4. **Mise à jour automatique** : Le script peut détecter et appliquer les updates
5. **Compatible avec les anciennes installations** : Migration possible

