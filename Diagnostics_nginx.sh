#!/bin/bash
echo "═══════════════════════════════════════════════════════════"
echo "DIAGNOSTIC BOLT.DIY-INTRANET - User Manager 503 Error"
echo "═══════════════════════════════════════════════════════════"
echo ""

cd /home/theking/DOCKER-PROJETS/BOLT.DIY-INTRANET

echo "1️⃣  ÉTAT DES CONTENEURS"
echo "────────────────────────────────────────────────────────────"
docker-compose ps
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

echo "6️⃣  PORTS OUVERTS DANS USER-MANAGER"
echo "────────────────────────────────────────────────────────────"
docker exec bolt-user-manager netstat -tuln 2>/dev/null || docker exec bolt-user-manager ss -tuln
echo ""

echo "7️⃣  TEST CONNEXION DEPUIS NGINX VERS USER-MANAGER:80"
echo "────────────────────────────────────────────────────────────"
docker exec bolt-nginx wget -O- --timeout=3 http://user-manager:80 2>&1 | head -20
echo ""

echo "8️⃣  TEST CONNEXION DEPUIS NGINX VERS USER-MANAGER:8080"
echo "────────────────────────────────────────────────────────────"
docker exec bolt-nginx wget -O- --timeout=3 http://user-manager:8080 2>&1 | head -10
echo ""

echo "9️⃣  RÉSOLUTION DNS DE 'user-manager' DEPUIS NGINX"
echo "────────────────────────────────────────────────────────────"
docker exec bolt-nginx nslookup user-manager
echo ""

echo "🔟  LOGS NGINX (20 dernières lignes)"
echo "────────────────────────────────────────────────────────────"
docker logs bolt-nginx --tail 20
echo ""

echo "1️⃣1️⃣  LOGS USER-MANAGER (20 dernières lignes)"
echo "────────────────────────────────────────────────────────────"
docker logs bolt-user-manager --tail 20
echo ""

echo "1️⃣2️⃣  FICHIERS DANS /var/www/html (USER-MANAGER)"
echo "────────────────────────────────────────────────────────────"
docker exec bolt-user-manager ls -la /var/www/html/
echo ""

echo "1️⃣3️⃣  TEST CURL DIRECT DANS USER-MANAGER SUR PORT 80"
echo "────────────────────────────────────────────────────────────"
docker exec bolt-user-manager curl -I http://localhost:80 2>&1
echo ""

echo "1️⃣4️⃣  RÉSEAU DOCKER - ADRESSES IP"
echo "────────────────────────────────────────────────────────────"
docker network inspect boltdiy-intranet_bolt-network --format '{{range .Containers}}{{.Name}}: {{.IPv4Address}}{{"\n"}}{{end}}'
echo ""

echo "=== 1. Conteneurs en cours ==="
docker ps --format "table {{.Names}}\t{{.Image}}\t{{.Status}}\t{{.Ports}}" | grep -E "bolt-|NAME" || echo "Aucun conteneur bolt-*"

echo
echo "=== 2. Inspect Nginx (bolt-nginx) ==="
docker inspect bolt-nginx --format 'Name: {{.Name}}  Status: {{.State.Status}}  Ports: {{range $p,$v := .NetworkSettings.Ports}}{{$p}} -> {{(index $v 0).HostPort}} {{end}}' 2>/dev/null || echo "bolt-nginx introuvable"

echo
echo "=== 3. Logs Nginx (20 dernières lignes) ==="
docker logs bolt-nginx --tail 20 2>&1 || echo "Pas de logs pour bolt-nginx"

echo
echo "=== 4. Test écoute interne dans le conteneur Nginx ==="
docker exec bolt-nginx sh -c "netstat -tuln 2>/dev/null || ss -tuln 2>/dev/null || echo 'netstat/ss non disponibles'; echo; echo 'Test curl localhost:80'; wget -qO- http://localhost:80 2>&1 | head -5" 2>/dev/null || echo "Échec docker exec sur bolt-nginx"

echo
echo "=== 5. Vérifier le mapping de port dans docker-compose.yml ==="
grep -n "nginx:" -n docker-compose.yml
grep -n "ports:" -n docker-compose.yml -n
grep -n "HOST_PORT_HOME" -n .env 2>/dev/null || grep -n "HOST_PORT_HOME" file.env 2>/dev/null || echo "HOST_PORT_HOME non trouvé"

echo
echo "=== 6. Redémarrage contrôlé du stack ==="
docker compose down
docker compose up -d

echo
echo "=== 7. Conteneurs après redémarrage ==="
docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}" | grep -E "bolt-|NAME" || echo "Aucun conteneur bolt-*"

echo
echo "=== 8. Test direct depuis la machine ==="
curl -I http://192.168.1.200:8686/ 2>&1 | head -10

echo "═══════════════════════════════════════════════════════════"
echo "FIN DU DIAGNOSTIC"
echo "═══════════════════════════════════════════════════════════"

