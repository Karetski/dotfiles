#!/usr/bin/env bash
set -euo pipefail

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
export DOTFILES_DIR

. "$DOTFILES_DIR/lib/utils.sh"
. "$DOTFILES_DIR/vars/main.sh"
if [ -f "$DOTFILES_DIR/vars/local.sh" ]; then
  . "$DOTFILES_DIR/vars/local.sh"
fi

ROLES=(homebrew zsh git lazygit claude codex ghostty micro neovim)
TAG="${TAG:-}"

_TOTAL=${#ROLES[@]}
_INDEX=0

_role_is_configured() {
  case "$1" in
    claude) command -v claude > /dev/null 2>&1 || [ -f "$HOME/.claude/settings.json" ] ;;
    codex)  [ -d "$HOME/.codex" ] ;;
    *)      return 1 ;;
  esac
}

for role in "${ROLES[@]}"; do
  [ -n "$TAG" ] && [ "$role" != "$TAG" ] && continue
  _INDEX=$(( _INDEX + 1 ))
  if [ -n "$TAG" ]; then
    _log_section "$role"
  else
    _log_section "$role" "$_INDEX" "$_TOTAL"
  fi
  if _contains "$role" "${OPTIONAL_ROLES[@]+"${OPTIONAL_ROLES[@]}"}"; then
    if [ -n "$TAG" ] && [ "$role" = "$TAG" ]; then
      :
    elif _role_is_configured "$role"; then
      _log_note "$role" "optional — already configured"
    elif ! _optional_selected "$role" "role" "$role"; then
      continue
    fi
  fi
  # shellcheck source=/dev/null
  . "$DOTFILES_DIR/$role/install.sh"
done

_log_summary
