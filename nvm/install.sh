#!/usr/bin/env bash
ensure_brew_formula nvm

ensure_dir "$HOME/.nvm"

# Bootstrap a default Node via nvm if none is selected yet. nvm is a shell
# function (not a binary), so source it in a `bash -c` subshell — that shell
# starts with default options and won't trip the parent's set -euo pipefail.
if [ -e "$HOME/.nvm/alias/default" ]; then
  _log_skip "nvm default node" "already set"
elif _optional_selected "nvm-default-node" "bootstrap" "nvm install --lts"; then
  if [ "$DRY_RUN" != "1" ]; then
    bash -c '
      export NVM_DIR="$HOME/.nvm"
      # shellcheck disable=SC1090
      . "$(brew --prefix nvm)/nvm.sh"
      nvm install --lts
      nvm alias default "lts/*"
    '
    _log_ok "nvm default node" "installed"
  fi
fi
