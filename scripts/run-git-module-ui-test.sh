#!/usr/bin/env bash
set -euo pipefail

root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$root"

[[ -f .env ]] || { echo 'Missing .env; run cp .env.example .env first.' >&2; exit 1; }
set -a
# shellcheck disable=SC1091
source .env
set +a

export IGNITION_URL="${IGNITION_GATEWAY_URL:-http://127.0.0.1:8088}"
export IGNITION_USER="${GATEWAY_ADMIN_USERNAME:?Set GATEWAY_ADMIN_USERNAME in .env}"
export IGNITION_PASSWORD="${GATEWAY_ADMIN_PASSWORD:?Set GATEWAY_ADMIN_PASSWORD in .env}"

cd projects/example-project/e2e
[[ -d node_modules ]] || npm install --no-package-lock
npm run test:git-module
