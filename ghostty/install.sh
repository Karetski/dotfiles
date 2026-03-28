#!/usr/bin/env bash
ensure_dir "$HOME/Library/Application Support/com.mitchellh.ghostty"
deploy_file "$DOTFILES_DIR/ghostty/files/config.ghostty" "$HOME/Library/Application Support/com.mitchellh.ghostty/config.ghostty"
