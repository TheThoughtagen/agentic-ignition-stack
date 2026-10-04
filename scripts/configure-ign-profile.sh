#!/usr/bin/env bash
set -euo pipefail

root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$root"

# shellcheck source=lib/ignition-cli.sh
source "$(dirname "${BASH_SOURCE[0]}")/lib/ignition-cli.sh"

load_ignition_env
require_ign
: "${IGNITION_TOKEN:?Generated API token not found. Run ./scripts/bootstrap.sh first.}"

profile_name="${IGN_PROFILE_NAME:-agentic-ignition}"
gateway_url="${IGNITION_GATEWAY_URL%/}"

# add overwrites an existing profile of the same name, so a changed
# IGNITION_GATEWAY_URL is applied instead of reusing a stale URL.
ign profile add "$profile_name" "$gateway_url" \
  --token-env IGNITION_TOKEN \
  --active \
  --label "Agentic Ignition Stack"

ign doctor
