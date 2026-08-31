#!/bin/bash
set -e

echo "Resetting the deployed CareBridge Health website and Nginx state..."

# Stop nginx
systemctl stop nginx || true

# Remove deployed website content and Nginx site files
rm -rf /var/www/paleon-lab-health.com/*
rm -rf /var/www/staging.paleon-lab-health.com/*

rm -f /etc/nginx/sites-enabled/paleon-lab-health.com
rm -f /etc/nginx/sites-enabled/staging.paleon-lab-health.com
rm -f /etc/nginx/sites-available/paleon-lab-health.com
rm -f /etc/nginx/sites-available/staging.paleon-lab-health.com
rm -f /etc/nginx/snippets/security-headers.conf

echo "Running fresh deployment script..."
cd scripts
bash deploy.sh

echo "Deployed website and Nginx state reset successfully. This script does not destroy Terraform, DNS, or EC2 infrastructure."
