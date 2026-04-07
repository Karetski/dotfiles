#!/usr/bin/env bash
set -euo pipefail

file_path=$(jq -r '.tool_input.file_path // .tool_input.path // ""')

# Only check .sh files
if [[ "$file_path" != *.sh ]]; then
  exit 0
fi

# Only check if the file exists
if [[ ! -f "$file_path" ]]; then
  exit 0
fi

if ! bash -n "$file_path" 2>&1; then
  echo "Syntax error in $file_path — fix before continuing." >&2
  exit 1
fi

exit 0
