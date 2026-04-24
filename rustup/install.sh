#!/usr/bin/env bash
ensure_brew_formula rustup

# rustup only installs the toolchain bootstrapper; rustc/cargo themselves
# only materialise once a default toolchain is selected (≈200MB download).
# Prompt via the shared _optional_selected helper so the user can opt out
# on machines where Rust is already set up via another installer.
if rustup show active-toolchain > /dev/null 2>&1; then
  _log_skip "rust toolchain" "already set"
elif _optional_selected "rust-toolchain" "bootstrap" "rustup default stable"; then
  if [ "$DRY_RUN" != "1" ]; then
    rustup default stable
    _log_ok "rust toolchain" "installed"
  fi
fi
