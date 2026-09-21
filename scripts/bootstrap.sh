#!/usr/bin/env bash
set -euo pipefail

if ! command -v docker >/dev/null 2>&1; then
  echo "Docker is required. Install Docker Desktop or Docker Engine first." >&2
  exit 1
fi

if ! docker compose version >/dev/null 2>&1; then
  echo "Docker Compose v2 is required." >&2
  exit 1
fi

if [[ ! -f .env ]]; then
  echo "Create .env from .env.example and set a tested IGNITION_IMAGE first." >&2
  exit 1
fi

docker compose --env-file .env config --quiet
docker compose --env-file .env up -d

echo "Gateway started. Follow its logs with: docker compose --env-file .env logs -f ignition"
echo "Complete commissioning at the local gateway before running scan or test commands."
