#!/usr/bin/env bash
ensure_brew_cask visual-studio-code

# Only settings.json is managed; the rest of User/ is VS Code state, so no _sanitize_dir
ensure_dir "$HOME/Library/Application Support/Code/User"
deploy_file "$DOTFILES_DIR/vscode/files/settings.json" "$HOME/Library/Application Support/Code/User/settings.json"

_sanitize_bak "$HOME/Library/Application Support/Code/User/settings.json"
