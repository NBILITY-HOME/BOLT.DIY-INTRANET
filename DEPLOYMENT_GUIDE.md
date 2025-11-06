# 📦 GUIDE DE DÉPLOIEMENT - BOLT.DIY NBILITY v3.0

## 🎯 Objectif

Ce guide explique comment déployer tous les fichiers dans le repository GitHub et comment migrer depuis une installation existante (v2.x).

---

## 📂 FICHIERS À PLACER DANS LE REPOSITORY GITHUB

### 🔴 OBLIGATOIRES - Racine du repository

```
BOLT.DIY-DOCKER-LOCAL/
├── README.md                           ✅ Documentation principale
├── LICENSE                             ✅ Licence du projet
├── .gitignore                          ✅ Exclusions Git
└── CHANGELOG.md                        ⚠️  À créer (historique des versions)
```

**Actions :**
1. Créer le repository sur GitHub (privé)
2. Copier `README.md` à la racine
3. Copier `.gitignore` à la racine
4. Créer `LICENSE` avec votre licence propriétaire
5. Créer `CHANGELOG.md` avec l'historique

---

### 🔴 OBLIGATOIRES - DATA-LOCAL/

```
DATA-LOCAL/
├── docker-compose.yml                  ✅ Configuration Docker Compose
├── Dockerfile                          ✅ Image User Manager
├── nginx/
│   └── nginx.conf                      ✅ Configuration Nginx
├── templates/
│   ├── index.html                      ✅ Template page normale
│   ├── index-maintenance.html          ✅ Template maintenance
│   ├── 404.html                        ✅ Template erreur
│   └── README.txt                      ✅ Documentation templates
└── user-manager/
    └── app/
        └── index.php                   ✅ Interface User Manager
```

**Actions :**
1. Créer la structure de dossiers
2. Copier TOUS les fichiers de configuration actuels
3. Vérifier que les templates utilisent bien les placeholders

---

### 🔴 OBLIGATOIRES - scripts/

```
scripts/
└── install_bolt_nbility_v3.sh          ✅ Script d'installation
```

**Actions :**
1. Créer le dossier `scripts/`
2. Copier le nouveau script v3.0
3. Rendre le script exécutable :
   ```bash
   chmod +x scripts/install_bolt_nbility_v3.sh
   ```

---

## 🚀 PROCÉDURE DE DÉPLOIEMENT COMPLÈTE

### Étape 1 : Créer le repository GitHub

```bash
# Sur GitHub.com
1. Allez sur https://github.com/NBILITY-HOME
2. Cliquez sur "New repository"
3. Nom : BOLT.DIY-DOCKER-LOCAL
4. Visibilité : Private (IMPORTANT !)
5. Cochez "Add a README file"
6. Créez le repository
```

### Étape 2 : Cloner le repository localement

```bash
# Sur votre machine locale
cd ~/projects
git clone https://github.com/NBILITY-HOME/BOLT.DIY-DOCKER-LOCAL.git
cd BOLT.DIY-DOCKER-LOCAL
```

### Étape 3 : Créer la structure complète

```bash
# Créer tous les dossiers
mkdir -p DATA-LOCAL/nginx
mkdir -p DATA-LOCAL/templates
mkdir -p DATA-LOCAL/user-manager/app
mkdir -p DATA-LOCAL/htpasswd-manager
mkdir -p scripts
```

### Étape 4 : Copier tous les fichiers

```bash
# Fichiers racine
cp /chemin/vers/README.md ./
cp /chemin/vers/.gitignore ./
echo "© Copyright Nbility 2025 - Proprietary License" > LICENSE

# Scripts
cp /chemin/vers/install_bolt_nbility_v3.sh scripts/
chmod +x scripts/install_bolt_nbility_v3.sh

# DATA-LOCAL
cp /chemin/vers/docker-compose.yml DATA-LOCAL/
cp /chemin/vers/Dockerfile DATA-LOCAL/
cp /chemin/vers/nginx.conf DATA-LOCAL/nginx/

# Templates
cp /chemin/vers/index.html DATA-LOCAL/templates/
cp /chemin/vers/index-maintenance.html DATA-LOCAL/templates/
cp /chemin/vers/404.html DATA-LOCAL/templates/
cp /chemin/vers/templates-README.txt DATA-LOCAL/templates/README.txt

# User Manager
cp /chemin/vers/index.php DATA-LOCAL/user-manager/app/
```

### Étape 5 : Vérifier les placeholders dans les templates

```bash
# Vérifier que les templates contiennent bien les placeholders
grep -r "{{LOCAL_IP}}" DATA-LOCAL/templates/
grep -r "{{HOST_PORT_HTTP}}" DATA-LOCAL/templates/
grep -r "{{HOST_PORT_UM}}" DATA-LOCAL/templates/
grep -r "{{PROTOCOL}}" DATA-LOCAL/templates/

# Si ces commandes ne renvoient rien, vous devez remplacer
# les valeurs en dur par les placeholders !
```

### Étape 6 : Créer le CHANGELOG.md

```bash
cat > CHANGELOG.md << 'EOF'
# Changelog

Tous les changements notables de ce projet seront documentés dans ce fichier.

## [3.0.0] - 2025-11-06

### Ajouté
- Authentification GitHub avec credentials cryptés SHA-256
- Gestion automatique du repository privé
- Séparation configuration (GitHub) / exécution (local)
- Documentation complète du projet
- Guide de migration depuis v2.x

### Modifié
- Structure du projet complètement réorganisée
- Script d'installation entièrement refactorisé
- Amélioration de la sécurité globale

### Sécurité
- Stockage sécurisé des credentials GitHub
- Chiffrement SHA-256 + encodage Base64
- Vérification d'intégrité automatique

## [2.6.0] - 2025-10-XX

### Ajouté
- Templates HTML personnalisables
- Mode maintenance
- Génération automatique des pages

## [2.0.0] - 2025-09-XX

### Ajouté
- Installation interactive
- User Manager
- Docker Compose

## [1.0.0] - 2025-08-XX

### Ajouté
- Première version du projet
EOF
```

