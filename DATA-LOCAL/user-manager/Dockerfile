FROM php:8.2-apache

# Métadonnées
LABEL maintainer="contact@nbility.fr"
LABEL description="Bolt.DIY User Manager v2.0 with PHP 8.2 and Apache"
LABEL version="2.0"

# Installation des dépendances système
RUN apt-get update && apt-get install -y \
    git \
    curl \
    libpng-dev \
    libonig-dev \
    libxml2-dev \
    libzip-dev \
    zip \
    unzip \
    default-mysql-client \
    && rm -rf /var/lib/apt/lists/*

# Installation des extensions PHP
RUN docker-php-ext-install \
    pdo_mysql \
    mysqli \
    mbstring \
    exif \
    pcntl \
    bcmath \
    gd \
    zip

# Installation de Composer
COPY --from=composer:latest /usr/bin/composer /usr/bin/composer

# Configuration Apache
RUN a2enmod rewrite headers expires && \
    sed -i 's/AllowOverride None/AllowOverride All/' /etc/apache2/apache2.conf

# Configuration PHP
RUN echo "memory_limit = 256M" > /usr/local/etc/php/conf.d/memory.ini && \
    echo "upload_max_filesize = 20M" >> /usr/local/etc/php/conf.d/memory.ini && \
    echo "post_max_size = 20M" >> /usr/local/etc/php/conf.d/memory.ini && \
    echo "max_execution_time = 60" >> /usr/local/etc/php/conf.d/memory.ini

# Répertoire de travail
WORKDIR /var/www/html

# Copie du composer.json si présent
COPY app/composer.json* /var/www/html/

# Installation des dépendances PHP (si composer.json existe)
RUN if [ -f composer.json ]; then \
        composer install --no-dev --optimize-autoloader --no-interaction; \
    fi

# Copie du code source
COPY app/ /var/www/html/

# Fichier health check
RUN echo "<?php http_response_code(200); echo 'healthy'; ?>" > /var/www/html/health.php

# Permissions
RUN chown -R www-data:www-data /var/www/html && \
    chmod -R 755 /var/www/html

# Port exposé
EXPOSE 80

# Démarrage Apache
CMD ["apache2-foreground"]

