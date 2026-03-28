#!/usr/bin/env bash
ensure_dir "$HOME/.config/git"
deploy_template "$DOTFILES_DIR/git/templates/gitconfig" "$HOME/.gitconfig" "0644" '$GIT_NAME $GIT_EMAIL'
deploy_file "$DOTFILES_DIR/git/files/ignore" "$HOME/.config/git/ignore"
