#!/usr/bin/env bash

# Preflight: verify Homebrew itself is installed. Individual packages are
# declared by the roles that need them via ensure_brew_formula/ensure_brew_cask.
if command -v brew > /dev/null 2>&1; then
  _log_skip "brew" "already installed"
else
  _log_err "Homebrew is not installed. Install it first:"
  _log_err '  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"'
  exit 1
fi
