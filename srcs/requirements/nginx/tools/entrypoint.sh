#!/bin/sh
set -eu

CERT=/etc/nginx/ssl/inception.crt
KEY=/etc/nginx/ssl/inception.key

if [ ! -f "$CERT" ] || [ ! -f "$KEY" ]; then
  openssl req -x509 -nodes -newkey rsa:2048 -days 365 \
    -keyout "$KEY" -out "$CERT" \
    -subj "/C=MA/ST=RABAT/L=KHOURIBGA/O=42/OU=42/CN=${DOMAIN_NAME}"
fi

exec "$@"
