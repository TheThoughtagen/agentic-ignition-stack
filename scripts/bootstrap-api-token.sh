#!/usr/bin/env bash
set -euo pipefail

root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
secret_dir="$root/secrets"
config_root="$root/gateway/config"
token_file="$secret_dir/ignition-api-token"
token_name="agentic-bootstrap"

mkdir -p "$secret_dir" "$config_root/ignition/api-token/$token_name" "$config_root/ignition/security-properties"
chmod 700 "$secret_dir"

if [[ -s "$token_file" ]]; then
  full_token="$(tr -d '\r\n' < "$token_file")"
  token_key="${full_token#*:}"
else
  token_key="$(openssl rand 32 | openssl base64 -A | tr '+/' '-_' | tr -d '=')"
  full_token="${token_name}:${token_key}"
  printf '%s' "$full_token" > "$token_file"
  chmod 600 "$token_file"
fi

key_b64="$(printf '%s' "$token_key" | tr -- '-_' '+/')"
pad=$(( (4 - ${#key_b64} % 4) % 4 ))
if (( pad > 0 )); then
  key_b64="${key_b64}$(printf '%*s' "$pad" '' | tr ' ' '=')"
fi
token_hash="$(printf '%s' "$key_b64" | openssl base64 -d -A | openssl dgst -sha256 -binary | openssl base64 -A | tr '+/' '-_' | tr -d '=')"
timestamp="$(( $(date +%s) * 1000 ))"
uuid="$(uuidgen | tr '[:upper:]' '[:lower:]')"

cat > "$config_root/config-mode.json" <<'JSON'
{
  "title": "Core",
  "description": "Generated local development Gateway configuration",
  "enabled": true,
  "inheritable": true,
  "parent": "external"
}
JSON

cat > "$config_root/ignition/api-token/$token_name/config.json" <<JSON
{
  "profile": {
    "secureChannelRequired": false,
    "securityLevels": [{
      "children": [{
        "children": [{"children": [], "name": "admin"}],
        "name": "it"
      }],
      "description": "Authenticated local development automation",
      "name": "Authenticated"
    }],
    "timestamp": $timestamp,
    "type": "basic-token"
  },
  "settings": {"tokenHash": "$token_hash"}
}
JSON

cat > "$config_root/ignition/api-token/$token_name/resource.json" <<JSON
{
  "scope": "A",
  "version": 1,
  "restricted": false,
  "overridable": true,
  "files": ["config.json"],
  "attributes": {"uuid": "$uuid", "enabled": true}
}
JSON

permissions='{"securityLevels":[{"children":[{"children":[{"children":[],"name":"Administrator"}],"name":"Roles"},{"children":[{"children":[],"name":"admin"}],"name":"it"}],"name":"Authenticated"}],"type":"AnyOf"}'
cat > "$config_root/ignition/security-properties/config.json" <<JSON
{
  "accessPermissions": $permissions,
  "allowDesignerSSO": false,
  "allowUserAdmin": false,
  "createProjectPermissions": $permissions,
  "createProjectRoleName": "",
  "designerAuthStrategy": "CLASSIC",
  "designerAuthTokenInactivityTimeout": 10,
  "designerAuthTokenTimeToLive": 0,
  "designerPermissions": $permissions,
  "designerRoleName": "Administrator",
  "forceIdpAuth": false,
  "gatewayAuditProfile": "",
  "readPermissions": $permissions,
  "systemAuthProfile": "default",
  "systemIdentityProvider": "default",
  "userInactivityTimeout": 10,
  "writePermissions": $permissions
}
JSON

cat > "$config_root/ignition/security-properties/resource.json" <<'JSON'
{
  "scope": "A",
  "version": 1,
  "restricted": false,
  "overridable": true,
  "files": ["config.json"],
  "attributes": {"enabled": true}
}
JSON

printf 'Prepared local API token and Gateway security resources.\n'
