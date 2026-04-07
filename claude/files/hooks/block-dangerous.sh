#!/usr/bin/env bash
set -euo pipefail

command=$(jq -r '.tool_input.command // ""')

dangerous_patterns=(
  "rm -rf /"
  "rm -rf ~"
  "git reset --hard"
  "git push.*--force"
  "git push.*-f"
  "git clean -fd"
  "DROP TABLE"
  "DROP DATABASE"
  "> /dev/sda"
  "mkfs\."
  ":(){ :|:& };:"
)

for pattern in "${dangerous_patterns[@]}"; do
  if echo "$command" | grep -qE "$pattern"; then
    echo "Blocked: command matches dangerous pattern '$pattern'. Propose a safer alternative." >&2
    exit 2
  fi
done

exit 0
