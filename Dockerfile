FROM php:8.1.0-fpm-alpine

RUN apk add --no-cache \
    gd \
    curl \
    git \
    bash \
    ca-certificates \
    postgresql-dev \
    postgresql-client \
    libc6-compat && \
    ln -s /lib/libc.musl-x86_64.so.1 /lib/ld-linux-x86-64.so.2

# Install dependencies for GD and install GD with support for jpeg, png webp and freetype
# Info about installing GD in PHP https://www.php.net/manual/en/image.installation.php
RUN apk add --no-cache \
        libjpeg-turbo-dev \
        libpng-dev \
        libwebp-dev \
        freetype-dev

RUN docker-php-ext-configure gd --with-jpeg --with-webp --with-freetype
RUN docker-php-ext-install gd

RUN apk add --update linux-headers

COPY docker-php-ext-pecl /usr/local/bin/

RUN docker-php-source extract \
    && docker-php-ext-enable opcache \
    && docker-php-ext-install pdo pdo_pgsql \
    && docker-php-source delete

# Install composer (php package manager)
RUN curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer

# Bug fix iconv on Alpine 3.14
# PHP Notice:  iconv(): Wrong charset, conversion from `UTF-8' to `ASCII//TRANSLIT' is not allowed in Command line code on line 1
# [1]: https://gitlab.alpinelinux.org/alpine/aports/-/issues/12328
# [2]: https://github.com/docker-library/php/issues/240
# [3]: https://github.com/nunomaduro/phpinsights/issues/43
RUN apk add gnu-libiconv=1.15-r3 --update-cache --repository http://dl-cdn.alpinelinux.org/alpine/v3.13/community/ --allow-untrusted
ENV LD_PRELOAD /usr/lib/preloadable_libiconv.so

# Use the default production configuration
# RUN mv "$PHP_INI_DIR/php.ini-production" "$PHP_INI_DIR/php.ini"
