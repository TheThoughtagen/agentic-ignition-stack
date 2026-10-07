#!/usr/bin/env bash
set -euo pipefail

version="${PROJECT_SCAN_MODULE_VERSION:-v1.0.0}"
asset="Project-Scan-Endpoint.modl"
url="https://github.com/bw-design-group/ignition-project-scan-endpoint/releases/download/${version}/${asset}"
destination="modules/${asset}"
# Verified against the upstream v1.0.0 release artifact; fail closed on drift.
expected_sha256="f0ffb9cf90f0dfb55647080399c4699a32d6ded0387e0142b7c1cb6212806722"

[[ "$version" == "v1.0.0" ]] || {
  echo "No verified checksum for Project Scan Endpoint ${version}." >&2
  exit 1
}
mkdir -p modules
temporary="$(mktemp modules/.project-scan.XXXXXX)"
trap 'rm -f "$temporary"' EXIT
curl --fail --location --silent --show-error --output "$temporary" "$url"
actual_sha256="$(openssl dgst -sha256 -r "$temporary" | awk '{print $1}')"
[[ "$actual_sha256" == "$expected_sha256" ]] || {
  echo "Project Scan Endpoint checksum mismatch; refusing module." >&2
  exit 1
}
mv "$temporary" "$destination"
trap - EXIT
printf 'Downloaded and verified %s (%s).\n' "$destination" "$version"
