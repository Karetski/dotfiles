#!/usr/bin/env bash
ensure_dir "$HOME/.config/zed"
deploy_file "$DOTFILES_DIR/zed/files/settings.json" "$HOME/.config/zed/settings.json"
_sanitize_bak "$HOME/.config/zed/settings.json"
