#!/usr/bin/env bash

# Apply a boolean macOS default; skip if already at the desired value.
_defaults_bool() {
  local label="$1" domain="$2" key="$3" value="$4"
  local expected current
  [ "$value" = "true" ] && expected="1" || expected="0"
  current=$(defaults read "$domain" "$key" 2>/dev/null || true)
  if [ "$current" = "$expected" ]; then
    _log_skip "$label" "no change"
  elif [ "$DRY_RUN" = "1" ]; then
    _log_dry "$label" "would set → $value"
  else
    defaults write "$domain" "$key" -bool "$value"
    _log_ok "$label" "set → $value"
  fi
}

# Mission Control: keep Spaces in the user-defined order instead of
# silently promoting the most-recently-used Space to position 1.
_defaults_bool \
  "Mission Control — fixed Space order" \
  "com.apple.dock" \
  "mru-spaces" \
  "false"

# Restart Dock to apply any com.apple.dock changes made above.
if [ "$_SECTION_OK" -gt 0 ]; then
  killall Dock 2>/dev/null || true
fi
