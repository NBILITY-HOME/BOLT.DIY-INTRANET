#!/bin/bash

echo "═══════════════════════════════════════════════════════════"
echo "     DIAGNOSTIC BOLT.DIY-INTRANET - VERSION ÉTENDUE"
echo "═══════════════════════════════════════════════════════════"
echo ""

# ═══════════════════════════════════════════════════════════════
# CHARGEMENT DES VARIABLES D'ENVIRONNEMENT DEPUIS .env
# ═══════════════════════════════════════════════════════════════
if [ -f .env ]; then
    source .env
    echo "✅ Fichier .env chargé"
    echo ""
else
    echo "❌ ERREUR: Fichier .env introuvable !"
    exit 1
fi

cd /home/theking/DOCKER-PROJETS/BOLT.DIY-INTRANET

echo "1️⃣  ÉTAT DES CONTENEURS"
echo "────────────────────────────────────────────────────────────"
docker compose ps
echo ""

echo "2️⃣  NGINX.CONF - UPSTREAM USER_MANAGER"
echo "────────────────────────────────────────────────────────────"
docker exec bolt-nginx cat /etc/nginx/nginx.conf | grep -A 3 "upstream user_manager"
echo ""

echo "3️⃣  NGINX.CONF - LOCATION /user-manager"
echo "────────────────────────────────────────────────────────────"
docker exec bolt-nginx cat /etc/nginx/nginx.conf | grep -A 12 "location /user-manager"
echo ""

echo "4️⃣  APACHE ÉCOUTE SUR QUEL PORT ?"
echo "────────────────────────────────────────────────────────────"
docker exec bolt-user-manager cat /etc/apache2/ports.conf | grep "Listen"
echo ""

echo "5️⃣  APACHE VIRTUALHOST CONFIG"
echo "────────────────────────────────────────────────────────────"
docker exec bolt-user-manager cat /etc/apache2/sites-enabled/000-default.conf | head -15
echo ""

echo "6️⃣  TEST CONNEXION DEPUIS NGINX VERS BOLT-USER-MANAGER:80"
echo "────────────────────────────────────────────────────────────"
docker exec bolt-nginx wget -O- --timeout=3 http://bolt-user-manager:80 2>&1 | head -20
echo ""

echo "7️⃣  RÉSOLUTION DNS DE 'bolt-user-manager' DEPUIS NGINX"
echo "────────────────────────────────────────────────────────────"
docker exec bolt-nginx nslookup bolt-user-manager
echo ""

echo "8️⃣  LOGS NGINX (20 dernières lignes)"
echo "────────────────────────────────────────────────────────────"
docker logs bolt-nginx --tail 20
echo ""

echo "9️⃣  LOGS USER-MANAGER (20 dernières lignes)"
echo "────────────────────────────────────────────────────────────"
docker logs bolt-user-manager --tail 20
echo ""

echo "🔟  FICHIERS DANS /var/www/html (USER-MANAGER)"
echo "────────────────────────────────────────────────────────────"
docker exec bolt-user-manager ls -la /var/www/html/
echo ""

echo "1️⃣1️⃣  TEST CURL DIRECT DANS USER-MANAGER SUR PORT 80"
echo "────────────────────────────────────────────────────────────"
docker exec bolt-user-manager curl -I http://localhost:80 2>&1
echo ""

echo "1️⃣2️⃣  RÉSEAU DOCKER - ADRESSES IP"
echo "────────────────────────────────────────────────────────────"
docker network inspect boltdiy-intranet_bolt-network --format '{{range .Containers}}{{.Name}}: {{.IPv4Address}}{{"\n"}}{{end}}'
echo ""

echo "1️⃣3️⃣  TEST CONNEXION À MARIADB DEPUIS USER-MANAGER"
echo "────────────────────────────────────────────────────────────"
docker exec bolt-user-manager php -r "
\$host = '${DB_HOST}';
\$db   = '${DB_NAME}';
\$user = '${DB_USER}';
\$pass = '${DB_PASSWORD}';
\$charset = 'utf8mb4';

\$dsn = \"mysql:host=\$host;dbname=\$db;charset=\$charset\";
\$options = [
    PDO::ATTR_ERRMODE            => PDO::ERRMODE_EXCEPTION,
    PDO::ATTR_DEFAULT_FETCH_MODE => PDO::FETCH_ASSOC,
    PDO::ATTR_EMULATE_PREPARES   => false,
];

try {
    \$pdo = new PDO(\$dsn, \$user, \$pass, \$options);
    echo \"✅ CONNEXION RÉUSSIE À MARIADB\n\";
    echo \"📊 Serveur: \" . \$pdo->query('SELECT VERSION()')->fetchColumn() . \"\n\";
} catch (PDOException \$e) {
    echo \"❌ ERREUR CONNEXION: \" . \$e->getMessage() . \"\n\";
    exit(1);
}
" 2>&1
echo ""

