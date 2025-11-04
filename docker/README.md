# Configuração Docker para Laravel em Produção

Esta configuração usa **nginx + PHP-FPM** para servir a aplicação Laravel em produção.

## Como usar

### 1. Reconstruir a imagem Docker

```bash
docker compose build --no-cache
```

### 2. Parar e remover containers antigos

```bash
docker compose down
```

### 3. Subir os novos containers

```bash
docker compose up -d
```

### 4. Executar comandos do Laravel (se necessário)

```bash
# Gerar chave da aplicação
docker compose exec laravel.test php artisan key:generate

# Rodar migrações
docker compose exec laravel.test php artisan migrate --force

# Criar link simbólico do storage
docker compose exec laravel.test php artisan storage:link

# Limpar cache
docker compose exec laravel.test php artisan config:clear
docker compose exec laravel.test php artisan cache:clear
docker compose exec laravel.test php artisan route:clear
docker compose exec laravel.test php artisan view:clear
```

### 5. Verificar logs

```bash
# Logs do nginx e PHP-FPM
docker compose logs -f laravel.test
```

## Estrutura dos arquivos

- `docker/Dockerfile` - Imagem Docker com nginx + PHP-FPM
- `docker/nginx.conf` - Configuração do nginx apontando para `/var/www/html/public`
- `docker/php-fpm.conf` - Configuração do PHP-FPM
- `docker/supervisord.conf` - Gerenciamento de processos (nginx + PHP-FPM)
- `docker/start-container` - Script de inicialização
- `docker/php.ini` - Configurações do PHP

## Solução de problemas

### Erro "directory index of '/app/' is forbidden"

Isso significa que o nginx está tentando servir um diretório ao invés do arquivo PHP. Verifique:

1. Se a imagem foi reconstruída: `docker compose build --no-cache`
2. Se os containers foram recriados: `docker compose down && docker compose up -d`
3. Se o nginx está usando a configuração correta: `docker compose exec laravel.test nginx -t`
4. Se o diretório `/var/www/html/public` existe: `docker compose exec laravel.test ls -la /var/www/html/public`

### Verificar configuração do nginx dentro do container

```bash
docker compose exec laravel.test cat /etc/nginx/sites-enabled/default
```

O arquivo deve mostrar `root /var/www/html/public;`

