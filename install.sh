#!/usr/bin/env bash
set -euo pipefail

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
export DOTFILES_DIR

. "$DOTFILES_DIR/lib/utils.sh"
. "$DOTFILES_DIR/vars/main.sh"
if [ -f "$DOTFILES_DIR/vars/local.sh" ]; then
  . "$DOTFILES_DIR/vars/local.sh"
fi

ROLES=(homebrew zsh git lazygit claude ghostty micro)
TAG="${TAG:-}"

for role in "${ROLES[@]}"; do
  [ -n "$TAG" ] && [ "$role" != "$TAG" ] && continue
  _log_section "$role"
  # shellcheck source=/dev/null
  . "$DOTFILES_DIR/$role/install.sh"
done

_log_summary
