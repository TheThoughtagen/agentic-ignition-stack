#!/usr/bin/env bash
# Shared helpers for talking to the local gateway through ignition-cli (`ign`).
# Shellcheck: source this file after setting -euo pipefail in the caller.

load_ignition_env() {
  if [[ -f .env ]]; then
    set -a
    # shellcheck disable=SC1091
    . ./.env
    set +a
  fi
  if [[ -z "${IGNITION_TOKEN:-}" && -s secrets/ignition-api-token ]]; then
    IGNITION_TOKEN="$(tr -d '\r\n' < secrets/ignition-api-token)"
    export IGNITION_TOKEN
  fi
  export IGNITION_GATEWAY_URL="${IGNITION_GATEWAY_URL:-http://127.0.0.1:8088}"
  export IGNITION_PROJECT="${IGNITION_PROJECT:-example-project}"
}

require_ign() {
  command -v ign >/dev/null 2>&1 || {
    echo "ign is required (https://github.com/TheThoughtagen/ignition-cli)." >&2
    echo "Install a release binary or: cargo install ignition-cli" >&2
    exit 1
  }
}

commissioned_project_names() {
  awk '$1 == "ignition_projectName:" { print $2 }' gw-init/git.yaml
}

assert_project_matches_git_yaml() {
  local names
  names="$(commissioned_project_names)"
  if [[ -z "$names" ]]; then
    echo "gw-init/git.yaml is missing ignition_projectName." >&2
    exit 1
  fi
  if ! printf '%s\n' "$names" | grep -Fxq -- "$IGNITION_PROJECT"; then
    echo "IGNITION_PROJECT (${IGNITION_PROJECT}) must match a gw-init/git.yaml ignition_projectName ($(printf '%s' "$names" | tr '\n' ' '))." >&2
    exit 1
  fi
}
