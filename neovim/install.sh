#!/usr/bin/env bash
ensure_brew_formula neovim

ensure_dir "$HOME/.config/nvim"

# Migrate from Vimscript to Lua config — rename the old file so Neovim doesn't
# load both init.vim and init.lua (init.lua takes precedence, but keep the backup)
if [ -f "$HOME/.config/nvim/init.vim" ] && [ "$DRY_RUN" != "1" ]; then
  mv "$HOME/.config/nvim/init.vim" "$HOME/.config/nvim/init.vim.bak"
  _log_ok "init.vim" "renamed to init.vim.bak (conflict)"
fi

deploy_file "$DOTFILES_DIR/neovim/files/.config/nvim/init.lua" "$HOME/.config/nvim/init.lua"
_sanitize_bak "$HOME/.config/nvim/init.lua"
# sanitize-ignore lists files created by lazy.nvim and other plugins at runtime
_sanitize_dir "$HOME/.config/nvim" "$DOTFILES_DIR/neovim/sanitize-ignore" "init.lua"
