#!/usr/bin/env bash
if ! command -v brew > /dev/null 2>&1; then
  _log_err "Homebrew is not installed. Please install it first:"
  _log_err '  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"'
  exit 1
fi

for formula in "${HOMEBREW_FORMULAE[@]}"; do
  if brew list --formula "$formula" > /dev/null 2>&1; then
    _log_skip "$formula" "already installed"
  elif [ "$DRY_RUN" = "1" ]; then
    _log_dry "$formula" "would install"
  else
    brew install "$formula"
    _log_ok "$formula" "installed"
  fi
done

for cask in "${HOMEBREW_CASKS[@]}"; do
  if brew list --cask "$cask" > /dev/null 2>&1; then
    _log_skip "$cask" "already installed (cask)"
  elif [ "$DRY_RUN" = "1" ]; then
    _log_dry "$cask" "would install (cask)"
  else
    brew install --cask --adopt "$cask"
    _log_ok "$cask" "installed (cask)"
  fi
done
