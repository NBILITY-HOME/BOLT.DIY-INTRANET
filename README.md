# 🚀 BOLT.DIY - Nbility Edition

Déploiement Docker sécurisé de Bolt.DIY avec authentification et interface moderne !

Version dockerisée de [Bolt.DIY](https://github.com/stackblitz-labs/bolt.diy) (open-source de Bolt.new) pour développer des applications web complètes avec n'importe quel LLM (OpenAI, Claude, Gemini, Ollama, etc.).

---

## ✨ Fonctionnalités

- 🎨 **Interface moderne** avec page d'accueil futuriste 2025
- 🔐 **Authentification Nginx** avec htpasswd
- 👥 **Gestion multi-utilisateurs** via interface web
- 🐳 **Architecture Docker** multi-conteneurs optimisée
- 🤖 **Support tous LLMs** (OpenAI, Anthropic, Google, Mistral, Ollama...)

---

## 🚀 Installation rapide

### Prérequis
- Docker & Docker Compose
- Git
- Linux (Debian/Ubuntu recommandé)

### Installation

```bash
# 1. Cloner le projet
git clone https://github.com/votre-username/BOLT.DIY.git
cd BOLT.DIY

# 2. Lancer le script d'installation
chmod +x install_bolt_nbility.sh
./install_bolt_nbility.sh

# 3. Suivre les instructions interactives
# - Configurer l'IP et le port
# - Définir le compte admin
# - Ajouter vos clés API LLM (optionnel)
```

**C'est tout !** 🎉 Accédez à `http://VOTRE_IP:8080`

---

## 📂 Architecture

```
┌──────────────┐
│ Utilisateur  │
└──────┬───────┘
       │ Port 8080
┌──────▼────────────────────┐
│  Nginx Reverse Proxy      │
│  - Auth HTTP Basic        │
│  - / → Page accueil       │
│  - /bolt → App Bolt.DIY   │
│  - /user-manager → Admin  │
└───────┬───────────────────┘
        │
   ┌────┴────┐
   │         │
┌──▼──┐   ┌─▼────────────┐
│Bolt │   │User Manager  │
│Core │   │(htpasswd)    │
└─────┘   └──────────────┘
```

**3 conteneurs Docker** :
- `bolt-nbility-core` : Application Bolt.DIY
- `bolt-nbility-nginx` : Proxy + authentification
- `bolt-nbility-htpasswd-manager` : Gestion utilisateurs

---

## 🔐 Utilisation

### Première connexion
1. Allez sur `http://VOTRE_IP:8080`
2. Cliquez sur **"Accéder à Bolt.DIY"**
3. Connectez-vous avec vos identifiants admin

### Gérer les utilisateurs
1. Sur la page d'accueil, cliquez sur **"Gérer les utilisateurs"**
2. Ajoutez/supprimez des utilisateurs via l'interface

### Configurer les LLM
Les clés API sont dans le fichier `.env`. Pour modifier :

```bash
nano DATA/.env
docker compose restart bolt-nbility-core
```

---

## 🛠️ Commandes utiles

```bash
# Démarrer
docker compose up -d

# Arrêter
docker compose down

# Voir les logs
docker compose logs -f

# Redémarrer
docker compose restart

# Mettre à jour
git pull
./install_bolt_nbility.sh
```

---

## 🐛 Dépannage

**Le site ne s'affiche pas ?**
```bash
docker compose ps  # Vérifier que tous les conteneurs tournent
docker compose logs bolt-nbility-nginx  # Voir les logs Nginx
```

**Erreur d'authentification ?**
```bash
# Réinitialiser le mot de passe admin
docker exec -it bolt-nbility-nginx htpasswd -B /etc/nginx/.htpasswd admin
docker compose restart bolt-nbility-nginx
```

**Plus d'aide ?** Consultez les [issues GitHub](https://github.com/votre-username/BOLT.DIY/issues)

---

## 👥 Crédits

- **Bolt.DIY** : [StackBlitz Labs](https://github.com/stackblitz-labs/bolt.diy)
- **Édition Nbility** : Développé par [Nbility](https://nbility.fr) - Seysses, France
- **Contributions** : Bienvenue via Pull Requests !

---

## 📄 Licence

Projet basé sur [Bolt.DIY](https://github.com/stackblitz-labs/bolt.diy) sous licence MIT.

**© 2025 Nbility - Tous droits réservés**
