FROM php:5.6-fpm-alpine

WORKDIR /data/www

COPY files/dockerized-phantomjs.tar.gz /tmp/
COPY files/phantomjs-2.1.1-linux-x86_64.tar.bz2 /usr/local/

RUN sed -i 's/dl-cdn.alpinelinux.org/mirrors.aliyun.com/g' /etc/apk/repositories \
    && apk --update upgrade \
    && apk add --no-cache --virtual .build-deps \
        tzdata ca-certificates \
        curl autoconf automake make file gcc g++ re2c \
        pcre-dev \
        freetype-dev \
        libjpeg-turbo-dev \
        libpng-dev \
        libwebp-dev \
        libmcrypt-dev \
        libpng-dev \
        libxml2-dev \
        libzip-dev \
        cyrus-sasl-dev \
        libmemcached-dev \
        postgresql-dev \
    && docker-php-ext-configure gd --with-freetype-dir=/usr/include/ --with-jpeg-dir=/usr/include/ \
    && docker-php-ext-install -j$(nproc) gd \
    && docker-php-ext-configure zip --with-libzip \
    && docker-php-ext-install zip \
    && docker-php-ext-install mysql mysqli pdo_mysql pgsql pdo_pgsql exif pcntl sockets \
    && pecl install https://pecl.php.net/get/memcached-2.2.0.tgz \
    && pecl install https://pecl.php.net/get/redis-2.2.8.tgz \
    && pecl install https://pecl.php.net/get/xdebug-2.5.5.tgz \
    && pecl install https://pecl.php.net/get/xhprof-0.9.4.tgz \
    && docker-php-ext-enable xhprof \
    && cd /usr/local/etc/php && cp php.ini-production php.ini \
    && cd / \
    && runDeps="$( \
        scanelf --needed --nobanner --format '%n#p' --recursive /usr/local \
            | tr ',' '\n' \
            | sort -u \
            | awk 'system("[ -e /usr/local/lib/" $1 " ]") == 0 { next } { print "so:" $1 }' \
    )" \
    && apk add --no-cache $runDeps \
    && apk del --no-network .build-deps

RUN apk add fontconfig mkfontscale wqy-zenhei --update-cache --repository http://nl.alpinelinux.org/alpine/edge/testing --allow-untrusted

RUN cd /tmp && mkdir dockerized-phantomjs && tar zxf dockerized-phantomjs.tar.gz -C ./dockerized-phantomjs &&  \
    cd dockerized-phantomjs && \
    cp -R lib lib64 / &&\
    cp -R usr/lib/x86_64-linux-gnu /usr/lib && \
    cp -R usr/share /usr/ && \
    cp -R etc/fonts /etc && \
    cd /usr/local && tar jxf phantomjs-2.1.1-linux-x86_64.tar.bz2 && \
    ln -s /lib64/ld-linux-x86-64.so.2 /lib/ && \
    ln -s /usr/local/phantomjs-2.1.1-linux-x86_64/bin/phantomjs /usr/local/bin && \
    rm -rf /usr/local/phantomjs-2.1.1-linux-x86_64.tar.bz2 && rm -rf /tmp/*

RUN apk add --no-cache --repository http://mirrors.aliyun.com/alpine/edge/community gnu-libiconv
ENV LD_PRELOAD /usr/lib/preloadable_libiconv.so
