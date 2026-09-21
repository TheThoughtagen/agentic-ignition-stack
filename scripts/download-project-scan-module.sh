#!/usr/bin/env bash
set -euo pipefail

version="${PROJECT_SCAN_MODULE_VERSION:-v1.0.0}"
asset="Project-Scan-Endpoint.modl"
url="https://github.com/bw-design-group/ignition-project-scan-endpoint/releases/download/${version}/${asset}"
destination="modules/${asset}"

mkdir -p modules
curl --fail --location --silent --show-error --output "$destination" "$url"
printf 'Downloaded %s (%s). Install it in Gateway → Config → Modules → Install or Upgrade a Module.\n' "$destination" "$version"
