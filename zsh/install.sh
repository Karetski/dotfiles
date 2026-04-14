#!/usr/bin/env bash

# zsh-autocomplete powers real-time completion; fzf backs the `vf` alias;
# nvm manages Node versions and is sourced from .zshrc so Mason-installed
# LSPs (bashls, jsonls, yamlls, pyright, ts_ls) can find node/npm on PATH.
ensure_brew_formula zsh-autocomplete
ensure_brew_formula fzf
ensure_brew_formula nvm

ensure_dir "$HOME/.nvm"

# Bootstrap a default Node via nvm if none is selected yet. nvm is a shell
# function (not a binary), so source it in a `bash -c` subshell — that shell
# starts with default options and won't trip the parent's set -euo pipefail.
if [ ! -e "$HOME/.nvm/alias/default" ]; then
  if _optional_selected "nvm-default-node" "bootstrap" "nvm install --lts"; then
    if [ "$DRY_RUN" != "1" ]; then
      bash -c '
        export NVM_DIR="$HOME/.nvm"
        # shellcheck disable=SC1090
        . "$(brew --prefix nvm)/nvm.sh"
        nvm install --lts
        nvm alias default "lts/*"
      '
    fi
  fi
fi

# ~/.local/bin is prepended to PATH in .zshrc for role-deployed scripts
ensure_dir "$HOME/.local/bin"
deploy_file "$DOTFILES_DIR/zsh/files/.zshrc" "$HOME/.zshrc"
_sanitize_bak "$HOME/.zshrc"
