#!/bin/bash
set -e

# Setup script for OpenBao/Vault
# Requires 'vault' CLI and permissions to be logged in as root/admin.

echo "Setting up OpenBao for GitOps..."

# Namespaces 'staging' and 'prod' are assumed to exist.
# KV engines are assumed to be mounted at:
# - staging: stag-keys/
# - prod: secrets/

# 1. Enable AppRole in Root (mounted at actions/)
unset VAULT_NAMESPACE
echo "Enabling AppRole auth method at 'actions/'..."
vault auth enable -path=actions approle || echo "AppRole already enabled at 'actions/'"

# 2. Create Policy
echo "Creating 'promoter' policy..."
# Defines permissions to read from staging and write to production.
cat <<EOF > /tmp/promoter-policy.hcl
# Allow tokens to look up their own properties
path "auth/token/lookup-self" {
    capabilities = ["read"]
}

# Read from Staging (namespace: staging, mount: stag-keys)
path "staging/stag-keys/data/*" {
    capabilities = ["read", "list"]
}
path "staging/stag-keys/metadata/*" {
    capabilities = ["read", "list"]
}

# Write to Production (namespace: prod, mount: secrets)
path "prod/secrets/data/*" {
    capabilities = ["create", "update", "read", "list"]
}
path "prod/secrets/metadata/*" {
    capabilities = ["create", "update", "read", "list"]
}
EOF

vault policy write promoter /tmp/promoter-policy.hcl

# 3. Create AppRole
echo "Creating 'promoter' AppRole..."
vault write auth/actions/role/promoter \
    token_policies="promoter" \
    token_ttl=15m \
    token_max_ttl=30m

# 4. Get Creds
echo "Generating credentials..."
ROLE_ID=$(vault read -field=role_id auth/actions/role/promoter/role-id)
SECRET_ID=$(vault write -f -field=secret_id auth/actions/role/promoter/secret-id)

echo ""
echo "Setup Complete."
echo "---------------------------------------------------"
echo "VAULT_ROLE_ID: $ROLE_ID"
echo "VAULT_SECRET_ID: $SECRET_ID"
echo "---------------------------------------------------"
echo "Please add these (and VAULT_ADDR) to your GitHub Repository Secrets."
