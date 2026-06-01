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

if ! command -v jq > /dev/null 2>&1; then
  echo "ERROR: jq is required but not installed." >&2
  exit 1
fi

payload=$(jq -n \
  --arg conn  "${COMICREAL_DEFAULT_CONNECTION}" \
  --arg key   "${JWT_SIGNING_KEY}" \
  --arg iss   "${JWT_ISSUER}" \
  --arg aud   "${JWT_AUDIENCE}" \
  '{data: {"ConnectionStrings__DefaultConnection": $conn, "Jwt__SigningKey": $key, "Jwt__Issuer": $iss, "Jwt__Audience": $aud}}')

curl -fsS \
  --header "X-Vault-Token: ${VAULT_TOKEN}" \
  --header "Content-Type: application/json" \
  --request POST \
  --data "${payload}" \
  "${VAULT_ADDR%/}/v1/secret/data/comicrealm" \
  > /dev/null

echo "Vault seeded at secret/comicrealm"
