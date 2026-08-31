#!/bin/bash
set -e

if [ "$(id -u)" -ne 0 ]; then
    echo "ERROR: deploy.sh must be run as root."
    echo "Run: sudo ./scripts/deploy.sh"
    exit 1
fi

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

echo "Starting CareBridge Health deployment..."

# Install required packages. Use the headers-more module, not nginx-extras.
apt-get update
apt-get install -y nginx certbot python3-certbot-nginx python3-yaml git libnginx-mod-http-headers-more-filter

# Create web directories matching the repo structure
mkdir -p /var/www/paleon-lab-health.com
mkdir -p /var/www/staging.paleon-lab-health.com/uploads

# Copy website files from repo using repo-root relative paths
cp -r "$REPO_ROOT/website/main/." /var/www/paleon-lab-health.com/
cp -r "$REPO_ROOT/website/staging/." /var/www/staging.paleon-lab-health.com/

# Set ownership
chown -R www-data:www-data /var/www/paleon-lab-health.com
chown -R www-data:www-data /var/www/staging.paleon-lab-health.com

# Install bootstrap HTTP config before certs exist
cp "$REPO_ROOT/nginx/nginx.conf" /etc/nginx/nginx.conf
mkdir -p /etc/nginx/snippets
cp "$REPO_ROOT/nginx/security-headers.conf" /etc/nginx/snippets/
rm -f /etc/nginx/sites-enabled/default
cp "$REPO_ROOT/nginx/bootstrap.conf" /etc/nginx/sites-available/paleon-lab-health.com
ln -sf /etc/nginx/sites-available/paleon-lab-health.com /etc/nginx/sites-enabled/

# Bootstrap HTTP-only config is sufficient until the main certificate is obtained.
nginx -t
systemctl reload nginx

echo "Bootstrap HTTP config installed. Run setup-ssl.sh to obtain the main certificate and then install final HTTPS configs."
