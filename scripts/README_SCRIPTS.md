# BOLT.DIY Nbility v7.0 - Structure Modulaire

## 📦 Fichiers

### Scripts modulaires (à éditer)
- `install_bolt_v7.0_part1.sh` - Header + Fonctions utilitaires (~250 lignes)
- `install_bolt_v7.0_part2.sh` - Configuration + Clone + Vérification (~400 lignes)
- `install_bolt_v7.0_part3.sh` - Docker Compose + Nginx (~300 lignes)
- `install_bolt_v7.0_part4.sh` - Dockerfile + Health + ENV (~250 lignes)
- `install_bolt_v7.0_part5.sh` - Base de données SQL (~200 lignes)
- `install_bolt_v7.0_part6.sh` - Build + Summary (~150 lignes)

### Scripts générés
- `install_bolt_v7.0.sh` - Script final assemblé (généré automatiquement)
- `assemble.sh` - Script d'assemblage

## 🔧 Utilisation

### 1. Assembler le script
```bash
./assemble.sh
```

### 2. Lancer l'installation
```bash
./install_bolt_v7.0.sh
```

## ✏️ Modification

Pour modifier le script d'installation:

1. Éditez le fichier part concerné (ex: `install_bolt_v7.0_part3.sh`)
2. Relancez l'assemblage: `./assemble.sh`
3. Le nouveau `install_bolt_v7.0.sh` est généré

## 📊 Avantages de la structure modulaire

- ✅ Fichiers plus petits (150-400 lignes)
- ✅ Lisibilité améliorée
- ✅ Maintenance facilitée
- ✅ Historique Git plus clair
- ✅ Tests modulaires possibles

## 🎯 Structure du script final

```
install_bolt_v7.0.sh (~1700 lignes)
├── Header & Variables
├── Fonctions utilitaires
├── Configuration interactive
├── Clone & Vérification GitHub
├── Génération Docker (compose, nginx, dockerfile)
├── Configuration (.env, SQL, htpasswd)
└── Build & Summary
```

## 📝 Notes

- Le script final est généré automatiquement
- Ne pas éditer `install_bolt_v7.0.sh` directement
- Toujours passer par les fichiers parts

## 🚀 Repository

https://github.com/NBILITY-HOME/BOLT.DIY-INTRANET
