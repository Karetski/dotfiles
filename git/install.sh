#!/usr/bin/env bash

# GIT_NAME and GIT_EMAIL are substituted into the gitconfig template
if [ -z "${GIT_NAME:-}" ] || [ -z "${GIT_EMAIL:-}" ]; then
  echo "ERROR: GIT_NAME and GIT_EMAIL must be set in vars/local.sh" >&2
  exit 1
fi
ensure_dir "$HOME/.config/git"
# Restrict envsubst to only $GIT_NAME and $GIT_EMAIL to preserve other $ literals
deploy_template "$DOTFILES_DIR/git/templates/gitconfig" "$HOME/.gitconfig" "0644" '$GIT_NAME $GIT_EMAIL'
deploy_file "$DOTFILES_DIR/git/files/ignore" "$HOME/.config/git/ignore"

_sanitize_bak "$HOME/.gitconfig"
_sanitize_bak "$HOME/.config/git/ignore"
# Prompt to remove unmanaged files in ~/.config/git (only "ignore" is managed)
_sanitize_dir "$HOME/.config/git" "" "ignore"
