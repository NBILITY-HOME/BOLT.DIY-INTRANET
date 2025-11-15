
#═══════════════════════════════════════════════════════════════════════════
# GÉNÉRATION NGINX.CONF
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
    gzip_disable "msie6";

    # Configuration du serveur
    server {
        listen 80;
        server_name _;

        # Page d'accueil
        location / {
            root /usr/share/nginx/html;
            index index.html;
            try_files $uri $uri/ =404;
        }

        # Proxy vers Bolt.DIY
        location /bolt {
            auth_basic "Bolt.DIY - Accès Restreint";
            auth_basic_user_file /etc/nginx/.htpasswd;

            proxy_pass http://bolt:5173;
            proxy_http_version 1.1;
            proxy_set_header Upgrade $http_upgrade;
            proxy_set_header Connection 'upgrade';
            proxy_set_header Host $host;
            proxy_cache_bypass $http_upgrade;
            proxy_set_header X-Real-IP $remote_addr;
            proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
            proxy_set_header X-Forwarded-Proto $scheme;

            proxy_read_timeout 300s;
            proxy_connect_timeout 75s;
        }

        # Proxy vers User Manager
        location /user-manager {
            auth_basic "User Manager - Accès Admin";
            auth_basic_user_file /etc/nginx/.htpasswd;

            rewrite ^/user-manager(/.*)$ $1 break;

            proxy_pass http://user-manager:8080;
            proxy_http_version 1.1;
            proxy_set_header Host $host;
            proxy_set_header X-Real-IP $remote_addr;
            proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
            proxy_set_header X-Forwarded-Proto $scheme;

            proxy_read_timeout 300s;
            proxy_connect_timeout 75s;
        }

        # Page d'erreur personnalisée
        error_page 404 /404.html;
        location = /404.html {
            root /usr/share/nginx/html;
            internal;
        }

        error_page 500 502 503 504 /50x.html;
        location = /50x.html {
            root /usr/share/nginx/html;
        }

        # Health check
        location /health {
            access_log off;
            return 200 "healthy\n";
            add_header Content-Type text/plain;
        }
    }
}
NGINX_CONF_EOF

    print_success "nginx.conf créé"
}

#═══════════════════════════════════════════════════════════════════════════
# GÉNÉRATION DOCKER-COMPOSE.YML
#═══════════════════════════════════════════════════════════════════════════

generate_docker_compose() {
    print_section "GÉNÉRATION DOCKER-COMPOSE.YML"

    print_step "Création du fichier docker-compose.yml..."

    cat > "$PROJECT_ROOT/docker-compose.yml" << COMPOSE_EOF
version: '3.8'

services:
  # =========================================================================
  # NGINX - Reverse Proxy
  # =========================================================================
  nginx:
    image: nginx:alpine
    container_name: bolt-nginx
    restart: unless-stopped
    ports:
      - "${HOST_PORT_HOME}:80"
    volumes:
      - ${NGINX_DIR}/nginx.conf:/etc/nginx/nginx.conf:ro
      - ${NGINX_DIR}:/usr/share/nginx/html:ro
      - ${NGINX_DIR}/.htpasswd:/etc/nginx/.htpasswd:ro
    depends_on:
      - bolt
      - user-manager
    networks:
      - bolt-network
    healthcheck:
      test: ["CMD", "wget", "--quiet", "--tries=1", "--spider", "http://localhost/health"]
      interval: 30s
      timeout: 10s
      retries: 3

  # =========================================================================
  # BOLT.DIY - Application principale
  # =========================================================================
  bolt:
    image: node:20-slim
    container_name: bolt-app
    restart: unless-stopped
    working_dir: /app
    command: sh -c "npm install && npm run dev -- --host 0.0.0.0"
    ports:
      - "${HOST_PORT_BOLT}:5173"
    volumes:
      - ${BOLTDIY_DIR}:/app
    environment:
      - NODE_ENV=development
    env_file:
      - ${BOLTDIY_DIR}/.env
    networks:
      - bolt-network
    healthcheck:
      test: ["CMD", "node", "--version"]
      interval: 30s
      timeout: 10s
      retries: 3

  # =========================================================================
  # MARIADB - Base de données
  # =========================================================================
  mariadb:
    image: mariadb:latest
    container_name: bolt-mariadb
    restart: unless-stopped
    environment:
      MARIADB_ROOT_PASSWORD: \${MARIADB_ROOT_PASSWORD}
      MARIADB_DATABASE: usermanager
      MARIADB_USER: usermanager
      MARIADB_PASSWORD: \${MARIADB_USER_PASSWORD}
    volumes:
      - ${MARIADB_DIR}/data:/var/lib/mysql
      - ${MARIADB_DIR}/init:/docker-entrypoint-initdb.d:ro
    networks:
      - bolt-network
    healthcheck:
      test: ["CMD", "healthcheck.sh", "--connect", "--innodb_initialized"]
      interval: 30s
      timeout: 10s
      retries: 3

  # =========================================================================
  # USER MANAGER - Gestion utilisateurs
  # =========================================================================
  user-manager:
    build:
      context: ${USERMANAGER_DIR}
      dockerfile: Dockerfile
    container_name: bolt-user-manager
    restart: unless-stopped
    ports:
      - "${HOST_PORT_UM}:8080"
    volumes:
      - ${USERMANAGER_DIR}/app:/var/www/html
    environment:
      - PHP_MEMORY_LIMIT=256M
      - PHP_UPLOAD_MAX_FILESIZE=50M
      - PHP_POST_MAX_SIZE=50M
    env_file:
      - ${USERMANAGER_DIR}/.env
    depends_on:
      - mariadb
    networks:
      - bolt-network
    healthcheck:
      test: ["CMD", "php", "-v"]
      interval: 30s
      timeout: 10s
      retries: 3

# =========================================================================
# NETWORKS
# =========================================================================
networks:
  bolt-network:
    driver: bridge
    ipam:
      config:
        - subnet: 172.20.0.0/16
COMPOSE_EOF

    print_success "docker-compose.yml créé"
}