echo "1️⃣4️⃣  LISTE DES BASES DE DONNÉES"
echo "────────────────────────────────────────────────────────────"
docker exec bolt-mariadb mariadb -uroot -p${MARIADB_ROOT_PASSWORD} -e "SHOW DATABASES;" 2>&1 | grep -v "Warning"
echo ""

echo "1️⃣5️⃣  TABLES DANS LA BASE ${DB_NAME}"
echo "────────────────────────────────────────────────────────────"
docker exec bolt-mariadb mariadb -uroot -p${MARIADB_ROOT_PASSWORD} -e "USE ${DB_NAME}; SHOW TABLES;" 2>&1 | grep -v "Warning"
echo ""

echo "1️⃣6️⃣  UTILISATEURS DANS LA BASE (TABLEAU)"
echo "────────────────────────────────────────────────────────────"
docker exec bolt-mariadb mariadb -uroot -p${MARIADB_ROOT_PASSWORD} -e "
USE ${DB_NAME};
SELECT
    id,
    username,
    email,
    role,
    is_active,
    DATE_FORMAT(created_at, '%Y-%m-%d %H:%i') AS created,
    DATE_FORMAT(last_login, '%Y-%m-%d %H:%i') AS last_login
FROM users
ORDER BY id;
" 2>&1 | grep -v "Warning"
echo ""

echo "1️⃣7️⃣  STATISTIQUES DES UTILISATEURS"
echo "────────────────────────────────────────────────────────────"
docker exec bolt-mariadb mariadb -uroot -p${MARIADB_ROOT_PASSWORD} -e "
USE ${DB_NAME};
SELECT
    COUNT(*) as total_users,
    SUM(CASE WHEN is_active = 1 THEN 1 ELSE 0 END) as actifs,
    SUM(CASE WHEN is_active = 0 THEN 1 ELSE 0 END) as inactifs,
    COUNT(DISTINCT role) as nombre_roles
FROM users;
" 2>&1 | grep -v "Warning"
echo ""

echo "1️⃣8️⃣  GROUPES ET PERMISSIONS"
echo "────────────────────────────────────────────────────────────"
docker exec bolt-mariadb mariadb -uroot -p${MARIADB_ROOT_PASSWORD} -e "
USE ${DB_NAME};
SELECT g.id, g.name, g.description, COUNT(ugm.user_id) as nb_membres
FROM groups g
LEFT JOIN user_group_memberships ugm ON g.id = ugm.group_id
GROUP BY g.id, g.name, g.description
ORDER BY g.id;
" 2>&1 | grep -v "Warning"
echo ""

echo "1️⃣9️⃣  VARIABLES D'ENVIRONNEMENT (.env)"
echo "────────────────────────────────────────────────────────────"
echo "DB_HOST=${DB_HOST}"
echo "DB_NAME=${DB_NAME}"
echo "DB_USER=${DB_USER}"
echo "DB_PASSWORD=***********"
echo "MARIADB_ROOT_PASSWORD=***********"
echo "LOCAL_IP=${LOCAL_IP}"
echo "HOST_PORT_HOME=${HOST_PORT_HOME}"
echo ""

echo "2️⃣0️⃣  VARIABLES D'ENVIRONNEMENT USER-MANAGER (conteneur)"
echo "────────────────────────────────────────────────────────────"
docker exec bolt-user-manager env | grep -E "DB_|PHP_" | sort
echo ""

echo "2️⃣1️⃣  TEST DIRECT URL /user-manager/"
echo "────────────────────────────────────────────────────────────"
curl -I http://${LOCAL_IP}:${HOST_PORT_HOME}/user-manager/ 2>&1 | head -15
echo ""

echo "2️⃣2️⃣  TEST DIRECT URL /user-manager/login.php"
echo "────────────────────────────────────────────────────────────"
curl -I http://${LOCAL_IP}:${HOST_PORT_HOME}/user-manager/login.php 2>&1 | head -15
echo ""

echo "2️⃣3️⃣  FICHIERS PHP DANS public/"
echo "────────────────────────────────────────────────────────────"
docker exec bolt-user-manager ls -lh /var/www/html/public/*.php 2>&1
echo ""

echo "2️⃣4️⃣  VÉRIFICATION SYNTAXE PHP DE INDEX.PHP"
echo "────────────────────────────────────────────────────────────"
docker exec bolt-user-manager php -l /var/www/html/public/index.php
echo ""

echo "2️⃣5️⃣  TEST NGINX CONFIGURATION"
echo "────────────────────────────────────────────────────────────"
docker exec bolt-nginx nginx -t
echo ""

echo "═══════════════════════════════════════════════════════════"
echo "                  FIN DU DIAGNOSTIC"
echo "═══════════════════════════════════════════════════════════"
