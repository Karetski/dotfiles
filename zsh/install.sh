#!/usr/bin/env bash

# zsh-autocomplete powers real-time completion; fzf backs the `vf` alias.
# nvm is installed by its own role; .zshrc below sources it so node/npm
# land on PATH for interactive shells (and therefore Mason's installs).
ensure_brew_formula zsh-autocomplete
ensure_brew_formula fzf

# ~/.local/bin is prepended to PATH in .zshrc for role-deployed scripts
ensure_dir "$HOME/.local/bin"
deploy_file "$DOTFILES_DIR/zsh/files/.zshrc" "$HOME/.zshrc"
_sanitize_bak "$HOME/.zshrc"
