#!/usr/bin/env bash
set -euo pipefail

module_path="${1:?Usage: ./scripts/install-module.sh <path-to-module.modl>}"
: "${IGNITION_GATEWAY_URL:?Set IGNITION_GATEWAY_URL}"
: "${IGNITION_API_TOKEN:?Set IGNITION_API_TOKEN}"

[[ -f "$module_path" ]] || { echo "Module not found: $module_path" >&2; exit 1; }
command -v jq >/dev/null || { echo "jq is required." >&2; exit 1; }
command -v unzip >/dev/null || { echo "unzip is required." >&2; exit 1; }

api() {
  curl --fail --silent --show-error \
    --header "X-Ignition-API-Token: ${IGNITION_API_TOKEN}" \
    "$@"
}

module_xml="$(unzip -p "$module_path" module.xml)"
module_id="$(printf '%s' "$module_xml" | tr -d '\r\n' | sed 's#-->#\n#g' | sed 's#<!--.*$##' | grep -o '<id>[^<]*</id>' | head -1 | sed -e 's#<id>##' -e 's#</id>##')"
module_version="$(printf '%s' "$module_xml" | tr -d '\r\n' | sed 's#-->#\n#g' | sed 's#<!--.*$##' | grep -o '<version>[^<]*</version>' | head -1 | sed -e 's#<version>##' -e 's#</version>##')"
[[ -n "$module_id" ]] || { echo "Unable to read module ID from $module_path" >&2; exit 1; }

filename="$(basename "$module_path")"
printf 'Uploading %s (%s v%s)\n' "$filename" "$module_id" "$module_version"
api --request POST --header 'Content-Type: application/octet-stream' \
  --data-binary "@$module_path" \
  "${IGNITION_GATEWAY_URL%/}/data/api/v1/modules/upload?fileName=${filename}" >/dev/null

# EULA/certificate endpoints are no-ops when the module does not require them.
for kind in eula certificate; do
  details="$(api "${IGNITION_GATEWAY_URL%/}/data/api/v1/modules/${kind}?moduleId=${module_id}" 2>/dev/null || true)"
  if [[ -n "$details" ]] && printf '%s' "$details" | jq -e 'if $kind == "eula" then .hash else .serialNumber end' --arg kind "$kind" >/dev/null 2>&1; then
    api --request POST "${IGNITION_GATEWAY_URL%/}/data/api/v1/modules/${kind}?moduleId=${module_id}" >/dev/null || true
  fi
done

api --request POST "${IGNITION_GATEWAY_URL%/}/data/api/v1/modules/install?moduleId=${module_id}" >/dev/null
printf 'Installed %s; restart the gateway to activate it.\n' "$module_id"
