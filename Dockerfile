FROM composer:2 AS vendor

WORKDIR /app

COPY composer.json composer.lock ./
RUN composer install \
    --no-dev \
    --no-interaction \
    --prefer-dist \
    --optimize-autoloader \
    --no-scripts

COPY . .
RUN composer dump-autoload --optimize --no-dev --classmap-authoritative

FROM php:8.3-fpm-alpine

WORKDIR /var/www/html

RUN apk add --no-cache \
    nginx \
    bash \
    curl \
    fcgi \
    gettext \
    icu-dev \
    oniguruma-dev \
    libzip-dev \
    zlib-dev \
    $PHPIZE_DEPS \
    && docker-php-ext-install -j"$(nproc)" pdo_mysql mbstring bcmath intl \
    && apk del $PHPIZE_DEPS

COPY --from=vendor /app /var/www/html
COPY docker/nginx/default.conf.template /etc/nginx/templates/default.conf.template
COPY docker/start-container.sh /usr/local/bin/start-container

RUN chmod +x /usr/local/bin/start-container \
    && mkdir -p /run/nginx /var/lib/nginx/tmp /var/log/nginx \
    && chown -R www-data:www-data /var/www/html/storage /var/www/html/bootstrap/cache \
    && chmod -R ug+rwx /var/www/html/storage /var/www/html/bootstrap/cache \
    && rm -f /etc/nginx/http.d/default.conf

EXPOSE 8080

CMD ["/usr/local/bin/start-container"]
