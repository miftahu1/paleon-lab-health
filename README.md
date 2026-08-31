# Paleon Lab — Site 2: CareBridge Health

**External Scanner Validation Test Site**  
Domain: `paleon-lab-health.com` (and `staging.paleon-lab-health.com`)

---

## Overview

This repository contains the complete infrastructure-as-code and static assets for **Site 2** of the Paleon external-scanner validation lab. It models a realistic UK healthtech SME ("CareBridge Health") with two distinct attack surfaces:

| Surface | Hostname | Purpose |
|---------|----------|---------|
| **Main Site** | `paleon-lab-health.com` | Clean control — valid TLS, strong security headers, no deliberate weaknesses |
| **Staging Portal** | `staging.paleon-lab-health.com` | Intentionally weak staging surface — exposes scanner-observable misconfigurations and synthetic data |

All weaknesses are **non-exploitable, synthetic, and observable-only** — designed for scanner detection, not attacker abuse.

---

## Scanner Findings (Expected)

The `expected.yaml` defines 9 intended findings across 6 categories:

| ID | Category | Finding | Strength | Severity |
|----|----------|---------|----------|----------|
| SITE2-001 | email_security | Weak SPF (`v=spf1 ?all`) | observed | medium |
| SITE2-002 | email_security | DMARC `p=none` (monitor only) | observed | medium |
| SITE2-003 | email_security | Missing DKIM record | observed | low |
| SITE2-004 | dns_security | Missing CAA records | observed | low |
| SITE2-005 | dns_security | DNSSEC disabled | observed | low |
| SITE2-006 | tls | Hostname-mismatch certificate on staging | observed | high |
| SITE2-007 | information_disclosure | Directory listing on `/uploads/` | observed | medium |
| SITE2-008 | information_disclosure | Outdated component disclosure (PHP 5.6.40 / Apache 2.2.8) | observed | medium |
| SITE2-009 | software_version | EOL software version detected | inferred | medium |

**Guardrails (must_not_flag):** 5 rules preventing false positives on the clean main site.

---

## Quick Start

```bash
# Serve the main site locally as the web root
python3 -m http.server 5500 --directory website/main

# Optional local staging preview
python3 -m http.server 5501 --directory website/staging

# Validate repo structure
./validate.sh

# Deploy (requires AWS creds + domain in Route53)
./scripts/deploy.sh

# Verify TLS + headers post-deployment
./scripts/validate.sh  # (run from target host)

# Teardown / reset to repo state
./reset.sh
```

### Route53 Delegation Requirement

Terraform creates the Route53 hosted zone for `paleon-lab-health.com`. The registrar must then delegate the domain to the four Route53 nameservers returned by Terraform. This must be completed before Certbot is run so the domain is publicly authoritative and can answer DNS correctly. Creating the hosted zone in Route53 does not automatically change the registrar nameservers.

> Note: The current Terraform deployment assumes an existing default VPC and subnet in `eu-west-2`; it does not create a custom VPC or subnet layer.

---

## Directory Structure

```
health/
├── README.md                 # This file
├── DEPLOYMENT.md             # Step-by-step deployment guide
├── ARCHITECTURE.md           # Technical architecture & design decisions
├── expected.yaml             # Scanner expectations (findings + guardrails)
├── validate.sh               # Local validation (structure, YAML, secrets)
├── reset.sh                  # Restore repo baseline
├── infrastructure/           # Terraform (EC2, security group, EIP, DNS)
│   ├── main.tf
│   ├── variables.tf
│   ├── outputs.tf
│   └── dns/route53.tf
├── nginx/                    # Nginx vhost configs
│   ├── main-site.conf        # Strong headers, valid TLS, autoindex off
│   └── staging.conf          # Mismatched cert, autoindex on, weak headers
├── website/
│   ├── main/                 # CareBridge Health main site
│   │   ├── index.html
│   │   ├── about/
│   │   │   └── index.html
│   │   ├── platform/
│   │   │   └── index.html
│   │   ├── patients/
│   │   │   └── index.html
│   │   ├── security/
│   │   │   └── index.html
│   │   ├── contact/
│   │   │   └── index.html
│   │   ├── assets/
│   │   │   ├── css/main.css
│   │   │   ├── js/main.js
│   │   │   └── images/favicon.svg
│   └── staging/              # Staging portal (legacy UI)
│       ├── index.html
│       ├── appointments/
│       │   └── index.html
│       ├── prescriptions/
│       │   └── index.html
│       ├── assets/
│       │   ├── css/style.css
│       │   └── js/main.js
│       └── uploads/
│           ├── patient-record-demo.txt
│           ├── lab-result-demo.csv
│           └── portal-export-demo.txt
└── scripts/
    ├── deploy.sh             # Sync to target + nginx reload
    ├── setup-ssl.sh          # Let's Encrypt certs (main + reuse for staging)
    └── validate.sh           # Post-deploy verification
```

---

## Design Principles

1. **Observable, Not Exploitable** — Every weakness is a configuration signal a scanner can see; none grant access or leak real data.
2. **Synthetic Data Only** — Patient IDs (`PATIENT-20481`), DOBs, NHS numbers are fake.
3. **Control Pair** — Main site demonstrates correct configuration; staging demonstrates the anti-patterns.
4. **Infrastructure as Code** — All DNS, TLS, and nginx config version-controlled.
5. **Reproducible** — Single `deploy.sh` makes any clean host match this repo.

---

## Requirements

- Linux host (Ubuntu 22.04+ / Debian 12+ recommended)
- Nginx 1.18+
- Terraform 1.5+ (provisions EC2, security group, EIP, and Route53 records)
- `certbot` (Let's Encrypt)
- Python 3 + PyYAML (for `validate.sh`)
- `libnginx-mod-http-headers-more-filter` for the staging `Server` header override
- AWS CLI configured with Route53 permissions (for DNS)

---

## License

Internal testing artifact — Paleon Labs. Not for production use.
Dated: 31/08/2026