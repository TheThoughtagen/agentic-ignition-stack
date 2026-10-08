#!/usr/bin/env bash
set -euo pipefail

root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$root"

# shellcheck source=lib/ignition-cli.sh
source "$(dirname "${BASH_SOURCE[0]}")/lib/ignition-cli.sh"

load_ignition_env
require_ign
assert_project_matches_git_yaml
: "${IGNITION_PROJECT:?Set IGNITION_PROJECT to the commissioned sample project name}"
: "${IGNITION_TOKEN:?Run ./scripts/bootstrap.sh first so ign can authenticate.}"

# The generic work-order suite uses its own flat, Gateway-native endpoint.
# Unlike an older nested scaffold, an empty test discovery cannot pass here.
response="$(curl --fail --silent --show-error --request POST \
  "${IGNITION_GATEWAY_URL%/}/system/webdev/${IGNITION_PROJECT}/work-order-tests")"
printf '%s\n' "$response" | jq .
printf '%s' "$response" | jq --exit-status \
  '(.total > 0) and (.failed == 0) and (.errors == 0)' >/dev/null
