FROM php:7.2-fpm

COPY --from=composer /usr/bin/composer /usr/bin/composer
COPY . /var/www
WORKDIR /var/www

RUN apt-get update && apt-get install -y \
    libfreetype6-dev \
    libjpeg62-turbo-dev \
    libpng-dev \
    git \
    zip \
    cron \
    && docker-php-ext-install -j$(nproc) iconv \
    && docker-php-ext-configure gd --with-freetype-dir=/usr/include/ --with-jpeg-dir=/usr/include/ \
    && docker-php-ext-install -j$(nproc) gd \
    && docker-php-ext-install -j$(nproc) bcmath 
RUN cp config/.config.example.php config/.config.php 
VOLUME ./config /var/www/config
RUN chmod -R 755 storage 
RUN chmod -R 777 /var/www/storage/framework/smarty/compile/ 
RUN composer install 
RUN php xcat initQQWry 
RUN php xcat initdownload 
RUN crontab -l | { cat; echo "30 22 * * * php /var/www/xcat sendDiaryMail"; } | crontab - 
RUN crontab -l | { cat; echo "0 0 * * * php /var/www/xcat dailyjob"; } | crontab - 
RUN crontab -l | { cat; echo "*/1 * * * * php /var/www/xcat checkjob"; } | crontab - 
RUN crontab -l | { cat; echo "*/1 * * * * php /var/www/xcat syncnode"; } | crontab - 
RUN { \
    echo '[program:crond]'; \
    echo 'command=cron -f'; \
    echo 'autostart=true'; \
    echo 'autorestart=true'; \
    echo 'killasgroup=true'; \
    echo 'stopasgroup=true'; \
    } | tee /etc/supervisor/crond.conf