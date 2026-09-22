#!/usr/bin/env bash
set -euo pipefail

root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$root"

for command in docker curl jq openssl unzip; do
  command -v "$command" >/dev/null 2>&1 || {
    echo "$command is required." >&2
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
set -a
# shellcheck disable=SC1091
. ./.env
set +a

./scripts/bootstrap-api-token.sh

if [[ "${AUTO_INSTALL_MODULES:-true}" == "true" ]]; then
  if [[ -f "$HOME/Downloads/Project-Scan-Endpoint.modl" ]]; then
    ./scripts/stage-project-scan-module.sh "$HOME/Downloads/Project-Scan-Endpoint.modl"
  elif [[ ! -f modules/Project-Scan-Endpoint.modl ]]; then
    ./scripts/download-project-scan-module.sh
  fi

  git_source="${GIT_MODULE_SOURCE:-$HOME/whiskeyhouse/whk-environment-orchestration/Git-unsigned.modl}"
  git_source="${git_source/#\~/$HOME}"
  if [[ -f "$git_source" ]]; then
    ./scripts/stage-git-module.sh "$git_source"
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
printf 'Gateway ready at %s with generated API-token automation.\n' "$gateway_url"
