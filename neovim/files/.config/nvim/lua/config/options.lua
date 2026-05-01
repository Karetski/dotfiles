-- nvm exposes node only via an interactive-zsh shell function, so Mason-installed
-- Node LSPs (bashls, pyright, ts_ls, yamlls, jsonls) can't resolve `#!/usr/bin/env node`
-- when nvim is launched outside an interactive shell. Prepend the installed version's bin.
local nvm_bins = vim.fn.glob("~/.nvm/versions/node/*/bin", true, true)
if #nvm_bins > 0 then
  table.sort(nvm_bins)
  vim.env.PATH = nvm_bins[#nvm_bins] .. ":" .. vim.env.PATH
end

vim.opt.number = true
vim.opt.relativenumber = true
vim.opt.scrolloff = 8
vim.opt.clipboard = "unnamedplus"
vim.opt.cursorline = true
vim.opt.timeoutlen = 300
vim.opt.updatetime = 250
vim.opt.virtualedit = "onemore"
vim.opt.exrc = true
vim.opt.mouse = "a"

vim.g.normal_editor_mode = vim.env.NVIM_NORMAL_EDITOR == "1"
if vim.g.normal_editor_mode then
  vim.opt.relativenumber = false
  vim.opt.showmode = true
  vim.opt.virtualedit = ""

  local normal_editor_group = vim.api.nvim_create_augroup("NormalEditorMode", { clear = true })
  vim.api.nvim_create_autocmd({ "VimEnter", "BufEnter", "WinEnter" }, {
    group = normal_editor_group,
    callback = function()
      if vim.bo.buftype == "" and vim.bo.modifiable then
        vim.schedule(function()
          if vim.bo.buftype == "" and vim.bo.modifiable then
            vim.cmd.startinsert()
          end
        end)
      end
    end,
  })
end

vim.diagnostic.config({
  virtual_lines = false,
  virtual_text = true,
  signs = true,
})

vim.g.mapleader = " "
