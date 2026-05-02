#!/usr/bin/env bash

# Install RTK (Rust Token Killer) via Homebrew
ensure_brew_formula "rtk"

# Initialize RTK for Claude Code and other agents.
# We use --no-patch because we manage settings.json via the claude/files/settings.json
# to ensure our configuration is persistent and consistent with other hooks.
if [ "$DRY_RUN" = "1" ]; then
  _log_dry "rtk" "would run rtk init -g --no-patch"
else
  # Use printf to handle the telemetry prompt non-interactively
  printf "n\n" | rtk init -g --no-patch > /dev/null 2>&1 || true
  _log_ok "rtk" "initialized globally"
fi
