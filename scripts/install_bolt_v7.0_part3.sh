
#═══════════════════════════════════════════════════════════════════════════
# FONCTION: Génération docker-compose.yml
#═══════════════════════════════════════════════════════════════════════════
generate_docker_compose() {
    print_section "GÉNÉRATION DOCKER-COMPOSE.YML"

    print_step "Création du fichier docker-compose.yml..."

    cat > "$PROJECT_ROOT/docker-compose.yml" << 'DOCKER_COMPOSE_EOF'
version: '3.8'

services:
  # ═══════════════════════════════════════════════════════════════════════════
  # BOLT.DIY - AI Code Generator
  # ═══════════════════════════════════════════════════════════════════════════
  bolt-nbility-core:
    image: ghcr.io/stackblitz-labs/bolt.diy:latest
    container_name: bolt-nbility-core
    restart: unless-stopped
    environment:
      - GROQ_API_KEY=${GROQ_API_KEY}
      - OPENAI_API_KEY=${OPENAI_API_KEY}
      - ANTHROPIC_API_KEY=${ANTHROPIC_API_KEY}
      - GOOGLE_GENERATIVE_AI_API_KEY=${GOOGLE_API_KEY}
    volumes:
      - ./DATA:/app/data:cached
    networks:
      - bolt-network
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:5173/"]
      interval: 30s
      timeout: 10s
      retries: 3

  # ═══════════════════════════════════════════════════════════════════════════
  # MARIADB - Base de données
  # ═══════════════════════════════════════════════════════════════════════════
  bolt-mariadb:
    image: mariadb:10.11
    container_name: bolt-mariadb
    restart: unless-stopped
    environment:
      MYSQL_ROOT_PASSWORD: ${MARIADB_ROOT_PASSWORD}
      MYSQL_DATABASE: bolt_usermanager
      MYSQL_USER: bolt_um
      MYSQL_PASSWORD: ${MARIADB_USER_PASSWORD}
    volumes:
      - mariadb-data:/var/lib/mysql
      - ./DATA-LOCAL/mariadb/init:/docker-entrypoint-initdb.d:ro
    networks:
      - bolt-network
    healthcheck:
      test: ["CMD", "healthcheck.sh", "--connect", "--innodb_initialized"]
      interval: 10s
      timeout: 5s
      retries: 5

  # ═══════════════════════════════════════════════════════════════════════════
  # USER MANAGER v2.0 - Gestion utilisateurs, groupes, permissions
  # ═══════════════════════════════════════════════════════════════════════════
  bolt-user-manager:
    build:
      context: ./DATA-LOCAL/user-manager
      dockerfile: Dockerfile
    container_name: bolt-user-manager
    restart: unless-stopped
    environment:
      - DB_HOST=bolt-mariadb
      - DB_PORT=3306
      - DB_NAME=bolt_usermanager
      - DB_USER=bolt_um
      - DB_PASSWORD=${MARIADB_USER_PASSWORD}
    volumes:
      - ./DATA-LOCAL/user-manager/app:/var/www/html:cached
      - ./DATA-LOCAL/user-manager/app/logs:/var/www/html/app/logs:rw
      - ./DATA-LOCAL/user-manager/uploads:/var/www/html/uploads:rw
      - ./DATA-LOCAL/user-manager/backups:/var/www/html/backups:rw
    networks:
      - bolt-network
    depends_on:
      bolt-mariadb:
        condition: service_healthy
    healthcheck:
      test: ["CMD", "php", "-r", "echo 'OK';"]
      interval: 30s
      timeout: 10s
      retries: 3

  # ═══════════════════════════════════════════════════════════════════════════
  # NGINX - Reverse Proxy + Authentification
  # ═══════════════════════════════════════════════════════════════════════════
  bolt-nginx:
    image: nginx:alpine
    container_name: bolt-nginx
    restart: unless-stopped
    ports:
      - "${HOST_PORT_BOLT}:80"
      - "${HOST_PORT_HOME}:8686"
      - "${HOST_PORT_UM}:8787"
    volumes:
      - ./DATA-LOCAL/nginx/nginx.conf:/etc/nginx/nginx.conf:ro
      - ./DATA-LOCAL/nginx/.htpasswd:/etc/nginx/.htpasswd:ro
      - ./DATA-LOCAL/nginx/home.html:/usr/share/nginx/html/home.html:ro
    networks:
      - bolt-network
    depends_on:
      - bolt-nbility-core
      - bolt-user-manager
    healthcheck:
      test: ["CMD", "wget", "--quiet", "--tries=1", "--spider", "http://localhost:80/health"]
      interval: 30s
      timeout: 10s
      retries: 3

networks:
  bolt-network:
    driver: bridge

volumes:
  mariadb-data:
    driver: local
DOCKER_COMPOSE_EOF

    print_success "docker-compose.yml créé"
    echo ""
}

