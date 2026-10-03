#!/usr/bin/env bash
set -euo pipefail

root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$root"

# shellcheck source=lib/ignition-cli.sh
source "$(dirname "${BASH_SOURCE[0]}")/lib/ignition-cli.sh"

load_ignition_env
require_ign
command -v jq >/dev/null 2>&1 || { echo "jq is required." >&2; exit 1; }
: "${IGNITION_TOKEN:?Generated API token not found. Run ./scripts/bootstrap.sh first.}"

profile_name="${IGN_PROFILE_NAME:-agentic-ignition}"
gateway_url="${IGNITION_GATEWAY_URL%/}"

existing="$(ign profile list --json 2>/dev/null || true)"
if printf '%s' "$existing" | jq -e --arg name "$profile_name" \
  '.data.profiles[]? | select(.name == $name)' >/dev/null 2>&1; then
  ign profile use "$profile_name" >/dev/null
elif ! ign profile add "$profile_name" "$gateway_url" \
    --token-env IGNITION_TOKEN \
    --active \
    --label "Agentic Ignition Stack"; then
  ign profile use "$profile_name"
fi

ign doctor
