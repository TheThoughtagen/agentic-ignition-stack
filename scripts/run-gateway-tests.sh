#!/usr/bin/env bash
set -euo pipefail

: "${IGNITION_GATEWAY_URL:?Set IGNITION_GATEWAY_URL}"
: "${IGNITION_PROJECT:?Set IGNITION_PROJECT to the local demo project directory}"

if ! command -v jq >/dev/null 2>&1; then
  echo "jq is required to evaluate the gateway test result." >&2
  exit 1
fi

response="$(curl --fail --silent --show-error \
  --request POST \
  "${IGNITION_GATEWAY_URL%/}/system/webdev/${IGNITION_PROJECT}/storm-tests")"

printf '%s\n' "$response" | jq .
printf '%s' "$response" | jq --exit-status '(.total > 0) and (.failed == 0) and (.errors == 0)' >/dev/null
