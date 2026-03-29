#!/usr/bin/env bash
# Shared variables for all install scripts.

export CLAUDE_SANDBOX_ENABLED=true

OPTIONAL_ROLES=(
  claude
  codex
)

HOMEBREW_FORMULAE=(
  zsh-autocomplete
  lazygit
  micro
  jq
  fzf
  neovim
)

HOMEBREW_CASKS=(
  codex
  ghostty
)

OPTIONAL_HOMEBREW_CASKS=(
  codex
)
