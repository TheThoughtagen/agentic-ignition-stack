#!/usr/bin/env bash
set -euo pipefail

source_path="${1:-${GIT_MODULE_SOURCE:-}}"
source_path="${source_path/#\~/$HOME}"
[[ -n "$source_path" && -f "$source_path" ]] || {
  echo "Git module not found: ${source_path:-<empty>}" >&2
  echo "Pass a local .modl path, set GIT_MODULE_SOURCE, or run ./scripts/download-git-module.sh." >&2
  exit 1
}

mkdir -p modules
filename="$(basename "$source_path")"
cp "$source_path" "modules/${filename}"
printf 'Staged Git module at modules/%s\n' "$filename"
