FROM php:8.2-apache

RUN apt-get update && \
    apt-get install -y --no-install-recommends curl && \
    rm -rf /var/lib/apt/lists/*

RUN a2enmod rewrite

RUN { \
        echo 'expose_php = Off'; \
        echo 'max_execution_time = 30'; \
        echo 'memory_limit = 256M'; \
        echo 'date.timezone = Europe/Paris'; \
    } > /usr/local/etc/php/conf.d/custom.ini

WORKDIR /var/www/html

RUN mkdir -p /var/www/html /app && \
    chown -R www-data:www-data /var/www/html /app && \
    chmod 755 /var/www/html /app

EXPOSE 80

CMD ["apache2-foreground"]
