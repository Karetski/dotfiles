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

# Apply a string macOS default; skip if already at the desired value.
_defaults_string() {
  local label="$1" domain="$2" key="$3" value="$4"
  local current
  current=$(defaults read "$domain" "$key" 2>/dev/null || true)
  if [ "$current" = "$value" ]; then
    _log_skip "$label" "no change"
  elif [ "$DRY_RUN" = "1" ]; then
    _log_dry "$label" "would set → $value"
  else
    defaults write "$domain" "$key" -string "$value"
    _log_ok "$label" "set → $value"
  fi
}

# Finder: use column view by default.
_defaults_string \
  "Finder — column view" \
  "com.apple.finder" \
  "FXPreferredViewStyle" \
  "clmv"

# Finder: group by kind by default.
_defaults_string \
  "Finder — group by kind" \
  "com.apple.finder" \
  "FXPreferredGroupBy" \
  "Kind"

# Finder: sort by kind by default.
_defaults_string \
  "Finder — sort by kind" \
  "com.apple.finder" \
  "FXPreferredSortOrder" \
  "kind"

# Mission Control: keep Spaces in the user-defined order instead of
# silently promoting the most-recently-used Space to position 1.
_defaults_bool \
  "Mission Control — fixed Space order" \
  "com.apple.dock" \
  "mru-spaces" \
  "false"

# Restart Finder and Dock to apply changes.
if [ "$_SECTION_OK" -gt 0 ]; then
  killall Finder 2>/dev/null || true
  killall Dock 2>/dev/null || true
fi
