# ═══════════════════════════════════════════════════════════════════════════
# BOLT.DIY USER MANAGER v2.0 - Dockerfile
# © Copyright Nbility 2025 - contact@nbility.fr
# PHP 8.2 + Apache + Extensions optimisées
# ═══════════════════════════════════════════════════════════════════════════

FROM php:8.2-apache

# ★ CONFIGURER APACHE POUR ÉCOUTER SUR LE PORT 8080 ★
RUN sed -i 's/Listen 80/Listen 8080/g' /etc/apache2/ports.conf \
    && sed -i 's/:80>/:8080>/g' /etc/apache2/sites-available/000-default.conf \
    && echo "ServerName localhost" >> /etc/apache2/apache2.conf


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
    procps \
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
    exif \
    pcntl \
    bcmath \
    intl \
    opcache \
    soap

# Configuration Apache
RUN a2enmod rewrite headers expires deflate ssl \
    && sed -ri -e 's!/var/www/html!${APACHE_DOCUMENT_ROOT}!g' /etc/apache2/sites-available/*.conf \
    && sed -ri -e 's!/var/www/!${APACHE_DOCUMENT_ROOT}!g' /etc/apache2/apache2.conf /etc/apache2/conf-available/*.conf

# Copier la configuration PHP personnalisée
COPY php.ini /usr/local/etc/php/conf.d/custom.ini

# Créer les répertoires nécessaires
RUN mkdir -p /var/www/html/logs \
    && mkdir -p /var/www/html/cache \
    && mkdir -p /var/www/html/uploads \
    && mkdir -p /var/www/html/backups \
    && chown -R www-data:www-data /var/www/html \
    && chmod -R 755 /var/www/html

# Configuration des permissions
RUN usermod -u 1000 www-data \
    && groupmod -g 1000 www-data

# Healthcheck
HEALTHCHECK --interval=30s --timeout=10s --start-period=40s --retries=3 \
    CMD curl -f http://localhost/health.php || exit 1

# Exposition du port
EXPOSE 8080

# Point d'entrée
WORKDIR /var/www/html

# Démarrage Apache en foreground
CMD ["apache2-foreground"]

# ═══════════════════════════════════════════════════════════════════════════
# FIN DU DOCKERFILE
# ═══════════════════════════════════════════════════════════════════════════
