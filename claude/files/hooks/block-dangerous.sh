#!/usr/bin/env bash
set -euo pipefail

command=$(jq -r '.tool_input.command // ""')

# Extended-regex patterns. Recursive `rm` of `/`, `~`, or `$HOME` is anchored
# with an end-of-word lookalike so `rm -rf /tmp/foo` and
# `rm -rf ~/Downloads/junk` stay allowed. Push flags must stand alone so
# branch names like `my-feature` don't trip `-f`.
dangerous_patterns=(
  "rm[[:space:]]+-[a-zA-Z]*[rR][a-zA-Z]*[[:space:]]+(/|~|\"?\\\$HOME\"?|\"?\\\$\\{HOME\\}\"?)/?([[:space:];&|]|$)"
  "git reset --hard"
  "git[[:space:]]+push.*[[:space:]](--force[a-z-]*|-f)([[:space:]=]|$)"
  "git[[:space:]]+push.*[[:space:]]\+[^[:space:]]"
  "git[[:space:]]+clean[[:space:]]+-[a-zA-Z]*f"
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

# AI attribution in commits/PRs — case-insensitive, only for commands that
# write commit messages or PR/issue text.
if echo "$command" | grep -qE "git[[:space:]].*commit|gh[[:space:]]+(pr|issue)[[:space:]]"; then
  attribution_pattern="co-authored-by:.*(claude|anthropic)|generated (with|by) (\[)?claude|noreply@anthropic\.com|claude\.(ai|com)/code"
  if echo "$command" | grep -qiE "$attribution_pattern"; then
    echo "Blocked: command adds AI attribution (Co-Authored-By / Generated with Claude). Remove it and retry." >&2
    exit 2
  fi
fi

exit 0
