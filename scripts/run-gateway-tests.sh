#!/usr/bin/env bash
set -euo pipefail

root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$root"

# shellcheck source=lib/ignition-cli.sh
source "$(dirname "${BASH_SOURCE[0]}")/lib/ignition-cli.sh"

load_ignition_env
require_ign
: "${IGNITION_PROJECT:?Set IGNITION_PROJECT to the commissioned sample project name}"
: "${IGNITION_TOKEN:?Run ./scripts/bootstrap.sh first so ign can authenticate.}"

ign testing run --project "$IGNITION_PROJECT"
