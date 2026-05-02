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
ensure_dir "$HOME/.claude/hooks"
# Hook scripts — deployed as executable (0755)
for hook in "$DOTFILES_DIR/claude/files/hooks/"*.sh; do
  deploy_file "$hook" "$HOME/.claude/hooks/$(basename "$hook")" "0755"
done
_sanitize_bak "$HOME/.claude/settings.json"
_sanitize_bak "$HOME/.claude/statusline.sh"
# Install Claude Code plugins at user scope
for _plugin in code-simplifier superpowers; do
  if claude plugin list 2>/dev/null | grep -A3 "^  . ${_plugin}@" | grep -q 'Scope: user'; then
    _log_skip "$_plugin" "already installed at user scope"
  elif [ "$DRY_RUN" = "1" ]; then
    _log_dry "$_plugin" "would install at user scope"
  else
    claude plugin install "$_plugin" --scope user
    _log_ok "$_plugin" "installed at user scope"
  fi
done
