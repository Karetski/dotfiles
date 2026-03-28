#!/usr/bin/env bash
ensure_dir "$HOME/Library/Application Support/lazygit"
deploy_file "$DOTFILES_DIR/lazygit/files/config.yml" "$HOME/Library/Application Support/lazygit/config.yml"
