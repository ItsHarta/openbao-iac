#!/bin/bash
set -e

# Setup script for OpenBao/Vault
# Requires 'vault' CLI and permissions to be logged in as root/admin.

echo "Setting up OpenBao for GitOps..."

# 1. Create Namespaces
echo "Creating namespaces..."
vault namespace create staging || echo "Namespace 'staging' might already exist"
vault namespace create production || echo "Namespace 'production' might already exist"

# 2. Enable KV v2 in namespaces
echo "Enabling KV-v2 secrets engines..."
export VAULT_NAMESPACE=staging
vault secrets enable -path=secret kv-v2 || echo "KV enabled in staging"

export VAULT_NAMESPACE=production
vault secrets enable -path=secret kv-v2 || echo "KV enabled in production"

# 3. Enable AppRole in Root
unset VAULT_NAMESPACE
echo "Enabling AppRole auth method in root..."
vault auth enable approle || echo "AppRole already enabled"

# 4. Create Policy
echo "Creating 'promoter' policy..."
# Defines permissions to read from staging and write to production.
# Assumes paths are relative to the root when using a root token/policy
# but accessing via namespace headers works if the policy allows the full path.
cat <<EOF > /tmp/promoter-policy.hcl
# Allow tokens to look up their own properties
path "auth/token/lookup-self" {
    capabilities = ["read"]
}

# Read from Staging
namespace "staging" {
  path "secret/data/*" {
      capabilities = ["read", "list"]
  }
  path "secret/metadata/*" {
      capabilities = ["read", "list"]
  }
}

# Write to Production
namespace "production" {
  path "secret/data/*" {
      capabilities = ["create", "update", "read", "list"]
  }
  path "secret/metadata/*" {
      capabilities = ["create", "update", "read", "list"]
  }
}
EOF

vault policy write promoter /tmp/promoter-policy.hcl

# 5. Create AppRole
echo "Creating 'promoter' AppRole..."
vault write auth/approle/role/promoter \
    token_policies="promoter" \
    token_ttl=1h \
    token_max_ttl=4h

# 6. Get Creds
echo "Generating credentials..."
ROLE_ID=$(vault read -field=role_id auth/approle/role/promoter/role-id)
SECRET_ID=$(vault write -f -field=secret_id auth/approle/role/promoter/secret-id)

echo ""
echo "Setup Complete."
echo "---------------------------------------------------"
echo "VAULT_ROLE_ID: $ROLE_ID"
echo "VAULT_SECRET_ID: $SECRET_ID"
echo "---------------------------------------------------"
echo "Please add these (and VAULT_ADDR) to your GitHub Repository Secrets."
