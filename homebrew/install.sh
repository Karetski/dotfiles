#!/usr/bin/env bash

# Homebrew must already be installed; this role only manages formulae and casks
if ! command -v brew > /dev/null 2>&1; then
  _log_err "Homebrew is not installed. Please install it first:"
  _log_err '  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"'
  exit 1
fi

# Install CLI formulae from HOMEBREW_FORMULAE (vars/main.sh)
for formula in "${HOMEBREW_FORMULAE[@]}"; do
  # Prompt for optional formulae, and for every formula under CONFIRM_MODE.
  # Already-installed packages skip the prompt — nothing would change anyway.
  if [ "${CONFIRM_MODE:-0}" = "1" ] || _contains "$formula" "${OPTIONAL_HOMEBREW_FORMULAE[@]+"${OPTIONAL_HOMEBREW_FORMULAE[@]}"}"; then
    if ! brew list --formula "$formula" > /dev/null 2>&1; then
      _optional_selected "$formula" "formula" "$formula" || continue
    fi
  fi
  if brew list --formula "$formula" > /dev/null 2>&1; then
    _log_skip "$formula" "already installed"
  elif [ "$DRY_RUN" = "1" ]; then
    _log_dry "$formula" "would install"
  else
    _log_brew_start "$formula"
    brew install "$formula" 2>&1 | _brew_pipe
    _log_brew_end
    _log_ok "$formula" "installed"
  fi
done

# Install GUI casks from HOMEBREW_CASKS (vars/main.sh)
for cask in "${HOMEBREW_CASKS[@]}"; do
  # Prompt for optional casks, and for every cask under CONFIRM_MODE.
  # Already-installed casks skip the prompt — nothing would change anyway.
  if [ "${CONFIRM_MODE:-0}" = "1" ] || _contains "$cask" "${OPTIONAL_HOMEBREW_CASKS[@]+"${OPTIONAL_HOMEBREW_CASKS[@]}"}"; then
    if ! brew list --cask "$cask" > /dev/null 2>&1; then
      _optional_selected "$cask" "cask" "$cask" || continue
    fi
  fi
  if brew list --cask "$cask" > /dev/null 2>&1; then
    _log_skip "$cask" "already installed  (cask)"
  elif [ "$DRY_RUN" = "1" ]; then
    _log_dry "$cask" "would install  (cask)"
  else
    _log_brew_start "$cask"
    # --adopt claims existing app installations instead of re-downloading
    brew install --cask --adopt "$cask" 2>&1 | _brew_pipe
    _log_brew_end
    _log_ok "$cask" "installed  (cask)"
  fi
done
