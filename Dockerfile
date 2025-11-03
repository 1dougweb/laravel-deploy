FROM php:8.2-fpm

# Instalar dependências do sistema
RUN apt-get update && apt-get install -y \
    git \
    curl \
    procps \
    libpng-dev \
    libonig-dev \
    libxml2-dev \
    libzip-dev \
    zip \
    unzip \
    && rm -rf /var/lib/apt/lists/*

# Instalar extensões PHP necessárias para Laravel
RUN docker-php-ext-install \
    pdo_mysql \
    mysqli \
    mbstring \
    exif \
    pcntl \
    bcmath \
    gd \
    zip \
    opcache

# Configurar OPcache para melhor performance
RUN echo "opcache.enable=1" >> /usr/local/etc/php/conf.d/opcache.ini \
    && echo "opcache.memory_consumption=256" >> /usr/local/etc/php/conf.d/opcache.ini \
    && echo "opcache.interned_strings_buffer=16" >> /usr/local/etc/php/conf.d/opcache.ini \
    && echo "opcache.max_accelerated_files=20000" >> /usr/local/etc/php/conf.d/opcache.ini \
    && echo "opcache.validate_timestamps=0" >> /usr/local/etc/php/conf.d/opcache.ini \
    && echo "opcache.fast_shutdown=1" >> /usr/local/etc/php/conf.d/opcache.ini \
    && echo "opcache.revalidate_freq=0" >> /usr/local/etc/php/conf.d/opcache.ini \
    && echo "opcache.max_wasted_percentage=5" >> /usr/local/etc/php/conf.d/opcache.ini

# Aumentar limites do PHP
RUN echo "memory_limit=512M" >> /usr/local/etc/php/conf.d/custom.ini \
    && echo "upload_max_filesize=100M" >> /usr/local/etc/php/conf.d/custom.ini \
    && echo "post_max_size=100M" >> /usr/local/etc/php/conf.d/custom.ini \
    && echo "max_execution_time=300" >> /usr/local/etc/php/conf.d/custom.ini \
    && echo "max_input_time=300" >> /usr/local/etc/php/conf.d/custom.ini

# Otimizar PHP-FPM para melhor performance
RUN sed -i 's/pm.max_children = 5/pm.max_children = 50/' /usr/local/etc/php-fpm.d/www.conf \
    && sed -i 's/pm.start_servers = 2/pm.start_servers = 10/' /usr/local/etc/php-fpm.d/www.conf \
    && sed -i 's/pm.min_spare_servers = 1/pm.min_spare_servers = 5/' /usr/local/etc/php-fpm.d/www.conf \
    && sed -i 's/pm.max_spare_servers = 3/pm.max_spare_servers = 20/' /usr/local/etc/php-fpm.d/www.conf \
    && sed -i 's/;pm.process_idle_timeout = 10s/pm.process_idle_timeout = 30s/' /usr/local/etc/php-fpm.d/www.conf

# Criar script de health check para PHP-FPM
RUN echo '#!/bin/sh\n\
pgrep php-fpm > /dev/null 2>&1' > /usr/local/bin/php-fpm-healthcheck \
    && chmod +x /usr/local/bin/php-fpm-healthcheck

# Criar script de inicialização do Laravel
RUN echo '#!/bin/bash\n\
\n\
# Aguardar banco de dados estar pronto (máximo 60 tentativas = 2 minutos)\n\
echo "Aguardando banco de dados ficar pronto..."\n\
for i in {1..60}; do\n\
  if php artisan db:show > /dev/null 2>&1; then\n\
    echo "Banco de dados conectado!"\n\
    break\n\
  fi\n\
  if [ $i -eq 60 ]; then\n\
    echo "Aviso: Não foi possível conectar ao banco de dados, mas continuando..."\n\
  fi\n\
  sleep 2\n\
done\n\
\n\
# Executar comandos do Laravel\n\
if [ -f artisan ]; then\n\
  echo "Configurando Laravel..."\n\
  \n\
  # Configurar permissões\n\
  mkdir -p /var/www/html/storage/framework/{sessions,views,cache}\n\
  mkdir -p /var/www/html/storage/logs\n\
  mkdir -p /var/www/html/bootstrap/cache\n\
  chown -R www-data:www-data /var/www/html/storage /var/www/html/bootstrap/cache 2>/dev/null || true\n\
  chmod -R 775 /var/www/html/storage /var/www/html/bootstrap/cache 2>/dev/null || true\n\
  \n\
  # Limpar cache\n\
  php artisan config:clear 2>/dev/null || true\n\
  php artisan cache:clear 2>/dev/null || true\n\
  php artisan route:clear 2>/dev/null || true\n\
  php artisan view:clear 2>/dev/null || true\n\
  \n\
  # Executar migrações (sem falhar se der erro)\n\
  php artisan migrate --force 2>/dev/null || echo "Migrações já executadas ou erro ignorado"\n\
  \n\
  # Otimizar aplicação (produção)\n\
  if [ "$APP_ENV" = "production" ] || [ -z "$APP_ENV" ]; then\n\
    php artisan config:cache 2>/dev/null || true\n\
    php artisan route:cache 2>/dev/null || true\n\
    php artisan view:cache 2>/dev/null || true\n\
    php artisan event:cache 2>/dev/null || true\n\
  fi\n\
  \n\
  echo "Laravel configurado!"\n\
fi\n\
\n\
# Iniciar PHP-FPM\n\
echo "Iniciando PHP-FPM..."\n\
exec php-fpm' > /usr/local/bin/docker-entrypoint.sh \
    && chmod +x /usr/local/bin/docker-entrypoint.sh

WORKDIR /var/www/html

ENTRYPOINT ["/usr/local/bin/docker-entrypoint.sh"]