### Étape 7 : Premier commit et push

```bash
# Ajouter tous les fichiers
git add .

# Vérifier ce qui sera commité
git status

# Commiter
git commit -m "🎉 Initial commit - Bolt.DIY Nbility v3.0

- Structure complète du projet
- Scripts d'installation avec authentification GitHub
- Documentation complète
- Templates HTML personnalisables
- Configuration Docker Compose
"

# Pousser vers GitHub
git push origin main
```

---

## 🔄 MIGRATION DEPUIS v2.x

Si vous avez déjà une installation Bolt.DIY v2.x :

### Option 1 : Migration propre (Recommandé)

```bash
# 1. Sauvegarder votre configuration actuelle
cd /votre/installation/actuelle
cp .env ~/backup_bolt_env
cp DATA/nginx/.htpasswd ~/backup_htpasswd

# 2. Arrêter les services actuels
docker compose down

# 3. Déplacer l'installation actuelle
cd ..
mv votre_installation votre_installation_backup

# 4. Créer un nouveau dossier
mkdir votre_installation_nouvelle
cd votre_installation_nouvelle

# 5. Télécharger le nouveau script
wget https://raw.githubusercontent.com/NBILITY-HOME/BOLT.DIY-DOCKER-LOCAL/main/scripts/install_bolt_nbility_v3.sh
chmod +x install_bolt_nbility_v3.sh

# 6. Lancer l'installation
./install_bolt_nbility_v3.sh

# 7. Restaurer vos clés API (optionnel)
# Éditez bolt.diy/.env et copiez vos clés depuis le backup
```

### Option 2 : Migration sur place (Avancé)

```bash
# 1. Sauvegarder
cp -r . ../backup_$(date +%Y%m%d)

# 2. Télécharger le nouveau script
wget https://raw.githubusercontent.com/NBILITY-HOME/BOLT.DIY-DOCKER-LOCAL/main/scripts/install_bolt_nbility_v3.sh
chmod +x install_bolt_nbility_v3.sh

# 3. Arrêter les services
docker compose down

# 4. Supprimer l'ancien script et DATA
rm install_bolt_nbility.sh
rm -rf DATA

# 5. Lancer la nouvelle installation
./install_bolt_nbility_v3.sh
```

---

## ✅ CHECKLIST DE VÉRIFICATION

Avant de considérer le déploiement comme terminé :

### Repository GitHub

- [ ] Le repository est créé et configuré en PRIVÉ
- [ ] Tous les fichiers sont présents dans le repository
- [ ] La structure de dossiers est correcte
- [ ] Les templates contiennent les placeholders
- [ ] Le README.md est complet et à jour
- [ ] Le .gitignore exclut les fichiers sensibles
- [ ] Le script d'installation est exécutable

### Tests locaux

- [ ] Le script peut cloner le repository
- [ ] L'authentification GitHub fonctionne
- [ ] Les fichiers sont correctement copiés
- [ ] Les templates sont correctement générés
- [ ] Les placeholders sont remplacés
- [ ] Docker Compose démarre sans erreur
- [ ] Bolt.DIY est accessible
- [ ] User Manager est accessible
- [ ] L'authentification Nginx fonctionne

### Documentation

- [ ] Le README principal est clair
- [ ] Les templates ont leur documentation
- [ ] Le CHANGELOG est à jour
- [ ] Les exemples fonctionnent
- [ ] Les liens sont corrects

---

## 🐛 DÉPANNAGE DU DÉPLOIEMENT

### Erreur : "Permission denied" lors du push

**Solution :**
```bash
# Configurer SSH pour GitHub
ssh-keygen -t ed25519 -C "your_email@example.com"
eval "$(ssh-agent -s)"
ssh-add ~/.ssh/id_ed25519

# Ajouter la clé sur GitHub :
# https://github.com/settings/keys
```

### Erreur : "Repository not found"

**Solution :**
```bash
# Vérifier l'URL du repository
git remote -v

# Corriger si nécessaire
git remote set-url origin https://github.com/NBILITY-HOME/BOLT.DIY-DOCKER-LOCAL.git
```

### Les placeholders ne fonctionnent pas

**Solution :**
```bash
# Vérifier la syntaxe exacte dans les templates
# CORRECT : {{LOCAL_IP}}
# INCORRECT : {{ LOCAL_IP }} ou {LOCAL_IP} ou $LOCAL_IP

# Remplacer manuellement si nécessaire
sed -i 's/192.168.1.200/{{LOCAL_IP}}/g' DATA-LOCAL/templates/index.html
```

---

## 📞 SUPPORT

Pour toute question sur le déploiement :

- 📧 Email : contact@nbility.fr
- 🌐 Website : https://nbility.fr
- 📝 GitHub Issues : https://github.com/NBILITY-HOME/BOLT.DIY-DOCKER-LOCAL/issues

---

## 🎉 FÉLICITATIONS !

Si vous avez suivi toutes les étapes, votre repository est maintenant prêt !

Prochaine étape : Tester l'installation sur un nouveau serveur pour valider
que tout fonctionne correctement.

---

**© Copyright Nbility 2025**
