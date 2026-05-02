#!/usr/bin/env bash
# bun ships via the oven-sh/bun tap, not homebrew-core
if brew tap | grep -qx oven-sh/bun; then
  _log_skip "oven-sh/bun" "already tapped"
elif [ "$DRY_RUN" = "1" ]; then
  _log_dry "oven-sh/bun" "would tap"
else
  brew tap oven-sh/bun > /dev/null
  _log_ok "oven-sh/bun" "tapped"
fi

ensure_brew_formula bun
