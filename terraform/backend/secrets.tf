# Pulls runtime secrets from the local Vault (see scripts/vault-seed.ps1).
# Reference fields as `data.vault_kv_secret_v2.secrets.data["<key>"]`.
data "vault_kv_secret_v2" "secrets" {
  mount = "secret"
  name  = "comicrealm"
}
