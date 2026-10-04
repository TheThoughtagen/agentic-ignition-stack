#!/usr/bin/env bash
set -euo pipefail

root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$root"

# shellcheck source=lib/ignition-cli.sh
source "$(dirname "${BASH_SOURCE[0]}")/lib/ignition-cli.sh"

load_ignition_env
assert_project_matches_git_yaml

[[ -f .env ]] || { echo 'Missing .env; run cp .env.example .env first.' >&2; exit 1; }

export IGNITION_URL="${IGNITION_GATEWAY_URL:-http://127.0.0.1:8088}"
export IGNITION_USER="${GATEWAY_ADMIN_USERNAME:?Set GATEWAY_ADMIN_USERNAME in .env}"
export IGNITION_PASSWORD="${GATEWAY_ADMIN_PASSWORD:?Set GATEWAY_ADMIN_PASSWORD in .env}"
export GIT_SAMPLE_REPO_URI="${GIT_SAMPLE_REPO_URI:-https://github.com/TheThoughtagen/agentic-ignition-example-project.git}"

cd e2e
[[ -d node_modules ]] || npm install --no-package-lock
npm run test:git-module
