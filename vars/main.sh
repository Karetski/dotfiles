#!/usr/bin/env bash
# Shared variables for all install scripts.
# Machine-specific overrides go in vars/local.sh (gitignored).

# Substituted into claude/templates/settings.json via envsubst
export CLAUDE_SANDBOX_ENABLED=true

# Roles that prompt before applying (unless ENABLE_OPTIONAL_<NAME>=1 in local.sh)
OPTIONAL_ROLES=(
  claude
  stats
)

# CLI tools installed by the homebrew role
HOMEBREW_FORMULAE=(
  zsh-autocomplete
  lazygit
  jq
  fzf
  neovim
)

# GUI apps installed by the homebrew role (--cask --adopt)
HOMEBREW_CASKS=(
  ghostty
  stats
  zed
)

# Formulae that prompt before installing (same opt-in mechanism as OPTIONAL_ROLES)
OPTIONAL_HOMEBREW_FORMULAE=()

# Casks that prompt before installing (same opt-in mechanism as OPTIONAL_ROLES)
OPTIONAL_HOMEBREW_CASKS=(
  stats
  zed
)
