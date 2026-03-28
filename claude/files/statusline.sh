#!/usr/bin/env bash
# Claude Code status line script
# Receives JSON on stdin; outputs a single status line string.

input=$(cat)

# Current working directory (shortened)
current_dir=$(echo "$input" | jq -r '.workspace.current_dir // empty')
current_dir="${current_dir/#$HOME/\~}"
current_dir=$(echo "$current_dir" | awk -F/ '{print $(NF-1)"/"$NF}')

# Git branch
branch=$(git -C "${current_dir/#\~/$HOME}" --no-optional-locks symbolic-ref --short HEAD 2>/dev/null)

# Model (strip date suffix like -20241022)
model=$(echo "$input" | jq -r '.model.display_name // empty' | sed 's/ [0-9].*$//')

# Context usage + progress bar
used_pct=$(echo "$input" | jq -r '.context_window.used_percentage // empty')
used_pct_int=$(printf '%.0f' "${used_pct:-0}")
n=$((used_pct_int * 10 / 100))
bar=""
for i in $(seq 1 10); do [ "$i" -le "$n" ] && bar="${bar}▓" || bar="${bar}░"; done

# Rate limits
five_pct=$(echo "$input" | jq -r '.rate_limits.five_hour.used_percentage // empty')

# Assemble
sep="  │  "
parts=()
[ -n "$current_dir" ] && parts+=("$current_dir${branch:+  ⎇ $branch}")
[ -n "$model" ] && parts+=("$model")
[ -n "$used_pct" ] && parts+=("$bar ${used_pct_int}%")
[ -n "$five_pct" ] && parts+=("5h: $(printf '%.0f' "$five_pct")%")

result=""
for part in "${parts[@]}"; do
  [ -n "$result" ] && result="${result}${sep}${part}" || result="$part"
done
printf '%s' "$result"
