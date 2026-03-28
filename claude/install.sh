#!/usr/bin/env bash
if ! command -v claude > /dev/null 2>&1; then
  if [ "$DRY_RUN" = "1" ]; then
    _log_dry "install claude CLI"
  else
    curl -sSL https://claude.ai/install.sh | sh
  fi
else
  _log_skip "claude CLI"
fi
deploy_template "$DOTFILES_DIR/claude/templates/settings.json" "$HOME/.claude/settings.json" "0644" '$CLAUDE_SANDBOX_ENABLED'
deploy_file "$DOTFILES_DIR/claude/files/statusline.sh" "$HOME/.claude/statusline.sh" "0755"
