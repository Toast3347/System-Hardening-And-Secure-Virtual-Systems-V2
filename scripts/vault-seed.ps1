# -----------------------------------------------------------------------------
# Seeds the local Vault (KV v2) with all ComicRealm runtime secrets via REST.
# Reads values from environment variables (typically loaded from .env) and
# writes them to `secret/comicrealm`. Safe to re-run.
# -----------------------------------------------------------------------------
[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'

function Require-Env([string]$Name) {
    $value = [Environment]::GetEnvironmentVariable($Name)
    if ([string]::IsNullOrWhiteSpace($value)) {
        throw "$Name must be set"
    }
    return $value
}

$vaultAddr  = (Require-Env 'VAULT_ADDR').TrimEnd('/')
$vaultToken = Require-Env 'VAULT_TOKEN'

$payload = @{
    data = @{
        'ConnectionStrings__DefaultConnection' = Require-Env 'COMICREAL_DEFAULT_CONNECTION'
        'Jwt__SigningKey'                      = Require-Env 'JWT_SIGNING_KEY'
        'Jwt__Issuer'                          = Require-Env 'JWT_ISSUER'
        'Jwt__Audience'                        = Require-Env 'JWT_AUDIENCE'
    }
} | ConvertTo-Json -Depth 4

Invoke-RestMethod `
    -Uri "$vaultAddr/v1/secret/data/comicrealm" `
    -Method Post `
    -Headers @{ 'X-Vault-Token' = $vaultToken } `
    -ContentType 'application/json' `
    -Body $payload | Out-Null

Write-Host "Vault seeded at secret/comicrealm"
