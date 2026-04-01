#!/usr/bin/env bash

# Install Claude CLI if not already present (separate from Homebrew — uses Anthropic's installer)
if ! command -v claude > /dev/null 2>&1; then
  if [ "$DRY_RUN" = "1" ]; then
    _log_dry "claude" "would install"
  else
    curl -sSL https://claude.ai/install.sh | sh
    _log_ok "claude" "installed"
  fi
else
  _log_skip "claude" "already installed"
fi
# Substitutes $CLAUDE_SANDBOX_ENABLED from vars/main.sh
deploy_template "$DOTFILES_DIR/claude/templates/settings.json" "$HOME/.claude/settings.json" "0644" '$CLAUDE_SANDBOX_ENABLED'
# Deployed as executable (0755) — invoked by Claude Code's status line harness
deploy_file "$DOTFILES_DIR/claude/files/statusline.sh" "$HOME/.claude/statusline.sh" "0755"
_sanitize_bak "$HOME/.claude/settings.json"
_sanitize_bak "$HOME/.claude/statusline.sh"
