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
ROLES=(
  # preflight
  xcode-select
  homebrew

  # shell
  zsh
  zsh-autocomplete
  fzf
  nvm

  # cli tools
  git
  lazygit
  jq
  ripgrep
  fd

  # dev tools
  claude
  docker-desktop

  # system
  ghostty
  stats
  linearmouse

  # toolchains
  go
  rust

  # editor
  zed
  neovim
)
# TAG limits the run to a single role (e.g. TAG=git)
TAG="${TAG:-}"
# CONFIRM_MODE=1 treats every role and brew package as optional for this run,
# prompting [y/N] before each one regardless of OPTIONAL_* membership.
CONFIRM_MODE="${CONFIRM_MODE:-0}"
export CONFIRM_MODE

_TOTAL=${#ROLES[@]}
_INDEX=0
_PREV_GROUP=""

# Check whether an optional role was already set up on this machine,
# so we can skip the interactive prompt and just note it.
_role_is_configured() {
  case "$1" in
    claude)         command -v claude > /dev/null 2>&1 || [ -f "$HOME/.claude/settings.json" ] ;;
    stats)          [ -d "/Applications/Stats.app" ] ;;
    zed)            [ -d "/Applications/Zed.app" ] ;;
    docker-desktop) [ -d "/Applications/Docker.app" ] ;;
    linearmouse)    [ -d "/Applications/LinearMouse.app" ] ;;
    *)              return 1 ;;
  esac
}

# Map a role to its display group. Keep in sync with the comment
# headers inside the ROLES array above.
_role_group() {
  case "$1" in
    xcode-select|homebrew)                                   echo "preflight"  ;;
    zsh|zsh-autocomplete|fzf|nvm)                            echo "shell"      ;;
    git|lazygit|jq|ripgrep|fd)                               echo "cli tools"  ;;
    claude|docker-desktop)                                   echo "dev tools"  ;;
    ghostty|stats|linearmouse)                               echo "system"     ;;
    go|rust)                                                 echo "toolchains" ;;
    zed|neovim)                                              echo "editor"     ;;
    *)                                                       echo ""           ;;
  esac
}

for role in "${ROLES[@]}"; do
  # Skip roles that don't match the TAG filter
  [ -n "$TAG" ] && [ "$role" != "$TAG" ] && continue
  _INDEX=$(( _INDEX + 1 ))
  # Emit a group header when the group changes (full runs only —
  # single-role TAG runs don't need the grouping context).
  if [ -z "$TAG" ]; then
    _current_group=$(_role_group "$role")
    if [ "$_current_group" != "$_PREV_GROUP" ]; then
      _log_group "$_current_group"
      _PREV_GROUP="$_current_group"
    fi
  fi
  # Omit the [n/total] counter when running a single tagged role
  if [ -n "$TAG" ]; then
    _log_section "$role"
  else
    _log_section "$role" "$_INDEX" "$_TOTAL"
  fi
  if [ "$CONFIRM_MODE" = "1" ] || _contains "$role" "${OPTIONAL_ROLES[@]+"${OPTIONAL_ROLES[@]}"}"; then
    if [ -n "$TAG" ] && [ "$role" = "$TAG" ]; then
      # Explicit TAG targets always run without prompting
      :
    elif [ "$CONFIRM_MODE" != "1" ] && _role_is_configured "$role"; then
      _log_note "$role" "optional — already configured"
    elif ! _optional_selected "$role" "role" "$role"; then
      continue
    fi
  fi
  # shellcheck source=/dev/null
  . "$DOTFILES_DIR/$role/install.sh"
done

_log_summary
