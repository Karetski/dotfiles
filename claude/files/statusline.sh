#!/usr/bin/env bash
# Claude Code status line script.
# The Claude Code harness pipes a JSON payload to stdin on each render tick;
# this script parses it and prints a single pipe-separated status string.

input=$(cat)

# ── Directory ────────────────────────────────────────────────────────────────
# Show only the last two path components (e.g. "dotfiles/neovim")
current_dir_full=$(echo "$input" | jq -r '.workspace.current_dir // empty')
current_dir="${current_dir_full/#$HOME/\~}"
current_dir=$(echo "$current_dir" | awk -F/ '{print $(NF-1)"/"$NF}')

# ── Model ────────────────────────────────────────────────────────────────────
# Strip "Claude " prefix and trailing date suffix (e.g. "Claude Opus 4.6 20250101" → "Opus 4.6")
model=$(echo "$input" | jq -r '.model.display_name // empty' | sed 's/^Claude //; s/ [0-9].*$//')

# ── Context window usage ─────────────────────────────────────────────────────
used_pct=$(echo "$input" | jq -r '.context_window.used_percentage // empty')
used_pct_int=$(printf '%.0f' "${used_pct:-0}")

# ── 5-hour rate limit ────────────────────────────────────────────────────────
five_pct=$(echo "$input" | jq -r '.rate_limits.five_hour.used_percentage // empty')
five_resets_at=$(echo "$input" | jq -r '.rate_limits.five_hour.resets_at // empty')

# Convert reset timestamp to a human-readable countdown (e.g. "3h12m")
five_reset_str=""
if [ -n "$five_resets_at" ]; then
  now=$(date +%s)
  remaining=$(( five_resets_at - now ))
  if [ "$remaining" -gt 0 ]; then
    hrs=$(( remaining / 3600 ))
    mins=$(( (remaining % 3600) / 60 ))
    if [ "$hrs" -gt 0 ]; then
      five_reset_str="${hrs}h${mins}m"
    else
      five_reset_str="${mins}m"
    fi
  else
    five_reset_str="now"
  fi
fi

# ── Plugins line ─────────────────────────────────────────────────────────────
# Second line listing installed plugins relevant to this cwd (user-scoped or
# project-scoped where cwd is under projectPath), each prefixed with + or -
# based on effective enabled state (local > project > user, default enabled).
plugins_file="$HOME/.claude/plugins/installed_plugins.json"
plugins_line=""
if [ -f "$plugins_file" ] && [ -n "$current_dir_full" ]; then
  relevant=$(jq -r --arg cwd "$current_dir_full" '
    .plugins
    | to_entries[]
    | select(
        .value
        | any(
            .scope == "user"
            or ((.projectPath // "") as $p | ($p | length) > 0 and ($cwd | startswith($p)))
          )
      )
    | .key
  ' "$plugins_file" 2>/dev/null || true)

  plugin_parts=()
  while IFS= read -r name; do
    [ -z "$name" ] && continue
    state=""
    for f in "$current_dir_full/.claude/settings.local.json" \
             "$current_dir_full/.claude/settings.json" \
             "$HOME/.claude/settings.json"; do
      [ -f "$f" ] || continue
      # `(.enabledPlugins // {})[$n]` returns "null" when unset, "true"/"false"
      # otherwise. `// empty` would misfire on `false` and fall through.
      v=$(jq -r --arg n "$name" '(.enabledPlugins // {})[$n]' "$f" 2>/dev/null || true)
      if [ -n "$v" ] && [ "$v" != "null" ]; then state="$v"; break; fi
    done
    [ -z "$state" ] && state="true"
    short="${name%@*}"
    if [ "$state" = "true" ]; then
      plugin_parts+=("+$short")
    else
      plugin_parts+=("-$short")
    fi
  done <<< "$relevant"

  if [ "${#plugin_parts[@]}" -gt 0 ]; then
    plugins_line="plugins: ${plugin_parts[*]}"
  fi
fi

# ── Assemble segments ────────────────────────────────────────────────────────
# Join non-empty segments with " │ " separators
sep=" │ "
parts=()
[ -n "$current_dir" ] && parts+=("$current_dir")
[ -n "$model" ] && parts+=("$model")
[ -n "$used_pct" ] && parts+=("ctx:${used_pct_int}%")
if [ -n "$five_pct" ] && [ -n "$five_reset_str" ]; then
  parts+=("5h:$(printf '%.0f' "$five_pct")% | ${five_reset_str}")
elif [ -n "$five_pct" ]; then
  parts+=("5h:$(printf '%.0f' "$five_pct")%")
fi

result=""
for part in "${parts[@]}"; do
  [ -n "$result" ] && result="${result}${sep}${part}" || result="$part"
done
printf '%s' "$result"
[ -n "$plugins_line" ] && printf '\n%s' "$plugins_line"
