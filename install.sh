#!/usr/bin/env bash
set -euo pipefail

# Resolve repo root regardless of symlinks or working directory
DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
export DOTFILES_DIR

. "$DOTFILES_DIR/lib/utils.sh"
. "$DOTFILES_DIR/vars/main.sh"
if [ -f "$DOTFILES_DIR/vars/local.sh" ]; then
  . "$DOTFILES_DIR/vars/local.sh"
fi

# Roles are applied in this order; each has a matching <role>/install.sh
ROLES=(homebrew zsh git lazygit claude ghostty stats zed neovim)
# TAG limits the run to a single role (e.g. TAG=git)
TAG="${TAG:-}"

_TOTAL=${#ROLES[@]}
_INDEX=0

# Check whether an optional role was already set up on this machine,
# so we can skip the interactive prompt and just note it.
_role_is_configured() {
  case "$1" in
    claude) command -v claude > /dev/null 2>&1 || [ -f "$HOME/.claude/settings.json" ] ;;
    stats)  [ -d "/Applications/Stats.app" ] ;;
    zed)    [ -d "/Applications/Zed.app" ] ;;
    *)      return 1 ;;
  esac
}

for role in "${ROLES[@]}"; do
  # Skip roles that don't match the TAG filter
  [ -n "$TAG" ] && [ "$role" != "$TAG" ] && continue
  _INDEX=$(( _INDEX + 1 ))
  # Omit the [n/total] counter when running a single tagged role
  if [ -n "$TAG" ]; then
    _log_section "$role"
  else
    _log_section "$role" "$_INDEX" "$_TOTAL"
  fi
  if _contains "$role" "${OPTIONAL_ROLES[@]+"${OPTIONAL_ROLES[@]}"}"; then
    if [ -n "$TAG" ] && [ "$role" = "$TAG" ]; then
      # Explicit TAG targets always run without prompting
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
