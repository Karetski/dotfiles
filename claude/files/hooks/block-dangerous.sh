#!/usr/bin/env bash
set -euo pipefail

command=$(jq -r '.tool_input.command // ""')

# Extended-regex patterns. `rm -rf /` and `rm -rf ~` are anchored with an
# end-of-string-or-whitespace lookalike so `rm -rf /tmp/foo` and
# `rm -rf ~/Downloads/junk` stay allowed.
dangerous_patterns=(
  "rm[[:space:]]+-rf?[[:space:]]+/([[:space:]]|$)"
  "rm[[:space:]]+-rf?[[:space:]]+~([[:space:]]|$)"
  "git reset --hard"
  "git push.*--force"
  "git push.*-f"
  "git clean -fd"
  "DROP TABLE"
  "DROP DATABASE"
  "> /dev/sda"
  "mkfs\."
)

for pattern in "${dangerous_patterns[@]}"; do
  if echo "$command" | grep -qE "$pattern"; then
    echo "Blocked: command matches dangerous pattern '$pattern'. Propose a safer alternative." >&2
    exit 2
  fi
done

# Fork bomb — fixed-string match (the classic payload contains ERE
# metacharacters that broke the previous regex form).
if echo "$command" | grep -qF ':(){ :|:& };:'; then
  echo "Blocked: command contains a fork bomb. Propose a safer alternative." >&2
  exit 2
fi

exit 0
