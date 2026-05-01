#!/usr/bin/env bash
# Installs neovim and deploys its config. Runtime dependencies
# (ripgrep and fd for snacks.nvim pickers; node/npm via nvm for the
# Node-based LSPs) are installed by their own roles and resolved on
# PATH at launch time.
ensure_brew_formula neovim

NVIM_SRC="$DOTFILES_DIR/neovim/files/.config/nvim"
NVIM_DEST="$HOME/.config/nvim"

ensure_dir "$NVIM_DEST"
ensure_dir "$NVIM_DEST/lua/config"
ensure_dir "$NVIM_DEST/lua/plugins"

# Migrate from Vimscript to Lua config — rename the old file so Neovim doesn't
# load both init.vim and init.lua (init.lua takes precedence, but keep the backup)
if [ -f "$NVIM_DEST/init.vim" ] && [ "$DRY_RUN" != "1" ]; then
  mv "$NVIM_DEST/init.vim" "$NVIM_DEST/init.vim.bak"
  _log_ok "init.vim" "renamed to init.vim.bak (conflict)"
fi

deploy_file "$NVIM_SRC/init.lua" "$NVIM_DEST/init.lua"
for f in "$NVIM_SRC/lua/config/"*.lua; do
  deploy_file "$f" "$NVIM_DEST/lua/config/$(basename "$f")"
done
for f in "$NVIM_SRC/lua/plugins/"*.lua; do
  deploy_file "$f" "$NVIM_DEST/lua/plugins/$(basename "$f")"
done

_sanitize_bak "$NVIM_DEST/init.lua"
# sanitize-ignore lists files created by lazy.nvim and other plugins at runtime
_sanitize_dir "$NVIM_DEST" "$DOTFILES_DIR/neovim/sanitize-ignore" "init.lua"
_sanitize_dir "$NVIM_DEST/lua/config" "" $(cd "$NVIM_SRC/lua/config" && ls *.lua)
_sanitize_dir "$NVIM_DEST/lua/plugins" "" $(cd "$NVIM_SRC/lua/plugins" && ls *.lua)
