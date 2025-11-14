# 📦 SCRIPT D'INSTALLATION BOLT.DIY v6.5

## 🎯 Description

Script d'installation complet pour **Bolt.DIY Intranet Edition v6.5** avec :
- ✨ Docker Compose automatique
- ✨ NGINX reverse proxy avec préservation du port
- ✨ User Manager v2.0 (PHP 8.2 + Apache + MariaDB)
- ✨ Configuration complète des URLs et routing
- ✨ Tests et validation post-installation

## 📁 Fichiers fournis

Le script est découpé en 5 parties pour faciliter la transmission :

1. **install_bolt_nbility_v6.5_part1.sh** - Header, variables globales, fonctions utilitaires (273 lignes)
2. **install_bolt_nbility_v6.5_part2.sh** - Configuration interactive, docker-compose.yml (341 lignes)
3. **install_bolt_nbility_v6.5_part3.sh** - nginx.conf, Dockerfile User Manager, health.php (329 lignes)
4. **install_bolt_nbility_v6.5_part4.sh** - Fichiers .env, SQL (schema + seed), composer.json (679 lignes)
5. **install_bolt_nbility_v6.5_part5.sh** - HTML templates, Build Docker, Tests, Résumé (267 lignes)

**Total : ~1889 lignes**

## 🔧 Instructions d'assemblage

### Sur Linux/Mac :

```bash
# 1. Placer tous les fichiers part*.sh dans le même répertoire
cd /chemin/vers/les/fichiers

# 2. Assembler le script complet
cat install_bolt_nbility_v6.5_part1.sh \
    install_bolt_nbility_v6.5_part2.sh \
    install_bolt_nbility_v6.5_part3.sh \
    install_bolt_nbility_v6.5_part4.sh \
    install_bolt_nbility_v6.5_part5.sh > install_bolt_nbility_v6.5.sh

# 3. Rendre le script exécutable
chmod +x install_bolt_nbility_v6.5.sh

# 4. Vérifier le script
wc -l install_bolt_nbility_v6.5.sh
# Doit afficher environ 1889 lignes

# 5. Lancer l'installation
./install_bolt_nbility_v6.5.sh
```

### Sur Windows (Git Bash ou WSL) :

```bash
# Même commande que Linux
cat install_bolt_nbility_v6.5_part*.sh > install_bolt_nbility_v6.5.sh
chmod +x install_bolt_nbility_v6.5.sh
./install_bolt_nbility_v6.5.sh
```

## ✅ Vérification avant installation

```bash
# Vérifier que toutes les parties sont présentes
ls -lh install_bolt_nbility_v6.5_part*.sh

# Doit afficher 5 fichiers :
# install_bolt_nbility_v6.5_part1.sh
# install_bolt_nbility_v6.5_part2.sh
# install_bolt_nbility_v6.5_part3.sh
# install_bolt_nbility_v6.5_part4.sh
# install_bolt_nbility_v6.5_part5.sh

# Vérifier le contenu du script assemblé
head -n 5 install_bolt_nbility_v6.5.sh
# Doit commencer par : #!/bin/bash

tail -n 5 install_bolt_nbility_v6.5.sh
# Doit finir par : main
```

## 🚀 Lancement de l'installation

```bash
# Lancer le script (SANS sudo !)
./install_bolt_nbility_v6.5.sh
```

Le script va :
1. Vérifier les prérequis (Docker, Git, curl, etc.)
2. Vous demander les configurations (IP, ports, mots de passe)
3. Cloner le repository GitHub
4. Générer tous les fichiers de configuration
5. Créer la base de données MariaDB
6. Builder et démarrer les containers Docker
7. Tester les services
8. Afficher le résumé complet

## 📋 Prérequis

- **Docker** (v20.10+)
- **Docker Compose** (v2.0+)
- **Git** (v2.0+)
- **curl**
- **htpasswd** (apache2-utils)
- Connexion Internet
- Accès GitHub

Installation des prérequis (Debian/Ubuntu) :
```bash
sudo apt-get update
sudo apt-get install -y docker.io docker-compose git curl apache2-utils
```

## 🔑 Informations importantes

### Ports par défaut :
- **8585** : Bolt.DIY (application principale)
- **8686** : Page d'accueil HTML
- **8687** : User Manager
- **3306** : MariaDB (interne Docker)

### Services créés :
- `bolt-nginx` : Reverse proxy NGINX
- `bolt-core` : Application Bolt.DIY
- `bolt-home` : Page d'accueil statique
- `bolt-user-manager` : User Manager PHP
- `bolt-mariadb` : Base de données MariaDB

### Réseaux et volumes :
- Réseau : `bolt-network-app`
- Volumes : `bolt-nbility-data`, `mariadb-data`

## 🆘 Dépannage

### Le script ne se lance pas :
```bash
# Vérifier les permissions
ls -l install_bolt_nbility_v6.5.sh

# Doit afficher : -rwxr-xr-x

# Forcer les permissions
chmod +x install_bolt_nbility_v6.5.sh
```

### Erreur "Docker not found" :
```bash
# Installer Docker
sudo apt-get install docker.io docker-compose

# Ajouter votre utilisateur au groupe docker
sudo usermod -aG docker $USER
newgrp docker
```

### Erreur de build Docker :
```bash
# Nettoyer les images et conteneurs
docker system prune -a

# Relancer l'installation
./install_bolt_nbility_v6.5.sh
```

### Les ports sont déjà utilisés :
Le script détecte automatiquement les ports occupés et vous demandera d'en choisir d'autres.

## 📞 Support

- **Email** : contact@nbility.fr
- **Repository** : https://github.com/NBILITY-HOME/BOLT.DIY-INTRANET

## 📝 Changelog v6.5

### 🆕 Nouveautés :
- ✨ Génération automatique de `docker-compose.yml`
- ✨ Génération automatique de `nginx.conf` avec préservation du port
- ✨ Création du `Dockerfile` User Manager (PHP 8.2 + Apache)
- ✨ Configuration `.env` Bolt complète (APP_URL, VITE_BASE_URL, etc.)
- ✨ Création de `health.php` pour healthcheck Docker
- ✨ Validation et tests post-installation
- ✨ Diagnostic des problèmes de port automatique

### 🐛 Corrections :
- ✅ **Problème #1** : Admin Manager ne s'affiche plus (docker-compose manquant)
- ✅ **Problème #2** : Perte du port après login (headers NGINX manquants)

### 📈 Améliorations :
- Meilleurs messages d'erreur
- Validation de configuration
- Tests automatiques
- Résumé détaillé

## 📄 Licence

© Copyright Nbility 2025 - Tous droits réservés

---

**Bon déploiement ! 🚀**
