#!/usr/bin/env bash
# common.sh — Shared functions for Ignition Dev Tools plugin scripts.
# Source this file: source "$(dirname "$0")/lib/common.sh"

# Walk up from a directory to find the nearest project.json (Ignition project marker).
# Usage: PROJECT_ROOT=$(find_project_root "$PWD") || exit 0
# Stops when dirname stops changing: a Windows path ends at "C:" and a relative one at ".", never at "/".
find_project_root() {
  local dir="$1" parent
  while :; do
    if [ -f "$dir/project.json" ]; then echo "$dir"; return 0; fi
    parent=$(dirname "$dir")
    [ "$parent" = "$dir" ] && return 1
    dir="$parent"
  done
}

# Write a file with existence check, dry-run support, and force overwrite.
# Requires: PROJECT_ROOT, DRY_RUN, FORCE, CREATED, SKIPPED variables set by caller.
# Usage: write_file "relative/path/file.ext" "$CONTENT"
write_file() {
  local filepath="$1"
  local content="$2"
  local full_path="$PROJECT_ROOT/$filepath"

  # Check existence before dry-run so --dry-run accurately reflects real behavior
  if [[ -f "$full_path" ]] && [[ "$FORCE" != true ]]; then
    if [[ "$DRY_RUN" = true ]]; then
      echo "  Would skip (exists): $filepath"
    else
      echo "  Skipped (exists): $filepath"
    fi
    SKIPPED=$((SKIPPED + 1))
    return
  fi

  if [[ "$DRY_RUN" = true ]]; then
    echo "  Would create: $filepath"
    return
  fi

  mkdir -p "$(dirname "$full_path")" || {
    echo "Error: cannot create directory for $filepath — check permissions on $PROJECT_ROOT" >&2
    exit 1
  }
  printf '%s' "$content" > "$full_path"
  CREATED=$((CREATED + 1))
  echo "  Created: $filepath"
}
