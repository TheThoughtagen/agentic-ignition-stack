#!/usr/bin/env bash
set -euo pipefail

: "${IGNITION_GATEWAY_URL:?Set IGNITION_GATEWAY_URL}"
: "${IGNITION_API_TOKEN:?Set IGNITION_API_TOKEN}"

curl --fail --silent --show-error \
  --request POST \
  --header "X-Ignition-API-Token: ${IGNITION_API_TOKEN}" \
  "${IGNITION_GATEWAY_URL%/}/data/project-scan-endpoint/scan?updateDesigners=true&forceUpdate=true"
echo
