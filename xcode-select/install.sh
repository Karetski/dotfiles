#!/usr/bin/env bash

# xcode-select --install bootstraps Apple's Command Line Tools (clang,
# make, git, and the rest). Homebrew itself and any compile-from-source
# brew package will fail without them, so this role has to run before
# everything else. The installer is GUI-driven and asynchronous — we
# can't block on it, so if it needs to run we trigger it and abort the
# orchestrator with a clear message asking the user to re-run
# `make install` once the installer finishes.
if xcode-select -p > /dev/null 2>&1; then
  _log_skip "xcode-select" "Command Line Tools already installed"
elif [ "$DRY_RUN" = "1" ]; then
  _log_dry "xcode-select" "would launch Command Line Tools installer"
else
  xcode-select --install > /dev/null 2>&1 || true
  _log_err "Command Line Tools installer launched — wait for it to finish, then re-run 'make install'"
  exit 1
fi
