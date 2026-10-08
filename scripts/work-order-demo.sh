#!/usr/bin/env bash
# Local-only work-order demonstration entry point. Run from the stack root.
set -euo pipefail
root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$root"
[[ -f .env ]] || { echo 'Create .env from .env.example first.' >&2; exit 1; }
set -a
# shellcheck disable=SC1091
. ./.env
set +a
: "${DEMO_DB_PASSWORD:?Set DEMO_DB_PASSWORD in ignored .env}"
: "${IGNITION_PROJECT:?Set IGNITION_PROJECT in ignored .env}"
: "${IGNITION_GATEWAY_URL:?Set IGNITION_GATEWAY_URL in ignored .env}"

case "${1:-help}" in
  up)
    ./scripts/bootstrap.sh
    python3 ./scripts/configure-demo-db.py
    ./scripts/scan-project.sh
    echo "Perspective: ${IGNITION_GATEWAY_URL%/}/data/perspective/client/${IGNITION_PROJECT}/work-orders"
    ;;
  test)
    ./scripts/test.sh
    ;;
  cli)
    IGNITION_TOKEN="$(< secrets/ignition-api-token)"
    export IGNITION_TOKEN
    ign --profile "${IGN_PROFILE_NAME:-agentic-ignition}" status
    ign --profile "${IGN_PROFILE_NAME:-agentic-ignition}" connections --type database
    ;;
  db)
    docker compose exec -T postgres psql -U work_order_demo -d work_order_demo -c \
      'SELECT work_order_id, asset, triage_state, updated_at FROM work_order_triage ORDER BY work_order_id'
    ;;
  *)
    echo 'Usage: ./scripts/work-order-demo.sh up|test|cli|db' >&2
    exit 2
    ;;
esac
