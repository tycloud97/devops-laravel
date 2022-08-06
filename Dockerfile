
FROM composer:1.10.19 as build
COPY . /app/
RUN composer install --prefer-dist --no-dev --optimize-autoloader --no-interaction --ignore-platform-reqs

# Set the base image for subsequent instructions
FROM php:7.4-fpm

# Update packages
RUN apt-get update

# Install PHP and composer dependencies
RUN apt-get install -qq git curl libmcrypt-dev libjpeg-dev libpng-dev libfreetype6-dev libbz2-dev libicu-dev zip

# Clear out the local repository of retrieved package files
RUN apt-get clean

# Install needed extensions
# Here you can install any other extension that you need during the test and deployment process
RUN pecl install mcrypt-1.0.4
RUN docker-php-ext-enable mcrypt
RUN docker-php-ext-install pdo_mysql intl

RUN apt-get install -y nginx  supervisor && \
    rm -rf /var/lib/apt/lists/*

COPY --from=build /app /var/www/html
COPY .env.example /var/www/html/.env

WORKDIR /var/www/html

RUN rm /etc/nginx/sites-enabled/default

COPY /docker/nginx/nginx.conf /etc/nginx/conf.d/default.conf

RUN chmod 777 -R /var/www/html/storage/ && \
    chown -R www-data:www-data /var/www/ && \
    chmod +x ./entrypoint

ENTRYPOINT ["./entrypoint"]

EXPOSE 80