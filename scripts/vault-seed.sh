#!/usr/bin/env sh
# -----------------------------------------------------------------------------
# Seeds the local Vault (KV v2) with all ComicRealm runtime secrets.
# Reads values from environment variables (typically loaded from .env) and
# writes them to `secret/comicrealm` via the Vault HTTP API. Safe to re-run.
# -----------------------------------------------------------------------------
set -eu

: "${VAULT_ADDR:?VAULT_ADDR must be set (e.g. http://localhost:8200)}"
: "${VAULT_TOKEN:?VAULT_TOKEN must be set}"
: "${COMICREAL_DEFAULT_CONNECTION:?COMICREAL_DEFAULT_CONNECTION must be set}"
: "${JWT_SIGNING_KEY:?JWT_SIGNING_KEY must be set}"
: "${JWT_ISSUER:?JWT_ISSUER must be set}"
: "${JWT_AUDIENCE:?JWT_AUDIENCE must be set}"

payload=$(cat <<JSON
{
  "data": {
    "ConnectionStrings__DefaultConnection": "${COMICREAL_DEFAULT_CONNECTION}",
    "Jwt__SigningKey": "${JWT_SIGNING_KEY}",
    "Jwt__Issuer": "${JWT_ISSUER}",
    "Jwt__Audience": "${JWT_AUDIENCE}"
  }
}
JSON
)

curl -fsS \
  --header "X-Vault-Token: ${VAULT_TOKEN}" \
  --request POST \
  --data "${payload}" \
  "${VAULT_ADDR%/}/v1/secret/data/comicrealm" \
  > /dev/null

echo "Vault seeded at secret/comicrealm"
