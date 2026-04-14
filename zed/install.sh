#!/usr/bin/env bash
ensure_brew_cask zed

ensure_dir "$HOME/.config/zed"
deploy_file "$DOTFILES_DIR/zed/files/settings.json" "$HOME/.config/zed/settings.json"
deploy_file "$DOTFILES_DIR/zed/files/keymap.json" "$HOME/.config/zed/keymap.json"
_sanitize_bak "$HOME/.config/zed/settings.json"
_sanitize_bak "$HOME/.config/zed/keymap.json"
