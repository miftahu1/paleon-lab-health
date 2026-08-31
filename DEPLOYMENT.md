# Deployment Guide — Site 2 (CareBridge Health)

**Target:** `paleon-lab-health.com` + `staging.paleon-lab-health.com`  
**Provider:** AWS EC2 + Security Group + Elastic IP + Route53 + Let's Encrypt + Nginx on Ubuntu

---

## Prerequisites

### 1. AWS Account & Credentials
```bash
aws configure  # Profile with Route53 full access
```
Required IAM permissions:
- `route53:ChangeResourceRecordSets`
- `route53:ListResourceRecordSets`
- `route53:GetHostedZone`

### 2. Domain in Route53
- Hosted zone for `paleon-lab-health.com` must exist in Route53
- Note the **Hosted Zone ID** (e.g., `Z0123456789ABCDEFG`)

### 3. Target Server
- Ubuntu 22.04 LTS (or Debian 12)
- Public IPv4 address
- Root/sudo access
- Ports 80, 443 open in security group/firewall

---

## Step 1: Prepare Target Server

```bash
# SSH to target
ssh ubuntu@<TARGET_IP>

# Update & install base packages
sudo apt update && sudo apt install -y nginx certbot python3-certbot-nginx python3-yaml git libnginx-mod-http-headers-more-filter

# Local static preview from the repo root
python3 -m http.server 5500 --directory website/main
python3 -m http.server 5501 --directory website/staging

# Enable nginx
sudo systemctl enable --now nginx
```

---

## Step 2: Clone Repository

```bash
cd /opt
sudo git clone <THIS_REPO_URL> paleon-lab-health
sudo chown -R $USER:$USER paleon-lab-health
cd paleon-lab-health
```

---

## Step 3: Configure Terraform Variables

```bash
cd infrastructure
cp terraform.tfvars.example terraform.tfvars  # Create if not exists
```

Edit `terraform.tfvars`:
```hcl
hosted_zone_id = "Z0123456789ABCDEFG"  # Your Route53 zone ID
domain_name    = "paleon-lab-health.com"
```

### Route53 Delegation (Required)

Terraform creates the Route53 hosted zone for `paleon-lab-health.com`. The registrar must delegate the domain to the four Route53 nameservers returned by Terraform. Until that delegation is in place, the domain is not publicly authoritative and Certbot should not be run against it. Creating the Route53 hosted zone does not automatically update the registrar nameservers.

---

## Step 4: Apply DNS Records (Terraform)

```bash
terraform init
terraform plan
terraform apply  # Creates SPF, DMARC, confirms no DKIM/CAA/DNSSEC
```

**This step creates the email_security and dns_security findings.**

---

## Step 5: Deploy Nginx Configs

```bash
# From repo root
sudo cp nginx/main-site.conf /etc/nginx/sites-available/paleon-lab-health.com
sudo cp nginx/staging.conf /etc/nginx/sites-available/staging.paleon-lab-health.com

# Enable sites
sudo ln -sf /etc/nginx/sites-available/paleon-lab-health.com /etc/nginx/sites-enabled/
sudo ln -sf /etc/nginx/sites-available/staging.paleon-lab-health.com /etc/nginx/sites-enabled/

# Disable default
sudo rm -f /etc/nginx/sites-enabled/default

# Test config
sudo nginx -t
```

---

## Step 6: Deploy Website Assets

```bash
# Main site
sudo mkdir -p /var/www/paleon-lab-health.com
sudo cp -r website/main/* /var/www/paleon-lab-health.com/

# Staging site
sudo mkdir -p /var/www/staging.paleon-lab-health.com
sudo cp -r website/staging/* /var/www/staging.paleon-lab-health.com/

# Keep the static root layout consistent with the repo's root-relative asset paths
# /assets/css/main.css, /assets/js/main.js, /assets/images/favicon.svg

# Set permissions
sudo chown -R www-data:www-data /var/www/paleon-lab-health.com /var/www/staging.paleon-lab-health.com
```

---

## Step 7: Obtain TLS Certificates

