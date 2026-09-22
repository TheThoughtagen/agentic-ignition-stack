#!/usr/bin/env bash
set -euo pipefail

source_path="${1:-${GIT_MODULE_SOURCE:-${HOME}/whiskeyhouse/whk-environment-orchestration/Git-unsigned.modl}}"
source_path="${source_path/#\~/$HOME}"
[[ -f "$source_path" ]] || {
  echo "Git module not found: $source_path" >&2
  echo "Pass its .modl path or set GIT_MODULE_SOURCE." >&2
  exit 1
}

mkdir -p modules
filename="$(basename "$source_path")"
cp "$source_path" "modules/${filename}"
printf 'Staged Git module at modules/%s\n' "$filename"
