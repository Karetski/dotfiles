-- Bootstrap lazy.nvim
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not vim.loop.fs_stat(lazypath) then
  vim.fn.system({
    "git", "clone", "--filter=blob:none",
    "https://github.com/folke/lazy.nvim.git",
    "--branch=stable", lazypath,
  })
end
vim.opt.rtp:prepend(lazypath)

-- Options
vim.opt.number = true
vim.opt.relativenumber = true
vim.opt.scrolloff = 8
vim.opt.clipboard = "unnamedplus"
vim.opt.cursorline = true

-- Leader
vim.g.mapleader = " "

-- Keymaps
vim.keymap.set("n", "H", "0")
vim.keymap.set("n", "L", "$")
vim.keymap.set("n", "J", "G")
vim.keymap.set("n", "K", "gg")
vim.keymap.set("n", "w", "b")
vim.keymap.set("n", "W", "B")
vim.keymap.set("i", "jk", "<Esc>")
vim.keymap.set("n", "<leader>e", "<cmd>Neotree toggle<cr>")

-- Highlights
vim.api.nvim_set_hl(0, "MatchParen", { underline = true, bg = "none" })

-- Plugins
require("lazy").setup({
  {
    "nvim-neo-tree/neo-tree.nvim",
    branch = "v3.x",
    dependencies = {
      "nvim-lua/plenary.nvim",
      "nvim-tree/nvim-web-devicons",
      "MunifTanjim/nui.nvim",
    },
    opts = {
      filesystem = {
        follow_current_file = { enabled = true },
        hijack_netrw_behavior = "open_current",
      },
      window = { width = 30 },
    },
  },
  {
    "catppuccin/nvim",
    name = "catppuccin",
    priority = 1000,
    config = function()
      require("catppuccin").setup({ flavour = "latte" })
      vim.cmd("colorscheme catppuccin")
    end,
  },
})
