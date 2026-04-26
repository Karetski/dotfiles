#!/usr/bin/env bash
ensure_brew_cask stats

# Stats stores its preferences as a macOS plist under the app's bundle ID.
# We check in the XML form so diffs are reviewable; `defaults import` applies
# the source atomically through cfprefsd, which avoids racing the live app.
STATS_DOMAIN="eu.exelban.Stats"
STATS_PLIST="$HOME/Library/Preferences/${STATS_DOMAIN}.plist"
STATS_SRC="$DOTFILES_DIR/stats/files/eu.exelban.Stats.plist"
_stats_display=$(_shorten "$STATS_PLIST")

# Render the live plist as XML so we can diff it against the checked-in source
_stats_current=$(mktemp)
if [ -f "$STATS_PLIST" ]; then
  plutil -convert xml1 -o "$_stats_current" "$STATS_PLIST" 2>/dev/null || : > "$_stats_current"
  # Volatile keys are filtered out of the checked-in copy; strip them here
  # too so diffs stay focused on real settings changes. `support_ts` is a
  # timestamp Stats rewrites on its own, unrelated to user-visible settings.
  plutil -remove 'NSWindow Frame eu\.exelban\.Stats\.Settings\.WindowFrame' "$_stats_current" 2>/dev/null || true
  plutil -remove support_ts "$_stats_current" 2>/dev/null || true
fi

if [ -f "$STATS_PLIST" ] && diff -q "$STATS_SRC" "$_stats_current" > /dev/null 2>&1; then
  _log_skip "$_stats_display" "no change"
elif [ "$DRY_RUN" = "1" ]; then
  _log_dry "$_stats_display" "would import"
  [ -s "$_stats_current" ] && _log_diff "$_stats_current" "$STATS_SRC"
else
  _stats_udiff=""
  [ -s "$_stats_current" ] && _stats_udiff=$(diff -u "$_stats_current" "$STATS_SRC" 2>/dev/null || true)
  [ -f "$STATS_PLIST" ] && cp "$STATS_PLIST" "${STATS_PLIST}.bak"
  defaults import "$STATS_DOMAIN" "$STATS_SRC"
  _log_ok "$_stats_display" "imported"
  [ -n "$_stats_udiff" ] && _log_diff_raw "$_stats_udiff"
fi
rm -f "$_stats_current"

_sanitize_bak "$STATS_PLIST"
