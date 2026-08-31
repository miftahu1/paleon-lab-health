#!/bin/bash
set -e

echo "Running Site 2 Validation Checks..."
FAILED=0

# 1. Directory Structure check
echo "Checking directory structure..."
[ ! -d "infrastructure" ] && echo "❌ Missing infrastructure dir" && FAILED=1
[ ! -d "nginx" ] && echo "❌ Missing nginx dir" && FAILED=1
[ ! -d "website/main" ] && echo "❌ Missing main website dir" && FAILED=1
[ ! -d "website/staging/uploads" ] && echo "❌ Missing staging uploads dir" && FAILED=1

# 2. YAML validation
echo "Validating expected.yaml..."
if [ -f "expected.yaml" ]; then
    if command -v python &> /dev/null; then
        python -c "import yaml; yaml.safe_load(open('expected.yaml'))" || { echo "❌ Invalid YAML syntax"; FAILED=1; }
    else
        echo "⚠️ python not installed, skipping YAML check"
    fi
else
    echo "❌ expected.yaml is missing"
    FAILED=1
fi

# 3. Terraform validation (must fail if terraform is installed and config/validation fails)
echo "Validating Terraform configuration..."
if command -v terraform &> /dev/null; then
    if ! (cd infrastructure && terraform init -backend=false -input=false && terraform validate); then
        echo "❌ Terraform validation failed"
        FAILED=1
    fi
else
    echo "⚠️ terraform not installed, skipping terraform validate"
fi

# 4. Secret scan (Prevent committing real keys/secrets)
echo "Checking for committed secrets..."
if find . -type f -name "*.pem" -o -name "*.key" | grep -v node_modules | grep .; then
    echo "❌ Private key files found in repository! REMOVE THEM IMMEDIATELY."
    FAILED=1
else
    echo "✅ No private key files found"
fi

# 5. Check key config files exist
echo "Checking key configuration files..."
[ ! -f "expected.yaml" ] && echo "❌ expected.yaml missing" && FAILED=1
[ ! -f "nginx/main-site.conf" ] && echo "❌ nginx/main-site.conf missing" && FAILED=1
[ ! -f "nginx/staging.conf" ] && echo "❌ nginx/staging.conf missing" && FAILED=1
[ ! -f "infrastructure/main.tf" ] && echo "❌ infrastructure/main.tf missing" && FAILED=1

if [ $FAILED -eq 0 ]; then
    echo ""
    echo "============================================="
    echo "✅ All local validation checks passed!"
    echo "============================================="
    exit 0
else
    echo ""
    echo "============================================="
    echo "❌ Validation failed. See errors above."
    echo "============================================="
    exit 1
fi