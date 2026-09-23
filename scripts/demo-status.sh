#!/usr/bin/env bash
set -euo pipefail

root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$root"

[[ -f .env ]] || { echo 'Missing .env; run cp .env.example .env first.' >&2; exit 1; }
[[ -f secrets/ignition-api-token ]] || { echo 'Missing generated API token; run ./scripts/bootstrap.sh first.' >&2; exit 1; }

gateway_url="$(awk -F= '$1 == "IGNITION_GATEWAY_URL" {print substr($0, index($0, "=") + 1)}' .env)"
gateway_url="${gateway_url:-http://127.0.0.1:8088}"
token="$(<secrets/ignition-api-token)"

echo 'Gateway status'
curl --fail --silent "${gateway_url%/}/StatusPing" | jq .

echo
echo 'Installed development modules'
curl --fail --silent \
  --header "X-Ignition-API-Token: $token" \
  "${gateway_url%/}/data/api/v1/modules/healthy" |
  jq '[((.items? // .)[]) | select((.id // .moduleId) == "project-scan-endpoint" or (.id // .moduleId) == "com.axone_io.ignition.git") | {id:(.id // .moduleId), version}]'

echo
echo 'Git-commissioned sample project'
project_dir='projects/git-example-project'
[[ -d "$project_dir/.git" ]] || { echo 'Runtime clone not found.' >&2; exit 1; }
remote="$(git -C "$project_dir" remote | head -1)"
printf 'project: git-example-project\nbranch:  %s\nremote:  %s\ncommit:  %s\n' \
  "$(git -C "$project_dir" branch --show-current)" \
  "$(git -C "$project_dir" remote get-url "$remote")" \
  "$(git -C "$project_dir" rev-parse --short HEAD)"

echo
echo 'Project Scan Endpoint'
curl --fail --silent \
  --header "X-Ignition-API-Token: $token" \
  "${gateway_url%/}/data/project-scan-endpoint/confirm-support" | jq .
