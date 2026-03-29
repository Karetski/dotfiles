#!/usr/bin/env bash
ensure_dir "$HOME/Library/Application Support/lazygit"
deploy_file "$DOTFILES_DIR/lazygit/files/config.yml" "$HOME/Library/Application Support/lazygit/config.yml"

_sanitize_bak "$HOME/Library/Application Support/lazygit/config.yml"
_sanitize_dir "$HOME/Library/Application Support/lazygit" "$DOTFILES_DIR/lazygit/sanitize-ignore" "config.yml"