#═══════════════════════════════════════════════════════════════════════════
# FONCTION: Génération nginx.conf
#═══════════════════════════════════════════════════════════════════════════
generate_nginx_conf() {
    print_section "GÉNÉRATION NGINX.CONF"

    print_step "Création du fichier nginx.conf..."

    cat > "$NGINX_DIR/nginx.conf" << 'NGINX_CONF_EOF'
user nginx;
worker_processes auto;
error_log /var/log/nginx/error.log warn;
pid /var/run/nginx.pid;

events {
    worker_connections 1024;
}

http {
    include /etc/nginx/mime.types;
    default_type application/octet-stream;

    log_format main '$remote_addr - $remote_user [$time_local] "$request" '
                    '$status $body_bytes_sent "$http_referer" '
                    '"$http_user_agent" "$http_x_forwarded_for"';

    access_log /var/log/nginx/access.log main;

    sendfile on;
    tcp_nopush on;
    tcp_nodelay on;
    keepalive_timeout 65;
    types_hash_max_size 2048;
    client_max_body_size 100M;

    gzip on;
    gzip_vary on;
    gzip_proxied any;
    gzip_comp_level 6;
    gzip_types text/plain text/css text/xml text/javascript 
               application/json application/javascript application/xml+rss;

    # ═══════════════════════════════════════════════════════════════════════
    # SERVER 1: BOLT.DIY (Port 80) - AVEC AUTHENTIFICATION
    # ═══════════════════════════════════════════════════════════════════════
    server {
        listen 80;
        server_name _;

        # Authentification HTTP Basic
        auth_basic "Bolt.DIY - Accès Restreint";
        auth_basic_user_file /etc/nginx/.htpasswd;

        # Health check (sans auth)
        location = /health {
            auth_basic off;
            access_log off;
            return 200 "OK\n";
            add_header Content-Type text/plain;
        }

        # Proxy vers Bolt.DIY
        location / {
            proxy_pass http://bolt-nbility-core:5173;
            proxy_http_version 1.1;
            proxy_set_header Upgrade $http_upgrade;
            proxy_set_header Connection "upgrade";
            proxy_set_header Host $host;
            proxy_set_header X-Real-IP $remote_addr;
            proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
            proxy_set_header X-Forwarded-Proto $scheme;
            proxy_cache_bypass $http_upgrade;
            proxy_read_timeout 300s;
            proxy_connect_timeout 75s;
        }
    }

    # ═══════════════════════════════════════════════════════════════════════
    # SERVER 2: PAGE D'ACCUEIL (Port 8686) - SANS AUTHENTIFICATION
    # ═══════════════════════════════════════════════════════════════════════
    server {
        listen 8686;
        server_name _;

        root /usr/share/nginx/html;
        index home.html;

        location / {
            try_files $uri $uri/ =404;
        }

        location = /favicon.ico {
            log_not_found off;
            access_log off;
        }
    }

    # ═══════════════════════════════════════════════════════════════════════
    # SERVER 3: USER MANAGER v2.0 (Port 8787) - AVEC AUTHENTIFICATION
    # ═══════════════════════════════════════════════════════════════════════
    server {
        listen 8787;
        server_name _;

        # Authentification HTTP Basic
        auth_basic "User Manager - Accès Admin";
        auth_basic_user_file /etc/nginx/.htpasswd;

        # Racine vers User Manager
        root /var/www/html;

        # Configuration PHP
        location / {
            proxy_pass http://bolt-user-manager:80;
            proxy_set_header Host $host;
            proxy_set_header X-Real-IP $remote_addr;
            proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
            proxy_set_header X-Forwarded-Proto $scheme;
            proxy_read_timeout 300s;
        }

        # Fichiers statiques (CSS, JS, images)
        location ~* \.(css|js|jpg|jpeg|png|gif|ico|svg|woff|woff2|ttf|eot)$ {
            proxy_pass http://bolt-user-manager:80;
            expires 30d;
            add_header Cache-Control "public, immutable";
        }
    }
}
NGINX_CONF_EOF

    print_success "nginx.conf créé"

    # Copier home.html depuis le clone
    if [ -f "$CLONE_DIR/DATA-LOCAL/nginx/home.html" ]; then
        print_step "Copie de home.html depuis GitHub..."
        cp "$CLONE_DIR/DATA-LOCAL/nginx/home.html" "$NGINX_DIR/home.html"
        print_success "home.html copié"
    else
        print_warning "home.html non trouvé dans le clone, création d'une version basique..."
        cat > "$NGINX_DIR/home.html" << 'HOME_HTML_EOF'
<!DOCTYPE html>
<html lang="fr">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>BOLT.DIY Nbility - Accueil</title>
    <style>
        * { margin: 0; padding: 0; box-sizing: border-box; }
        body {
            font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif;
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            min-height: 100vh;
            display: flex;
            align-items: center;
            justify-content: center;
            color: white;
        }
        .container {
            text-align: center;
            padding: 2rem;
            background: rgba(255, 255, 255, 0.1);
            backdrop-filter: blur(10px);
            border-radius: 20px;
            box-shadow: 0 8px 32px 0 rgba(31, 38, 135, 0.37);
        }
        h1 { font-size: 3rem; margin-bottom: 1rem; }
        p { font-size: 1.2rem; margin-bottom: 2rem; opacity: 0.9; }
        .links { display: flex; gap: 1rem; justify-content: center; flex-wrap: wrap; }
        a {
            display: inline-block;
            padding: 1rem 2rem;
            background: white;
            color: #667eea;
            text-decoration: none;
            border-radius: 10px;
            font-weight: bold;
            transition: transform 0.3s, box-shadow 0.3s;
        }
        a:hover {
            transform: translateY(-5px);
            box-shadow: 0 10px 20px rgba(0,0,0,0.2);
        }
    </style>
</head>
<body>
    <div class="container">
        <h1>🚀 BOLT.DIY Nbility</h1>
        <p>Plateforme de développement IA</p>
        <div class="links">
            <a href="http://REPLACE_IP:REPLACE_PORT_BOLT" target="_blank" rel="noopener noreferrer">Accéder à Bolt.DIY</a>
            <a href="http://REPLACE_IP:REPLACE_PORT_UM" target="_blank" rel="noopener noreferrer">User Manager</a>
        </div>
    </div>
</body>
</html>
HOME_HTML_EOF

        # Remplacer les placeholders
        sed -i "s/REPLACE_IP/$LOCAL_IP/g" "$NGINX_DIR/home.html"
        sed -i "s/REPLACE_PORT_BOLT/$HOST_PORT_BOLT/g" "$NGINX_DIR/home.html"
        sed -i "s/REPLACE_PORT_UM/$HOST_PORT_UM/g" "$NGINX_DIR/home.html"

        print_success "home.html basique créé"
    fi

    echo ""
}
