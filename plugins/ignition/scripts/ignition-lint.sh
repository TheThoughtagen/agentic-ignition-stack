#!/usr/bin/env bash
# ignition-lint.sh — PostToolUse hook for Ignition projects
# Only runs when the edited file is inside an Ignition project (has project.json).

set -euo pipefail

source "$(dirname "$0")/lib/common.sh"

INPUT=$(cat)
# jq.exe on Windows ends its output with \r\n
FILE_PATH=$(echo "$INPUT" | jq -r '.tool_input.file_path // empty' | tr -d '\r')

# Bail if no file path or file doesn't exist
if [ -z "$FILE_PATH" ] || [ ! -f "$FILE_PATH" ]; then
  exit 0
fi

# Pick the lint profile first, so files that are never linted skip the project search
BASENAME=$(basename "$FILE_PATH")
EXT="${FILE_PATH##*.}"
PROFILE=""
case "$EXT" in
  py) PROFILE=scripts-only ;;
  json)
    case "$BASENAME" in
      view.json) PROFILE=perspective-only ;;
      tags.json) PROFILE=full ;;
    esac
    ;;
esac
[ -n "$PROFILE" ] || exit 0

PROJECT_ROOT=$(find_project_root "$(dirname "$FILE_PATH")") || exit 0

# Only proceed if ignition-lint is installed
if ! command -v ignition-lint &>/dev/null; then
  exit 0
fi

OUTPUT=$(ignition-lint --target "$FILE_PATH" --profile "$PROFILE" 2>&1) || true

if [ -n "$OUTPUT" ]; then
  jq -n \
    --arg reason "ignition-lint found issues in $BASENAME" \
    --arg context "$OUTPUT" \
    '{
      decision: "block",
      reason: $reason,
      hookSpecificOutput: {
        hookEventName: "PostToolUse",
        additionalContext: $context
      }
    }'
fi

exit 0
