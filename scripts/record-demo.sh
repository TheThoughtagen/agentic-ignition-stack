#!/usr/bin/env bash
set -euo pipefail

root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$root"

vhs_bin="${VHS_BIN:-vhs}"
command -v "$vhs_bin" >/dev/null 2>&1 || {
  echo 'VHS is required. Install the tested version with:' >&2
  echo '  go install github.com/charmbracelet/vhs@v0.11.0' >&2
  exit 1
}

./scripts/demo-status.sh >/dev/null
mkdir -p artifacts
rm -f artifacts/agentic-ignition-stack-demo.mp4 artifacts/agentic-ignition-stack-demo.gif
"$vhs_bin" demo/agentic-ignition-stack.tape

for artifact in artifacts/agentic-ignition-stack-demo.mp4 artifacts/agentic-ignition-stack-demo.gif; do
  [[ -s "$artifact" ]] || {
    echo "VHS did not create $artifact. VHS 0.12.0 has a known rendering regression; use v0.11.0." >&2
    exit 1
  }
done

printf 'Created:\n  %s\n  %s\n' \
  "$root/artifacts/agentic-ignition-stack-demo.mp4" \
  "$root/artifacts/agentic-ignition-stack-demo.gif"
