#!/usr/bin/env bash
# Claude Code status line script
# Receives JSON on stdin; outputs a single status line string.

input=$(cat)

# Current working directory (shortened)
current_dir_full=$(echo "$input" | jq -r '.workspace.current_dir // empty')
current_dir="${current_dir_full/#$HOME/\~}"
current_dir=$(echo "$current_dir" | awk -F/ '{print $(NF-1)"/"$NF}')

# Git branch + dirty indicator
branch=$(git -C "$current_dir_full" --no-optional-locks symbolic-ref --short HEAD 2>/dev/null)
if [ -n "$branch" ]; then
  porcelain=$(git -C "$current_dir_full" --no-optional-locks status --porcelain 2>/dev/null)
  unstaged=$(echo "$porcelain" | grep -c '^.[^ ]' || true)
  staged=$(echo "$porcelain" | grep -c '^[^ ]' || true)
  dirty_flag=""
  [ "$unstaged" -gt 0 ] && dirty_flag="${dirty_flag}□"
  [ "$staged" -gt 0 ] && dirty_flag="${dirty_flag}■"
  branch="⎇ ${branch}${dirty_flag:+ $dirty_flag}"
fi

# Model (strip "Claude " prefix and date suffix like -20241022)
model=$(echo "$input" | jq -r '.model.display_name // empty' | sed 's/^Claude //; s/ [0-9].*$//')

# Context usage + progress bar
used_pct=$(echo "$input" | jq -r '.context_window.used_percentage // empty')
used_pct_int=$(printf '%.0f' "${used_pct:-0}")

# Rate limits
five_pct=$(echo "$input" | jq -r '.rate_limits.five_hour.used_percentage // empty')
five_resets_at=$(echo "$input" | jq -r '.rate_limits.five_hour.resets_at // empty')

# 5h reset countdown
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

# Assemble
sep=" │ "
parts=()
[ -n "$current_dir" ] && parts+=("$current_dir")
[ -n "$branch" ] && parts+=("$branch")
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
