#!/usr/bin/env bash
set -euo pipefail

root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$root"

for command in docker curl jq openssl unzip ign; do
  command -v "$command" >/dev/null 2>&1 || {
    if [[ "$command" == "ign" ]]; then
      echo "ign is required (https://github.com/TheThoughtagen/ignition-cli)." >&2
      echo "Install a release binary or: cargo install ignition-cli" >&2
    else
      echo "$command is required." >&2
    fi
    exit 1
  }
done

docker compose version >/dev/null 2>&1 || {
  echo "Docker Compose v2 is required." >&2
  exit 1
}

if [[ ! -f .env ]]; then
  cp .env.example .env
  echo "Created .env from .env.example. Replace the local admin password before shared use."
fi
# shellcheck source=lib/ignition-cli.sh
source "$(dirname "${BASH_SOURCE[0]}")/lib/ignition-cli.sh"
load_ignition_env
assert_project_matches_git_yaml

git_modl_matches_requested_version() {
  local file="$1"
  local ver base
  [[ -n "${GIT_MODULE_VERSION:-}" ]] || return 0
  ver="${GIT_MODULE_VERSION#v}"
  base="$(basename "$file")"
  [[ "$base" == *"$ver"* ]]
}

is_git_modl() {
  local base
  base="$(basename "$1")"
  [[ "$base" == Git*.modl || "$base" == git*.modl ]]
}

git_override_basename=""

./scripts/bootstrap-api-token.sh

if [[ "${AUTO_INSTALL_MODULES:-true}" == "true" ]]; then
  if [[ "${CI:-false}" == "true" && ! -f modules/Project-Scan-Endpoint.modl ]]; then
    echo 'CI requires a verified Project Scan Endpoint module before bootstrap.' >&2
    exit 1
  fi
  if [[ "${CI:-false}" != "true" && -f "$HOME/Downloads/Project-Scan-Endpoint.modl" ]]; then
    ./scripts/stage-project-scan-module.sh "$HOME/Downloads/Project-Scan-Endpoint.modl"
  elif [[ ! -f modules/Project-Scan-Endpoint.modl ]]; then
    ./scripts/download-project-scan-module.sh
  fi

  git_modl_staged=false
  git_override_basename=""
  shopt -s nullglob
  for _existing_git_modl in modules/Git*.modl modules/git*.modl; do
    if git_modl_matches_requested_version "$_existing_git_modl"; then
      git_modl_staged=true
      break
    fi
  done
  shopt -u nullglob

  if [[ -n "${GIT_MODULE_SOURCE:-}" ]]; then
    git_source="${GIT_MODULE_SOURCE/#\~/$HOME}"
    if [[ -f "$git_source" ]]; then
      ./scripts/stage-git-module.sh "$git_source"
      git_modl_staged=true
      git_override_basename="$(basename "$git_source")"
    elif [[ "$git_modl_staged" != "true" ]]; then
      echo "GIT_MODULE_SOURCE is set but not found at ${git_source}; downloading the latest Git module release." >&2
    fi
  fi

  if [[ "$git_modl_staged" != "true" ]]; then
    ./scripts/download-git-module.sh
  fi
fi

docker compose --env-file .env config --quiet
docker compose --env-file .env up -d

token="$(tr -d '\r\n' < secrets/ignition-api-token)"
gateway_url="${IGNITION_GATEWAY_URL:-http://127.0.0.1:8088}"
for _ in $(seq 1 90); do
  state="$(curl --fail --silent --max-time 5 "${gateway_url%/}/StatusPing" 2>/dev/null || true)"
  printf '%s' "$state" | grep -q '"state":"RUNNING"' && break
  sleep 5
done

api_code="$(curl --silent --output /dev/null --write-out '%{http_code}' --max-time 10 \
  --header "X-Ignition-API-Token: $token" \
  "${gateway_url%/}/data/api/v1/gateway-info" || true)"
if [[ "$api_code" == "403" ]]; then
  ./scripts/patch-security-properties.sh
  docker compose --env-file .env restart ignition
  for _ in $(seq 1 90); do
    state="$(curl --fail --silent --max-time 5 "${gateway_url%/}/StatusPing" 2>/dev/null || true)"
    printf '%s' "$state" | grep -q '"state":"RUNNING"' && break
    sleep 5
  done
fi

curl --fail --silent --show-error --max-time 10 \
  --header "X-Ignition-API-Token: $token" \
  "${gateway_url%/}/data/api/v1/gateway-info" >/dev/null || {
    echo "Gateway API did not become ready with the generated token." >&2
    exit 1
  }

installed=false
if [[ "${AUTO_INSTALL_MODULES:-true}" == "true" ]]; then
  healthy="$(curl --fail --silent --header "X-Ignition-API-Token: $token" \
    "${gateway_url%/}/data/api/v1/modules/healthy")"
  for module in modules/*.modl; do
    [[ -e "$module" ]] || continue
    if [[ -n "${GIT_MODULE_VERSION:-}" ]] && is_git_modl "$module"; then
      if ! git_modl_matches_requested_version "$module" && \
        [[ "$(basename "$module")" != "$git_override_basename" ]]; then
        printf 'Skipping %s (does not match GIT_MODULE_VERSION=%s).\n' \
          "$(basename "$module")" "$GIT_MODULE_VERSION"
        continue
      fi
    fi
    module_id="$(unzip -p "$module" module.xml | tr -d '\r\n' | grep -o '<id>[^<]*</id>' | head -1 | sed -e 's#<id>##' -e 's#</id>##')"
    if [[ "${FORCE_MODULE_INSTALL:-false}" != "true" ]] && \
      printf '%s' "$healthy" | jq -e --arg id "$module_id" \
      'any((.items? // .)[]; (.id // .moduleId) == $id)' >/dev/null; then
      printf '%s is already healthy; skipping.\n' "$module_id"
      continue
    fi
    ./scripts/install-module.sh "$module"
    installed=true
  done
fi

if [[ "$installed" == "true" ]]; then
  docker compose --env-file .env restart ignition
  for _ in $(seq 1 90); do
    state="$(curl --fail --silent --max-time 5 "${gateway_url%/}/StatusPing" 2>/dev/null || true)"
    printf '%s' "$state" | grep -q '"state":"RUNNING"' && break
    sleep 5
  done
  ./scripts/complete-commissioning.sh
fi

curl --fail --silent --show-error --max-time 10 \
  --header "X-Ignition-API-Token: $token" \
  "${gateway_url%/}/data/api/v1/gateway-info" >/dev/null

./scripts/wait-for-sample-project.sh
./scripts/configure-ign-profile.sh

printf 'Gateway ready at %s with generated API-token automation.\n' "$gateway_url"
printf 'Sample project %s commissioned from GitHub; ign profile %s is active.\n' \
  "$IGNITION_PROJECT" \
  "${IGN_PROFILE_NAME:-agentic-ignition}"
