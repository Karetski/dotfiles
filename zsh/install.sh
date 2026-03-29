#!/usr/bin/env bash
ensure_dir "$HOME/.local/bin"
deploy_file "$DOTFILES_DIR/zsh/files/.zshrc" "$HOME/.zshrc"
_sanitize_bak "$HOME/.zshrc"
