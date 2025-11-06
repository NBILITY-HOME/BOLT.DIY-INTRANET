DATA/
├── templates/              ← NOUVEAU DOSSIER
│   ├── index-normal.html          # Page quand Bolt fonctionne
│   ├── index-maintenance.html     # Page quand Bolt hors ligne  
│   ├── 404.html                   # Page d'erreur élégante
│   └── README.txt                 # Documentation des templates
```

**Explication :**
- Les templates sont les **modèles source** avec des placeholders
- Le script d'installation les copiera dans `DATA/nginx/html/`
- Il remplacera les placeholders par les vraies valeurs (IP, ports)

---

## 📄 **ARBORESCENCE.txt mise à jour**
```
═══════════════════════════════════════════════════════════════════════════
  📁 ARBORESCENCE BOLT.DIY NBILITY
═══════════════════════════════════════════════════════════════════════════

/MON_PROJET_RACINE/
├── install_bolt_nbility.sh      ← Script d'installation interactif
├── docker-compose.yml           ← Configuration Docker Compose
├── bolt.diy/                    ← Code source (cloné automatiquement)
│   ├── .env                     ← Généré automatiquement par le script
│   └── ...
└── DATA/                        ← Répertoire des configurations
    ├── Dockerfile               ← Dockerfile pour bolt-user-manager
    ├── htpasswd-manager/        ← Contexte de construction
    ├── nginx/                   ← Configuration Nginx
    │   ├── nginx.conf           ← Configuration du serveur web
    │   ├── .htpasswd            ← Généré automatiquement par le script
    │   └── html/                ← Pages HTML statiques (générées)
    │       ├── index.html       ← Page active (copiée depuis templates)
    │       └── 404.html         ← Page d'erreur (copiée depuis templates)
    ├── templates/               ← 🆕 NOUVEAU : Modèles de pages HTML
    │   ├── index-normal.html    ← Template page normale
    │   ├── index-maintenance.html ← Template page maintenance
    │   ├── 404.html             ← Template page erreur
    │   └── README.txt           ← Documentation des templates
    └── user-manager/            ← Application de gestion des utilisateurs
        └── app/
            └── index.php        ← Interface PHP de gestion

═══════════════════════════════════════════════════════════════════════════
  📝 FICHIERS FOURNIS
═══════════════════════════════════════════════════════════════════════════

RACINE DU PROJET :
  • install_bolt_nbility.sh     - Script d'installation avec menu interactif
  • docker-compose.yml          - Configuration des 3 services Docker

DATA/ :
  • Dockerfile                  - Image Docker pour User Manager
  
DATA/nginx/ :
  • nginx.conf                  - Configuration du reverse proxy
  
DATA/nginx/html/ :
  • index.html                  - Page d'accueil active (générée depuis template)
  • 404.html                    - Page d'erreur (générée depuis template)

DATA/templates/ :                🆕 NOUVEAU
  • index-normal.html           - Template : page normale (Bolt opérationnel)
  • index-maintenance.html      - Template : page maintenance (Bolt hors ligne)
  • 404.html                    - Template : page d'erreur élégante
  • README.txt                  - Documentation : comment utiliser les templates
  
DATA/user-manager/app/ :
  • index.php                   - Interface de gestion des utilisateurs

═══════════════════════════════════════════════════════════════════════════
  🚀 INSTALLATION
═══════════════════════════════════════════════════════════════════════════

1. Placez tous les fichiers dans l'arborescence ci-dessus

2. Rendez le script exécutable :
   chmod +x install_bolt_nbility.sh

3. Lancez l'installation :
   ./install_bolt_nbility.sh

4. Suivez les instructions interactives

5. Le script copiera automatiquement le bon template dans DATA/nginx/html/
   en remplaçant les placeholders par vos valeurs (IP, ports)

═══════════════════════════════════════════════════════════════════════════
  ℹ️  NOTES IMPORTANTES
═══════════════════════════════════════════════════════════════════════════

- Le script vérifie que tous les fichiers de configuration sont présents
- Le fichier .htpasswd est généré automatiquement lors de l'installation
- Le répertoire bolt.diy/ est cloné automatiquement depuis GitHub
- Le fichier .env est généré automatiquement avec vos clés API
- Les templates HTML sont copiés et personnalisés avec vos paramètres
- Ne modifiez pas directement DATA/nginx/html/index.html (éditez les templates)

═══════════════════════════════════════════════════════════════════════════
