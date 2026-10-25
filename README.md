# nginx-proxy + certbot

Reverse proxy central con nginx y certificados de Let's Encrypt renovados por certbot.
Cada app vive en su propio stack y se conecta a la red externa `proxy-net`; nginx le llega por el nombre del contenedor y termina el TLS.

> **Estado:** archivado desde el 2026-10-11. Lo reemplazó el Traefik de Dokploy.
> Se guarda como plantilla y para poder volver atrás.

## Estructura

```
docker-compose.yml        nginx (80/443) + certbot (renueva cada 12 h)
nginx/nginx.conf          config global (server_tokens off, headers, client_max_body_size)
nginx/conf.d/
  00-default.conf         catch-all: acceso por IP o Host desconocido -> 444 / handshake TLS rechazado
  app.conf.example        plantilla de vhost
  <app>.conf              un archivo por dominio (NO versionado, ver .gitignore)
scripts/init-ssl.sh       emite el primer certificado de un dominio (webroot)
certbot/conf/             certificados y llaves (NO versionado, ver .gitignore)
certbot/www/              webroot de los desafíos ACME
```

## Poner en marcha en un servidor nuevo

```bash
docker network create proxy-net
docker compose up -d
```

## Agregar un dominio

1. Apunta el registro DNS (A) del dominio a la IP del servidor.
2. Conecta el contenedor de la app a `proxy-net` (en su compose: red `proxy-net` con `external: true`).
3. Emite el certificado (lo resuelve `00-default.conf`, sin necesitar todavía el server block):
   ```bash
   ./scripts/init-ssl.sh app.tudominio.com tu@email.com
   ```
4. Crea el vhost a partir de la plantilla y reemplaza dominio, contenedor y puerto:
   ```bash
   cp nginx/conf.d/app.conf.example nginx/conf.d/app.conf
   ```
5. Recarga nginx:
   ```bash
   docker compose exec nginx nginx -s reload
   ```

## Volver a usar este stack en lugar de Traefik/Dokploy

Los puertos 80/443 los ocupa `dokploy-traefik`; hay que liberarlos primero:

```bash
docker stop dokploy-traefik && docker update --restart=no dokploy-traefik
docker update --restart=unless-stopped nginx-proxy certbot
docker compose up -d
```

Si los certificados de `certbot/conf` vencieron, renuévalos con `docker compose run --rm certbot renew`.
