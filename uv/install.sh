#!/usr/bin/env bash
ensure_brew_formula uv

# uv fetches Python on demand per-project, but a globally installed version
# is convenient for ad-hoc scripts and uvx one-shot tool runs.
if uv python list --only-installed 2>/dev/null | grep -q .; then
  _log_skip "uv default python" "already installed"
elif _optional_selected "uv-default-python" "bootstrap" "uv python install"; then
  if [ "$DRY_RUN" != "1" ]; then
    uv python install
    _log_ok "uv default python" "installed"
  fi
fi
