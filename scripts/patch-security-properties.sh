#!/usr/bin/env bash
set -euo pipefail

file="gateway/config/ignition/security-properties/config.json"
resource="gateway/config/ignition/security-properties/resource.json"
[[ -f "$file" ]] || { echo "Security properties not found: $file" >&2; exit 1; }

it_admin='{"name":"it","children":[{"name":"admin","children":[]}]}'
for field in accessPermissions readPermissions writePermissions createProjectPermissions designerPermissions; do
  jq --arg field "$field" --argjson child "$it_admin" '
    if .[$field].securityLevels[0].children | map(.name) | index("it") | not
    then .[$field].securityLevels[0].children += [$child]
    else . end
  ' "$file" > "$file.tmp"
  mv "$file.tmp" "$file"
done

jq '.version = ((.version // 0) + 1)' "$resource" > "$resource.tmp"
mv "$resource.tmp" "$resource"
printf 'Patched Gateway permissions for the generated local API token.\n'
