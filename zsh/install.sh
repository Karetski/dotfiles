#!/usr/bin/env bash

# zsh-autocomplete powers real-time completion; fzf backs the `vf` alias.
ensure_brew_formula zsh-autocomplete
ensure_brew_formula fzf

# ~/.local/bin is prepended to PATH in .zshrc for role-deployed scripts
ensure_dir "$HOME/.local/bin"
deploy_file "$DOTFILES_DIR/zsh/files/.zshrc" "$HOME/.zshrc"
_sanitize_bak "$HOME/.zshrc"
