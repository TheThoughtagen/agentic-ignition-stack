#!/usr/bin/env bash
set -euo pipefail

root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$root"

# shellcheck source=lib/ignition-cli.sh
source "$(dirname "${BASH_SOURCE[0]}")/lib/ignition-cli.sh"

load_ignition_env
assert_project_matches_git_yaml

project_dir="projects/${IGNITION_PROJECT}"
for _ in $(seq 1 90); do
  if [[ -f "${project_dir}/project.json" && -d "${project_dir}/.git" ]]; then
    printf 'Commissioned sample ready at %s (%s)\n' \
      "$project_dir" \
      "$(git -C "$project_dir" rev-parse --short HEAD)"
    exit 0
  fi
  sleep 5
done

echo "Git module did not clone agentic-ignition-example-project as ${project_dir} within the wait budget." >&2
echo "Confirm the Git module is installed and gw-init/git.yaml commissions IGNITION_PROJECT=${IGNITION_PROJECT}." >&2
exit 1
