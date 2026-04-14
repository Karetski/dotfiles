#!/usr/bin/env bash
# Toggle the Superpowers plugin's enabled state for the current project.
# Walks up from cwd to find an existing .claude/ directory, reads the
# effective enabled state (local > project > user precedence), flips it,
# and writes the result to .claude/settings.local.json.

set -euo pipefail

PLUGIN="superpowers@claude-plugins-official"

# Nearest ancestor containing .claude/, else cwd
find_root() {
  local d
  d=$(pwd)
  while [ "$d" != "/" ]; do
    if [ -d "$d/.claude" ]; then
      printf '%s' "$d"
      return
    fi
    d=$(dirname "$d")
  done
  pwd
}

root=$(find_root)
dir="$root/.claude"
file="$dir/settings.local.json"

current=""
for candidate in "$file" "$dir/settings.json" "$HOME/.claude/settings.json"; do
  [ -f "$candidate" ] || continue
  # Read the raw value as a string; "null" means the key is absent. Using
  # `// empty` is wrong here because jq's alternative also fires on `false`,
  # which would hide an explicitly-disabled plugin from the precedence check.
  value=$(jq -r --arg name "$PLUGIN" '(.enabledPlugins // {})[$name]' "$candidate" 2>/dev/null || true)
  if [ -n "$value" ] && [ "$value" != "null" ]; then
    current="$value"
    break
  fi
done
# Plugins default to enabled when installed, so an unset value means "on"
[ -z "$current" ] && current="true"

if [ "$current" = "true" ]; then
  new="false"
  label="DISABLED"
else
  new="true"
  label="ENABLED"
fi

mkdir -p "$dir"
[ -f "$file" ] || printf '{}\n' > "$file"

# Write the updated JSON via a temp file. Passing an explicit template keeps
# the write inside $TMPDIR (required under Claude Code's sandbox, where bare
# `mktemp` on macOS would fall back to /var/folders and fail).
tmp=$(mktemp "${TMPDIR:-/tmp}/superpowers-toggle.XXXXXX")
jq --arg name "$PLUGIN" --argjson val "$new" \
  '.enabledPlugins[$name] = $val' "$file" > "$tmp"
mv "$tmp" "$file"

rel="${file#"$root"/}"
printf 'Superpowers %s in %s\n' "$label" "$rel"
printf 'Run /reload-plugins to apply.\n'
