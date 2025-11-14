
# ═══════════════════════════════════════════════════════════════════════════
# FONCTION: Génération de nginx.conf
# ═══════════════════════════════════════════════════════════════════════════
generate_nginx_conf() {
    print_section "GÉNÉRATION DE NGINX.CONF"

    print_step "Création de nginx.conf..."

    cat > "$NGINX_DIR/nginx.conf" << 'NGINX_CONF_EOF'
user nginx;
worker_processes auto;
error_log /var/log/nginx/error.log warn;
pid /var/run/nginx.pid;

events {
    worker_connections 1024;
    use epoll;
    multi_accept on;
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
               application/json application/javascript application/xml+rss 
               application/rss+xml font/truetype font/opentype 
               application/vnd.ms-fontobject image/svg+xml;

    upstream bolt_backend {
        server bolt-core:5173;
        keepalive 32;
    }

    upstream home_backend {
        server bolt-home:80;
        keepalive 16;
    }

    upstream usermanager_backend {
        server bolt-user-manager:80;
        keepalive 16;
    }

    # ════════════════════════════════════════════════════════════════
    # SERVER BOLT.DIY (Port 8585) - AVEC AUTHENTIFICATION
    # ════════════════════════════════════════════════════════════════
    server {
        listen 8585;
        server_name _;

        port_in_redirect off;
        absolute_redirect off;

        auth_basic "Bolt.DIY - Accès Restreint";
        auth_basic_user_file /etc/nginx/.htpasswd;

        location /health {
            auth_basic off;
            access_log off;
            return 200 "healthy\n";
            add_header Content-Type text/plain;
        }

        location / {
            proxy_pass http://bolt_backend;

            proxy_set_header Host $http_host;
            proxy_set_header X-Real-IP $remote_addr;
            proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
            proxy_set_header X-Forwarded-Proto $scheme;
            proxy_set_header X-Forwarded-Host $host:$server_port;
            proxy_set_header X-Forwarded-Port $server_port;

            proxy_http_version 1.1;
            proxy_set_header Upgrade $http_upgrade;
            proxy_set_header Connection "upgrade";

            proxy_connect_timeout 60s;
            proxy_send_timeout 60s;
            proxy_read_timeout 60s;
            proxy_buffering off;

            proxy_redirect http:// http://;
            proxy_redirect https:// https://;
        }

        location ~* \.(js|css|png|jpg|jpeg|gif|ico|svg|woff|woff2|ttf|eot)$ {
            proxy_pass http://bolt_backend;
            proxy_set_header Host $http_host;
            expires 1y;
            add_header Cache-Control "public, immutable";
        }
    }

    # ════════════════════════════════════════════════════════════════
    # SERVER BOLT HOME (Port 8686) - SANS AUTHENTIFICATION (PUBLIC)
    # ════════════════════════════════════════════════════════════════
    server {
        listen 8686;
        server_name _;

        port_in_redirect off;
        absolute_redirect off;

        # PAS D'AUTHENTIFICATION - Page publique d'accueil

        location / {
            proxy_pass http://home_backend;
            proxy_set_header Host $http_host;
            proxy_set_header X-Real-IP $remote_addr;
            proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
            proxy_set_header X-Forwarded-Proto $scheme;
        }
    }

    # ════════════════════════════════════════════════════════════════
    # SERVER USER MANAGER (Port 8687) - AVEC AUTHENTIFICATION
    # ════════════════════════════════════════════════════════════════
    server {
        listen 8687;
        server_name _;

        port_in_redirect off;
        absolute_redirect off;

        auth_basic "User Manager - Accès Restreint";
        auth_basic_user_file /etc/nginx/.htpasswd;

        location /health.php {
            auth_basic off;
            proxy_pass http://usermanager_backend;
            access_log off;
        }

        location / {
            proxy_pass http://usermanager_backend;

            proxy_set_header Host $http_host;
            proxy_set_header X-Real-IP $remote_addr;
            proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
            proxy_set_header X-Forwarded-Proto $scheme;
            proxy_set_header X-Forwarded-Host $host:$server_port;
            proxy_set_header X-Forwarded-Port $server_port;

            proxy_connect_timeout 60s;
            proxy_send_timeout 60s;
            proxy_read_timeout 60s;
        }

        location ~* \.(css|js|jpg|jpeg|png|gif|ico|svg)$ {
            proxy_pass http://usermanager_backend;
            expires 1h;
            add_header Cache-Control "public";
        }
    }
}
NGINX_CONF_EOF

    print_success "nginx.conf créé"
    echo ""
}
