#!/bin/bash
# Uso: ./scripts/init-ssl.sh app1.tudominio.com tu@email.com
set -e
# docker compose busca el compose en el directorio actual: ir a la raiz del stack
cd "$(dirname "$0")/.."

DOMAIN=$1
EMAIL=$2

if [ -z "$DOMAIN" ] || [ -z "$EMAIL" ]; then
  echo "Uso: $0 <dominio> <email>"
  exit 1
fi

echo "▶ Obteniendo certificado para $DOMAIN..."

docker compose run --rm \
  --entrypoint certbot \
  certbot certonly \
  --webroot \
  --webroot-path=/var/www/certbot \
  --email "$EMAIL" \
  --agree-tos \
  --no-eff-email \
  -d "$DOMAIN"

echo "✅ Listo. Recarga nginx con: docker compose exec nginx nginx -s reload"
