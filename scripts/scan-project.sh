#!/usr/bin/env bash
set -euo pipefail

IGNITION_GATEWAY_URL="${IGNITION_GATEWAY_URL:-http://127.0.0.1:8088}"
if [[ -z "${IGNITION_API_TOKEN:-}" && -s secrets/ignition-api-token ]]; then
  IGNITION_API_TOKEN="$(tr -d '\r\n' < secrets/ignition-api-token)"
fi
: "${IGNITION_API_TOKEN:?Run ./scripts/bootstrap-api-token.sh first}"

curl --fail --silent --show-error \
  --request POST \
  --header "X-Ignition-API-Token: ${IGNITION_API_TOKEN}" \
  "${IGNITION_GATEWAY_URL%/}/data/project-scan-endpoint/scan?updateDesigners=true&forceUpdate=true"
echo
