-- Personal option overrides on top of LazyVim defaults.
-- LazyVim already sets sensible values for relativenumber, number, cursorline,
-- clipboard, mouse, timeoutlen, signcolumn, undofile, smartcase, ignorecase,
-- laststatus=3, splitkeep=screen, etc.

vim.opt.scrolloff   = 8           -- LazyVim default is 4
vim.opt.virtualedit = "onemore"   -- LazyVim uses "block"; "onemore" lets the cursor move past the last char
vim.opt.exrc        = true        -- Auto-load project-local .nvim.lua (e.g. per-project makeprg)

-- Pin diagnostic presentation (no inline-multiline)
vim.diagnostic.config({
  virtual_lines = false,
  virtual_text  = true,
  signs         = true,
})

-- nvm exposes node only via an interactive-zsh shell function, so Mason-installed
-- Node LSPs (bashls, pyright, ts_ls, yamlls, jsonls) can't resolve `#!/usr/bin/env node`
-- when nvim is launched outside an interactive shell. Prepend the installed version's bin.
local nvm_bins = vim.fn.glob("~/.nvm/versions/node/*/bin", true, true)
if #nvm_bins > 0 then
  table.sort(nvm_bins)
  vim.env.PATH = nvm_bins[#nvm_bins] .. ":" .. vim.env.PATH
end
