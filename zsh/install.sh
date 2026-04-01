#!/usr/bin/env bash

# ~/.local/bin is prepended to PATH in .zshrc for role-deployed scripts
ensure_dir "$HOME/.local/bin"
deploy_file "$DOTFILES_DIR/zsh/files/.zshrc" "$HOME/.zshrc"
_sanitize_bak "$HOME/.zshrc"