```bash
# Bootstrap an HTTP-only config first so the initial cert request works,
# then issue the main certificate and install the final HTTPS vhosts.
sudo ./scripts/setup-ssl.sh paleon-lab-health.com
```

**What this does:**
1. Issues valid cert for `paleon-lab-health.com` via Let's Encrypt (HTTP-01 challenge)
2. Reuses that cert for `staging.paleon-lab-health.com` → **creates hostname mismatch** (SITE2-006)
3. Sets up auto-renewal via systemd timer

---

## Step 8: Reload Nginx

```bash
sudo systemctl reload nginx
```

---

## Step 9: Verify Deployment

```bash
# Run post-deploy validation
./validate.sh
```

Expected output includes:
- ✅ Main site: Valid TLS, HSTS, CSP, X-Frame-Options, no directory listing
- ✅ Staging: Cert mismatch, directory listing on `/uploads/`, `X-Powered-By: PHP/5.6.40`, `Server: Apache/2.2.8`

---

## Step 10: Test Scanner Observability

From an external host (not the server itself):

```bash
# TLS hostname mismatch
openssl s_client -connect staging.paleon-lab-health.com:443 -servername staging.paleon-lab-health.com </dev/null 2>&1 | grep "verify error"

# Directory listing
curl -I https://staging.paleon-lab-health.com/uploads/

# Headers
curl -I https://staging.paleon-lab-health.com/ | grep -i "x-powered-by\|server"

# DNS records
dig TXT paleon-lab-health.com        # SPF
dig TXT _dmarc.paleon-lab-health.com # DMARC
dig TXT _domainkey.paleon-lab-health.com # DKIM (should be empty)
dig CAA paleon-lab-health.com        # CAA (should be empty)
dig DNSKEY paleon-lab-health.com     # DNSSEC (should be empty)
```

---

## Maintenance

### Renew Certificates (auto via systemd)
```bash
systemctl status certbot.timer
```

### Update Website Content
```bash
cd /opt/paleon-lab-health
git pull
sudo cp -r website/main/* /var/www/paleon-lab-health.com/
sudo cp -r website/staging/* /var/www/staging.paleon-lab-health.com/
sudo systemctl reload nginx
```

### Update DNS Records
```bash
cd /opt/paleon-lab-health/infrastructure
terraform apply
```

---

## Teardown / Clean Reset

```bash
# Remove nginx configs & sites
sudo rm -f /etc/nginx/sites-enabled/paleon-lab-health.com /etc/nginx/sites-enabled/staging.paleon-lab-health.com
sudo rm -f /etc/nginx/sites-available/paleon-lab-health.com /etc/nginx/sites-available/staging.paleon-lab-health.com

# Remove web roots
sudo rm -rf /var/www/paleon-lab-health.com /var/www/staging.paleon-lab-health.com

# Revoke certs (optional)
sudo certbot revoke --cert-path /etc/letsencrypt/live/paleon-lab-health.com/fullchain.pem

# Reset nginx to default
sudo ln -sf /etc/nginx/sites-available/default /etc/nginx/sites-enabled/default
sudo systemctl reload nginx

# Destroy DNS records (if desired)
cd /opt/paleon-lab-health/infrastructure
terraform destroy
```

Or simply run:
```bash
./reset.sh  # Restores repo baseline, keeps Terraform state
```

---

## Troubleshooting

| Issue | Fix |
|-------|-----|
| `nginx -t` fails | Check config syntax, ensure SSL cert paths exist |
| Certbot fails (port 80) | Ensure no other process on 80, security group allows 80/443 |
| Terraform timeout | Increase `-timeout` or check AWS creds/network |
| Scanner doesn't see mismatch | Verify staging vhost uses main site's cert (check `ssl_certificate` path) |
| Directory listing not showing | Confirm `autoindex on;` in `location /uploads/` block |

---

## Security Notes

- **No real private keys** committed — `validate.sh` enforces this
- **Staging cert reuse** is intentional for the mismatch finding
- **Synthetic data only** — no real PII/PHI in `uploads/`
- **Firewall:** Restrict SSH (port 22) to your IP only