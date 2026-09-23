#!/usr/bin/env bash
set -euo pipefail

: "${IGNITION_PROJECT:?Set IGNITION_PROJECT}"
project_dir="projects/${IGNITION_PROJECT}"

if [[ ! -f "${project_dir}/project.json" ]]; then
  echo "No Ignition project found at ${project_dir}. Create/import it, then run the plugin scaffolds." >&2
  exit 1
fi

command -v ignition-lint >/dev/null 2>&1 || {
  echo "Install ignition-lint-toolkit before testing." >&2
  exit 1
}

ignition-lint --project "$project_dir" --profile default
./scripts/scan-project.sh
./scripts/run-gateway-tests.sh

if [[ ! -d "${project_dir}/e2e" ]]; then
  echo "No Playwright scaffold found at ${project_dir}/e2e. Run /ignition:init-e2e first." >&2
  exit 1
fi

(
  cd "${project_dir}/e2e"
  npx playwright test
)
