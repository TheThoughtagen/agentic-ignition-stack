#!/usr/bin/env bash
set -euo pipefail

root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$root"

# shellcheck source=lib/ignition-cli.sh
source "$(dirname "${BASH_SOURCE[0]}")/lib/ignition-cli.sh"

load_ignition_env
require_ign
assert_project_matches_git_yaml
: "${IGNITION_TOKEN:?Run ./scripts/bootstrap.sh first so ign can authenticate.}"

project_dir="projects/${IGNITION_PROJECT}"

if [[ ! -f "${project_dir}/project.json" ]]; then
  echo "No commissioned sample at ${project_dir}." >&2
  echo "Run ./scripts/bootstrap.sh so the Git module can clone agentic-ignition-example-project." >&2
  exit 1
fi

ign lint "$project_dir" --strict -- --profile default
./scripts/scan-project.sh
./scripts/run-gateway-tests.sh

if [[ ! -d "${project_dir}/e2e" ]]; then
  echo "No Playwright scaffold found at ${project_dir}/e2e." >&2
  echo "The commissioned GitHub sample must include e2e/; run /ignition:init-e2e in that repository." >&2
  exit 1
fi

export IGNITION_URL="${IGNITION_GATEWAY_URL}"
export IGNITION_USER="${GATEWAY_ADMIN_USERNAME:?Set GATEWAY_ADMIN_USERNAME in .env}"
export IGNITION_PASSWORD="${GATEWAY_ADMIN_PASSWORD:?Set GATEWAY_ADMIN_PASSWORD in .env}"
export PERSPECTIVE_PROJECT="${IGNITION_PROJECT}"

(
  cd "${project_dir}/e2e"
  if [[ -f package-lock.json ]]; then
    [[ -d node_modules ]] || npm ci
  else
    [[ -d node_modules ]] || npm install --no-package-lock
  fi
  npx playwright test --project=chromium
)
