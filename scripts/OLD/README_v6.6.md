# 📦 SCRIPT BOLT.DIY v6.6 - INSTRUCTIONS D'ASSEMBLAGE

## 🐛 Corrections v6.6

**Problème résolu:** Erreur de syntaxe `line 398: syntax error near unexpected token '('`

**Cause:** Les commandes `read -p "$(echo -e ...)"` ne fonctionnent pas en bash.

**Solution:** Remplacement par `echo -ne + read` séparés.

## 📁 Fichiers fournis

8 fichiers à assembler:

1. `install_bolt_nbility_v6.6_part1.sh` - Header, variables, fonctions (255 lignes)
2. `install_bolt_nbility_v6.6_part2.sh` - Configuration interactive **CORRIGÉE** (183 lignes)
3. `install_bolt_nbility_v6.6_part3.sh` - docker-compose.yml (142 lignes)
4. `install_bolt_nbility_v6.6_part4.sh` - nginx.conf (172 lignes)
5. `install_bolt_nbility_v6.6_part5.sh` - Dockerfiles, .env (148 lignes)
6. `install_bolt_nbility_v6.6_part6.sh` - SQL schema + seed (385 lignes)
7. `install_bolt_nbility_v6.6_part7.sh` - User Manager, htpasswd (212 lignes)
8. `install_bolt_nbility_v6.6_part8.sh` - Build, tests, résumé (154 lignes)

**Total: ~1651 lignes**

## 🔧 Assemblage

### Méthode automatique (recommandée)

```bash
chmod +x assemble_v6.6.sh
./assemble_v6.6.sh
```

### Méthode manuelle

```bash
cat install_bolt_nbility_v6.6_part*.sh > install_bolt_nbility_v6.6.sh
chmod +x install_bolt_nbility_v6.6.sh
```

## ✅ Vérification

```bash
# Vérifier les 8 fichiers
ls -lh install_bolt_nbility_v6.6_part*.sh

# Vérifier le script assemblé
head -n 5 install_bolt_nbility_v6.6.sh
# Doit commencer par: #!/bin/bash

# Compter les lignes
wc -l install_bolt_nbility_v6.6.sh
# Doit afficher environ 1651 lignes
```

## 🚀 Installation

```bash
# Lancer le script (SANS sudo !)
./install_bolt_nbility_v6.6.sh
```

## 📋 Prérequis

- Docker (v20.10+)
- Docker Compose (v2.0+)
- Git
- curl
- htpasswd (apache2-utils)

Installation (Debian/Ubuntu):
```bash
sudo apt-get update
sudo apt-get install -y docker.io docker-compose git curl apache2-utils
sudo usermod -aG docker $USER
newgrp docker
```

## 🎯 Nouveautés v6.6

✅ **Correction syntaxe read -p**
✅ Génération docker-compose.yml automatique
✅ Génération nginx.conf avec préservation du port
✅ Dockerfile User Manager (PHP 8.2 + Apache)
✅ Configuration .env Bolt complète
✅ Tests post-installation
✅ Résumé détaillé

## 📞 Support

**Email:** contact@nbility.fr
**GitHub:** https://github.com/NBILITY-HOME/BOLT.DIY-INTRANET

---

**© Nbility 2025**
