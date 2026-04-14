#!/usr/bin/env bash

# Deploys .zshrc. Dependencies (zsh-autocomplete, fzf, nvm) are installed
# by their own roles and sourced from .zshrc at interactive-shell startup.

# ~/.local/bin is prepended to PATH in .zshrc for role-deployed scripts
ensure_dir "$HOME/.local/bin"
deploy_file "$DOTFILES_DIR/zsh/files/.zshrc" "$HOME/.zshrc"
_sanitize_bak "$HOME/.zshrc"
