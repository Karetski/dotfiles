#!/usr/bin/env bash
set -euo pipefail

file_path=$(jq -r '.tool_input.file_path // .tool_input.path // ""')

protected_patterns=(
  "vars/local.sh"
  ".env"
  ".claude/settings.local.json"
)

for pattern in "${protected_patterns[@]}"; do
  case "$file_path" in
    *"/$pattern"|"$pattern")
      echo "Blocked: '$file_path' is protected. Explain why this edit is necessary." >&2
      exit 2
      ;;
  esac
done

exit 0
