#!/usr/bin/env bash
ensure_dir "$HOME/.config/nvim"

# Rename conflicting init file if present
if [ -f "$HOME/.config/nvim/init.vim" ] && [ "$DRY_RUN" != "1" ]; then
  mv "$HOME/.config/nvim/init.vim" "$HOME/.config/nvim/init.vim.bak"
  _log_ok "init.vim" "renamed to init.vim.bak (conflict)"
fi

deploy_file "$DOTFILES_DIR/neovim/files/.config/nvim/init.lua" "$HOME/.config/nvim/init.lua"
_sanitize_bak "$HOME/.config/nvim/init.lua"
_sanitize_dir "$HOME/.config/nvim" "$DOTFILES_DIR/neovim/sanitize-ignore" "init.lua"
