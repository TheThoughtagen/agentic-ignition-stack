#!/usr/bin/env bash
set -euo pipefail

source_path="${1:-${HOME}/Downloads/Project-Scan-Endpoint.modl}"
destination="modules/Project-Scan-Endpoint.modl"
expected_sha256="f0ffb9cf90f0dfb55647080399c4699a32d6ded0387e0142b7c1cb6212806722"

if [[ ! -f "$source_path" ]]; then
  echo "Module not found: $source_path" >&2
  echo "Download the pinned release with ./scripts/download-project-scan-module.sh" >&2
  exit 1
fi

actual_sha256="$(shasum -a 256 "$source_path" | awk '{print $1}')"
if [[ "$actual_sha256" != "$expected_sha256" ]]; then
  echo "Unexpected Project Scan Endpoint checksum: $actual_sha256" >&2
  exit 1
fi

mkdir -p modules
cp "$source_path" "$destination"
printf 'Staged %s for Gateway module installation.\n' "$destination"
