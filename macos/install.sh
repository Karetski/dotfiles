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

# Read a nested plist value (plutil dot-path) from a domain, via cfprefsd.
_defaults_keypath_read() {
  defaults export "$1" - 2>/dev/null | plutil -extract "$2" raw -o - - 2>/dev/null || true
}

# Apply nested plist values that `defaults write` can't target. macOS forbids
# editing the on-disk plist directly (only cfprefsd may write it), and an app
# like Finder rewrites these keys while running, so the whole domain is
# round-tripped through `defaults export`/`import` with the app quit, then the
# app is relaunched. Args after the domain/app are "keypath=value" pairs.
_defaults_keypaths_quit() {
  local label="$1" domain="$2" app="$3"; shift 3
  local -a pending=()
  local pair keypath value current
  # Read-only pass: decide what actually needs changing.
  for pair in "$@"; do
    keypath="${pair%%=*}"; value="${pair#*=}"
    current=$(_defaults_keypath_read "$domain" "$keypath")
    if [ "$current" = "$value" ]; then
      _log_skip "$label — ${keypath##*.}" "no change"
    elif [ "$DRY_RUN" = "1" ]; then
      _log_dry "$label — ${keypath##*.}" "would set → $value"
    else
      pending+=("$pair")
    fi
  done
  [ "${#pending[@]}" -eq 0 ] && return 0

  # Write pass: quit the app so it can't clobber, edit the exported domain in one
  # transaction, import it back through cfprefsd, then relaunch the app.
  local tmp
  tmp=$(mktemp "${TMPDIR:-/tmp}/dotfiles-$domain.XXXXXX") || { _log_err "$label — mktemp failed"; return 1; }
  killall "$app" 2>/dev/null || true
  sleep 1
  defaults export "$domain" - > "$tmp"
  for pair in "${pending[@]}"; do
    keypath="${pair%%=*}"; value="${pair#*=}"
    if plutil -replace "$keypath" -string "$value" "$tmp" 2>/dev/null; then
      _log_ok "$label — ${keypath##*.}" "set → $value"
    else
      _log_note "$label — ${keypath##*.}" "view not yet initialised — open it in $app once, then re-run"
    fi
  done
  defaults import "$domain" "$tmp"
  rm -f "$tmp"
  open -a "$app" 2>/dev/null || true
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

# Finder: sort by kind by default. The actual sort/arrange setting lives in
# nested per-view dictionaries (not the ineffective FXPreferredSortOrder key), so
# it is applied via _defaults_keypaths_quit near the end, after all finder writes.

# Finder: keep folders on top when sorting by name.
_defaults_bool \
  "Finder — folders on top" \
  "com.apple.finder" \
  "_FXSortFoldersFirst" \
  "true"

# Finder: search current folder by default (SCcf).
_defaults_string \
  "Finder — search current folder" \
  "com.apple.finder" \
  "FXDefaultSearchScope" \
  "SCcf"

# Global: apply Finder preferences to Open/Save panels.
_defaults_string \
  "Global — column view" \
  "NSGlobalDomain" \
  "FXPreferredViewStyle" \
  "clmv"
_defaults_string \
  "Global — group by kind" \
  "NSGlobalDomain" \
  "FXPreferredGroupBy" \
  "Kind"

# Global: expanded save and print panels by default.
_defaults_bool \
  "Global — expanded save panel" \
  "NSGlobalDomain" \
  "NSNavPanelExpandedStateForSaveMode" \
  "true"
_defaults_bool \
  "Global — expanded save panel (v2)" \
  "NSGlobalDomain" \
  "NSNavPanelExpandedStateForSaveMode2" \
  "true"
_defaults_bool \
  "Global — expanded print panel" \
  "NSGlobalDomain" \
  "PMPrintingExpandedStateForPrint" \
  "true"
_defaults_bool \
  "Global — expanded print panel (v2)" \
  "NSGlobalDomain" \
  "PMPrintingExpandedStateForPrint2" \
  "true"

# Mission Control: keep Spaces in the user-defined order instead of
# silently promoting the most-recently-used Space to position 1.
_defaults_bool \
  "Mission Control — fixed Space order" \
  "com.apple.dock" \
  "mru-spaces" \
  "false"

# Finder: sort by kind by default, per view. These are nested keys `defaults
# write` can't reach, so they go through the export/import + quit/relaunch path.
# Column view (the default) uses four-char arrange codes (kipl = Kind); list and
# icon views use plain sort/arrange names.
_defaults_keypaths_quit \
  "Finder — sort by kind" \
  "com.apple.finder" \
  "Finder" \
  "StandardViewOptions.ColumnViewOptions.ArrangeBy=kipl" \
  "StandardViewSettings.ExtendedListViewSettingsV2.sortColumn=kind" \
  "StandardViewSettings.ListViewSettings.sortColumn=kind" \
  "StandardViewSettings.IconViewSettings.arrangeBy=kind"

# Restart Finder and Dock to apply the remaining changes. (The sort step above
# already quits/relaunches Finder when it has work to do.)
if [ "$_SECTION_OK" -gt 0 ]; then
  killall Finder 2>/dev/null || true
  killall Dock 2>/dev/null || true
fi
