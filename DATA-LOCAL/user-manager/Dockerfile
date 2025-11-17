# ═══════════════════════════════════════════════════════════════════════════
# BOLT.DIY USER MANAGER v2.0 - Dockerfile
# © Copyright Nbility 2025 - contact@nbility.fr
# PHP 8.2 + Apache + Extensions optimisées
# ═══════════════════════════════════════════════════════════════════════════

FROM php:8.2-apache

# Métadonnées
LABEL maintainer="contact@nbility.fr"
LABEL version="2.0.0"
LABEL description="Bolt.DIY User Manager - Interface de gestion des utilisateurs"

# Variables d'environnement
ENV DEBIAN_FRONTEND=noninteractive
ENV TZ=Europe/Paris
ENV APACHE_DOCUMENT_ROOT=/var/www/html

# Installation des dépendances système
RUN apt-get update && apt-get install -y \
    # Outils de base
    curl \
    wget \
    git \
    unzip \
    vim \
    nano \
    # Librairies pour PHP
    libzip-dev \
    libpng-dev \
    libjpeg-dev \
    libfreetype6-dev \
    libonig-dev \
    libxml2-dev \
    libicu-dev \
    # MariaDB client
    default-mysql-client \
    # Outils de monitoring
    htop \
    && rm -rf /var/lib/apt/lists/*

# Installation des extensions PHP
RUN docker-php-ext-configure gd --with-freetype --with-jpeg \
    && docker-php-ext-install -j$(nproc) \
        pdo \
        pdo_mysql \
        mysqli \
        zip \
        gd \
        mbstring \
        intl \
        opcache \
        exif \
        bcmath

# Configuration PHP - OPcache
RUN { \
        echo 'opcache.memory_consumption=128'; \
        echo 'opcache.interned_strings_buffer=8'; \
        echo 'opcache.max_accelerated_files=4000'; \
        echo 'opcache.revalidate_freq=2'; \
        echo 'opcache.fast_shutdown=1'; \
        echo 'opcache.enable_cli=0'; \
    } > /usr/local/etc/php/conf.d/opcache-recommended.ini

# Configuration PHP - Uploads et limites
RUN { \
        echo 'upload_max_filesize=50M'; \
        echo 'post_max_size=50M'; \
        echo 'max_execution_time=300'; \
        echo 'memory_limit=256M'; \
        echo 'date.timezone=Europe/Paris'; \
    } > /usr/local/etc/php/conf.d/uploads.ini

# Création du dossier de sessions PHP et permissions
RUN mkdir -p /var/lib/php/sessions \
    && chown -R www-data:www-data /var/lib/php/sessions \
    && chmod 1733 /var/lib/php/sessions

# Configuration Apache - activation des modules
RUN a2enmod rewrite headers expires deflate

# Permissions sur le répertoire web
RUN chown -R www-data:www-data /var/www/html \
    && chmod -R 755 /var/www/html

# Port exposé
EXPOSE 80

# Healthcheck
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
    CMD curl -f http://localhost/health.php || exit 1

# Démarrage Apache en foreground
CMD ["apache2-foreground"]
