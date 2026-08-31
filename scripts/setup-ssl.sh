#!/bin/bash
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

# This script must be run with a domain argument
if [ -z "$1" ]; then
    echo "Usage: ./setup-ssl.sh <domain>"
    echo "Example: ./setup-ssl.sh paleon-lab-health.com"
    exit 1
fi

DOMAIN="$1"
EMAIL="admin@$DOMAIN"
WEBROOT="/var/www/paleon-lab-health.com"
CERT_PATH="/etc/letsencrypt/live/$DOMAIN"

mkdir -p "$WEBROOT"

# Obtain a valid certificate for the main host only using webroot validation.
certbot certonly --webroot -w "$WEBROOT" -d "$DOMAIN" -d "www.$DOMAIN" --non-interactive --agree-tos -m "$EMAIL"

# Install final HTTPS configs after the main certificate exists.
cp "$REPO_ROOT/nginx/main-site.conf" /etc/nginx/sites-available/paleon-lab-health.com
cp "$REPO_ROOT/nginx/staging.conf" /etc/nginx/sites-available/staging.paleon-lab-health.com
ln -sf /etc/nginx/sites-available/paleon-lab-health.com /etc/nginx/sites-enabled/
ln -sf /etc/nginx/sites-available/staging.paleon-lab-health.com /etc/nginx/sites-enabled/

# Staging intentionally reuses the main certificate to trigger the hostname mismatch.
# No separate staging cert is requested or installed.
nginx -t
systemctl reload nginx

echo "SSL setup completed."
echo "Main host: valid certificate for $DOMAIN and www.$DOMAIN."
echo "Staging host: intentionally reuses the same certificate, creating the hostname mismatch condition."
