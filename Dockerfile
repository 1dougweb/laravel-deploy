FROM ghcr.io/archielite/laravel:php8.1

WORKDIR /var/www/html

# Criar script de inicialização para configurar Laravel
RUN echo '#!/bin/bash\n\
\n\
# Configurar permissões\n\
mkdir -p /var/www/html/storage/framework/{sessions,views,cache} 2>/dev/null || true\n\
mkdir -p /var/www/html/storage/logs 2>/dev/null || true\n\
mkdir -p /var/www/html/bootstrap/cache 2>/dev/null || true\n\
chown -R www-data:www-data /var/www/html/storage /var/www/html/bootstrap/cache 2>/dev/null || true\n\
chmod -R 775 /var/www/html/storage /var/www/html/bootstrap/cache 2>/dev/null || true\n\
\n\
# Executar comandos do Laravel se artisan existir\n\
if [ -f /var/www/html/artisan ]; then\n\
  echo "Configurando Laravel..."\n\
  cd /var/www/html\n\
  \n\
  # Limpar cache\n\
  php artisan config:clear 2>/dev/null || true\n\
  php artisan cache:clear 2>/dev/null || true\n\
  php artisan route:clear 2>/dev/null || true\n\
  php artisan view:clear 2>/dev/null || true\n\
  \n\
  echo "Laravel configurado!"\n\
fi\n\
\n\
# Executar o comando original da imagem\n\
exec "$@"' > /usr/local/bin/docker-entrypoint.sh \
    && chmod +x /usr/local/bin/docker-entrypoint.sh

ENTRYPOINT ["/usr/local/bin/docker-entrypoint.sh"]

