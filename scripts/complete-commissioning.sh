#!/usr/bin/env bash
set -euo pipefail

url="${IGNITION_GATEWAY_URL:-http://127.0.0.1:8088}"
status="$(curl --fail --silent "${url%/}/StatusPing" 2>/dev/null || true)"
printf '%s' "$status" | grep -q 'COMMISSIONING' || exit 0

bootstrap="$(curl --fail --silent "${url%/}/bootstrap")"
steps="$(printf '%s' "$bootstrap" | jq -r '.steps | keys[]')"

if printf '%s\n' "$steps" | grep -qx modules; then
  modules="$(curl --fail --silent "${url%/}/get-step?step=modules")"
  licenses="$(printf '%s' "$modules" | jq -c '[.license[].moduleId]')"
  certificates="$(printf '%s' "$modules" | jq -c '[.certificate[].moduleId]')"
  payload="$(jq -n --argjson licenses "$licenses" --argjson certificates "$certificates" \
    '{id:"modules",step:"modules",data:{acceptedLicenses:$licenses,acceptedCertificates:$certificates}}')"
  curl --fail --silent --request POST --header 'Content-Type: application/json' \
    --data "$payload" "${url%/}/post-step" >/dev/null
fi

curl --silent --request POST --header 'Content-Type: application/json' \
  --data '{"id":"finished","step":"finished","data":{"startGateway":true}}' \
  "${url%/}/post-step" >/dev/null

for _ in $(seq 1 90); do
  status="$(curl --fail --silent --max-time 5 "${url%/}/StatusPing" 2>/dev/null || true)"
  if printf '%s' "$status" | grep -q '"state":"RUNNING"' && ! printf '%s' "$status" | grep -q COMMISSIONING; then
    echo 'Gateway module commissioning completed.'
    exit 0
  fi
  sleep 5
done

echo 'Gateway did not leave module commissioning mode.' >&2
exit 1
